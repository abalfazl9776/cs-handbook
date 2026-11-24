## Sharding
Sharding can also be used to scaling reads when even replicas can handle the amount read requests.
But, how to handle hot spots? how to pick shard keys? picking one shard key like userId facilitates queries related to single user like "all posts of a user" but complicates queries for ranges like "new posts from all users".
%TODO%
Sharding creates new problems you need to address. Cross-shard transactions become nearly impossible, so you need to design your shard boundaries to avoid them.
Resharding is painful. You can't just add a new shard without moving massive amounts of data around.

## Batch Processing
Batching techniques help reduce per-operation overhead by grouping multiple writes together.
%TODO%

## Async Writes
For burst handling, you can use write queues to buffer temporary spikes or implement [load shedding](./system-design-concepts.md#Concepts#Notes#Load%20Shedding) to prioritize important writes during overload.
%TODO%


