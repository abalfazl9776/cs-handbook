

--Queues--
queue declaration may cause channel level exception with mismatch props


--Channels--
multithread access to channel to write and generate frame may cause broken frames (mereged messages or ...) and lead to channel level exceptions


--Publishing--
publishing a message to a durable exchange or queue(s) doesn't make a message persistent: it all depends on persistence mode of the message itself
Marking messages as persistent doesn't fully guarantee that a message won't be lost. saved it yet. it'll be cached first. for stronger guarantee use publisher confirms.


--Consumers--
in Consuming, Automatic acknowledgement mode can also overwhelm consumers which cannot process messages as quickly as they are delivered. This can result in permanently growing memory usage and/or OS swapping for the consumer process. in manual acknowledgement mode we can use qos with prefetch size


--Connections--
High number of unacknowledged messages will lead to higher memory usage by the broker.
connections are meant to be long-lived
A system is said to have high connection churn when its rate of newly opened connections is consistently high and its rate of closed connection is consistently high. This usually means that an application uses short lived connections. While with some workloads this scenario is difficult to avoid, long lived connections should be used instead when possible.
While connection and disconnection rates are system-specific, rates consistently above 100/second likely indicate a suboptimal connection management approach by one or more applications and usually are worth investigating.
Some clients and runtimes (notably PHP) do not use long-lived connections and high connection churn rates are expected from them. A specialized proxy should be used with those clients to mitigate the churn they naturally create.
When a connection is no longer necessary, applications must close them to conserve resources. Apps that fail to do it run the risk of eventually exhausting its target node of resources.
Operating systems have a limit around how many TCP connections (sockets) a single process can have open simultaneously. The limit is often sufficient for development and some QA environments. Production environments must be configured to use a higher limit in order to support a larger number of concurrent client connections.
Ports also vary for plain TCP and TLS-enabled connections. 




queue declaration may cause channel level exception with mismatch props
multithread access to channel to write and generate frame may cause broken frames (mereged messages or ...) and lead to channel level exceptions
publishing a message to a durable exchange or queue(s) doesn't make a message persistent: it all depends on persistence mode of the message itself
Marking messages as persistent doesn't fully guarantee that a message won't be lost. saved it yet. it'll be cached first. for stronger guarantee use publisher confirms.
7:00 PM
Connections that publish messages can outpace other parts of the system, most likely busy queues and queues that perform replication. When that happens, flow control is applied to publishing connections
It is therefore recommended that, when possible, publishers and consumers use separate connections so that consumers are isolated from potential flow control that may be applied to publishing connections, affecting manual consumer acknowledgements.
7:18 PM
For applications that use multiple threads/processes for processing, it is very common to open a new channel per thread/process and not share channels between them.
Much like connections, channels are meant to be long lived. That is, there is no need to open a channel per operation and doing so would be very inefficient, since opening a channel is a network roundtrip.
If a channel is closed immediately after a consumer acknowledged a number of deliveries on it, the acknowledgements may or may not reach their target queue before the channel is terminated. In this case the messages with a pending acknowledgement on the channel will be automatically requeued following the channel closure.

This scenario usually applies to workloads with short lived channels. Using long lived channels and designing consumers in a way that they can handle redeliveries potential surprises may be associated with this edge case behavior. Note that redelivered messages will be explicitly marked as such.

10:12 AM

Channels | RabbitMQ
https://www.rabbitmq.com
10:22 AM
Limiting the number of channels used per connection is highly recommended. As a guideline, most applications can use a single digit number of channels per connection. Those with particularly high concurrency rates (usually such applications are consumers) can start with one channel per thread/process/coroutine and switch to channel pooling when metrics suggest that the original model is no longer sustainable, e.g. because it consumes too much memory.
Should the configured limit be exceeded, the connection will be closed with a fatal error
10:44 AM
A connection leak is a condition under which an application repeatedly opens connections without closing them, or at least closing only some of them.

Connection leaks eventually exhaust the node (or multiple target nodes) of file handles, which means any new inbound client, peer or CLI tool connection will be rejected. A build-up in the number of concurrent connections also increases node's memory consumption.
A channel leak is a condition under which an application repeatedly opens channels without closing them, or at least closing only some of them.

