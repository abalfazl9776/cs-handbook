## Types of threads
1. Worker Threads / CPU Bound Threads
2. I/O Completion Threads / Asynchronous I/O threads / Completion Port Threads

How to change default thread pool size in .NET application?
```csharp
ThreadPool.SetMinThreads(
    workerThreads: 100,
    completionPortThreads: 100);
```

### ThreadPool starvation
The shared .NET ThreadPool cannot provide workers promptly.
ThreadPool starvation occurs when the .NET ThreadPool cannot provide worker threads quickly enough to execute queued work, causing requests, continuations, callbacks, and background operations to experience excessive delays.
When we talk about thread pool starvation, **the primary concern is usually worker-thread availability**. 

### Thread starvation
A broader term that can refer to a thread being unable to obtain CPU time or execution opportunity.

### Diagnostic symptoms
When investigating a .NET application, look for:
- A growing ThreadPool work queue.
- Increasing ThreadPool thread count.
- Low or unexpectedly _low CPU utilization_ during severe latency.
- Increasing request latency without a corresponding increase in useful throughput.
- Many threads blocked in synchronous calls.
- ThreadPool starvation warnings in ASP.NET Core or .NET runtime diagnostics.

### How to detect ThreadPool starvation in .NET
.NET exposes useful ThreadPool metrics through dotnet-counters.

`dotnet-counters monitor --process-id <PID> System.Runtime`

For a production incident, use:
- dotnet-counters for live runtime metrics.
  - threadpool-thread-count
  - threadpool-queue-length
  - threadpool-completed-items-count
  - cpu-usage
- dotnet-trace for runtime events and ThreadPool behavior.
- dotnet-dump for analyzing thread stacks.

---

## `.GetAwaiter().GetResult()` vs `.Result`
`.Result` wraps exceptions in `AggregateException` but `.GetAwaiter().GetResult()` doesn't.

---

## What is `ConfigureAwait(false)`
- By default, await may capture the current SynchronizationContext to resume execution there.
- `ConfigureAwait(false)` tells the awaiter not to require resuming on the captured context.
- It can prevent classic **deadlocks** caused by blocking a context with `.Result` or `.Wait()`.
- It must be applied to the awaited operation inside the async method, NOT to the caller's `GetAwaiter().GetResult()`. For example:
    ```csharp
    async Task<string> GetDataAsync()
    {
        await Task.Delay(1000).ConfigureAwait(false);
        return "Done";
    }
    
    // Blocking caller
    var result = GetDataAsync().GetAwaiter().GetResult();
    ```
- Use it in library code that doesn't need the caller's synchronization context.
- In ASP.NET Core, it is generally unnecessary because there is no custom request synchronization context by default.
- It does not make blocking calls safe or prevent ThreadPool starvation.
- Prefer await over synchronous blocking whenever possible.

---

## What is `Volatile`?

`Volatile` is a .NET synchronization primitive that provides **memory visibility and ordering guarantees for communication between threads**.

It addresses problems related to compiler/JIT optimizations and CPU memory ordering, where threads may observe shared memory operations differently than expected.

```csharp
Volatile.Read(ref _state);
Volatile.Write(ref _state, value);
```

The `volatile` keyword provides similar semantics for field accesses, while `Volatile.Read` and `Volatile.Write` allow explicit control over individual accesses.

### What problem does it solve?

Consider a worker thread that needs to stop when another thread sets a flag:

```csharp
private bool _stop;

void Worker()
{
    while (!_stop)
    {
        DoWork();
    }
}

void Stop()
{
    _stop = true;
}
```

Although this code may appear to work, ordinary reads and writes do not establish the synchronization guarantees required for communication between threads.

The runtime/compiler may optimize memory accesses, and the program has no proper synchronization relationship between the threads.

Consequently, the worker is not guaranteed to observe the update as expected.

A correct implementation:

```csharp
private bool _stop;

void Worker()
{
    while (!Volatile.Read(ref _stop))
    {
        DoWork();
    }
}

void Stop()
{
    Volatile.Write(ref _stop, true);
}
```

Now the reader and writer have the appropriate memory-ordering guarantees.

### Main usage: Publishing state between threads

One thread prepares some data and then publishes a flag indicating that the data is ready.

```csharp
private int _data;
private bool _ready;

// Producer
void Publish()
{
    _data = 42;
    Volatile.Write(ref _ready, true);
}

// Consumer
void Consume()
{
    if (Volatile.Read(ref _ready))
    {
        Console.WriteLine(_data); // Guaranteed to observe 42
    }
}
```

The important relationship:

- `Volatile.Write` provides release semantics.
- `Volatile.Read` provides acquire semantics.
- When the reader observes the published value, writes preceding the publication become visible to it.

This is commonly called **release/acquire synchronization**.

### What happens if `Volatile.Read` is used without `Volatile.Write`?

`Volatile.Read` does not require a corresponding `Volatile.Write` specifically.

The writer can use another synchronization operation, such as:

- `Interlocked.Exchange`
- `Interlocked.CompareExchange`
- Another appropriate synchronization mechanism

For example:

```csharp
// Producer
_data = 42;
Interlocked.Exchange(ref _ready, 1);

// Consumer
if (Volatile.Read(ref _ready) == 1)
{
    Console.WriteLine(_data);
}
```

Here, `Interlocked.Exchange` provides the publishing operation.

However, if the writer performs only an ordinary write:

```csharp
_data = 42;
_ready = true;
```

while the reader uses `Volatile.Read`, you have not established the complete publication protocol.

**Important:** `Volatile.Read` alone is not a magic operation that makes another thread's writes visible.

### CPU caches and memory ordering

A common misconception is that `Volatile` simply forces the CPU to read directly from RAM instead of its cache.

That is not accurate.

Modern CPUs maintain cache coherence. The problem is that **cache coherence alone does not establish the synchronization guarantees required by the .NET memory model**.

`Volatile` provides appropriate memory-ordering semantics rather than simply bypassing CPU caches.

The important concept is not just whether a thread sees a value, but:

> If a thread observes a particular state, what other memory operations is it guaranteed to observe?

### CancellationToken: A higher-level alternative for earlier example

For stopping a background operation, you generally don't need to implement your own volatile flag.

```csharp
void Worker(CancellationToken token)
{
    while (!token.IsCancellationRequested)
    {
        DoWork();
    }
}
```

`CancellationToken` works with synchronous methods and does not require `Task`.

In ASP.NET Core, the request's cancellation token can be triggered when the request is aborted, including when the client disconnects.

However, cancellation is cooperative: the operation must check the token or pass it to APIs that support cancellation.

A background job that must continue after an HTTP request ends should use a separate cancellation lifetime.

---

## What is `SpinLock`
The SpinLock structure is a low-level, mutual-exclusion synchronization primitive that spins while it waits to acquire a lock. 
On multicore computers, when wait times are expected to be short and when contention is minimal, SpinLock can perform better than other kinds of locks. 
However, we recommend that you use SpinLock only when you determine by profiling that the System.Threading.Monitor method or the Interlocked methods are significantly slowing the performance of your program.
Consult docs before using it.

---

