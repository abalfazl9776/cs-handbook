## Caching
### What is caching?
Reading data from memory instead of database (SSD).
Reading from SSD: ~1ms
Reading from Memory: ~100ns
About 10,000 times faster.
### Where to place a cache?
1. **External Caching**: global cache and same view of data across all application instances
2. **In-process Caching**: faster, no need to network roundtrip to an external cache. Suffers from inconsistencies or different view of data.
3. **CDN**: When origin server is in another country or continent. Best use case for media caching.
4. **Client-side Caching**: Caching data in browsers or mobile devices. Suitable case for offline first or offline heavy processing apps.

### Cache architectures
Also referred as **caching strategies**.
now change this to also have write and read flows
#### Cache-Aside (Lazy Loading)
1. Application checks the cache.
2. If the data is there, return it.
3. If not, fetch from the database, store it in the cache, and return it.

Default choice. Cache-aside only caches data when needed, which keeps the cache lean. We also usually invalidate the cache in updates.

Downsides:
- The downside is that a cache miss causes extra latency.
#### Write-Through Caching
1. Application writes only to the cache.
2. The cache then synchronously writes to the database before returning to the application.
3. The write operation does not complete until both the cache and database are updated. 

Requires a cache implementation that supports write-through. Use this when reads must always return fresh data and your system can tolerate slightly slower writes.

Downsides:
- The tradeoff is slower writes because the application must wait for both the cache update and the database write to complete.
- Write-through can also pollute the cache (**cache pollution**) with data that may never be read again.
- Write-through still suffers from the **dual-write** problem. If the cache update succeeds but the database write fails, or vice versa, the systems can end up inconsistent. You need retry logic, error handling, or eventually accept that perfect consistency is difficult without distributed transactions.

#### Write-Behind (Write-Back) Caching
1. Application writes only to the cache (and reads from cache).
2. The cache batches and writes the data to the database asynchronously in the background.

This makes writes very fast. Use this when you need high write throughput and eventual consistency is acceptable. Common in analytics and metrics pipelines.

Downsides:
- If the cache crashes before flushing, you can lose data. This is best for workloads where occasional data loss is acceptable.
#### Read-Through Caching
1. Application never talks to the database directly.
2. On a cache miss, the cache itself fetches from the database, stores the data, and returns it.

This is the read equivalent of write-through. In both patterns, the cache acts as an intermediary that handles database operations. Requires a specialized caching library or service.

#### Write-Around Caching
1. Application writes directly to the database, bypassing the cache.
2. On a cache miss, the application fetches data from the database but does not populate the cache.
3. Data enters the cache only through a separate mechanism or policy.

Use this when newly written data is unlikely to be read again, to avoid cache pollution.

Downsides:
- Repeated reads of uncached data cause repeated database queries, increasing latency and database load.
- Frequently accessed data may never benefit from caching unless another mechanism populates the cache.
#### Important distinction
These patterns describe different dimensions of caching. Cache-aside and read-through primarily describe read behavior, while write-through, write-behind, and write-around primarily describe write behavior. They can be combined, provided their consistency and invalidation rules are defined.
### Cache eviction policies
Eviction is not Expiration. Eviction means removing an item to free cache capacity. Expiration means an item is no longer considered valid after a configured duration or deadline.

**LRU (Least Recently Used)**: LRU evicts the item that has not been accessed for the longest time. It tracks access order using a linked list or ring buffer so the least recently used item can be removed in constant time. It is the default in many systems because it adapts well to most workloads where recently used data is likely to be used again.

Implementation:
- Hash map: Provides O(1) average-time lookup of cache entries.
- Doubly linked list: Maintains the usage order, allowing entries to be moved (to first position when accessed) or removed (when there is no room) in O(1) time.

**LFU (Least Frequently Used)**: LFU evicts the item that has been accessed the least. It maintains a counter for each key and removes the one with the lowest frequency. Some implementations use **approximate LFU** to avoid the cost of precise frequency tracking. This works well when certain keys are consistently popular over time, like trending videos or top playlists and suitable for highly skewed access patterns.

What if two items have the same frequency? A common approach is LRU among items with the same frequency. This combination is often called *LFU with LRU tie-breaking.*

**FIFO (First In First Out)**: Because it may evict items that are still hot, it is rarely used in real systems beyond simple caching layers.

**TTL (Time To Live)**: TTL is not an eviction policy by itself. Instead, it sets an expiration time for each key and removes entries that are too old. It is often combined with LRU or LFU to balance freshness and memory usage. TTL is a must have when data must eventually refresh, like API responses or session tokens.

#### A Quick comparison

