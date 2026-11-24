## Concepts:
**producer**
**consumer/consumer group** (each consumer is in one consumer group)
**broker** (backend server for kafka
**message/record** (data) (consists of timestamp, value, optional key and custom headers)
**key**: In general, the same key should produce the same partition assignment for a message. Used for grouping related events.
**topic/partition** (topic are like folders and partition are like files)
**ISR**: number of in-sync replicas of topic partitions.
**zookeeper** (or kraft in newer versions): handles clustering and consensus. provides discovery, configuration and synchronization
**offset**: the number of the messages (index position) a consumer has read up to that from a topic and should continue with that to get next messages.
**Rebalancing**



------------------
Producer Configs
------------------
prop: acks || values: -1,0,1,all (-1 and all means no lost message, safety)(0 means fire and forget)(1 means just the leader replica)
prop: bootstrap.servers || values: one of available broker address for initial conneection to cluster and get cluster info and metadata
prop: max.in.flight.requests.per.connection || values: [number] (1 for ordering)
prop: key/value.serializer || values: [custom]


Once the producer is connected to the cluster (one of bootstrap servers), it can obtain the metadata it needs to get the
details (such as where the leader replica for the partition resides on disk) we did not previously provide.
The bootstrap.servers parameter in connecting to kafka is to only find a one kafka node, and then it will take the cluster information from that. no need to be full list of brokers.

Producers doesn't need to know about zookeeper.

Producers doesn't need to know about partitions (they obtain partition leader info from cluster, automatically).

Kafka provides a default way to send messages to a specific partition. The default for a message with no key was a round-robin assignment strategy prior to Kafka version 2.4.
In versions after 2.4, messages without keys use a sticky partition strategy. However, sometimes we have specific ways that we want our data to be partitioned. One way to take
control of this is to write our own unique partitioner class.
The client can control which partition the data gets written to by providing
their own logic with the Partitioner interface.


------------------
Consumer Configs
------------------
prop: bootstrap.servers || values: like producer
prop: key/value.deserializer || values: [custom]
prop: enable.auto.commit || values: true(default),false
prop: auto.offset.reset || values: earliest, latest
prop: group.id || values: [custom] (need to join a consumer group)
prop: client.id || values: [custom]
prop: heartbeat.interval.ms || values: [custom]: (Interval for consumer’s pings to the group coordinator)
prop: partition.assignment.strategy || values: Range, RoundRobin, Sticky, CooperativeSticky
each consumer can subscribe to multiple topics at the same time.


Messages are not pushed to consumer from kafka brokers, instead, consumers pull messages. The power of processing control shifts to the consumer in this situation. 

Consumers themselves control the rate of consumption

Consumers can fetch data from a follower replica due to an issue like
network latency concerns (for example, having a cluster that stretches across data centers), KIP-392 introduced this ability in version 2.4.0. But this is not the default behavior.

If Consumers in a consumer group are more than partitions of a topic they consume, e.g. four consumers and three partitions, one consumer will stay idle. And, in an instance
where there are more partitions than consumers, consumers handle more than one
partition if needed.
As a general rule, only one consumer per consumer group can read one partition.

The group coordinator (one of brokers) is not only in charge of
assigning which consumers read which partitions at the beginning of group startup but also when consumers are added or fail and exit the group.


Why is the concept of consumer groups paramount? Probably the most important reason is that scaling is impacted by either adding customers to or removing consumers
from a group. Consumers that are not part of the same group do not share the same
coordination of offset knowledge.

One of the neat things about being part of a consumer group is that when a consumer
fails, the partitions that it was reading are reassigned [8]. An existing consumer takes
the place of reading a partition that was once read by the consumer that dropped out
of the group. (rebalancing maybe!)

Because messages are not removed from other consumers or delivered once,
consumer clients need a way to keep a record of where they have read in the topic. In
addition, because many applications can read the same topic, it is important that the
offsets and partitions are specific to a certain consumer group.


For each group of consumers, a specific broker takes on the
role of being a group coordinator [8]. The consumer client talks to this coordinator
in order to get a partition assignment along with other details it needs in order to consume messages. Partition assignment is needed because consumers are reading messages from partitions. Topic is a logical name for what a consumer is interested.

The property partition.assignment.strategy is what determines which partitions are assigned to each consumer.

One option is to use enable.auto.commit set to true, the default for consumer
clients. Offsets are committed on our behalf. One of the nicest parts of this
option is that we do not have to make any other calls to commit the offsets that are
consumed.

If you need to be sure to commit a
record at a specific time as you process it or a specific offset in particular, you should
make sure that you send the offset metadata into the commit method.

When passing offsetmetadata to a commit method (in consumer side) we should send next offset that we want to poll. so we add 1 to the offset that is just conusmed.

As we did with a producer when we sent a message earlier, we can also commit offsets in a synchronous or asynchronous manner.

Maybe we want to read from the beginning of a topic even if we have already done so. The
important configuration to set for this behavior is auto.offset.reset to earliest. Another technique that we can use is to run the same logic but use a different group ID.

Sometimes you just want to start your logic from when the consumers start up and forget about past messages. set auto.offset.reset to latest.

we have the ability to retrieve the offset and timestamps per a
topic or partition when we map each to a timestamp. using a method named offsetsForTimes and passing a timestamp. this method Finds the first offset greater or equal to that timestamp.



A consumer can prioritize partitions to consume partitions with higher priority messages first. We use TopicPartition objects to tell Kafka which specific partitions we are interested in for a topic. Passing the TopicPartition objects to the assign method of consumer (instead of subscribing to topic) takes the place of allowing a consumer to be at the discretion of a group coordinator assignment.


-----------
Use cases
-----------
massive quantities of data are one of the critical areas where Kafka shines.

If your main access pattern for data is a mostly random lookup of data, Kafka
might not be your best option. Linear read and writes are where Kafka shines.

High availability and persistent storage are built into kafka from start. so messages wont be lost with server restarts.

It is not yet another message broker, it provides:
- the ability to replay messages
- parallel processing of data

concumers can consume from same topic independently without causing messages being removed from topic.

----------
Ordering
----------
if you need the exact ordering of messages in Kafka for the entire topic,
only one producer and only one partition in the topic and only one consumer should exist.

Kafka itself does allow messages to be sorted by time, but the message
payload can include time. in newer versions, ProducerRecord (in java client) contain a timestamp on the events you sent. The actual time that is used in the message can stay as this value, or it can be a broker timestamp that occurs when the message is logged. Setting the topic configuration message.timestamp.type to CreateTime uses the time set by the client, whereas  setting it to LogAppendTime uses the broker time.

The data is ordered in the log by offsets and
not by timestamp. Although reading timestamped data is often thought of as a consumer client concern, it is also a producer concern because the producer takes the
first steps in ensuring message order.
As discussed earlier, this is also why max.in.flight.requests.per.connection is
important when considering whether you want to allow retries or many inflight
requests at a time. If a retry happens and other requests succeed on their first attempt,
earlier messages might be added after the later ones

due to the producer resending messages on
failures or variations in when timestamps are added (by consumers, perhaps), times
might appear out of order. (maybe happens when setting message.timestamp.type to CreateTime so timestamps are set in client side.)


-------------
Performance
-------------
The smaller the message size and the amount of memory we can offer to
page caches, the better shape we are in to keep our performance healthy

The default message size is about 1 MB. With larger messages, you start to see memory pressure increase. In other words, the lower number of messages you can store in page cache could become a concern.

Kafka is made to keep its performance fast even while keeping its messages

so a design consideration is access pattern of data. latest messages are likely the ones clients are more interested in to, which can be served from page cache. adding more RAM helps more of workload to fall into page cache.

Kafka uses batching of messages for sending data as well as for writing to overcome the issue of performance while working with small messages and may overwhelm system.

Because the number of partitions determines the amount of parallel consumers you
can have, some might ask why you don’t always choose a large number such as 500
partitions. This quest for higher throughput is not free [9]. One key consideration is that many partitions might increase end-to-end latency. If milliseconds count in your application, you might not be able to wait until a partition is replicated between brokers [9]. This is key to having in-sync replicas, and it is done before a message is available for delivery to a consumer.

Why would you want to choose synchronous or asynchronous commit patterns?
Keep in mind that your latency is higher if you wait for a blocking call. This time factor might be worth the delay if your requirements include needs for data consistency.



-------
Topic
-------
prop: replication-factor || values: 1,2,... (includes leader, so 1 means only leader)
prop: partitions || values: 1,2,...
prop: cleanup.policy || values: compact (being able to compact later), delete


Kafka compacts the partition log in a background process, and records with the same key might
be removed except for the last one. The biggest “gotcha” for consumers that might cause an error is that when reading records from a compacted topic, consumers can still get multiple entries for a single key! Because compaction runs on the log files that are on disk, compaction may not see every message that exists in memory during cleanup. So, Consumers should be made aware of reading from a compacted topic, because then need to handle this case.

As a quick refresher, topics are made up of partitions, and partitions can have replicas
for fault tolerance. Also, partitions are written on the disks of the Kafka brokers. One
of the replicas of the partition will have the job of being the leader. The leader is in
charge of handling writes from external producer clients for that partition. Because the
leader is the only one with newly written data, it also has the job of being the source of
data for the replica followers. Replicas act as consumers of the leader partition and will fetch the messages.

For practical purposes, we should plan on having the total number of replicas less
than or equal to the number of brokers. In fact, attempting to create a topic with the
number of replicas being greater than the total number of brokers results in an error:
InvalidReplicationFactorException

having one partition on each server does not mean producers will write evenly among them.

How to choose the number of topics/partitions in a Kafka cluster?
Considering 3 things:
- Data correctness: making sure that events that must be ordered end up in the same partition and, thus, the same topic
-The volume of messages of interest per consumer: Do consumers have to filter out 99% of data only because they subscribed to a general topic?
-How much data you will have or need to process: Will the number of messages require multiple consumers to be running in order to process within the time constraints required by our applications? (number of consumers in a group is limited by the partitions in our topic)

A last thing to consider when deciding on the number of partitions for a topic is
that reducing that number is not currently supported [3]. this would not be desirable.
When consumers subscribe to a topic, they really are attached to a partition. The
removal of a partition could lose its current position when or if a consumer starts
reading from a reassigned partition.

log compaction: the goal is not to expire messages but rather to make sure that the latest value for a key exists and not to maintain any previous state


-----------
Zookeeper
-----------

in newer versions, Zookeeper is replaces with KRaft.

Although consumers used ZooKeeper to store the offsets that they consume to a certain point, now the offsets are often stored inside a Kafka internal topic.

ZooKeeper itself holds
information such as topics in our cluster [4]. ZooKeeper helps the brokers by coordinating assignments and notifications. if our ZooKeeper instances are
damaged, topic metadata and configuration could be lost.

elect a new controller between multiple available brokers.



--------
Broker
--------
each partition has a single leader replica. A leader
replica resides on a single broker at any given time. A broker can host the leader
replica of multiple partitions, and any broker in a cluster can host leader replicas.
Only one broker in the cluster, however, acts as the controller. The role of the controller is to handle cluster management [12]. The controller also performs other administrative actions like partition reassignment

In some cases, a broker that fails may have hosted the leader replica for a partition. if partition has a replication factor, then a new leader (broker) is elected.

A follower replicate might become slow and falls behind the leader, the leader then remove that replicate from it's ISR list. It is good to keep aware of how many
copies you have before it hits 0.

What if we have no ISRs and lose our lead replica due to a failure? When unclean
.leader.election.enable is true, the controller selects a leader for a partition even
if it is not up to date so that the system keeps running

Kafka replicas do not heal themselves automatically, so one of the things we want to monitor is under-replicated partitions.

with adding a Kafka broker to our cluster, the new broker will not be assigned
to any partitions! Any topic partitions that we create before adding a new broker still
persist on the brokers that existed at the time of their creation. The new broker is only used for new topics, unless we change some configurations!

For maintenance or updating we might want to shutdown some brokers one by one(rolling restart).
An important broker configuration property for rolling restarts is controlled.shutdown.enable. Setting this to true enables the transfer of partition leadership before a
broker shuts down.

Clients can usually be upgraded after all of the
Kafka brokers in a cluster are upgraded

we can set configurations at the broker level, which
our clients can override for specific options


---------
Storage
---------

Currently, the default retention limit for data in Kafka topics is seven days, but we can
easily configure this by time or data size.

By setting both log.retention.bytes and log.retention.ms to –1, we can effectively turn off data
deletion.

It's possible to export data to database or cloud storage before data is removed by retention.



---------
General
---------

data retention in kafka is configurable by size and age.


Note that offsets always increase for each partition, even if some messages are removed. Some of you might have run into the issue of numbers that keep increasing
until they hit the upper bound of a data type. Each partition has its own offset
sequence, so the hope is that the risk will be low.

Offset is being stored to present which consumer group, till which message has read in each partition.


if you config 3 partitions for a topic and you have 3 brokers, it means you each broker will be leader for one partition.

if you have replication factor of more that 1 in creating a topic, each partition is only read and written only by the leader broker. non-leaders (followers) only take updates from leaders.


message delivery semantics:
at least once
at most once
exactly once (EOS: exactly once semantics)


kafka also uses a append only log for writing purposes rather than random access to file system.

also it uses a page cache from OC instead of relying to in memory cache which may cause problems because of cycles and pauses of GC (in java).

our preference is to store messages in the original format in a topic. also keep kafka in head of your data pipelines to hold pure and untouched data.

kafka maturity model:
level 0: async communication between applications. decoupling
level 1: no need to most ETL and batch processing as live data flows.
level 2: schema versioning with schema registry
level 3: kafka becomes backbone of enterprise and real-time data is accessible everywhere 

Kafka has something called interceptors that can be used in many ways. By adding an interceptor on both the producer and consumer clients that we are using, we can separate the monitoring logic from the application logic. The crosscutting concern of
monitoring can, hopefully, be more encapsulated by this approach. we can have more than one interceptor. The order in which we list the classes is important as that is the order in which the logic runs.

-----------
Questions
-----------
As figure 5.3 shows, consumers usually read from
the consumer’s partition leader replica. This consumer leader replica could be different from any producer’s leader replica due to changes in leadership over time; however, they are generally similar in concept.
**replica leader is only based on partition, or it's based on consumer and producer?

**can we start consuming from a specific offset?

**what is logrotation in general, not in kafka?

**when we want to create a new topic, where we send our commands? zookeeper or one of brokers?

**When unclean.leader.election.enable is true and replication factor for a topic is 0 (only leader) and leader fails, what happens? (when we have other replicas but they are out of sync, controller selects a new leader for a partition even if its not up to data so the system keeps running.)

**lambda and kappa architectures?

**cqrs with kafka. how netflic use kafka. can we use a cluster for read and one for write?

https://martinfowler.com/bliki/MaturityModel.html

**schema registry and avro


