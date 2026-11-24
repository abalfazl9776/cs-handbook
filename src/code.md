OOAD elements (abstraction, encapsulation, hierarchy, modularity, typing, concurrency, persistence)
OOP pillars (abstraction, encapsulation, inheritance, polymorphism)
Solid
Grasp
The principle of least astonishment
Kiss
Yagni
Law of Demeter (writing shy code)
If it quakes like a duck (classification: classic by properties and values, conceptual, prototype (more look alike)) 
DRY dont repeat your self
SLAP (Single Level of Abstraction Principle): 
Postel’s Law – Be liberal in what you accept, conservative in what you return (especially for APIs). 
Composition Over Inheritance 
Low representational gap
Speculative future-proofing
Speculative reuse
Premature optimization is the root of all evil!
Principle of least privilege 
Memory leak
Captive dependency 
Primitive obsession 
Hollywood principle (don't call us we'll call you)
Reach-in reporting Anti pattern
Dependency injection - ambient context - (dependency injection patterns, practices, principles)
Reactive applicationd (manifesto)
Boy scout rule
Managed code vs unmanaged code
Boxing and unboxing 
Concurrency (critical section, synchronized section, race condition, resource contention)
Concurrency problems (Producer-consumer, Readers-writers_problem, Dining_philosophers_problem)
lock contention
Double spending, double charging
Deadlock
livelock
starvation
Bound resources
mutual exclusion
Duck typing
Gossip protocol (decentralized data transfer)
Consistent hashing 
POC (proof of concept), MVP
humble object pattern
can execute, execute
Idempotency 
Offset based and cursor based pagination 
Pyramid of doom (nested ifs)
Special case pattern
Marker interface pattern
Non-repudiation (mostly in net sec)
Security pillars in pen testing (CIA: Confidentiality, integrity, accessibility)
Microservices : (schema registery, service discovery, process manager, bff, api gateway, projection for reports)
Sinks connectors and source connectors
DSL : domain specific language
WAL: write ahead logging
WBL: write behind logging 
Polling, polling consumer
SSE, server sent event
Web socket
Long polling vs Polling
Polling vs WebSockets vs SSE
RBAC - role based access control
ACL - access control list
ACL- anti corruption layer
Message delivery semantics : at least once, at most once, exactly once
Tpc, table per concrete
Observability 3 pillar  Log Trace Metric
Hyrum’s Law
Beyoncé Rule (google)
VCS: version control system
Monorepo
Database (sql rdbms, document store, key value, wide column, graph, vector, time series)
Caching strategy (cache aside, write through, read through, write back, write around)
Cache Invalidation
Cache stampede
Rate limit (leaky bucket, token bucket, fixed window counter, sliding window log, sliding window counter)
tail latency
Tail latency amplification 
Split brain situation (replication and leaders)
Fencing token
Web farm, Web garden
Leaky abstraction (all non-trivial abstractions, to some degree, are leaky. Joel spolsky)
Cartesian explosion
n + 1 query problem
Cardinality (in database )
System of record and system of reference 
single source of truth
synchronous system model
RedLock
backward compatibility = new code can handle old data (data written by old code)
forward compatibility = old code can handle new data (data written by new code)
Mvcc - multi version concurrency control 
Thorngate's postulate of commensurate complexity (LIKE BOUNDED CONTEXTS - customer has different meaning in different contexts) [Mastering Domain-Driven Design - Annegret Junker]
"scatter gather" pattern (request to all nodes and combine all the results)
REPL: A **read–eval–print loop** (**REPL**), also termed an **interactive toplevel** or **language shell**, is a simple interactive computer programming environment that takes single user inputs, executes them, and returns the result to the user
REPR pattern (Request-Endpoint-Response)
ADR: Decision, reason, alternative solution, trade-offs, fallback cost to 2nd solution
Full text search (indexing, inverted index, tokenization, and stemming)
Cascading failures, retry storms
CRDTs (Conflict-free Replicated Data Types)
Monotonically Increasing Identifier (like identity column and sequences in database)
SDLC: Software Development Life Cycle
RTE: Release Train Engineer (role)
hash collision
tombstones
monitor, lock, semaphore, semaphore slim, mutex, spin lock
cache pollution
dual write problem
micro-services communiation patterns
huristics for aggregates boundries
Aggregates are designed; bounded contexts are discovered
consistency requirements (consistency levels): Strong Consistency, Causal Consistency, Read-your-own-writes Consistency, Eventual Consistency (from cap theorem hello interview %TODO% - complete)
Bijective Function
Birthday paradox (hash collision)
Hedged request %TODO%
