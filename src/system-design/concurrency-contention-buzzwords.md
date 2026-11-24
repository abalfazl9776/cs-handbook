# Concurrency & Contention — Prioritized Buzzword Reference

A categorized reference of concurrency, contention, synchronization, database, and distributed-systems terminology.

**Priority legend**

- **MUST** — Essential for experienced software engineers, everyday development, and technical interviews.
- **ADVANCED** — Important to understand conceptually; implementation-level mastery is not always necessary.
- Unmarked terms — Specialized terminology worth recognizing.

---

## 1. Concurrency Fundamentals

- **MUST** — Concurrency
  - Multiple tasks make progress during overlapping periods, not necessarily simultaneously.
- **MUST** — Parallelism
  - Multiple tasks execute at the same instant on different processing resources.
- **MUST** — Multithreading
  - A process uses multiple threads that can execute independently or concurrently.
- Multiprocessing
  - Multiple processes execute with separate process-level memory and resources.
- **MUST** — Race Condition
  - The result depends on the timing or ordering of concurrent operations.
- **MUST** — Data Race
  - Threads access the same memory concurrently, at least one writes, and access is unsynchronized.
- **MUST** — Critical Section
  - A code region that must not be concurrently executed by conflicting operations.
- **MUST** — Shared State
  - Data or resources accessed by more than one execution flow.
- **MUST** — Thread Safety
  - Code remains correct when accessed concurrently by multiple threads.
- Reentrancy
  - A function can be entered again before an earlier invocation finishes without corrupting state.
- **MUST** — Mutual Exclusion
  - A mechanism ensures only one participant at a time enters a protected region.
- **MUST** — Atomicity
  - An operation appears indivisible: observers see it as all-or-nothing.
- **MUST** — Atomic Operation
  - An operation that cannot be observed in a partially completed state.
- **ADVANCED** — Linearizability
  - A consistency guarantee making each operation appear instantaneous and preserving real-time order.
- **ADVANCED** — Serializability
  - Concurrent transactions produce an outcome equivalent to some serial transaction order.
- **ADVANCED** — Happens-Before Relationship
  - A defined ordering guarantees that one action is visible before another.
- **ADVANCED** — Memory Consistency
  - Rules defining when and in what order memory updates become observable.
- Sequential Consistency
  - Operations appear in one global order that preserves each thread’s program order.

## 2. Synchronization Primitives

- **MUST** — Lock / Mutex
  - A mutual-exclusion primitive that allows one owner at a time.
- **MUST** — Semaphore
  - A counter-based primitive that limits how many participants may enter or proceed.
- Binary Semaphore
  - A semaphore whose permit count is limited to one.
- Counting Semaphore
  - A semaphore that allows a configured number of concurrent permits.
- Monitor
  - A synchronization construct combining mutual exclusion with condition-based waiting.
- Spinlock
  - A lock where a waiting thread repeatedly checks until the lock becomes available.
- **MUST** — Reader-Writer Lock
  - Allows multiple readers concurrently but restricts writers to exclusive access.
- Condition Variable
  - Lets threads sleep until a condition may have changed, usually alongside a lock.
- Event
  - A signalable state used to notify or release waiting threads.
- Barrier
  - Makes participating threads wait until all reach the same synchronization point.
- Countdown Latch
  - Allows waiters to proceed once a counter reaches zero.
- Manual Reset Event
  - A signaled event stays signaled until explicitly reset.
- Auto Reset Event
  - A signal releases one waiter and then automatically resets.
- Signal / Wait
  - One participant signals a condition or event while another blocks waiting for it.
- **MUST** — Compare-And-Swap (CAS)
  - Atomically changes a value only if it still equals an expected value.
- Test-And-Set
  - Atomically sets a value and returns its previous value, often used to acquire a lock.
- **MUST** — Interlocked Operations / Atomic Read-Modify-Write (RMW)
  - Atomic primitives update a value while preventing competing updates from interleaving.
- Memory Barrier / Fence
  - Constrains memory-operation ordering and visibility across the barrier.

## 3. CPU & Memory Model

- **MUST** — Memory Model
  - The rules governing ordering, visibility, and atomicity of memory operations.
- CPU Cache Coherence
  - A protocol keeps cached copies of shared memory consistent across CPU cores.
- Cache Line
  - The unit of memory transferred and maintained by a CPU cache.
- False Sharing
  - Independent variables on the same cache line cause unnecessary cache-coherence traffic.
- **ADVANCED** — Memory Reordering
  - Memory operations become observable in an order different from source order.
- Instruction Reordering
  - Compiler or CPU changes instruction order while preserving allowed behavior.
- Store Buffer
  - A CPU structure temporarily holds pending writes before they become globally visible.
- **MUST** — Memory Visibility
  - Whether updates made by one thread can be observed by another thread.
