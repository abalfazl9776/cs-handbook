# Hash Tables: Implementation, Collisions, and Best Practices

## 1. Key Concepts

- **Map:** An abstract data type representing key-value associations. It can have different implementations with different performance characteristics.
    
- **Hash table:** A data structure that uses hashing and an underlying storage structure to provide efficient key-value operations.
    
- **Hash function:** Converts a key into a numeric hash code.
    
- **Bucket:** A logical storage location selected using a hash code and the table's capacity.
    
- **Hash collision:** Occurs when two different keys produce the same hash code or map to the same bucket/index.
    
- **Load factor:** Ratio of stored entries to available capacity.
    
- **Resizing / Rehashing:** Increasing capacity and redistributing entries to maintain efficient operations.
    
- **Probing:** Searching for alternative slots when the initial slot is occupied.
    
- **Tombstone:** A marker representing a deleted entry in an open-addressing hash table. It allows lookups to continue through previously occupied slots.
    
- **Clustering:** Formation of groups of occupied slots that increase probing costs.
    

## 2. How a Hash Table Achieves O(1) Average Lookup

A hash table avoids searching every entry by calculating where the requested key should be stored.

**Lookup process:**

1. Calculate the key's hash code using a hash function.
    
2. Convert the hash code into a bucket index.
    
3. Access the bucket or array slot directly.
    
4. Compare actual keys to identify the requested entry and resolve any collisions.
    

For a table with capacity `m`, a simplified bucket calculation is:

`index = hash(key) % m`

**Example:**

Suppose the hash function returns `83`, and the table has 10 buckets.

`index = 83 % 10 = 3`

The table can access bucket 3 directly rather than scanning all entries.

**Why O(1)?** Hash computation and array indexing take constant time under the usual fixed-size key assumptions. If keys are distributed reasonably well and collisions are controlled, the expected number of entries examined remains constant as the table grows.

However, collisions can cause additional work, so O(1) is an average/expected complexity, not a worst-case guarantee. A poor hash distribution can degrade lookup to O(n).

## 3. Example: Hash Function and Hash Table

Consider a simplified hash table with a capacity of 7 and integer keys.

For illustration, define:

`hash(key) = key`

Then calculate:

`index = hash(key) % 7`

|Key|Hash code|Bucket index|
|---|---|---|
|10|10|3|
|17|17|3|
|24|24|3|
|12|12|5|

Keys 10, 17, and 24 all map to bucket 3. This is a **collision**, even though their hash codes differ.

This example uses a deliberately simple hash function to demonstrate collisions. Real implementations use more sophisticated hashing and collision-resolution strategies.

The hash table must resolve collisions using one of the approaches below.

## 4. Collision-Resolution Strategies

The two primary approaches are **separate chaining** and **open addressing**.

### A. Separate Chaining

- The table uses an array of buckets.
    
- Each bucket references a collection of entries, commonly a linked list or another suitable structure.
    
- Colliding keys share a bucket but remain distinguishable through key equality comparisons.
    
- Resizing typically allocates a larger bucket array and redistributes entries.
    

**Example:**

```
Buckets
  0 → null
  1 → null
  2 → null
  3 → (10, "A") → (17, "B") → (24, "C")
  4 → null
  5 → (12, "D")
  6 → null
```

To find key 17, calculate its bucket index, access bucket 3, and examine the entries in that bucket until the matching key is found.

Average lookup is O(1) when bucket chains remain short. In the worst case, lookup is O(n).

### B. Open Addressing

- All entries are stored directly inside the table's array.
    
- When a collision occurs, a probing strategy searches for another available slot.
    
- Lookup follows the same probing sequence used during insertion.
    
- Deletion requires special handling, commonly using tombstones, to preserve lookup correctness.
    

#### Probing strategies

|Strategy|Probing rule|Advantages|Disadvantages|
|---|---|---|---|
|**Linear probing**|Check consecutive slots|Simple; good cache locality|Primary clustering|
|**Quadratic probing**|Use quadratic offsets|Reduces primary clustering|May not visit every slot; secondary clustering remains possible|
|**Double hashing**|Use a second hash function to determine the step size|Reduces clustering|More complex; requires suitable hash functions and capacity|

**Important terminology:**

- **Primary clustering:** Linear probing creates contiguous groups of occupied slots, increasing the cost of future insertions and lookups.
    
- **Secondary clustering:** Keys with the same initial hash follow the same probe sequence, even when quadratic probing is used.
    
- **Probe sequence:** The ordered sequence of slots examined during insertion or lookup.
    

