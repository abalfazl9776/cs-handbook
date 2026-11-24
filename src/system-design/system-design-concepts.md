# What is system design about in 1 minute?
## 1 - Too many reads? Scaling Reads
Cache, Read Replicas, Index Database
## 2 - Too many writes? Scaling Writes
Batch Process, Sharding, Async Writes
## 3 - Live Updates? Real-Time
WebSockets, Server-Sent Events, Polling (Long-Polling)
## 4 - Faster Background Jobs
Message queues, Worker Pools
## 5 - Things will fail! Reliability
Retries + backoff (or jitter), Idempotency, Circuit breakers
## 6 - Reads and Writes conflicts? Split Reads and Writes
CQRS
# Concepts
## Hyper Log Log
%TODO% where to use
to count unique items with efficient memory and low error rate.
in redis it uses only 12kB with error rate of les than 0.81%

## Bloom filters
%TODO% where to use
## Rate Limit Methods
### Leaky Bucket
### Token Bucket
### Fixed Window Counter
### Sliding Window Log
### Sliding Window Counter
%TODO%

## [Scaling Reads](./scaling-reads.md)
### Replication
### Caching

### Sharding (When Replication and Caching is not enough)
## [Scaling Writes](./scaling-writes.md)
### Sharding

## Consistent Hashing
%TODO%

## Distributed Locking
### Redis RedLock
### Locking Granularity
#### Single item vs Range or group of items
%TODO% How to lock group of items in an atomic way in context of distributed locking.
### Deadlocks
Always acquire locks in the same order to prevent deadlocks and cycles in requesting locks.
%% If we have n Requests(Client: c) and m (m>n) Resources(r) and c1 wants r1 and r2 and c2 wants r2 and r3 and cn wants rn and rn+1 and timing happens in a way that each client succeeds to acquire it's first resource then after that n-1 requests will fail and only cn can get rn+1 cause nobody wants that resource. Even if requests retry same thing can happen again. So maybe we can add jitter to retry delay. %%
### Timeout
Always set timeout so that in case of a process crash or kill, other clients can acquire the lock after a specific time.

## CAP THEOREM
It states you can only have two of three properties at once. Consistency (all nodes see the same data), Availability (every request gets a response), and Partition tolerance (system works even when network connections fail between nodes). Since network partitions are unavoidable in distributed systems, you're really choosing between consistency (refuse to serve requests) and availability (return potentially stale data).
### PACELC theorem
It's worth knowing that the CAP theorem only describes behavior during network partitions, which are relatively rare. In normal operation, the real tradeoff is between consistency and latency. During a Partition, choose Availability or Consistency; Else, choose Latency or Consistency. In practice this means that even when your network is healthy, choosing strong consistency adds latency because nodes need to coordinate before responding.

## Timeouts & Retries
- Use timeouts and retries to handle transient failures.
- Retry only when appropriate; idempotent APIs make retries safer.
- Use exponential backoff to increase the delay between failed attempts.
- Add jitter (randomness) to prevent synchronized retries and **thundering herd**.
- Bound retries and delays to avoid amplifying failures and **cascading failures**.
- Jitter methods: Full Jitter, Equal Jitter, Decorrelated Jitter.
## Idempotency
Performing the same operation multiple times has the same effect as performing it once. Use an idempotency key to identify a logical request and store its result. Repeated requests with the same key should not execute the operation again.
Which Http methods are idempotent?

| HTTP method | Idempotent?     | Explanation                                                                                                                          |
| ----------- | --------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| GET         | Yes             | Retrieves a resource without intending to change its state.                                                                          |
| HEAD        | Yes             | Like GET, but returns headers without the response body.                                                                             |
| PUT         | Yes             | Replaces a resource with the specified representation.                                                                               |
| DELETE      | Yes             | Repeatedly deleting the same resource has the same intended effect.                                                                  |
| OPTIONS     | Yes             | Requests communication options.                                                                                                      |
| TRACE       | Yes             | Diagnostic method; defined as idempotent.                                                                                            |
| POST        | No              | Often creates a resource or triggers an operation, potentially producing additional effects on each request.                         |
| PATCH       | Not necessarily | Depends on the patch operation; some patches are idempotent (like **setting** a value), others are not (like **adding** to a value). |

## Circuit Breaker
Stops calls to failing services to prevent cascading failures.
Here's how they work:
1. The circuit breaker monitors for failures when calling external services
2. When failures exceed a threshold, the circuit "trips" to an open state
3. While open, requests immediately fail without attempting the actual call
4. After a timeout period, the circuit transitions to a "half-open" state
5. A test request determines whether to close the circuit or keep it open
This pattern, inspired by electrical circuit breakers, prevents cascading failures across distributed systems and gives failing services time to recover.
Circuit breakers provide numerous advantages:
- Fail Fast: Quickly reject requests to failing services instead of waiting for timeouts
- Reduce Load: Prevent overwhelming already struggling services with more requests
- Self-Healing: Automatically test recovery without full traffic load
- Improved User Experience: Provide fast fallbacks instead of hanging UI
- System Stability: Prevent failures in one service from affecting the entire system
Most common places where we use circuit breakers are network calls (external service, database, etc.) or resource intensive operations that might time out.

## Kill Switch
%TODO%

## Notes
### Rate Limiting
Controls how many requests a client can send.  
### Load Shedding
Drops excess load when the system is overwhelmed. (reject low-priority report requests when the database is saturated.)
### Load balancing
Client side load balancers and server side load balancers
Dedicated load balancers (%TODO whare other types and pros and cause and where to use each%)
Layer 4 (tcp) load balancers and Layer 7 (application) level load balancers
Layer 4 like AWS NLB (Network load balancer) and Layer 7 like ALB (Application load balancer)
Layer 4 has better performance and should be used when we have WebSockets or stateful connections (%TODO maybe%)
Layer 7 should be used where? (%TODO%) when we need more intelligent routing decisions.
How DNS plays role of a client side load balancer?
#### Load balancing strategies (%TODO%)
- **Round Robin**: Requests are distributed sequentially across servers
- **Random**: Requests are distributed randomly across servers
- **Least Connections**: Requests go to the server with the fewest active connections
- **Least Response Time**: Requests go to the server with the fastest response time
- **IP Hash**: Client IP determines which server receives the request (useful for session persistence)
### Split brain
what is it? %TODO%
### Other topics
Eventual Consistency, Strong Consistency, Weak Consistency (no guarantee about convergence of data)
### General Recommendations
The fallacy of "the network is reliable" is one of the most dangerous assumptions in distributed systems. Always design with the expectation that network calls will fail, be delayed, or return unexpected results.

## Jargon
back-of-the-envelope calculations
MTBF — Mean Time Between Failures (How often do failures occur, on average? OR MTTF Mean time to failure)
MTTR — Mean Time to Repair/Recover (How long does recovery take, on average?)
RTO — Recovery Time Objective (How quickly must we recover?)
RPO — Recovery Point Objective (How much data can we afford to lose?)
Signal-to-Noise-Ratio