- Volatile Read / Write
  - Special memory access semantics that constrain visibility or ordering; not a general lock or atomic compound operation.
- Acquire Semantics
  - A read prevents later operations from moving before it in the relevant memory ordering.
- Release Semantics
  - A write prevents earlier operations from moving after it in the relevant memory ordering.
- Sequentially Consistent Operations
  - Atomic operations participate in the strongest commonly used global ordering model.
- Read-Modify-Write (RMW)
  - An operation reads a value, computes a change, and writes it back as one logical update.
- Atomic Read-Modify-Write
  - An RMW operation whose read and write cannot be interleaved by competing operations.
- **ADVANCED** — ABA Problem
  - A value changes from A to B and back to A, making a simple equality check miss the intermediate change.
- Cache Invalidation
  - A cached copy is marked unusable because another participant changed the underlying data.

## 4. Locking Problems & Failure Modes

- **MUST** — Deadlock
  - Two or more participants wait forever for resources held by one another.
- **MUST** — Livelock
  - Participants keep reacting or retrying but make no useful progress.
- **MUST** — Starvation
  - A participant waits indefinitely because others repeatedly get access first.
- **MUST** — Lock Contention
  - Multiple participants compete for the same lock, causing waiting or overhead.
- Lock Convoy
  - Many threads queue behind a lock because its owner or handoff is slow.
- Priority Inversion
  - A high-priority task waits for a resource held by a lower-priority task.
- Priority Inheritance
  - A lock holder temporarily inherits a waiting higher-priority task’s priority.
- Nested Locking
  - A thread acquires another lock while already holding one or more locks.
- Recursive Locking
  - The same thread acquires the same lock multiple times before releasing it.
- Reentrant Lock
  - A lock that permits its owning thread to acquire it again.
- **MUST** — Lock Granularity
  - How much work or how many resources a lock protects.
- Lock Striping
  - Several locks protect different partitions of one logical data structure.
- **ADVANCED** — Lock-Free
  - The system guarantees that some operation completes in a finite number of steps, despite contention.
- **ADVANCED** — Wait-Free
  - Every operation completes within a bounded number of its own steps.
- Obstruction-Free
  - An operation completes if it eventually runs without interference from other threads.
- Busy Waiting / Spin Waiting
  - A thread repeatedly checks for a condition instead of sleeping.
- **MUST** — Blocking
  - A thread waits and is not able to continue until an event or resource becomes available.
- Spinning
  - Repeatedly attempting or checking for progress, often without yielding the CPU.
- Context Switching
  - The scheduler pauses one execution context and resumes another.
- Oversubscription
  - More runnable threads or tasks exist than the available execution capacity can efficiently handle.

## 5. Lock Management & Patterns

- **MUST** — Optimistic Concurrency Control (OCC)
  - Allow work to proceed without locking, then validate conflicts before committing.
- **MUST** — Pessimistic Concurrency Control
  - Prevent conflicts in advance by locking or otherwise restricting concurrent access.
- **MUST** — Optimistic Locking
  - Detect conflicting updates at write time, commonly using a version or condition.
- **MUST** — Pessimistic Locking
  - Acquire locks before or during work to prevent conflicting operations.
- **MUST** — Versioning
  - Attach a version or revision to data to identify which state an operation observed.
- Version Check
  - Verify that the data version has not changed before accepting an update.
- Double-Checked Locking
  - Check a condition before and after acquiring a lock to avoid locking on the common path.
- Coarse-Grained Locking
  - Use a small number of locks to protect large regions or many objects.
- Fine-Grained Locking
  - Use separate locks for smaller regions or individual resources.
- Lock Escalation
  - Replace many fine-grained locks with a broader lock to reduce lock-management overhead.
- Lock Downgrading
  - Convert exclusive access to shared access without fully releasing the protected resource.
- **MUST** — Lock Ordering
  - Acquire locks in a consistent order to prevent circular wait and deadlock.
- Lock Hierarchy
  - A documented ordering or ranking that governs which locks may be acquired together.
- Try-Lock
  - Attempt to acquire a lock immediately or within a limited period without waiting indefinitely.
- Timeout-Based Locking
  - Stop waiting for a lock after a specified duration.
- Read-Copy-Update (RCU)
  - Readers access data with minimal locking while updates create a new version and defer reclamation.
- **MUST** — Immutable Data
  - Data that cannot be changed after creation, simplifying safe sharing.
- **MUST** — Thread Confinement
  - Keep mutable state accessible to only one thread or execution context.
- Actor Model
  - Encapsulate state in actors that communicate through messages rather than shared mutable state.
- **MUST** — Producer-Consumer Pattern
  - Producers create work and consumers process it, often through a queue.

## 6. Database Concurrency Control