### Comparison

|Characteristic|Separate Chaining|Open Addressing|
|---|---|---|
|Entry storage|Collections associated with buckets|Directly inside the table array|
|Collision handling|Add another entry to the bucket|Probe for another slot|
|Load factor|Can exceed 1|Must remain below 1|
|Memory overhead|Bucket array and per-entry or collection overhead|Typically compact entry storage|
|Cache locality|Often poorer due to pointer traversal|Often better due to array locality|
|Deletion|Usually straightforward|Requires careful handling of probe sequences|

## 5. Deletion and Tombstones

- In open addressing, simply marking a deleted slot as empty can break a probe sequence and cause existing keys to become unreachable.
    
- A **tombstone** marks a slot as deleted but preserves the ability to continue searching through it.
    
- Insertions may reuse tombstones, but implementations must continue searching when necessary to avoid inserting duplicate keys.
    
- Accumulated tombstones increase lookup and insertion costs.
    
- Rebuilding or resizing the table can remove tombstones and restore performance.
    

Separate chaining generally does not require tombstones because deleting an entry does not break a probing sequence.

## 6. Performance Characteristics

|Operation|Average / Expected|Worst Case|
|---|---|---|
|Lookup|O(1)|O(n)|
|Insertion|O(1) amortized|O(n) during resizing or under severe collisions|
|Deletion|O(1) expected|O(n), depending on collision handling|

**Amortized O(1)** means that although an individual insertion may trigger an expensive resize, the average cost across a sequence of insertions remains constant per operation under a geometric-growth strategy.

These bounds assume suitable hash distribution and table management. Adversarial or poorly distributed hashes can cause severe performance degradation.

## 7. Resizing and Load Factor

- A hash table typically resizes when its occupancy reaches a configured threshold.
    
- Resizing allocates additional storage and redistributes entries.
    
- The bucket index may change because the index calculation depends on the table's capacity.
    
- Geometric growth reduces the frequency of resizing.
    
- A lower load factor generally reduces collisions but consumes more memory.
    
- A higher load factor saves space but can increase lookup and insertion costs.
    
- For open addressing, keeping the load factor sufficiently below 1 is particularly important because available slots become increasingly scarce as the table fills.
    

If the expected collection size is known, preallocating capacity can reduce repeated allocations and copying.

## 8. Best Practices

- **Use a well-distributed hash function.** Poor distribution increases collisions and degrades performance.
    
- **Choose an appropriate load factor.** Balance memory usage against collision-resolution costs.
    
- **Preallocate capacity when the expected collection size is known.** This reduces resizing and copying.
    
- **Handle deletion correctly.** Open addressing requires tombstones or another deletion strategy that preserves probe sequences.
    
- **Consider cache locality.** Open addressing often benefits from contiguous memory access.
    
- **Avoid assuming O(1) is guaranteed.** Hash tables provide expected or average O(1) lookup under suitable conditions, not constant-time worst-case guarantees.
    
- **Use appropriate equality semantics.** Hash codes identify candidate locations; key equality determines whether the requested key has been found.
    
- **Maintain the hash/equality contract.** If two keys are equal according to the equality comparer, they must produce equal hash codes.
    
- **Avoid mutating keys.** Changing fields that participate in a key's equality or hash code while it is stored in a dictionary can make the entry effectively unreachable through normal lookup.
    
- **Prefer established library implementations** unless specialized requirements justify implementing a custom hash table.
    

## 9. C# and .NET

- `Dictionary<TKey, TValue>` is the standard general-purpose hash-based key-value collection.
    
- It uses hashing, buckets, and entries internally. Exact implementation details can change between .NET versions.
    
- `Dictionary<TKey, TValue>.EnsureCapacity()` can reduce repeated allocations when the expected number of entries is known.
    
- `List<T>` is an array-backed sequence, not a hash table. Indexed access is O(1), but searching by value is O(n).
    
- `Dictionary<TKey, TValue>` provides average O(1) lookup under suitable conditions.
    
- For custom key types, implement consistent `Equals()` and `GetHashCode()` behavior, or supply an appropriate `IEqualityComparer<TKey>`.
    
- `Dictionary<TKey, TValue>` is not inherently thread-safe for concurrent modifications.
    

## Summary

A hash table uses a hash function to calculate where a key should be stored, avoiding a full scan of the collection. Its underlying storage is commonly an array of buckets, with collisions handled through separate chaining or open addressing.

**The key to average O(1) lookup is direct access to a calculated location, combined with a well-distributed hash function, a controlled load factor, and efficient collision resolution.**