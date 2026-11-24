# Code Contention and Concurrency in .NET

This guide covers contention inside application code: threads, tasks, in-memory state, async coordination, caches, and resource capacity. These techniques generally coordinate one process unless explicitly stated otherwise. They do **not** replace database constraints or distributed coordination.

> First ask whether shared mutable state is necessary. If it is, choose the narrowest synchronization primitive that protects the whole invariant—not just one statement.

## Table of contents

| Problem or signal | First approach to consider |
|---|---|
| Work can be independent | Avoid shared mutable state / partition ownership ([details](#avoiding-shared-mutable-state)) |
| One scalar is concurrently updated | `Interlocked` ([details](#atomic-scalar-operations-with-interlocked)) |
| Several in-memory fields form one invariant | `lock` / `Monitor` ([details](#short-synchronous-critical-sections)) |
| Async code must limit concurrent access | `SemaphoreSlim` ([details](#async-coordination-with-semaphoreslim)) |
| Read-heavy in-memory state needs concurrent readers | `ReaderWriterLockSlim` only after measurement ([details](#readerwriterlockslim)) |
| Many threads update a shared collection | Concurrent collections / atomic dictionary patterns ([details](#concurrent-collections-and-dictionary-gotchas)) |
| A dependency has limited capacity | Bounded concurrency and backpressure ([details](#bounded-concurrency-and-backpressure)) |
| Many requests regenerate one cache key | Single-flight cache refresh ([details](#cache-stampedes)) |
| Threads/tasks stall or throughput collapses | Diagnose starvation, blocking, and lock contention ([details](#diagnosing-contention-and-starvation)) |

## Avoiding shared mutable state

**Problem.** Multiple threads or tasks update the same object even though work could be independent. Shared state forces synchronization and makes reasoning harder.

**Use this when.** Work can be divided by request, customer, aggregate, partition, or immutable input.

**Technique.** Prefer immutable data, local variables, ownership, and message passing. Each worker computes independently and combines results at a clear boundary. For per-key processing, use a keyed queue/actor-like owner rather than a global lock.

**Example.** Instead of having workers increment one shared total for every item, each worker computes a local subtotal and the caller combines the subtotals after all work completes.

```csharp
var subtotals = await Task.WhenAll(chunks.Select(chunk => Task.Run(() =>
    chunk.Sum(x => x.Value), cancellationToken)));
var total = subtotals.Sum();
```

**Gotchas.** `Task.Run` is not automatically beneficial, especially for I/O-bound work or small computations. Partitioning can create uneven work. If updates must be visible immediately or enforce a shared invariant, local aggregation alone is not enough.

## Atomic scalar operations with Interlocked

**Problem.** A read-modify-write such as `counter++` is not atomic. Two threads can read the same value and overwrite each other's increments.

**Use this when.** A simple scalar operation—increment, decrement, exchange, compare-and-swap—must be atomic.

**Technique.** Use `Interlocked` rather than a lock for supported primitive/reference operations. It provides atomic operations and memory-ordering guarantees appropriate to those operations.

**Example.**

```csharp
private long _processed;
Interlocked.Increment(ref _processed);

// Compare-and-swap style: change 0 to 1 only if it is still 0.
var previous = Interlocked.CompareExchange(ref _state, 1, 0);
if (previous == 0)
{
    // This caller changed the state from 0 to 1.
}
```

**Gotchas.** `Interlocked` protects only the operation it performs, not a multi-field invariant. It does not coordinate separate processes. Avoid assuming `volatile` makes `counter++` atomic; it does not. For complex logic, use a lock or redesign around ownership. Understand the compare-exchange return value: it returns the original value, not a Boolean.

## Short synchronous critical sections

**Problem.** Several threads must inspect and update multiple fields together. Atomic operations on individual fields would still allow an inconsistent intermediate state.

**Use this when.** The invariant is process-local and the critical section is short and synchronous.

**Technique.** Protect the whole invariant with `lock` (which uses `Monitor` under the hood). Keep the lock scope minimal.

**Example.**

```csharp
private readonly object _gate = new();
private decimal _balance;

public bool TryDebit(decimal amount)
{
    lock (_gate)
    {
        if (_balance < amount)
            return false;

        _balance -= amount;
        return true;
    }
}
```

**Gotchas.** `lock` cannot contain `await`; do not hold a thread-affine monitor across asynchronous work. Do not call unknown or slow code inside the lock. A process-local lock cannot protect data shared across application instances or machines. Use a database conditional update for a persistent balance.

## Async coordination with SemaphoreSlim

**Problem.** Async code needs to limit simultaneous access to a resource, or several async operations must enter a protected region.

**Use this when.** You need an async-compatible gate or concurrency limit inside one process.

**Technique.** `SemaphoreSlim.WaitAsync` lets tasks wait without blocking a thread while waiting. Always release in `finally`.

**Example.** Limit concurrent downstream calls to eight:

```csharp
private readonly SemaphoreSlim _ioSlots = new(initialCount: 8, maxCount: 8);

public async Task CallAsync(CancellationToken cancellationToken)
{
    await _ioSlots.WaitAsync(cancellationToken);
    try
    {
        await CallDependencyAsync(cancellationToken);
    }
    finally
    {
        _ioSlots.Release();
    }
}
```

**Gotchas.** `SemaphoreSlim` is process-local, not a distributed semaphore, and does not promise FIFO fairness. Do not forget `Release`, and do not release more times than acquired. A concurrency cap is not a rate limit: eight calls can still be sent in a burst. For rate limiting, use a rate limiter/token-bucket style policy. For cross-replica limits, coordinate at a shared gateway/service or use a distributed mechanism.

## ReaderWriterLockSlim

**Problem.** Many threads read a shared in-memory structure, while occasional writes need exclusive access.

**Use this when.** Profiling shows read contention on a structure where reads substantially outnumber writes and the protected operations are synchronous.

**Technique.** `ReaderWriterLockSlim` allows concurrent readers but exclusive writers.

**Example.**

```csharp
private readonly ReaderWriterLockSlim _rw = new();

_rw.EnterReadLock();
try
{
    return _snapshot;
}
finally
{
    _rw.ExitReadLock();
}
```

**Gotchas.** It adds complexity and can perform worse than a simple lock when writes are frequent or critical sections are short. It is not async-friendly; do not hold it across `await`. Consider immutable snapshots or copy-on-write when readers need low-latency access. Measure before adopting it.

## Concurrent collections and dictionary gotchas

**Problem.** Multiple threads add, remove, or update a shared collection. A regular `Dictionary` or `List` is not safe for concurrent mutation.

**Use this when.** Concurrent access to a collection is a real requirement.

**Technique.** Use `ConcurrentDictionary`, `ConcurrentQueue`, `ConcurrentBag`, or `ConcurrentStack` for their documented concurrent operations. For a dictionary value update, use atomic dictionary methods such as `TryAdd`, `TryUpdate`, or `AddOrUpdate` when appropriate.

**Example.**

```csharp
private readonly ConcurrentDictionary<string, int> _counts = new();
_counts.AddOrUpdate(key, 1, (_, current) => current + 1);
```

**Gotchas.** A `ConcurrentDictionary` makes its individual operations thread-safe, not arbitrary sequences across multiple collections. Do not assume an `AddOrUpdate` or `GetOrAdd` delegate executes exactly once; factories/update delegates may run more than once under contention. Keep such delegates side-effect-free. If the value itself is mutable, the dictionary does not automatically make mutations to that value safe. A `List<T>.ToList()` copy protects enumeration from structural changes to the original list, but it is a shallow copy: objects inside both lists are still shared, and concurrent mutation of those objects remains unsafe.

## Bounded concurrency and backpressure

**Problem.** Requests arrive faster than a downstream API, database, CPU pool, or worker can handle them. Waiting tasks consume memory and deadlines, and overload spreads through the system.

**Use this when.** The dependency has a finite safe concurrency/throughput and the application must bound work before overload occurs.

**Technique.** Use bounded concurrency, bounded queues, rate limits, deadlines, and rejection/load shedding. A `SemaphoreSlim` can cap local concurrent calls; a bounded `Channel<T>` can provide producer/consumer backpressure for in-process work.

**Example.** A local semaphore limits simultaneous dependency calls; a bounded channel can reject or wait when its capacity is reached rather than accumulating an unlimited queue.

```csharp
var channel = Channel.CreateBounded<WorkItem>(new BoundedChannelOptions(500)
{
    FullMode = BoundedChannelFullMode.Wait,
    SingleReader = false,
    SingleWriter = false
});
```

**Gotchas.** A local limit of 20 across five replicas still permits 100 concurrent calls. A bounded queue must have an intentional capacity and overflow policy. Waiting indefinitely merely moves overload into memory or request latency. Backpressure protects capacity; it does not enforce business correctness. Consider cancellation and end-to-end deadlines so queued work does not execute after it is no longer useful.

## Cache stampedes

**Problem.** A popular cache entry expires and many requests miss at once. Every request recomputes or fetches the same expensive value, overwhelming a database or service.

**Use this when.** Duplicate cache fills are expensive but do not themselves threaten business correctness.

**Technique.** Use single-flight refresh per cache key. In one process, a keyed async gate may be enough. Across nodes, consider stale-while-revalidate, TTL jitter, or a distributed lease if duplicate refreshes remain expensive.

**Example.**

```text
value = cache.get(key)
if value exists: return value

await acquire per-key refresh gate
try:
    re-check cache                 // another caller may have filled it
    if still missing:
        value = load from source
        cache.set(key, value, ttl + random_jitter)
finally:
    release gate
return cache.get(key)
```

**Gotchas.** Re-check after acquiring the gate. Remove per-key gates when no longer needed so the gate dictionary does not grow forever. TTL jitter spreads expirations but does not guarantee one refresh. If stale data is acceptable, stale-while-revalidate often gives better latency. Cache-fill coordination is not a substitute for business-data locking.

## Diagnosing contention and starvation

**Problem.** Throughput collapses, latency rises, threads appear blocked, or the service stops making progress despite CPU not being fully utilized.

**Technique.** Identify the waiting resource before changing synchronization:

- **Lock contention:** many threads wait for one critical section. Shorten it, reduce shared state, or partition by key.
- **Thread-pool starvation:** worker threads are blocked (often on sync-over-async or long blocking calls), so continuations and new work cannot run promptly. Prefer async end-to-end for I/O; avoid `.Result`, `.Wait()`, and unnecessary blocking.
- **Semaphore saturation:** tasks wait for a concurrency slot. Check whether the cap matches dependency capacity and whether holders are slow or stuck.
- **Connection-pool exhaustion:** tasks wait for database/HTTP connections. Check connection lifetime, leaks, long transactions, and downstream latency; this may look like database contention but occur before a query starts.
- **CPU saturation:** synchronization may not be the primary issue. Profile CPU, allocation, and GC before adding locks or more threads.

**Gotchas.** Increasing thread count or retrying blindly can worsen overload. Instrument wait time, lock duration, queue depth, semaphore wait, thread-pool counters, connection-pool wait, and dependency latency. Use runtime tracing/profiling to verify the bottleneck. Cancellation should flow through waits and I/O where supported; cancellation does not forcibly stop arbitrary code already running.

## Decision path for .NET code contention

1. **Can shared mutable state be removed?** Prefer immutable data, local aggregation, or ownership.
2. **Is it one scalar operation?** Use `Interlocked`.
3. **Is it a compound in-memory invariant?** Use a short `lock`.
4. **Must async tasks wait or be limited?** Use `SemaphoreSlim` or a bounded channel.
5. **Are concurrent reads materially faster?** Consider `ReaderWriterLockSlim` only after profiling.
6. **Is this shared state persistent or visible across replicas?** Do not use process-local primitives; use the [data contention guide](Data_Contention.md) for conditional writes, transactions, reservations, queues, and distributed coordination.
7. **Is the real problem overload?** Apply bounded concurrency/backpressure rather than adding more synchronization.

## Further reading

- [Microsoft — Overview of synchronization primitives](https://learn.microsoft.com/en-us/dotnet/standard/threading/overview-of-synchronization-primitives)
- [Microsoft — `Interlocked`](https://learn.microsoft.com/en-us/dotnet/api/system.threading.interlocked)
- [Microsoft — `lock` statement](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/statements/lock)
- [Microsoft — `SemaphoreSlim`](https://learn.microsoft.com/en-us/dotnet/api/system.threading.semaphoreslim)
- [Microsoft — Concurrent collections](https://learn.microsoft.com/en-us/dotnet/standard/collections/thread-safe/)
- [Microsoft — Channels](https://learn.microsoft.com/en-us/dotnet/core/extensions/channels)
- [Microsoft — .NET diagnostics](https://learn.microsoft.com/en-us/dotnet/core/diagnostics/)

%TODO mutex - semaphore %