- **MUST** — Multi-Version Concurrency Control (MVCC)
  - Maintain multiple data versions so readers and writers can often proceed without blocking each other.
- **MUST** — Snapshot Isolation
  - A transaction reads a consistent snapshot while concurrent transactions may commit changes.
- **MUST** — Read Committed
  - A transaction reads only data committed before each read, with exact behavior depending on the database.
- Repeatable Read
  - Repeated reads of the same rows remain stable within a transaction; phantom protection varies by database.
- **MUST** — Serializable Isolation
  - The database guarantees an outcome equivalent to transactions executing serially.
- Read Uncommitted
  - The weakest common isolation level, potentially allowing reads of uncommitted changes.
- **MUST** — Transaction Isolation
  - The degree to which concurrent transactions are protected from observing or causing anomalies.
- Row-Level Locking
  - Locks individual rows or records to limit interference between transactions.
- Page-Level Locking
  - Locks a database page containing multiple rows or records.
- Table-Level Locking
  - Locks an entire table, restricting concurrent access more broadly.
- Key Lock
  - A lock protecting an index key or key entry.
- Range Lock
  - A lock protecting a range of values or index keys.
- Key-Range Lock
  - A lock protecting an index-key interval, including gaps where needed to prevent inserts.
- Predicate Locking
  - Locks the set of records matching a logical predicate, including potential future matches.
- **MUST** — Shared Lock
  - Allows compatible readers to access a resource while preventing conflicting changes.
- **MUST** — Exclusive Lock
  - Gives one transaction exclusive access against conflicting reads or writes.
- Update Lock
  - A lock mode intended to reduce certain read-then-update conversion deadlocks.
- Intent Lock
  - Signals a transaction’s intention to lock lower-level resources within a larger resource.
- Schema Lock
  - Protects database object definitions from conflicting schema operations.
- Lock Escalation
  - Replace many fine-grained locks with a broader lock to reduce lock-management overhead.
- Deadlock Detection
  - The database detects a cycle of waiting and chooses a transaction to abort.
- Deadlock Victim
  - The transaction selected for rollback to break a deadlock.
- Lock Timeout
  - A transaction or statement stops waiting after a configured time limit.
- Blocking Chain
  - A sequence showing which sessions are waiting on other sessions or locks.
- Wait Statistics
  - Aggregated measurements of what tasks spend time waiting for.
- Write-Ahead Logging (WAL)
  - Records changes in a log before corresponding data pages are persisted.

## 7. Database Concurrency Anomalies

- **MUST** — Dirty Read
  - Reading another transaction’s uncommitted changes.
- **MUST** — Non-Repeatable Read
  - Reading the same row twice and getting different committed values.
- **MUST** — Phantom Read
  - Repeating a predicate query and seeing rows appear or disappear.
- **MUST** — Lost Update
  - One concurrent update overwrites another update that should have been preserved.
- **MUST** — Write Skew
  - Transactions make individually valid changes based on a shared snapshot but jointly violate a constraint.
- Read Skew
  - A transaction observes related values from inconsistent points in time.
- Dirty Write
  - One transaction overwrites another transaction’s uncommitted write.
- Serialization Anomaly
  - A concurrent transaction outcome that cannot be explained by any serial execution.
- **MUST** — Read-Modify-Write Race
  - Concurrent updates interleave between reading a value and writing its modified result.
- **MUST** — Check-Then-Act Race
  - A condition changes after it is checked but before the action based on it occurs.
- **MUST** — TOCTOU (Time-of-Check to Time-of-Use)
  - A resource or condition changes between validation and its later use.

## 8. Distributed Concurrency & Coordination

- **MUST** — Distributed Lock
  - A coordination mechanism intended to grant exclusive access across multiple processes or machines.
- Distributed Mutex
  - A distributed lock that allows only one holder at a time.
- Distributed Semaphore
  - A distributed permit mechanism limiting concurrent access across machines.
- **MUST** — Lease
  - A time-limited grant of ownership or access that expires unless renewed.
- Lease Expiration
  - The point after which a lease holder is no longer authorized by the lease.
- **ADVANCED** — Fencing Token
  - A monotonically increasing token that lets a resource reject stale lock holders.
- Lock Ownership
  - The identity of the participant currently authorized to hold or release a lock.
- Lock Renewal
  - Extending a lease or lock’s validity before it expires.
- **MUST** — Split Brain
  - Two nodes or groups simultaneously believe they are the legitimate leader or owner.
- **MUST** — Leader Election
  - A protocol selects one node to coordinate a distributed group.
- **MUST** — Consensus
  - A protocol lets distributed nodes agree on a value or ordered decisions despite failures.
- **MUST** — Quorum
  - A subset of participants large enough to satisfy a protocol’s agreement or availability rule.
