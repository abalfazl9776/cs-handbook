# Different types of Databases
%TODO%

# Different kinds of indexes
B-tree indexes
Hash Indexes
LSM Trees (Log-Structured Merge Trees)
Geospatial Indexes: Geohash, Quadtree, R-Tree
Inverted Indexes
Column-store indexes (columnar)

Clustered index
non-clustered index
composite index
covering index

# RDBMS
## Compare costs

Plan
Logical reads (IO statistics)
CPU time and elapsed time (parallel is expensive resulting to higher CPU time)
Temp db load and temp db spills (also look at table spools %TODO%)


## Jargons:
Halloween protection (seeing a record in a query twice because of an simultaneous update that has changes it's location) - spools (hopefully won't in recent versions)
Parameter sniffing
sushi principle: raw data is better
Replication 
Sharding
Partitioning
change data capture (CDC)
Connection Pools and Connection limits in database or instance %TODO%
Failover (%TODO% what is it in context of replication and HA)

### BI - Business Inteligence
Data BI
OLAP
OLTP
Data mart
Data warehouse 
Data lake

## Best practices:
prefer set-based queries instead of cursor or subquery or row by row processing
Sargable and non-sargble queries (conditions in where-clause)
Temp db spill, reasons, symptoms, root cause, how to prevent
Heap tables, where to and not to use!
Grouping, cub,sets , roll up , windowing, framing, apply in sql server

## Common Problems (Perfoemance killers)
### N+1 Query Problem
Executing one query to retrieve a collection, followed by N additional queries to retrieve related data for each record individually.
Results in excessive database queries and network round trips.
Use join instead.
### Cartesian Explosion
Occurs when JOINing multiple one-to-many relationships, causing rows to multiply across related collections.
Results in duplicated data in the result set, increased data transfer, and memory consumption.
Use split/separate queires instead and join in-memory.
### One-to-Many JOIN Row Multiplication *(Made up name)*
Occurs when JOINing a parent table with a child table containing multiple records per parent.
Repeats the parent's columns for every matching child record, increasing data transfer and memory consumption.
Use split/separate queires instead and join in-memory.
### Over-fetching
Occurs when a query retrieves more data (columns or rows) than the application actually needs.
Wastes database resources, network bandwidth, and application memory.
Select (project) only required columns.

## Join
%TODO% what are different types of joins and what are the differences between them?

## Queries
Window functions
aggregate functions
sub queries (correlated sub queries, ...)
cross apply
outer apply
join (inner, left, right, full, cartesian (with no condition))
%TODO - complete this section%
select top (1) WITH TIES ... order by date
select id, max(col), sum(col) ... group by id WITH ROLLUP
select * from A with (updlock, readpast)

## Isolation levels
- serializable does not necessarily serializes the transactions. it's usually inferred that this is achieved by blocking. it isn't.
if you want real serializability you should `select with (updlock)` at the begining of transaction, or else by normal `select` statements that hold share lock till the of the transaction, deadlock might happen. imaging a simple read then write scenario. t1 an t2 select a data and both hold shared lock, t1 wants to update the data and t2 wants to update the exat same data. deadlock! but if t1 had used `select with (updlock)`, t2 wouldn't have been able to get the shared lock from the first moment. (same is true for repeatable read)
- most important difference between isolation levels is about how they aquire shared locks and when they release it. 
  - read uncommited: doesn't try to acquire shared lock
  - read committed: tries to acquire lock, if successful, releases the lock and continues, if not, gets blocked until it can successfully acquires shared lock.
  - repeatable read: gets the lock and holds till the end of the transaction
  - serializalbe: get ranged-shared lock and holdes till the end of the transaction.
- avoid using table variables in joins and etc. the optimizor estimates is has a fixed default rows count every time and might use less optimized plan. use temp tables instead.


## channels and voices to follow:
Eric darling , sql server tuning

[Build Your own database](https://cstack.github.io/db_tutorial/)

# NoSQL

The most common types of NoSQL databases are key-value stores, document stores, column-family stores, and graph databases.