Channel leaks eventually exhaust the node (or multiple target nodes) of RAM and CPU resources.
10:56 AM
Channels that publish messages can outpace other parts of the system, most likely busy queues and queues that perform replication. When that happens, flow control is applied to publishing channels and, in turn, connections. Channels and connections that only consume messages are not affected. With slower consumers that use automatic acknowledgement mode it is very likely that connections and channels will experience flow  control when writing to the TCP socket.Monitoring systems can collect metrics on the number of connections in flow state. Applications that experience flow control regularly may consider to use separate connections to publish and consume to avoid flow control effects on non-publishing operations (e.g. queue management).
9:38 PM
If a message is delivered to a consumer and then requeued, either automatically by RabbitMQ or by the same or different consumer, RabbitMQ will set the redelivered flag on it when it is delivered again. This is a hint that a consumer may have seen this message before. This is not guaranteed as the original delivery might have not made it to any consumers due to a network or consumer application failure.
If the redelivered flag is not set then it is guaranteed that the message has not been seen before. Therefore if a consumer finds it more expensive to deduplicate messages or process them in an idempotent manner, it can do this only for messages with the redelivered flag set.
12:17 PM
When consumer priorities are in use, you can expect your highest priority consumers to receive all the messages until they become blocked, at which point lower priority consumers will start to receive some. It's important to understand that RabbitMQ will still prioritise delivering messages - it will not wait for a high priority blocked consumer to become unblocked if there is an active lower priority consumer ready.
8:08 PM
Depending on the acknowledgement mode used, RabbitMQ can consider a message to be successfully delivered either immediately after it is sent out (written to a TCP socket) or when an explicit ("manual") client acknowledgement is received.
In automatic acknowledgement mode, a message is considered to be successfully delivered immediately after it is sent. This mode trades off higher throughput (as long as the consumers can keep up) for reduced safety of delivery and consumer processing. This mode is often referred to as "fire-and-forget". Unlike with manual acknowledgement model, if consumers's TCP connection or channel is closed before successful delivery, the message sent by the server will be lost. Therefore, automatic message acknowledgement should be considered unsafe and not suitable for all workloads.
Another thing that's important to consider when using automatic acknowledgement mode is consumer overload. Manual acknowledgement mode is typically used with a bounded channel prefetch which limits the number of outstanding ("in progress") deliveries on a channel. With automatic acknowledgements, however, there is no such limit by definition. Consumers therefore can be overwhelmed by the rate of deliveries, potentially accumulating a backlog in memory and running out of heap or getting their process terminated by the OS. Some client libraries will apply TCP back pressure (stop reading from the socket until the backlog of unprocessed deliveries drops beyond a certain limit). Automatic acknowledgement mode is therefore only recommended for consumers that can process deliveries efficiently and at a steady rate.
8:15 PM
Requeued messages may be immediately ready for redelivery depending on their position in the queue and the prefetch value used by the channels with active consumers. This means that if all consumers requeue because they cannot process a delivery due to a transient condition, they will create a requeue/redelivery loop. Such loops can be costly in terms of network bandwidth and CPU resources. Consumer implementations can track the number of redeliveries and reject messages for good (discard them) or schedule requeueing after a delay.
8:33 PM
Automatic acknowledgement mode or manual acknowledgement mode with unlimited prefetch should be used with care. Consumers that consume a lot of messages without acknowledging will lead to memory consumption growth on the node they are connected to. Finding a suitable prefetch value is a matter of trial and error and will vary from workload to workload. Values in the 100 through 300 range usually offer optimal throughput and do not run significant risk of overwhelming consumers. Higher values often run into the law of diminishing returns.
8:39 PM
You can see that the utilisation increases with the prefetch limit until we reach a limit of about 30. After that the network bandwidth limitation starts to dominate and increasing the limit has no further benefit. So you can see that consumer utilisation is an easy way to monitor the performance of our consumers.
9:07 PM
If a message is published with the "mandatory" flag set, but cannot be delivered, the broker will return it to the sending client (via a basic.return AMQP 0-9-1 command).

To be notified of such returns, clients can subscribe to the IChannel.BasicReturn event. If there are no listeners attached to the event, then returned messages will be silently dropped.