- Raft
  - A consensus algorithm based on leader election and replicated logs.
- Paxos
  - A family of consensus protocols for agreeing on values despite failures.
- Distributed Coordination
  - Mechanisms that synchronize decisions or ownership across independent nodes.
- **MUST** — Distributed Transaction
  - A transaction spanning multiple independently managed resources or services.
- **ADVANCED** — Two-Phase Commit (2PC)
  - A coordinator first asks participants to prepare, then tells them to commit or abort.
- Three-Phase Commit (3PC)
  - A distributed commit protocol that adds a phase to reduce blocking under certain assumptions.
- **MUST** — Saga Pattern
  - A sequence of local transactions coordinated with compensating actions for failures.
- Compensating Transaction
  - A business operation that semantically reverses or offsets an earlier completed operation.
- **MUST** — Eventual Consistency
  - Replicas may temporarily differ but converge if updates stop and propagation succeeds.
- **MUST** — Strong Consistency
  - Reads reflect updates according to a strict consistency guarantee, often immediately after completion.
- Causal Consistency
  - Observers see causally related operations in an order that respects their dependencies.
- Linearizability
  - A consistency guarantee making each operation appear instantaneous and preserving real-time order.
- CAP Theorem
  - During a network partition, a distributed system cannot guarantee both strong consistency and availability for every request.
- Consistent Hashing
  - Maps keys and nodes to a ring-like space to reduce remapping when membership changes.
- Clock Skew
  - Different machines’ clocks disagree about the current time.
- Logical Clock
  - A counter-based mechanism that orders events without relying on wall-clock time.
- Lamport Timestamp
  - A logical timestamp that captures a partial ordering of distributed events.
- Vector Clock
  - A vector of counters used to track causal relationships and detect concurrent events.

## 9. Messaging & Queue-Based Coordination

- **MUST** — Message Ordering
  - The order in which messages are delivered or processed.
- FIFO Queue
  - A queue that returns items in first-in, first-out order.
- Partition Ordering
  - Ordering guarantees apply within a partition, rather than necessarily across all partitions.
- Single-Threaded Consumer
  - A consumer processes messages sequentially on one thread or execution lane.
- Consumer Group
  - A set of consumers sharing work from a topic or queue.
- Partition Ownership
  - The consumer or worker currently assigned to process a particular partition.
- **MUST** — Message Deduplication
  - Detecting and ignoring repeated delivery of the same logical message.
- **MUST** — Idempotency
  - Repeating an operation has the same effect as performing it once.
- **MUST** — Idempotency Key
  - A client-supplied or generated identifier used to recognize retries of one logical operation.
- **MUST** — At-Most-Once Delivery
  - A message is delivered zero or one times, so loss may occur but duplicates are avoided.
- **MUST** — At-Least-Once Delivery
  - A message is retried until acknowledged, so duplicates may occur.
- Exactly-Once Semantics
  - The system guarantees one logical effect under defined boundaries and failure assumptions.
- Message Acknowledgment
  - A consumer confirms that a message has been handled or accepted.
- Visibility Timeout
  - A period during which a retrieved queue message is hidden from other consumers.
- Message Redelivery
  - A message is delivered again after failure, timeout, or missing acknowledgment.
- Poison Message
  - A message that repeatedly fails processing and may block progress.
- **MUST** — Dead-Letter Queue (DLQ)
  - A separate destination for messages that cannot be processed successfully.
- **MUST** — Backpressure
  - A downstream capacity signal slows or limits upstream production.
- Queue-Based Serialization
  - A queue ensures work on a shared resource is processed in a controlled sequence.
- Work Queue
  - A queue distributes pending jobs to workers for processing.
- Competing Consumers
  - Multiple consumers pull work from the same queue to share processing load.
- **MUST** — Transactional Outbox
  - Store an event in the same database transaction as business data, then publish it asynchronously.
- Inbox Pattern
  - Persist received message identifiers or state to make handling duplicates safe.

## 10. High-Contention & Scalability Patterns

- **MUST** — Hot Key
  - A disproportionately popular key concentrates requests or updates on one resource.
- Hot Partition
  - One partition receives much more traffic than other partitions.
- Hot Row
  - A database row becomes a bottleneck because many transactions access or update it.
- Hot Spot
  - A resource or location receives concentrated traffic and becomes a bottleneck.
- Hot Counter
  - A counter receives frequent concurrent updates that contend on one location.
- Write Contention
  - Concurrent writers compete to modify the same data or resource.
- Read Contention
  - Concurrent readers compete for a resource or interfere with writers.
- Contention Amplification
  - A design causes contention to grow disproportionately as traffic or retries increase.
- **MUST** — Request Coalescing
  - Combine concurrent equivalent requests into one underlying operation.
