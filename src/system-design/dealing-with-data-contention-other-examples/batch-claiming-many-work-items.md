# Claiming Large Batches of Work Items

## Problem

Many application instances need to process a large table of independent work items in batches. Each item must be claimed by at most one active worker, and unfinished work must become available again after a worker crashes.

## Alternative: partition ownership with database-backed leases

Instead of having workers claim individual work items, divide the work-item space into a fixed number of logical partitions. A partition is simply a group of items that can be identified deterministically. For example, assign an item with `PartitionId = Hash(ItemId) % PartitionCount`, or use ranges of IDs. The same item must always map to the same partition. The partition count and mapping should remain stable, or changes to them must be handled as an explicit repartitioning operation.

A separate table stores the current owner and lease for each partition. Workers coordinate through this table; there is no separate coordinator process:

```text
PartitionLeases
---------------
PartitionId       -- primary key
WorkerId          -- current owner
LeaseExpiresAt    -- when ownership may be acquired by another worker
LeaseEpoch        -- increasing fencing token
```

A worker follows this lifecycle:

1. **Discover eligible partitions.** Look for partitions whose lease is absent or expired and that have work waiting. The work-exists check is an optimization to avoid leasing empty partitions; correctness must not depend on it because new work can arrive immediately afterward.
2. **Acquire ownership atomically.** In a short database transaction, claim an eligible partition only if its lease is still available or expired. Set `WorkerId`, extend `LeaseExpiresAt`, and increment `LeaseEpoch`. Use database locking/conditional updates so two workers cannot both acquire the same current lease.
3. **Bound ownership.** Configure a maximum number of partitions a worker may own. Without this limit, a worker that starts first can lease every partition, leaving later workers idle even when new work arrives. Claiming only a bounded number leaves capacity for other workers.
4. **Process only owned partitions.** Query the work-item table for ready items in the worker's owned partitions, and claim/process them in bounded batches. The item query can cover all owned partitions; a separate `COUNT(*)` or `EXISTS` query is not required before each batch.
5. **Renew while active.** Periodically extend each lease before it expires, conditional on the same `WorkerId` and `LeaseEpoch`. If the renewal updates zero rows, ownership has been lost and the worker must stop starting new work for that partition.
6. **Release idle partitions.** If a partition has no work for a configured idle period, release it so another worker can use its capacity. Avoid releasing and reacquiring it on every empty poll; that creates unnecessary lease churn. A worker should also release its partitions during a graceful shutdown.
7. **Recover after failure.** If a worker crashes, its leases eventually expire and another worker can acquire those partitions. The new owner receives a higher `LeaseEpoch`.

The lease epoch is a **fencing token**. Every completion or lease renewal must verify the current owner and epoch, so an old worker cannot update database state after its lease has expired and another worker has taken ownership. If processing performs external side effects, those operations must also be idempotent or enforce the fencing token themselves; a database lease cannot stop a stale process from calling an external system.

### Balancing and scheduling considerations

The database lease table is the runtime coordinator, while deterministic partitioning decides which items belong together. Workers repeatedly look for eligible partitions when they have capacity. A maximum partition count prevents one fast-starting worker from taking everything; releasing partitions that remain idle makes them available to workers that have work. You can prioritize partitions with the oldest or highest-priority ready item when acquiring leases, but this is a scheduling preference, not a guarantee of perfectly even distribution.

There is an inherent trade-off: longer leases and longer idle-release periods reduce coordination traffic but can leave capacity unused; shorter periods improve responsiveness but increase lease updates and ownership churn. Choose these intervals based on processing time and polling behavior, and monitor per-worker partition counts, queue depth, and processing latency.

Partition ownership is useful when all items in a logical group must be handled by one worker at a time, when per-partition ordering or partition-local state matters, or when group-level scheduling is a real requirement. It handles competing workers contention by serializing through single record logical partitons, but it is more complicated than claiming independent items: it adds lease management, renewal, balancing, failure recovery, and fencing. It also does not remove the need for item-level idempotency and safe retries.

