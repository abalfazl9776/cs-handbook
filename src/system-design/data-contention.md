# Data Contention: A Practical Decision Guide

Data contention occurs when concurrent operations compete over shared persistent state or a limited data resource. The goal is not to add locks everywhere. Protect the exact invariant that can be broken, using the least expensive mechanism that actually protects it.

> Keep one authoritative owner for each piece of state. Make that owner enforce the invariant atomically. Add coordination only when the simpler boundary is not wide enough.

Examples primarily use SQL Server syntax. PostgreSQL examples are included where materially different. Isolation and concurrency semantics vary by database.

## Table of contents

| Problem or signal | First approach to consider |
|---|---|
| Work can be divided by key | Avoid shared state / single-writer ownership ([details](#avoiding-shared-state)) |
| A row-level rule can be checked during a write | Conditional update or constraint ([details](#conditional-writes-and-constraints)) |
| Requests or messages may repeat | Idempotency key and unique constraint ([details](#duplicate-requests-and-idempotency)) |
| A read–decide–write occasionally conflicts | Optimistic concurrency ([details](#optimistic-concurrency-control)) |
| A read–decide–write must wait for conflicting writers | Pessimistic database locking ([details](#pessimistic-database-locking)) |
| A rule spans rows | Conditional write on a maintained guard/count row, targeted parent-row serialization, or serializable isolation ([details](#cross-row-invariants-and-serializable-isolation)) |
| A resource must be held during a user workflow | Expiring reservation ([details](#time-bound-reservations)) |
| Workers compete to claim jobs | Atomic job claim ([details](#competing-workers-claiming-jobs)) |
| One key receives too many writes | Per-key queue or sharded state ([details](#queue-based-serialization), [details](#hot-counters-and-write-sharding)) |
| Multiple nodes need a lease | Distributed lock with ownership safeguards ([details](#distributed-locks)) |
| Readers block writers | MVCC / row-versioned reads ([details](#reducing-reader-writer-blocking)) |
| A workflow crosses databases/services | Saga or 2PC ([details](#when-the-invariant-crosses-services)) |
| Concurrent writes happen in multiple regions | Single-writer ownership or conflict-free merge ([details](#multi-region-writes-and-replication)) |
| Latency, lock waits, or retries rise | Diagnose contention before adding coordination ([details](#deadlocks-retries-and-operational-diagnosis)) |

## Avoiding shared state

**Problem.** Multiple workers update the same counter, aggregate, file, or database row even though the work could be divided. This creates contention before locking is needed.

**Use this when.** Requests can be assigned independent ownership boundaries such as tenant, account, order, customer, or resource ID.

**Technique.** Partition work so each key has one logical owner at a time. Keep unrelated keys independent. Prefer a single-writer model per aggregate over allowing every node to update every aggregate.

**Example.** Route all events for `order-123` to one queue partition or actor. Events for `order-456` can be processed in parallel elsewhere.

**Gotchas.** Partitioning localizes contention but does not remove it for a genuinely hot key. A poor partition key can create overloaded partitions. Changing partition count can affect key mapping and ordering. Do not split state if an invariant must be enforced atomically across the pieces.

## Conditional writes and constraints

**Problem.** Code reads a value, checks a rule, and writes later. Two requests can both pass the check using the same stale value.

**Use this when.** The rule can be expressed as a predicate on the row being changed: stock must be sufficient, a seat available, a job unclaimed, or status still `Pending`.

**Technique.** Put the condition in the write itself. Let the database serialize conflicting writes to the same row. Treat affected-row count as the attempt's result.

**Example.** Atomic inventory decrement:

```sql
UPDATE dbo.Inventory
SET AvailableQuantity = AvailableQuantity - @quantity
WHERE ProductId = @productId
  AND AvailableQuantity >= @quantity;

-- 1 row: reserved; 0 rows: insufficient stock or missing product.
```

Gate related writes on the conditional update succeeding:

```sql
BEGIN TRANSACTION;

UPDATE dbo.Inventory
SET AvailableQuantity = AvailableQuantity - @quantity
WHERE ProductId = @productId
  AND AvailableQuantity >= @quantity;

IF @@ROWCOUNT = 0
BEGIN
    ROLLBACK TRANSACTION;
    RETURN;
END;

INSERT dbo.Reservations(ProductId, UserId, Quantity)
VALUES (@productId, @userId, @quantity);

COMMIT TRANSACTION;
```

For a particular seat, update the seat itself:

```sql
UPDATE dbo.Seats
SET Status = 'Reserved', ReservedBy = @userId
WHERE SeatId = @seatId
  AND Status = 'Available';
```

A unique index protects uniqueness:

```sql
CREATE UNIQUE INDEX UX_Seat_Concert_Seat
ON dbo.Seats(ConcertId, SeatNumber);
```

If number of concurrent requests are too many for a single database instance to handle, you can use Redis with `SET NX` command.

**Gotchas.** Zero affected rows is usually not a SQL error and does not automatically roll back the transaction. Check the count before dependent writes. A count row protects the count, not the identity of a seat. Use a transaction for multiple writes that must succeed together. Constraints are the final protection against races in “check then insert”; application pre-checks are insufficient. A `CHECK` constraint normally validates one row, not an arbitrary aggregate across rows.

## Duplicate requests and idempotency

**Problem.** A user retries after a timeout, a client sends twice, or a broker redelivers. The original operation may have succeeded even though the caller did not receive its response.

**Use this when.** The same logical command may be delivered more than once and must have one effective outcome.

**Technique.** Require an idempotency key identifying the logical operation. Enforce uniqueness in the authoritative database and persist status/result. On duplicate, return or resume the existing operation rather than executing it again.

**Example.**

```sql
CREATE UNIQUE INDEX UX_Payment_IdempotencyKey
ON dbo.Payments(IdempotencyKey);
```

Persist the request and business state in one transaction. Store a request hash too, so the same key cannot be reused for a different amount or recipient.

**Gotchas.** Idempotency does not prevent two different requests from spending the same balance; you may need both idempotency and a conditional debit. “Exactly once” is not generally guaranteed end-to-end over a network. Design for at-least-once delivery with idempotent effects. For external payment providers, use their idempotency feature when supported and reconcile uncertain outcomes. Do not hold a database transaction open while calling the provider.

## Optimistic concurrency control

**Problem.** The application reads a row, calculates a change, and writes based on what it read. Another writer may change the row first.

**Use this when.** Conflicts are relatively rare, reads are common, and retrying a conflict is inexpensive.

**Technique.** Store a version that changes on every successful update. Include the observed version in the write predicate. If no row matches, reload, recalculate, and retry or report a conflict.

**Example.**

```sql
UPDATE dbo.Products
SET Price = @newPrice,
    Version = Version + 1
WHERE ProductId = @productId
  AND Version = @expectedVersion;

-- 1 row: success. 0 rows: stale version.
```

This idea also appears as HTTP `ETag` / `If-Match`, DynamoDB condition expressions, and ORM concurrency tokens. SQL Server `rowversion` is a database-generated concurrency token, not a date/time value.

**Gotchas.** High contention can turn retries into a retry storm: wasted work, extra load, and worse latency. Use bounded retries with backoff and jitter. A value changing A → B → A can hide an intervening update (ABA); a monotonically increasing version avoids this. Timestamps are weaker tokens when precision or update paths allow reuse. A failed version check must prevent related writes.

## Pessimistic database locking

**Problem.** The application must inspect data and make a decision that cannot be expressed as one conditional write—for example, finding four adjacent seats. Another transaction could change the selected rows between read and write.

**Use this when.** The read–decide–write gap is unavoidable and conflicts are frequent enough that losing and retrying costs more than waiting.

**Technique.** Acquire locks before reading the state used for the decision, keep them while deciding and writing, and commit quickly. Lock only the necessary rows or key range.

**Example.** PostgreSQL:

```sql
BEGIN;
SELECT seat_number
FROM seats
WHERE concert_id = 'concert-1'
  AND section = 'floor'
  AND status = 'available'
ORDER BY seat_number
FOR UPDATE;

-- Select a contiguous block and update those rows.
UPDATE seats
SET status = 'reserved', reserved_by = 'user-123'
WHERE concert_id = 'concert-1'
  AND seat_number IN ('A15', 'A16', 'A17', 'A18');
COMMIT;
```

SQL Server lock acquisition:

```sql
BEGIN TRANSACTION;
SELECT SeatNumber
FROM dbo.Seats WITH (UPDLOCK)
WHERE ConcertId = @concertId
  AND Section = 'floor';

-- Decide and update while transaction is open.
COMMIT TRANSACTION;
```

In SQL Server, `UPDLOCK` requests update locks and holds them until transaction completion. `HOLDLOCK` applies serializable semantics to the referenced table. `ROWLOCK` is a request, not a guarantee.

**Gotchas.** Long transactions, broad scans, and slow queries increase blocking. Never wait for user input or call an API while holding database locks. Acquire multiple resources in a consistent order to reduce deadlocks. Locks on returned rows do not necessarily protect rows that do not exist; use a unique constraint or appropriate range protection. Supporting indexes help narrow the locked range. Under MVCC, ordinary readers may see an older committed version while a writer holds a row lock; behavior depends on engine and isolation.

## Reducing reader-writer blocking

**Problem.** Read-heavy workloads see SELECT statements waiting behind updates, or read transactions hold shared locks long enough to slow writers.

**Use this when.** Reads greatly outnumber writes and readers need a consistent committed view rather than blocking writers.

**Technique.** Use the database's MVCC or row-versioned read mode where appropriate. PostgreSQL uses MVCC for normal reads. SQL Server `READ_COMMITTED_SNAPSHOT` makes `READ COMMITTED` reads use row versions; `SNAPSHOT` provides a transaction-level snapshot when enabled.

**Example.** SQL Server database setting (requires DBA review and deployment planning):

```sql
ALTER DATABASE YourDatabase
SET READ_COMMITTED_SNAPSHOT ON;
```

**Gotchas.** Row-versioned reads reduce reader–writer blocking; they do not make read-modify-write logic safe. Keep conditional writes, constraints, or OCC for write correctness. Version stores need capacity/cleanup planning. Test transaction behavior before changing database isolation settings.

## Cross-row invariants and serializable isolation

**Problem.** A **cross-row invariant** is a business rule whose correctness depends on multiple rows or on a predicate/range of rows: at least one engineer must remain on call; an order may contain at most five items; a team may have at most N active members. The invariant is the rule that must always hold.

**Write skew** is one way concurrent transactions can violate such a rule. Two transactions read overlapping state, make individually valid decisions, and then update different rows, so they do not directly conflict at the row level. For example, Alice and Bob each see that the other engineer is on call and independently remove themselves; both commits can leave nobody on call. A concurrent child-count limit has the same underlying shape: two requests can read the same count and insert different new child rows, exceeding the limit. It is often described as a predicate/count variant of write skew; the important distinction is that the **invariant** is the rule, while **write skew** is the race/anomaly that breaks it.

**Use this when.** The invariant spans rows or a predicate/range, and no single row is changed by every competing transaction.

**Technique.** First see whether the rule can be represented by one shared row: a maintained count updated with a conditional write, or a guard row that every participating writer updates or locks. For a parent/child limit, a practical guard can be the parent row itself: lock it before counting or changing its children, so writers for one parent serialize while different parents remain concurrent. See [Cross-row invariant: enforcing a maximum number of child rows](./dealing-with-data-contention-other-examples/cross-row-invariant-general-sql-solution.md) for the SQL Server protocol and its trade-offs. Otherwise use `SERIALIZABLE` isolation and retry serialization failures by rerunning the entire transaction.

**Example.** PostgreSQL:

```sql
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SELECT COUNT(*)
FROM on_call
WHERE team_id = 'payments'
  AND is_active = TRUE;

-- Verify another engineer remains active.
UPDATE on_call
SET is_active = FALSE
WHERE engineer_id = 'alice';

COMMIT;
```

A `TeamOnCallState` guard row can make the shared invariant explicit, at the cost of serializing changes for that team. For an order-item limit, the `Orders` row can instead be the guard/serialization point; acquire its lock before counting or inserting items.

**Gotchas.** Do not assume `REPEATABLE READ` prevents write skew; behavior differs by engine. `SERIALIZABLE` may block or abort transactions. Retry the whole transaction on serialization/deadlock errors. A parent/guard-row strategy is a protocol: every write path that can affect the invariant must use it. Avoid applying serializable isolation globally without evidence. A guard row can become a hot bottleneck; revisit the invariant and workload before adding infrastructure.

## Time-bound reservations

**Problem.** A user selects a resource but needs time to finish checkout, booking, or dispatch. A database transaction cannot stay open for minutes while a user fills out a form or an external service responds.

**Use this when.** The business concept is “hold this resource for this owner until expiry,” not “keep a database transaction open.”

**Technique.** Store the hold as durable state in the authoritative database. Claim it with a conditional write that succeeds only if available or the previous hold expired.

**Example.**

```sql
UPDATE dbo.Seats
SET Status = 'Held',
    HeldBy = @userId,
    ExpiresAt = DATEADD(minute, 10, SYSUTCDATETIME()),
    HoldVersion = HoldVersion + 1
WHERE SeatId = @seatId
  AND (
      Status = 'Available'
      OR (Status = 'Held' AND ExpiresAt <= SYSUTCDATETIME())
  );
```

Finalize only if the same user still owns the same hold/version and it has not expired:

```sql
UPDATE dbo.Seats
SET Status = 'Sold'
WHERE SeatId = @seatId
  AND Status = 'Held'
  AND HeldBy = @userId
  AND HoldVersion = @holdVersion
  AND ExpiresAt > SYSUTCDATETIME();
```

**Gotchas.** Define behavior for payment success after expiry, late callbacks, and retries. Include owner and generation/version so an old workflow cannot finalize a newer reservation. Use a consistent time source, typically database UTC. A cleanup job may normalize stale rows, but correctness must not depend on timely cleanup.

## Competing workers claiming jobs

**Problem.** Several worker instances poll a jobs table and select the same `Ready` job before any changes its status.

**Use this when.** A database table acts as a lightweight queue and workers must claim distinct jobs without an external broker.

**Technique.** Select and mark a job claimed in one short transaction. Lock the candidate row; where supported, skip rows already claimed by another worker.

**Example.** SQL Server:

```sql
;WITH next_job AS
(
    SELECT TOP (1) JobId
    FROM dbo.Jobs WITH (UPDLOCK, READPAST, ROWLOCK)
    WHERE Status = 'Ready'
    ORDER BY Priority DESC, CreatedAt, JobId
)
UPDATE j
SET Status = 'Running',
    WorkerId = @workerId,
    LeaseExpiresAt = DATEADD(minute, 2, SYSUTCDATETIME())
OUTPUT inserted.JobId, inserted.Payload
FROM dbo.Jobs AS j
JOIN next_job AS n ON n.JobId = j.JobId;
```

PostgreSQL commonly uses `SELECT ... FOR UPDATE SKIP LOCKED` in a transaction followed by the claim update.

**Gotchas.** Claim and state change must be atomic. A worker can crash after claiming, so use a lease/visibility timeout and safe reclamation. Processing must be idempotent because a job can run again. SQL Server `READPAST` has isolation-level and row/page-lock limitations; verify behavior with your settings, especially when read-committed snapshot is enabled. This is not a replacement for a durable broker when replay, streaming throughput, or independent consumer groups are needed.

**Large work-item tables.** When many workers need to process a large table in batches, prefer atomic batch claiming directly from the item table as the starting point. Bound batch size and concurrent batches per instance; use item leases plus a claim generation/fencing token for crash recovery and stale-worker protection. `ROWLOCK` is only a request, and claimed rows need not be contiguous. See [Claiming Large Batches of Work Items](./dealing-with-data-contention-other-examples/batch-claiming-many-work-items.md) for the SQL Server/PostgreSQL patterns, worker loop, recovery, and when a durable broker or partition coordinator may be justified.

## Queue-based serialization

**Problem.** A hot resource receives bursts of writes that overwhelm the database's sustainable rate. Locking preserves correctness but requests pile up and time out.

**Use this when.** A hot key needs ordered processing and can tolerate asynchronous completion or queue latency. Examples: auction bids, per-account ledger commands, and per-order transitions.

**Technique.** Send commands to a durable queue partitioned by resource key. Process each key sequentially while different keys run in parallel. In Kafka, use the resource ID as message key so events map to one partition and retain partition order.

**Example.**

```text
publish(topic = "auction-commands", key = auctionId, value = bidCommand)

consumer:
    process each partition sequentially
    validate bid against current state
    persist result and deduplication key
    acknowledge only after durable processing
```

**Gotchas.** A queue buffers and orders work; it does not increase the maximum processing rate of one hot key. Concurrent processing within a partition can break ordering. Redelivery and restarts require idempotency. Plan for lag, poison messages, retries, and dead letters. Do not add a queue when ordinary transactions handle measured peaks.

## Hot counters and write sharding

**Problem.** A popular item causes every request to update the same counter row, such as likes or views. Even atomic increments can make that row a write bottleneck.

**Use this when.** The counter is high-volume and reads can aggregate partial values, or the business can safely allocate independent quotas.

**Technique.** Split the counter into N buckets and direct increments to a bucket, for example by hashing user ID. Read by summing buckets or periodically aggregate into a read-optimized value.

**Example.**

```text
bucket = hash(userId) % N
UPDATE CounterBuckets
SET Value = Value + 1
WHERE ItemId = @itemId AND BucketId = bucket

read total = SUM(Value) across the item's buckets
```

For strict inventory, allocate per-shard quotas whose total never exceeds global stock rather than letting each shard assume stock is available.

**Gotchas.** Reads become more expensive and may be slightly stale with asynchronous aggregation. Choose bucket count and hash distribution carefully. Deduplicate retried events. Sharded counters suit commutative totals like likes; they are not a drop-in solution for a global “never sell more than N” invariant.

## Distributed locks

**Problem.** Multiple application instances coordinate access across nodes, and exclusive ownership must span transactions, an external call, or a wait. A process-local lock cannot coordinate replicas; a database row lock should not be held through a long workflow.

**Use this when.** A lease is genuinely required across nodes and the operation cannot be expressed more simply as a conditional write or business reservation.

**Technique.** Use a shared lock service or database-backed lease. Redis acquisition should be atomic, with a unique ownership token and TTL:

```redis
SET lock:resource-123 <unique-token> NX PX 30000
```

Release only if the token still belongs to the caller. With Redis versions lacking a suitable safe release command, use atomic compare-and-delete (Lua):

```lua
if redis.call('GET', KEYS[1]) == ARGV[1] then
    return redis.call('DEL', KEYS[1])
end
return 0
```

**Gotchas.** Never use `SETNX` then a separate expiry command; a crash can leave a permanent lock. Never blindly `DEL`: the lease may expire and a new owner may acquire it. TTL is a lease, not proof the old holder stopped. A paused process can resume after expiry. For correctness-critical resources, use a **fencing token** (monotonically increasing ownership number) and make the protected resource reject older tokens. Plan for lock-service failure, failover, renewal, and timeouts. A plain Redis TTL lock is not an unconditional guarantee against overlapping owners. ZooKeeper or etcd provide stronger coordination primitives but add operational complexity; stale clients still need protection at the resource.

## When the invariant crosses services

**Problem.** One operation must update independent databases/services, such as transferring funds across databases. A local transaction or row lock cannot make both systems commit atomically.

**Use this when.** The operation crosses transactional boundaries. This is a distributed workflow problem, not merely contention on one row.

**Technique.** Prefer a **Saga** when intermediate states and compensating actions are acceptable. Each step commits locally; failures trigger retries or compensations. Use **Two-Phase Commit (2PC)** only when all participants support it and strict atomic commit justifies coordination and availability costs.

**Example.**

```text
Saga:
1. Debit source account (idempotent local transaction).
2. Credit destination account (idempotent local transaction).
3. If credit cannot complete, retry or compensate the debit.
4. Persist workflow state and reconcile incomplete transfers.

2PC:
1. Coordinator asks participants to PREPARE.
2. If all prepared, COMMIT; otherwise ABORT.
```

**Gotchas.** A Saga is not atomic: intermediate states are visible and compensation is a new business action that can fail. Persist workflow state, use idempotent steps, retries, outbox/inbox where appropriate, and reconciliation. 2PC can leave prepared transactions/locks while the coordinator is unavailable. Keep related data in one database when possible. Do not introduce 2PC just because two services are involved; identify the consistency requirement first.

## Multi-region writes and replication

**Problem.** The same record can be updated concurrently in multiple regions or replicas, so no single row or leader sees every writer. A local lock in each region cannot coordinate the others.

**Use this when.** The application intentionally permits concurrent writes across regions or uses multi-leader/leaderless replication.

**Technique.** Prefer single-writer ownership per key or a home region when strong ordering is required. For naturally commutative operations, use a CRDT or another conflict-free merge.

**Example.** A distributed likes counter can merge independent increments. A balance or limited-inventory value generally cannot be merged as a simple counter while preserving “never negative” or “never oversell.”

**Gotchas.** Last-write-wins can silently discard meaningful updates. Vector clocks can detect some concurrent histories but require application conflict resolution. CRDTs work for operations with suitable algebraic properties; they do not automatically preserve arbitrary business constraints. Strong cross-region consistency requires coordination and its latency/availability cost.

## Deadlocks, retries, and operational diagnosis

**Problem.** Requests wait on locks, deadlock, repeatedly lose optimistic updates, or queue behind a hot resource. Adding another lock is not automatically the fix.

**Technique.** Identify the actual failure mode:

- **Blocking:** one transaction waits for another to release a lock. Find the blocker and shorten/narrow its transaction.
- **Deadlock:** transactions form a wait cycle. Access resources in a consistent order; retry the entire aborted transaction after randomized delay.
- **Optimistic conflict:** a version/conditional write matched zero rows. Reload and retry only if the operation remains valid.
- **Hot key:** many requests converge on one row/key/partition. Consider queueing, partitioning, or a different ownership model.
- **Overload:** concurrency exceeds dependency capacity. Apply backpressure rather than more retries.

**Example.** SQL Server error `1205` indicates a deadlock victim; retry the complete transaction with bounded backoff and jitter. PostgreSQL applications commonly handle serialization failures (`40001`) and deadlocks (`40P01`) by retrying the whole transaction.

**Gotchas.** Retry only known transient/conflict failures, with attempt limits and an overall deadline. A retry must not repeat a non-idempotent external side effect. Keep transactions short and avoid network calls, user interaction, or long CPU work while locks are held. Monitor lock waits, deadlock count, transaction duration, retry rate, conditional-write failures, hottest keys, queue lag, and connection-pool waits. What looks like database contention may be waiting for a pooled connection. `NOLOCK` is not a contention solution: it trades consistency for dirty/inconsistent reads and does not make writes safe.

## Interview decision path

Make the invariant explicit before naming a technology:

1. **What can become incorrect?** Duplicate order, negative balance, oversold inventory, two owners of one seat, lost update, or broken cross-row rule?
2. **Where is authoritative state?** Put the check and transition there whenever possible.
3. **Can one conditional write or constraint enforce it?** Start there.
4. **If not, is read–decide–write required?** OCC for rare conflicts; short pessimistic locks for frequent conflicts.
5. **Does the invariant span rows?** Name the rule separately from the anomaly: write skew is one possible failure mode. Prefer a shared conditional count/guard row; for parent-child limits, serialize writers through the parent row ([pattern](./dealing-with-data-contention-other-examples/cross-row-invariant-general-sql-solution.md)); otherwise use `SERIALIZABLE`.
6. **Must ownership survive user wait or external call?** Model an expiring reservation; use a distributed lock only for remaining coordination.
7. **Is one hot key exceeding capacity?** Estimate peak writes per key. Consider per-key queueing or sharded state only when justified.
8. **Does it cross services or regions?** Treat Saga/2PC or multi-region conflict resolution as a separate problem.

| Scenario | Likely starting point |
|---|---|
| Auction bid | Conditional update/OCC on high bid/version; queue by auction ID only if peak load requires it |
| Last ticket or inventory unit | Conditional update on the specific seat/item plus transaction for related records |
| Adjacent seats | Short transaction with row locks, then an expiring reservation |
| Bank transfer in one database | ACID transaction, guarded debit, deterministic lock order if needed |
| Transfer across databases | Saga in many service-oriented designs; 2PC only with explicit atomic-commit requirement |
| Driver dispatch | Conditional `Available` → `Pending`; expiry/lease for unanswered offers |
| Viral likes/views | Sharded counters or append-only events with asynchronous aggregation |
| Repeated payment request | Idempotency key + unique constraint + provider idempotency where supported |
| Last engineer stepping off call | Guard row or `SERIALIZABLE` transaction |
| At most five items per order | Short transaction that locks the parent row before counting/inserting children; see the [cross-row invariant pattern](./dealing-with-data-contention-other-examples/cross-row-invariant-general-sql-solution.md) |
| Popular cache key expires | See the code-side [cache stampede guide](Content_Contention_in_DotNet.md#cache-stampedes) |

## Further reading

- [Hello Interview — Dealing with Contention](https://www.hellointerview.com/learn/system-design/patterns/dealing-with-contention)
- [Microsoft — Transaction locking and row versioning](https://learn.microsoft.com/en-us/sql/relational-databases/sql-server-transaction-locking-and-row-versioning-guide)
- [Microsoft — Table hints (Transact-SQL)](https://learn.microsoft.com/en-us/sql/t-sql/queries/hints-transact-sql-table)
- [Microsoft — Deadlocks guide](https://learn.microsoft.com/en-us/sql/relational-databases/sql-server-deadlocks-guide)
- [PostgreSQL — Explicit locking](https://www.postgresql.org/docs/current/explicit-locking.html)
- [PostgreSQL — Transaction isolation](https://www.postgresql.org/docs/current/transaction-iso.html)
- [Redis — Distributed locks](https://redis.io/docs/latest/develop/clients/patterns/distributed-locks/)
- [Amazon DynamoDB — Optimistic locking](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/BestPractices_OptimisticLocking.html)
- [Apache Kafka — Documentation](https://kafka.apache.org/documentation/)
