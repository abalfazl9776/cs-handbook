# How to handle cross-row invariant using an ORM without a single line of SQL with DDD style

> Related general database solution: **[Cross-row invariant: enforcing a
> maximum number of child
> rows](cross-row-invariant-general-sql-solution.md)**. That document
> explains the T-SQL parent-row locking approach. This document applies
> the same serialization idea using ordinary EF Core operations and a
> DDD-style repository.

## 1. Problem description

An order can contain at most five order items. The rule depends on the
order and its child rows, so it is a cross-row invariant.

A plain `CountAsync()` followed by an insert is not safe when requests
run concurrently. Two requests can observe the same count and both
decide that there is room.

The goal here is to preserve the invariant using EF Core's normal entity
operations, without raw SQL or locking hints, while keeping persistence
coordination out of the application handler.

## 2. Solution alternatives and risks considered

Before choosing the solution, consider the alternatives and what they
cost.

### Serializable count-then-insert

The handler can start a `SERIALIZABLE` transaction, count the children,
and insert if the count is below five.

This preserves the invariant when the query and insert are in the same
transaction, with an appropriate index on `OrderItems(OrderId)`.
However, two requests can both acquire compatible shared range locks
while reading. When both try to insert, they may need incompatible locks
and create a lock-conversion deadlock. SQL Server chooses a victim, so
one request fails unless the application retries the entire transaction.

Serializable range locks can also cause longer or broader blocking,
especially with unsuitable indexes or large ranges. It is correct, but
it does not provide the desired behavior of making competing requests
simply queue behind one another without this particular deadlock
pattern.

### Optimistic concurrency token on the parent

A `rowversion` or other concurrency token can detect that another
request modified the parent. But child changes do not automatically
update the parent: the application must deliberately update it. A losing
request receives a concurrency exception and must retry the entire
operation or return a conflict.

This can be appropriate when contention is rare, but it is an optimistic
conflict-and-retry design rather than straightforward pessimistic
serialization.

### Chosen direction: update the parent row first

Use a normal EF Core `UPDATE` of a technical property on the parent
order. SQL Server takes an exclusive lock for that update and holds it
until the surrounding transaction completes.

A competing request attempting the same update for the same order waits.
After the first transaction commits, the second update proceeds; only
then does it load the child collection and evaluate the invariant
against the latest committed state.

This is the ORM equivalent of the parent-row serialization approach
described in the [general SQL
solution](cross-row-invariant-general-sql-solution.md).

## 3. Solution description

Use three clear responsibilities:

-   **Domain aggregate:** owns the business invariant and rejects adding
    an item when five already exist.
-   **Repository:** loads the aggregate and performs the
    persistence-specific coordination update before loading its
    children.
-   **Application command handler:** owns the transaction boundary and
    orchestrates the use case.

Expose one repository method:

``` csharp
public interface IOrderRepository
{
    Task<Order?> GetForUpdateAsync(
        int orderId,
        CancellationToken cancellationToken);
}
```

The method name describes the intent. The application layer does not
need to know about mutation tokens, EF Core collection loading, or SQL
Server locks.

### Domain aggregate

``` csharp
public class Order
{
    private readonly List<OrderItem> _items = [];

    public int Id { get; private set; }

    public IReadOnlyCollection<OrderItem> Items => _items;

    // Technical persistence coordination property.
    public Guid MutationToken { get; private set; }

    public void AddItem(OrderItem item)
    {
        if (_items.Count >= 5)
            throw new MaximumOrderItemsReachedException();

        _items.Add(item);
    }
}
```

The domain method enforces the business rule. The technical token has no
business meaning; it exists to make the repository issue an actual
update to the parent row.

### EF Core repository implementation

``` csharp
public async Task<Order?> GetForUpdateAsync(
    int orderId,
    CancellationToken cancellationToken)
{
    var order = await _dbContext.Orders
        .SingleOrDefaultAsync(
            x => x.Id == orderId,
            cancellationToken);

    if (order is null)
        return null;

    // Change a mapped, non-key property so EF issues an UPDATE.
    // Do not configure MutationToken as an EF concurrency token.
    _dbContext.Entry(order)
        .Property(x => x.MutationToken)
        .CurrentValue = Guid.NewGuid();

    // This SaveChanges must execute before loading the children.
    // The UPDATE acquires the parent-row lock, held by the
    // surrounding transaction.
    await _dbContext.SaveChangesAsync(cancellationToken);

    // Load children only after the parent lock has been acquired.
    await _dbContext.Entry(order)
        .Collection(x => x.Items)
        .LoadAsync(cancellationToken);

    return order;
}
```

This repository method must be called inside an active transaction.
Otherwise, the parent update could commit and release its lock before
the children are loaded and checked.

`MutationToken` should be mapped as a normal property, **not**
configured with `.IsConcurrencyToken()`. We want a normal blocking
update, not optimistic concurrency detection. A private setter is
compatible with EF Core's property access; the repository can set the
mapped property through `Entry(...).Property(...).CurrentValue`.