|Characteristic|LRU|LFU|
|---|---|---|
|Tracks|Last access time or usage order|Access frequency|
|Eviction target|Least recently accessed|Least frequently accessed|
|Adapts to changing access patterns|Generally quickly|Potentially slowly|
|Protects frequently accessed historical items|Not necessarily|Yes, unless frequency aging changes the ranking|
|Implementation complexity|Relatively low|Higher|
|Common implementation|Hash map + doubly linked list|Hash maps + frequency buckets + lists|
|Typical weakness|May evict frequently used items after a temporary period of inactivity|May retain items that were popular in the past but are no longer needed|
##### A practical problem with LFU: Stale popularity
How can LFU solve this problem? Implementations can use **frequency aging**. Frequency aging reduces the influence of old accesses over time, allowing the cache to adapt to new patterns. For example, instead of retaining a lifetime access count indefinitely, a policy might periodically reduce counters or use a time-decayed frequency estimate. This can make LFU more adaptive, but it introduces additional design decisions.
##### Use LRU when:
- Recently accessed data is likely to be requested again.
- Access patterns change relatively quickly.
- You want a simple, well-understood eviction policy.
- You need predictable implementation complexity.
Example: An application caches recently requested customer records. Customers who were accessed recently may be more likely to be accessed again.
##### Use LFU when:
- A relatively stable subset of items receives most requests.
- Frequently requested items should remain cached even if they experience short periods without activity.
- Historical access frequency is a good predictor of future demand.
Example: A content delivery service caches frequently requested resources, and popularity remains relatively stable over time.

### Common issues that come up from caching
#### Cache Stampede (thundering herd)
A phenomenon that happens when a popular cache entry expires and many requests try to rebuild it at the same time. There is a brief window, even if only a second, where every request misses the cache and goes straight to the database. Instead of one query, you suddenly have hundreds or thousands, which can overload the database.

How to handle it?
- **Request coalescing (single flight)**: Allow only one request to rebuild the cache while others wait for the result. This is the most effective solution.
- **Cache warming**: Refresh popular keys proactively before they expire. This only helps when using TTL-based expiration. If you invalidate cache on writes instead, warming does not prevent stampedes.
#### Cache Consistency (how to handle cache invalidation)
Cache consistency problems are some of the most commonly discussed in system design interviews. They happen when the cache and database return different values for the same data. This is common because most systems read from the cache but write to the database first. That creates a window where the cache still holds stale data.

There is no perfect solution. You choose a strategy based on how fresh the data must be.
How to handle it:
- Cache invalidation on writes: Delete the cache entry after updating the database so it gets repopulated with fresh data.
- Short TTLs for stale tolerance: Let slightly stale data live temporarily if eventual consistency is acceptable.
- Accept eventual consistency: For feeds, metrics, and analytics, a short delay is usually fine.
#### Hot Keys
A hot key is a cache entry that receives a huge amount of traffic compared to everything else. Even if the cache hit rate is high, a single hot key can overload one cache node or one Redis shard and become a bottleneck.

How to handle it:
- **Replicate hot keys:** Store the same value on multiple cache nodes and load balance reads across them. For example, store the same data under several keys (product:123:1 through product:123:10) so the copies hash to different slots and land on different nodes, then have readers pick a suffix at random
- **Add a local fallback cache:** Use **client-side caching**. Keep extremely hot values in-process (server-side application) to avoid pounding Redis.
- **Read replicas:** Adding replicas multiplies read capacity. (In redis it's asynchronous by default, so there is chance to read stale data. Unless using commands like `WAIT`.)
- **Apply rate limiting:** Slow down abusive traffic patterns on specific keys.

For this problem you should also apply some other pattern in Scaling Reads.
### How to talk about caching in an interview
#### 1. Identify the bottleneck
Start by pointing to the specific problem caching will solve. 
- Read-heavy workload
- Expensive queries
- High database CPU
- Latency requirements
Take a look at numbers to know and reason about numbers and how caching helps. %TODO%
#### 2. Decide what to cache
Not everything should be cached. Focus on data that is read frequently, doesn't change often, and is expensive to fetch or compute.
Think about cache keys. How will you look up cached data? For user profiles, the key might be user:123:profile. For trending posts, it could be trending:posts:global.
#### 3. Choose your cache architecture
Pick a [caching pattern](#Cache%20architectures) that matches your consistency requirements.
#### 4. Set an eviction policy
Explain how you'll manage cache size. Check [eviction policies](#Cache%20eviction%20policies).
#### 5. Address the downsides
Caching introduces complexity. Show you've thought about the trade-offs.
##### Cache invalidation
How do you keep cached data fresh? Do you invalidate on writes, rely on TTL, or accept eventual consistency?

*"When a user updates their profile, we'll delete the cache entry so the next read fetches fresh data from the database."*
##### Cache failures
What happens if Redis goes down? Will your database get crushed by the sudden traffic spike?

*"If Redis is unavailable, requests will fall back to the database. We'll add circuit breakers so we don't overwhelm the database with a stampede. We might also consider keeping a small in-process cache as a last-resort layer."*
##### Thundering herd
What happens when a popular cache entry expires and 1000 requests try to refetch it simultaneously?

*"For extremely popular keys, we can use probabilistic early expiration or request coalescing so only one request fetches from the database while others wait for that result."*

Don't list every possible problem. Pick one or two that are relevant to the system you're designing and explain how you'd handle them. For staff-level candidates, focus on the important but non-obvious scenarios rather than burning time on things the interviewer can already assume.
### Other
Be proactive about what are you caching, what are your cache keys and and what the values.

Hybrid Cache (is also useful to prevent all requests flooding to database and bringing the whole system down when main cache, presumably Redis, goes down so caching fallbacks to something like in-process caching before forwarding each request to database. In this case using circuit breakers to shed load can also be useful)

Data Structures available in caching technologies %TODO%

## Replication
%TODO%
how to handle replication lag
how to handle hot keys


## Sharding
Sharding can also be used to scaling reads when even replicas can handle the amount read requests. But that's last resort. See Sharding and it's challenges in [[Scaling Writes]].
