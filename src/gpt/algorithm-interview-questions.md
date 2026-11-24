# Algorithm Interview Questions — Constraint-Driven Problem Solving

These questions focus on algorithm design under constraints rather than memorizing standard LeetCode patterns.

## 1. Memory-Constrained Algorithms

### 1. External Sorting
You have **1 TB of records** and **8 GB RAM**. Sort them by a field. You cannot use a database.

**Follow-ups:**
- How do you divide the data?
- How do you create sorted runs?
- How do you merge the runs?
- Why use a k-way merge?
- What happens if there are too many runs?

### 2. Top-K Elements
You have **10 billion numbers** that do not fit in memory. Find the **1,000 largest numbers**.

**Follow-ups:**
- What if you need the top 10 million?
- What if the numbers arrive as a stream?
- Can you solve it in one pass?
- What is the memory complexity?

### 3. Find Duplicates
You receive **500 million integers**, but only **1 GB RAM**. Determine whether any value appears more than once.

**Follow-ups:**
- What if you need to list all duplicates?
- What if you cannot use disk?
- What if the integer range is known?
- What if approximate results are acceptable?

### 4. Find the Median
You have **100 GB of numbers** and only **1 GB RAM**. Find the exact median.

**Follow-ups:**
- Can you avoid sorting the entire dataset?
- How many passes over the data are required?
- What changes if approximate median is acceptable?

### 5. Find the 90th Percentile
You have a dataset larger than memory. Find its **90th percentile**.

**Follow-ups:**
- Exact answer vs approximate answer?
- What algorithms become possible if approximation is allowed?
- What if the data arrives as a stream?

---

## 2. Streaming Algorithms

### 6. Count Distinct Users
You receive a stream containing **billions of user IDs**. Estimate how many unique users appeared.

You cannot store every user ID.

**Topics to consider:**
- Bloom filters
- HyperLogLog
- Probabilistic algorithms
- Accuracy vs memory trade-offs

### 7. Most Frequent Items
You receive a continuous stream of events. Find the **100 most frequently occurring IDs**.

You cannot store every distinct ID.

**Follow-ups:**
- Do you need an exact answer?
- What if the stream is infinite?
- What if memory is fixed?
- How would Count-Min Sketch or Misra-Gries help?

### 8. Random Element from an Infinite Stream
Numbers arrive one at a time and you do not know how many there will be. At the end, return one uniformly random element.

**Constraints:**
- O(1) memory
- O(N) time
- One pass

What algorithm can solve this?

---

## 3. Large-Data Algorithm Design

### 9. Merge Huge Sorted Datasets
You have **100 sorted files**, each containing **10 GB of numbers**. Your machine has **1 GB RAM**. Produce one globally sorted output.

**Follow-ups:**
- How many values do you keep in memory?
- Why use a heap?
- What is the complexity?
- Can you merge two files at a time?
- When is k-way merge better?
- How does the number of files affect performance?

### 10. Search a Huge Dataset
You have **1 TB of sorted data** but only **100 MB RAM**. How would you search for a value?

**Follow-ups:**
- What if the data is not sorted?
- What if you need millions of searches?
- Would you preprocess the data?
- Would an index help?
- What if disk access is very slow?

### 11. Huge Log Processing
You have **2 TB of web-server logs**. Find the **100 IP addresses that generated the most requests**.

A simple `Dictionary<IP, Count>` may not fit in memory.

**Follow-ups:**
- What if exact results are required?
- What if approximate results are acceptable?
- Can you use multiple passes?
- Can you use disk?
- Can you partition the data?

---

## 4. Graph Problems Under Constraints

### 12. Graph Does Not Fit in Memory
You have a graph with **10 billion edges**. You need to determine whether there is a path between A and B.

A normal BFS may require more memory than available.

**Follow-ups:**
- How would you represent the graph?
- What if the graph is stored on disk?
- Can bidirectional search help?
- How would partitioning affect the algorithm?