- Singleflight
  - A mechanism ensures only one in-flight operation runs for a given key while others share its result.
- **MUST** — Cache Stampede
  - Many requests simultaneously regenerate the same expired or missing cache entry.
- **MUST** — Thundering Herd
  - Many waiting or triggered clients wake up and compete for the same resource at once.
- Cache Avalanche
  - Many cache entries expire or become unavailable together, causing a surge against the backend.
- Sharded Counter
  - Split one logical counter across multiple independently updated counters.
- Striped Counter
  - Distribute counter updates across stripes to reduce contention, then aggregate them.
- Counter Aggregation
  - Combine partial counter values to obtain a total.
- **MUST** — Batching
  - Group multiple operations into one larger operation to reduce per-operation overhead.
- Write Batching
  - Combine multiple writes into fewer write operations or transactions.
- Request Batching
  - Combine multiple requests into one request to reduce overhead.
- Queue-Based Buffering
  - Temporarily queue work to absorb bursts and smooth processing rate.
- Traffic Shaping
  - Control traffic rate or burstiness before it reaches a constrained resource.
- **MUST** — Load Shedding
  - Reject or discard selected work to protect a system under overload.
- **MUST** — Rate Limiting
  - Restrict the number of operations allowed per unit of time.
- Concurrency Limiting
  - Restrict how many operations may be in progress simultaneously.
- Workload Isolation
  - Separate workloads so one workload’s resource use or failures do not overwhelm another.
- **MUST** — Partitioning
  - Divide data or work into logical pieces for management or parallel processing.
- **MUST** — Sharding
  - Distribute partitions across multiple machines or storage nodes.

## 11. Thread Pool & Runtime Concurrency

- **MUST** — Thread Pool
  - A reusable set of threads that execute submitted work.
- **MUST** — Thread Pool Starvation
  - Queued work cannot get worker threads because existing workers are blocked or occupied.
- Worker Thread
  - A thread assigned to execute a unit of work.
- **MUST** — Async/Await
  - Language constructs for composing asynchronous operations without blocking during awaited waits.
- **MUST** — Asynchronous I/O
  - I/O operations progress without requiring a thread to block while waiting.
- **MUST** — Synchronous Blocking
  - A thread remains occupied while waiting for an operation to finish.
- Thread Affinity
  - A constraint or preference that keeps work associated with a particular thread or CPU.
- Thread Scheduling
  - Choosing which runnable thread executes and when.
- Preemptive Scheduling
  - The scheduler can interrupt a running task to give another task CPU time.
- Cooperative Scheduling
  - Tasks yield control voluntarily or at defined cooperation points.
- Work Stealing
  - An idle worker takes queued work from another worker to balance load.
- Task Parallelism
  - Different tasks execute concurrently to perform separate units of work.
- Data Parallelism
  - The same operation is applied concurrently to different portions of data.
- Fork-Join
  - Work is split into subtasks and later joined after completion.
- **MUST** — Cancellation Token
  - A signal object through which cancellation is requested and observed.
- Cooperative Cancellation
  - Running work periodically checks a cancellation request and stops itself safely.
- Structured Concurrency
  - Child tasks are scoped and managed so their lifetimes and failures relate to a parent task.
- Execution Context
  - Ambient execution information that flows with work, such as identity or tracing context.
- Continuation
  - The code or task scheduled to run after an asynchronous operation completes.
- Task Scheduler
  - The component that determines when and where tasks execute.

## 12. Contention Performance & Diagnostics

- **MUST** — Throughput
  - The amount of work completed per unit of time.
- **MUST** — Latency
  - The time taken for one operation or request to complete.
- **MUST** — Tail Latency
  - Latency experienced by the slowest fraction of requests.
- **MUST** — p95 / p99 Latency
  - The latency threshold below which 95% or 99% of measured requests complete.
- **MUST** — Queueing Delay
  - Time spent waiting in a queue before processing begins.
- Lock Wait Time
  - Time spent waiting to acquire a lock.
- Lock Hold Time
  - Time a participant keeps a lock after acquiring it.
- Contention Rate
  - How frequently operations encounter competition or wait for shared resources.
- **MUST** — Saturation
  - A resource is at or near capacity, so additional load mainly increases waiting or failures.
- Utilization
  - The fraction of a resource’s capacity that is being used.
- Little's Law
  - For a stable system, average items in the system equal arrival rate multiplied by average time in the system.
- Amdahl's Law
  - The serial portion of work limits the maximum speedup from parallelization.
- Scalability
  - How effectively a system handles increased load or resources.
- Parallel Efficiency
  - The speedup achieved relative to the ideal speedup from adding processors.
- Serialization Bottleneck
  - A component that forces otherwise parallel work through one narrow execution path.
- **MUST** — Head-of-Line Blocking
  - A delayed item prevents later items from progressing even when they could otherwise proceed.