### Application command handler

``` csharp
public async Task Handle(
    AddOrderItemCommand command,
    CancellationToken cancellationToken)
{
    await using var transaction =
        await _dbContext.Database.BeginTransactionAsync(
            IsolationLevel.ReadCommitted,
            cancellationToken);

    var order = await _orderRepository.GetForUpdateAsync(
        command.OrderId,
        cancellationToken);

    if (order is null)
        throw new OrderNotFoundException(command.OrderId);

    order.AddItem(new OrderItem(/* command data */));

    await _dbContext.SaveChangesAsync(cancellationToken);

    await transaction.CommitAsync(cancellationToken);
}
```

The handler reads like the use case:

1.  Start a transaction.
2.  Get the order for modification.
3.  Execute the domain operation.
4.  Save and commit.

The repository encapsulates both the coordination update and loading the
complete aggregate.

## 4. When to use it

Use this approach when:

-   You use EF Core or a similar ORM and want to avoid hand-written SQL
    and locking hints.
-   The invariant belongs to an aggregate and depends on its child
    collection.
-   Contention should be serialized per aggregate/parent, not globally.
-   You can keep the transaction short.
-   You want the application handler to express the use case without
    exposing persistence locking details.

It is particularly suitable for bounded child collections, such as a
maximum number of order items, attendees, active child records, or
revisions.

## 5. Caveats

-   **All writers must use the same protocol.** Every operation that
    changes the child collection or otherwise affects the invariant must
    obtain the parent lock first. Direct child inserts that bypass the
    repository can violate the rule.
-   **The transaction is essential.** The parent update, child loading,
    domain operation, child insert, and commit must all belong to the
    same transaction.
-   **Ordering is essential.** The repository must execute the parent
    `UPDATE` before loading the children. If EF defers the update until
    a later `SaveChanges`, the lock is acquired too late.
-   **Use a real mapped update.** Changing a technical property must
    cause EF Core to send an `UPDATE`. Do not rely on changing an
    unmapped or ignored property.
-   **Do not configure the token as a concurrency token.** Doing so
    changes the behavior to optimistic concurrency checking and can
    cause the waiting request to receive `DbUpdateConcurrencyException`
    instead of proceeding after the first transaction commits.
-   **Keep the transaction short.** The exclusive parent lock is held
    until commit or rollback. Avoid network calls, message publishing,
    user interaction, or lengthy computation inside the transaction.
-   **Blocking is intentional.** Concurrent modifications to the same
    order queue behind one another. This avoids the specific
    shared-range-lock conversion deadlock from the Serializable
    count-then-insert approach, but it does not eliminate every possible
    deadlock in the wider system.
-   **Use consistent lock ordering.** If a use case locks multiple
    aggregates or other rows, acquire them in a consistent order to
    reduce deadlock risk.
-   **Use a fresh `DbContext` per command/attempt.** This keeps tracking
    and transaction state isolated, especially if a transient failure
    requires retrying.
-   **The repository method assumes a transaction.** Consider enforcing
    this expectation in infrastructure code or documenting it clearly.
    The application layer should own the transaction boundary.
-   **The aggregate must contain the data needed by the invariant.**
    Here, loading all order items is reasonable because the domain
    operation needs their count. For large child collections, reconsider
    the aggregate boundary or the invariant representation.
-   **This is a protocol, not a database constraint.** Other
    applications, scripts, or direct database writers can bypass it.
    Restrict write access or centralize writes if the invariant must
    hold across multiple writers.

## 6. Similar solutions and comparison
The main alternatives are covered above: Serializable count-and-insert, optimistic concurrency with a parent token, and the general SQL alternatives in the [this document](cross-row-invariant-general-sql-solution.md).

Compared with those approaches, parent-row serialization through the repository has these characteristics:

| Approach | Main risk or cost | Compared with this solution |
|---|---|---|
| Serializable count-and-insert | Lock-conversion deadlocks and potentially broader range blocking. | Parent update makes competing writers wait before reading the count. |
| Optimistic concurrency token | Conflicts require catching and retrying the whole operation. | Parent-row update uses blocking rather than optimistic conflict detection. |
| Maintained child counter | Denormalized count can drift if any write path misses the update. | This solution counts actual children, at the cost of loading them. |
| Application-only count check | Concurrent requests can exceed the limit. | This solution coordinates concurrent writers in the database. |

## Summary

For an EF Core DDD application, expose `GetForUpdateAsync` on the order
repository. Its implementation loads the parent, changes a technical
mutation token, executes `SaveChangesAsync` to acquire the parent-row
lock, then loads the children and returns the aggregate.

The command handler owns a short `ReadCommitted` transaction and invokes
the aggregate's business method. This keeps business rules in the
domain, persistence coordination in the repository, and transaction
orchestration in the application layer without writing raw SQL.
