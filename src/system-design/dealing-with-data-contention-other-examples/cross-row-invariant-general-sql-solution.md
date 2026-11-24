# Cross-row invariant: enforcing a maximum number of child rows

## 1. Problem description

A **cross-row invariant** is a business rule whose correctness depends
on more than one database row.

Example: an `Orders` table has a one-to-many relationship with
`OrderItems`, and an order may contain at most five items.

A naïve implementation reads the current number of items, checks whether
it is below five, and inserts a new item. This is not safe under
concurrency:

-   Two requests can read the same count.
-   Both can conclude that another item is allowed.
-   Both can insert.
-   The order can end up with six items even though each request
    performed the check.

The invariant must be protected across the complete read-check-write
operation, not merely checked in application code.

## 2. Solution description: serialize writers through the parent row

For SQL Server, acquire an update lock on the parent `Orders` row before
counting or modifying its children. Keep the lock until the transaction
commits or rolls back.

An update lock (`UPDLOCK`) is incompatible with another update lock on
the same resource. Therefore, a second transaction attempting the same
protocol for the same order waits before it performs the count. Once the
first transaction commits, the second continues and reads the new
committed child count.

This gives each order a serialization point: only one participating
transaction at a time can make a decision based on that order's current
item count.

The child count and insert must be in the same transaction as the parent
lock acquisition.

### T-SQL example
The essential sequence is:

``` sql
BEGIN TRANSACTION;

SELECT Id
FROM dbo.Orders WITH (UPDLOCK, HOLDLOCK)
WHERE Id = @OrderId;

SELECT @ItemCount = COUNT(*)
FROM dbo.OrderItems
WHERE OrderId = @OrderId;

IF @ItemCount < 5
    INSERT dbo.OrderItems (OrderId, ProductId)
    VALUES (@OrderId, @ProductId);
ELSE
    THROW 50002, 'Maximum item count reached.', 1;

COMMIT TRANSACTION;
```

The parent lookup should use an index (normally the primary key) on
`Orders.Id`. The child index makes the count efficient and reduces the amount of data SQL Server needs to examine.

Also you can implement a similar solution without writing a single line of T-SQL using your favorite ORM. To do so, check [this document](./handling-cross-row-invariant-without-sql.md).

## 3. When to use it

Use this pattern when:

-   A business invariant spans a parent row and its child rows.
-   Writes affecting the same parent must make decisions one at a time.
-   Contention is naturally scoped to one aggregate or parent, while
    different parents should remain concurrent.
-   A short database transaction is acceptable.
-   You want to enforce the rule in the database transaction rather than
    rely on an application-only pre-check.

Examples include:

-   An order may contain at most five items.
-   A booking may have no more than a fixed number of attendees.
-   A document may have at most N active revisions.
-   A parent may have at most N active child records.

## 4. Caveats

-   **Every writer must follow the protocol.** Any code path that
    inserts, deletes, or changes child rows in a way that affects the
    invariant must acquire the same parent lock first. A writer that
    inserts directly into `OrderItems` can bypass the protection.
-   **Keep the transaction short.** Do not perform lengthy
    computation while holding the lock.
-   **Contention is per parent.** Requests for the same order are
    intentionally serialized. Requests for different orders can proceed
    concurrently.
-   **Blocking is expected.** A competing request waits for the
    transaction holding the parent lock. Long-running transactions
    therefore increase latency for that order.
-   **Deadlocks are reduced, not made impossible.** If every code path
    acquires locks in the same order, this pattern avoids the specific
    shared-range-lock-to-exclusive-lock conversion deadlock caused by
    concurrent count-then-insert under `SERIALIZABLE`. Other resources,
    inconsistent lock ordering, triggers, foreign keys, or unrelated
    work can still create deadlocks. Handle SQL Server deadlock error
    1205 with a bounded retry of the entire transaction where
    appropriate.
-   **Choose indexes deliberately.** The parent lookup should be
    selective, and `OrderItems(OrderId)` should support the count.
    Missing or unsuitable indexes can increase scanning, locking, and
    blocking. SQL Server may choose broader locks or escalate locks
    under pressure; `ROWLOCK`, if added, is a hint and not a guarantee.
-   **The parent must exist.** The example protects the parent lookup
    and reports a missing order. If parent creation and child creation
    have special concurrency rules, account for those separately.
-   **The lock is a protocol, not a declarative constraint.** The
    database does not automatically know that all child writers must
    first lock the parent. Restrict direct writes and centralize the
    operation where possible.

## 5. Similar solutions and their trade-offs

### Serializable count-then-insert

Run the count and insert in a `SERIALIZABLE` transaction, with a
suitable index on `OrderItems(OrderId)`.

This can protect the relevant key range and preserve the invariant.
However, two transactions can both acquire compatible shared range locks
while reading, then both request incompatible locks to insert. This
lock-conversion pattern can deadlock. SQL Server chooses a victim; the
application must retry the **entire** transaction, re-reading the count.
Serializable isolation can also create broader range locking and more
blocking than a targeted parent-row lock.

### Optimistic concurrency token on the parent

Add a `rowversion` (or application-managed concurrency token) to
`Orders`. Each child mutation must also update the parent. Concurrent
requests can then detect that another request changed the parent and one
receives a concurrency exception.

This is a valid optimistic approach when conflicts are uncommon. It does
not by itself enforce the maximum: the application must catch the
conflict and retry the whole read-check-write operation, or return a
conflict to the caller. It also requires an actual parent update on
every relevant child mutation.

### Maintained child-count column

Store an `ItemCount` on `Orders` and atomically increment it only when
it is below five:

``` sql
UPDATE dbo.Orders
SET ItemCount = ItemCount + 1
WHERE Id = @OrderId
  AND ItemCount < 5;
```

Check that exactly one row was updated, then insert the child in the
same transaction. If no row was updated, the order is missing or already
at capacity (distinguish those cases if the API requires it).

This can avoid counting child rows on every insertion and makes the
capacity check an atomic conditional update. The trade-off is
denormalized state: every insert, delete, cascade, import, and repair
path must keep `ItemCount` correct. A missed update can permanently
desynchronize the counter from the actual children. Reconciliation and
operational safeguards may be necessary.

### Application-only count check

Read the count and insert without a database concurrency mechanism. This
is simple but unsafe: concurrent requests can both pass the check and
violate the invariant. It should not be used when the limit must be
guaranteed.

## Summary

For a modest per-parent limit such as five order items, serializing
participating writers through the parent row is a straightforward
pessimistic strategy. It gives a clear per-order lock point, avoids the
specific count-range lock conversion deadlock, and keeps different
orders independent. Its correctness depends on all writers following the
same short-transaction protocol.