- Backlog
  - Accumulated work waiting to be processed.
- Queue Depth
  - The number of items currently waiting in a queue.
- **MUST** — Retry Storm
  - Retries multiply load during failures and can worsen the original overload.
- **MUST** — Exponential Backoff
  - Increase retry delays exponentially after successive failures.
- **MUST** — Jitter
  - Add randomness to retry delays to prevent clients retrying in synchronized bursts.
- Circuit Breaker
  - Temporarily stop calls to a failing dependency to allow recovery and avoid wasted work.
- Bulkhead Pattern
  - Isolate resource pools or workloads so one failure or overload does not spread.
- Cascading Failure
  - A failure in one component triggers failures in dependent components.
- Coordinated Omission
  - A load test underreports latency by failing to record requests that should have occurred during stalls.

---

# Technology-Specific Terminology

Some entries below are technology-specific names or APIs, while the underlying concept may be general.

## 1. .NET / C# / CLR

| Term | Classification |
|---|---|
| `lock` statement | C# language construct |
| `Monitor` | .NET synchronization API |
| `Interlocked` | .NET atomic operations API |
| `Volatile` | .NET API; C# also has the `volatile` keyword |
| `SemaphoreSlim` | .NET API |
| `ReaderWriterLockSlim` | .NET API |
| `ManualResetEventSlim` | .NET API |
| `AutoResetEvent` | .NET API |
| `CancellationToken` | .NET API |
| `SynchronizationContext` | .NET runtime concept/API |
| `ExecutionContext` | .NET runtime concept/API |
| `TaskScheduler` | .NET API |
| `ThreadPool` | .NET runtime API |
| `Channel<T>` | .NET Channels API |

## 2. SQL Server

| Term | Classification |
|---|---|
| `UPDLOCK` | SQL Server lock hint |
| `HOLDLOCK` | SQL Server lock hint |
| `ROWLOCK` | SQL Server lock hint |
| `READPAST` | SQL Server lock hint |
| `NOLOCK` | SQL Server table hint |
| `sp_getapplock` | SQL Server application-level locking |
| `READ_COMMITTED_SNAPSHOT` (RCSI) | SQL Server isolation configuration |
| `SNAPSHOT` isolation | SQL Server implementation of snapshot isolation |

## 3. Redis

| Term | Classification |
|---|---|
| `SET NX PX` | Redis atomic lock-acquisition pattern |
| `WATCH` | Redis optimistic locking |
| `MULTI / EXEC` | Redis transaction commands |
| Lua Scripts | Redis server-side atomic execution |
| Redlock | Redis distributed-lock algorithm |

## 4. Kafka

| Term | Classification |
|---|---|
| Consumer Group | Kafka consumer coordination |
| Partition Assignment | Kafka partition distribution |
| Rebalancing | Consumer group reassignment |
| Offset | Kafka message position |
| Consumer Lag | Kafka processing backlog |
| Idempotent Producer | Kafka producer guarantee |
| Transactional Producer | Kafka transactional messaging |
| ISR (In-Sync Replicas) | Kafka replication terminology |

## 5. Operating System Concepts

| Term | Classification |
|---|---|
| Kernel Mutex | Operating-system synchronization primitive |
| Futex | Linux fast userspace mutex mechanism |
| Critical Section | OS synchronization concept; also a Windows API primitive |
| SRW Lock | Windows Slim Reader/Writer Lock |
| I/O Completion Port (IOCP) | Windows asynchronous I/O mechanism |
| Interrupt | Hardware/OS event mechanism |
| Interrupt Handler | OS/hardware execution mechanism |
| Scheduler | Operating-system task/thread scheduling |
| Context Switch | OS/runtime execution transition |
| System Call | User-mode to kernel-mode transition |

---

# Suggested Learning Priorities

| Priority | Focus |
|---|---|
| **Level 1 — Foundation** | Sections 1, 2, 4, 5, 6, 7, and 11 |
| **Level 2 — Distributed Systems** | Sections 8, 9, and 10 |
| **Level 3 — Deep Internals** | Section 3, advanced synchronization primitives, consensus algorithms, and advanced diagnostics |

**Remember:** recognizing a term is not the same as understanding it. For example, be able to explain why `Interlocked.Increment` is atomic, why `volatile` alone does not make `x++` thread-safe, why `READ COMMITTED` does not necessarily prevent lost updates, and why distributed locks may require fencing tokens.

---

# Comparing Confusing & Related Topics

These pairs are easy to confuse. The distinction matters when choosing a correctness mechanism or diagnosing performance.

## Concurrency vs. Parallelism
- **Concurrency** is about overlapping progress; **parallelism** is about simultaneous execution. A single CPU can interleave concurrent tasks without executing them in parallel.