### 13. Shortest Path with Limited Memory
You have a huge graph that does not fit into RAM. Find the shortest path between two nodes.

**Topics to consider:**
- External storage
- Bidirectional search
- Graph representation
- Partitioning
- I/O cost

---

## 5. Distributed / Scalability-Oriented Algorithms

### 14. Sort Across Multiple Machines
You have **100 machines**, each with **16 GB RAM**. You need to sort **10 TB of data**.

**Follow-ups:**
- How do you distribute the data?
- How do you partition it?
- How do you perform local sorting?
- How do you produce globally sorted output?
- What happens if one machine is much slower than the others?
- How do you deal with stragglers?

### 15. Distributed Top-K
You have **1 billion records distributed across 20 machines**. Find the global top 100.

**Key observation to explore:**

Each machine can calculate its local top 100. Then only:

`20 × 100 = 2,000 items`

need to be considered for the final top 100.

**Follow-ups:**
- Why is this correct?
- What if the data is partitioned unevenly?
- What if you need top 1 million?
- How would you minimize network traffic?

---

## 6. Choosing the Right Algorithm

### 16. Choose a Sorting Algorithm
You need to sort **100 million integers**. Which would you choose?

Possible candidates:
- Quicksort
- Merge sort
- Heap sort
- Counting sort
- Radix sort

There is no universally correct answer.

Ask about:
- Integer range
- Available memory
- Stability requirements
- Data distribution
- Disk vs RAM
- Parallelism
- Worst-case guarantees

### 17. Determine Whether a Number Exists
You need to determine whether a number exists in **1 billion integers**.

Possible approaches:
- Linear scan
- Binary search
- Hash table
- Bloom filter
- Sorting
- Indexing

The appropriate choice depends on the workload.

Consider:
- Number of queries
- Whether preprocessing is allowed
- Memory limits
- Whether false positives are acceptable
- Whether the data changes frequently

---

# Suggested Interview Progression

Rather than solving hundreds of unrelated questions, practice questions that force you to reason about changing constraints.

## Level 1 — Basic Constraints
- Top-K
- Duplicate detection
- Median
- Large sorting

## Level 2 — Memory Constraints
- External merge sort
- K-way merge
- Replacement selection
- External searching

## Level 3 — Streaming
- Reservoir sampling
- Count distinct
- Frequency estimation
- Approximate quantiles

## Level 4 — Distributed
- Distributed sorting
- Distributed top-K
- Partitioning
- Data-local computation
- Stragglers

## Level 5 — Trade-Off Analysis
For every problem, ask:

1. What is the simplest solution?
2. Why does it fail under the given constraints?
3. What information actually needs to be kept?
4. Can I process the data in multiple passes?
5. Can I use disk?
6. Can I trade accuracy for memory?
7. Can I partition the problem?
8. Can I move computation closer to the data?
9. What is the time complexity?
10. What is the memory complexity?
11. What is the dominant cost: CPU, RAM, disk I/O, or network?
12. What changes if one constraint changes?

---

# Particularly Good Questions for Deep Practice

These are especially useful for interviewer-style follow-ups:

1. **1 TB data, 8 GB RAM — sort it.**
2. **500 million integers, 1 GB RAM — find duplicates.**
3. **100 GB numbers, 1 GB RAM — find the exact median.**
4. **10 billion numbers — find top 1,000.**
5. **Infinite stream — return a uniformly random element.**
6. **Billions of IDs — estimate the number of distinct IDs.**
7. **100 sorted 10 GB files — produce one sorted output with 1 GB RAM.**
8. **2 TB logs — find the 100 most frequent IP addresses.**
9. **10 billion-edge graph — determine reachability with limited memory.**
10. **10 TB data across 100 machines — globally sort it.**
11. **1 billion distributed records — find global top 100.**
12. **Choose between quicksort, merge sort, counting sort, and radix sort for 100 million integers.**

For each question, do not stop after finding an algorithm. Try to explain **why the algorithm is appropriate under the constraints**, and what changes when the constraints change.