## Recommended approach: atomic batch claiming

For independent work items, start with direct batch claiming from the work-item table. It is simpler and usually provides sufficient concurrency without a second ownership mechanism. Use partition ownership only when you need group-level coordination, such as per-customer ordering, partition-local state, or exclusive processing of all items in a logical group.

The claim operation must select and update the rows in one atomic database statement. Do not select a batch in one query and update it in a later query; concurrent workers could select the same rows.

### SQL Server

```sql
;WITH batch AS
(
    SELECT TOP (@BatchSize) ItemId
    FROM dbo.WorkItems WITH (UPDLOCK, READPAST, ROWLOCK)
    WHERE AvailableAt <= SYSUTCDATETIME()
      AND
      (
          Status = 'Ready'
          OR (Status = 'Running' AND LeaseExpiresAt <= SYSUTCDATETIME())
      )
    ORDER BY Priority DESC, CreatedAt, ItemId
)
UPDATE wi
SET Status = 'Running',
    WorkerId = @workerId,
    LeaseEpoch = LeaseEpoch + 1,
    LeaseExpiresAt = DATEADD(MINUTE, @leaseMinutes, SYSUTCDATETIME())
OUTPUT inserted.ItemId, inserted.Payload, inserted.LeaseEpoch
FROM dbo.WorkItems AS wi
JOIN batch AS b ON b.ItemId = wi.ItemId;
```

- `UPDLOCK` prevents competing claimers from claiming the same selected rows.
- `READPAST` lets a worker skip row-level locks held by another worker instead of waiting for them.
- `ROWLOCK` requests row-level locks; it is not a guarantee and does not disable lock escalation. `READPAST` does not skip page locks.
- The `ORDER BY` defines selection preference, not a guarantee that batches are contiguous or that `OUTPUT` rows are returned in that order.
- If `READ_COMMITTED_SNAPSHOT` is enabled and the session uses `READ COMMITTED`, check the SQL Server requirements for combining `READPAST` with `READCOMMITTEDLOCK`.

### PostgreSQL

Use `FOR UPDATE SKIP LOCKED` to select candidate rows inside the same transaction, then update and return the claimed rows. PostgreSQL does not use SQL Server's lock hints; row-level locking with `SKIP LOCKED` is the usual queue-claiming pattern.

## Worker loop and recovery

1. Each instance claims a bounded batch whenever it has processing capacity.
2. It commits the claim transaction immediately; do not keep database locks or a transaction open while processing the batch.
3. It processes the returned items and records completion in a short transaction.
4. If no rows are returned, it is idle until its next polling interval. Avoid a separate `COUNT(*)` or `EXISTS` query before claiming.
5. A worker crash leaves items in `Running`. Their leases expire, allowing another worker to reclaim them.
6. Use a per-item increasing `LeaseEpoch` (or a unique claim token). Completion must match the current worker and claim generation so a stale worker cannot complete an item after it has been reclaimed.
7. Make processing idempotent. If an external side effect succeeds but the worker crashes before recording completion, the item may be processed again.

Use an index that supports the eligibility predicate and ordering, and validate it with the actual execution plan. Start with a moderate batch size and bounded concurrent batches per instance; tune using throughput, lock waits, log pressure, and latency measurements.

## When to use a broker or partition coordinator instead

Direct batch claiming is usually the simplest choice when items are independent and SQL Server is already the durable source of truth. Non-contiguous batches do not by themselves make this approach incorrect or inefficient; SQL Server can locate and update individual index keys. Measure before adding partition ownership.

If you genuinely need exclusive ownership of groups of items, per-key ordering, or sophisticated scheduling and rebalancing, consider an established durable broker or coordination system rather than building partition assignment, leases, renewal, balancing, and fencing from scratch. This adds infrastructure and operational costs, so adopt it only when the requirements justify it. A broker does not remove the need for idempotent processing and safe handling of retries.