## Race Condition vs. Data Race
- A **race condition** is a broad correctness bug caused by timing or ordering. A **data race** is a narrower unsynchronized memory-access conflict; data races are one possible cause of race conditions.

## Atomicity vs. Thread Safety
- **Atomicity** means an operation is indivisible. **Thread safety** means the overall code remains correct under concurrent use; it may require multiple atomic operations plus coordination.

## Atomic Operation vs. Atomic Read-Modify-Write
- A simple atomic read or write protects one access. An **atomic RMW** makes the read, calculation/update, and write one indivisible operation; `x++` is not automatically atomic.

## CAS vs. Interlocked Operations
- **CAS** is a specific compare-and-swap primitive. **Interlocked operations** are a family of atomic operations, often implemented using CAS or hardware atomic instructions depending on the operation and platform.

## Lock vs. Semaphore
- A **mutex/lock** usually has ownership: the acquiring thread is expected to release it. A **semaphore** represents permits and generally does not enforce thread ownership; it is useful for limiting concurrency.

## Mutex vs. Monitor
- A **mutex** focuses on mutual exclusion. A **monitor** commonly combines mutual exclusion with condition waiting/notification, such as waiting until a predicate becomes true.

## Spinlock vs. Blocking Lock
- A **spinlock** repeatedly checks for availability and can be efficient for very short waits. A **blocking lock** suspends the waiter, avoiding wasted CPU during longer waits but adding scheduling overhead.

## Deadlock vs. Livelock vs. Starvation
- **Deadlock:** participants are stuck waiting on each other. **Livelock:** participants remain active but make no progress. **Starvation:** one participant is continually denied progress while others proceed.

## Lock Contention vs. Lock Convoy
- **Contention** is competition for a lock. A **convoy** is a performance pattern where many waiters queue behind a slow lock holder or delayed handoff.

## Lock-Free vs. Wait-Free
- **Lock-free** guarantees system-wide progress: some operation completes. **Wait-free** is stronger: every operation completes within a bounded number of its own steps.

## Optimistic Concurrency Control vs. Optimistic Locking
- **OCC** is a broader concurrency-control strategy: proceed, validate, then commit or retry. **Optimistic locking** is a common implementation pattern using a version or conditional update to detect conflicts.

## Pessimistic Concurrency Control vs. Pessimistic Locking
- **Pessimistic concurrency control** is the broad strategy of preventing conflicts in advance. **Pessimistic locking** is a specific way to implement it by acquiring locks.

## MVCC vs. Snapshot Isolation
- **MVCC** is a mechanism that stores multiple versions. **Snapshot isolation** is an isolation guarantee often implemented using MVCC; MVCC alone does not imply snapshot isolation.

## Repeatable Read vs. Serializable
- **Repeatable Read** generally stabilizes repeated reads of existing rows, but phantom behavior varies by database. **Serializable** additionally guarantees an outcome equivalent to a serial execution.

## Read Committed vs. RCSI (SQL Server)
- Traditional lock-based **Read Committed** may use shared locks for reads. SQL Server **RCSI** implements Read Committed using row versions, giving each statement a snapshot rather than holding read locks in the same way.

## Lost Update vs. Write Skew
- **Lost update:** one write overwrites another update to the same value/resource. **Write skew:** transactions update different rows based on a shared snapshot, jointly violating a cross-row rule.

## Dirty Read vs. Non-Repeatable Read vs. Phantom Read
- **Dirty read:** sees uncommitted data. **Non-repeatable read:** the same row changes between reads. **Phantom read:** a repeated predicate query returns a different set of rows.

## Distributed Lock vs. Lease vs. Fencing Token
- A **distributed lock** coordinates access. A **lease** limits ownership by time. A **fencing token** protects the resource from stale holders by requiring monotonically increasing tokens to be checked at the resource itself.

## Lease Expiration vs. Lock Release
- **Expiration** happens automatically when the lease time runs out, even if the holder is still running. **Release** is an explicit action by the holder; relying only on expiration can leave stale work executing.

## Leader Election vs. Consensus
- **Leader election** chooses a coordinator. **Consensus** is the broader problem of agreeing on decisions or values; many leader-based systems use consensus to safely elect or maintain leadership.

## 2PC vs. Saga
- **2PC** coordinates atomic commit across transactional participants and can hold resources while waiting. A **Saga** uses separate local transactions and compensating business actions, so it does not provide one global atomic rollback.

## At-Least-Once vs. Exactly-Once
- **At-least-once** delivery may repeat messages, so consumers need idempotency/deduplication. **Exactly-once** usually means exactly one logical effect within a defined system boundary—not that messages can never be duplicated anywhere.

## Idempotency vs. Deduplication
- **Idempotency** makes repeated execution produce the same logical effect. **Deduplication** detects repeated messages/requests; it is one technique for supporting idempotency, but alone may not make side effects safe.

## Backpressure vs. Rate Limiting vs. Concurrency Limiting
- **Backpressure** communicates that downstream capacity is constrained. **Rate limiting** caps operations per time interval. **Concurrency limiting** caps simultaneous in-flight operations.

## Rate Limiting vs. Load Shedding
- **Rate limiting** proactively enforces a traffic quota. **Load shedding** rejects selected work when the system is overloaded to protect critical functionality.

## Request Coalescing vs. Batching
- **Coalescing** merges duplicate concurrent requests for the same result into one operation. **Batching** groups multiple distinct operations into one larger operation.

## Cache Stampede vs. Thundering Herd vs. Cache Avalanche
- **Stampede:** many requests regenerate one missing/expired cache key. **Thundering herd:** many clients wake or retry together against a resource. **Avalanche:** many cache entries expire or fail together, overwhelming the backend.

## Thread Pool Starvation vs. CPU Saturation
- **Thread-pool starvation** means work cannot obtain a worker, often because workers are blocked. **CPU saturation** means processors are busy; adding workers may worsen it rather than solve it.

## Async I/O vs. Multithreading
- **Async I/O** avoids occupying a thread while waiting for I/O. **Multithreading** uses multiple threads; asynchronous code can be single-threaded, and multithreaded code can still block.

## Latency vs. Throughput vs. Queueing Delay
- **Latency** is time per request; **throughput** is completed work per unit time; **queueing delay** is the portion spent waiting before service begins. Improving one does not always improve the others.

## p95/p99 vs. Average Latency
- The **average** can hide a small group of very slow requests. **p95/p99** show latency thresholds for the slowest 5%/1%, making tail behavior visible.

## Partitioning vs. Sharding
- **Partitioning** divides data/work into pieces. **Sharding** distributes those pieces across multiple nodes or machines; sharding is a distributed form of partitioning.

## Cache Coherence vs. Memory Visibility
- **Cache coherence** concerns consistency of cached copies of a memory location. **Visibility** is the broader question of whether one thread’s writes become observable by another under the language/runtime memory model.

## Volatile vs. Interlocked vs. Lock
- **Volatile** constrains certain reads/writes and ordering but does not make compound operations atomic. **Interlocked** provides atomic operations on specific values. A **lock** protects multi-step invariants and critical sections.

## Memory Barrier vs. Lock
- A **memory barrier** constrains ordering/visibility but does not provide mutual exclusion. A **lock** generally provides exclusion and synchronization, often with memory-ordering guarantees as part of its contract.

## Context Switch vs. Thread Pool Starvation
- A **context switch** is the act of switching execution contexts and has overhead. **Starvation** is a failure to get scheduled/worker capacity in time; frequent context switches can contribute but are not the same issue.

## Queue Depth vs. Backlog vs. Queueing Delay
- **Queue depth** is the number of queued items at a point in time. **Backlog** is accumulated unfinished work. **Queueing delay** is how long an item waits; a growing queue often predicts rising delay.

## Exponential Backoff vs. Jitter
- **Exponential backoff** increases retry intervals after failures. **Jitter** randomizes those intervals so many clients do not retry simultaneously.

## Circuit Breaker vs. Bulkhead
- A **circuit breaker** temporarily blocks calls to a failing dependency. A **bulkhead** isolates resources or concurrency pools so one dependency/workload cannot consume everything.

## Consistent Hashing vs. Consensus
- **Consistent hashing** distributes keys among nodes with limited remapping when membership changes. **Consensus** makes nodes agree on decisions; they solve different distributed-systems problems.

## Strong Consistency vs. Linearizability
- **Strong consistency** is an umbrella phrase whose exact meaning depends on the system. **Linearizability** is a precise guarantee that operations appear atomic and respect real-time order.

## OS Critical Section vs. Critical Section (General)
- A **critical section** generally means code that accesses shared state and needs protection. Some operating systems also expose a primitive literally named “Critical Section”; the API-specific behavior should not be assumed from the general term.

## Thread Affinity vs. Thread Confinement
- **Affinity** prefers or requires work to run on a particular thread/CPU. **Confinement** restricts access to mutable state to one thread, regardless of whether that thread is fixed or selected dynamically.

## Singleflight vs. Distributed Lock
- **Singleflight** suppresses duplicate in-flight work within a coordination scope, commonly one process. A **distributed lock** coordinates independent processes or machines; singleflight does not automatically provide cross-node coordination.

## Transactional Outbox vs. 2PC
- **Outbox** atomically records business data and an event in one local database transaction, then publishes asynchronously. **2PC** coordinates commit across multiple transactional participants; the outbox avoids needing a distributed commit for database-plus-message publication.

