asvs owasp

External sorting algorithms (and with limited memory, sorting large amount of data)

Processing large file with limited memory. Like finding duplicates in 20gb csv

Redis is single threaded, how it can handle millions requests per second 

How to handle concurrency issues, like preventing stock gets negative (dealing with contention - )

how to know and profile  hot paths before caching them. because its not wise to cache everything and overload redis

what are Hash indexes or hash table https://en.wikipedia.org/wiki/Hash_table

what are geospatial indexes for location queries

What’s topological sort?

What is cross join and what are the syntaxes of it?

authentication methods for service to service call

Bulkheads

CRDTs • Conflict-free Replicated Data Types

grpc supports streaming. such a wow. how? what kind of streaming?

how to download and upload file in a efficient way

pkce

Multi stage build docker

Kyc know your customer

dora - throughout metrics, stability metrics

What is a bloom filter

conformist client and other types. Documnet

how do server sent events work

what is data integrity and how it relates to Acid?

how long polling leaves the connection open and waits for response

does having ssl necessarily mean that no eavesdropping will happen? are we safe from man in middle attacks? what about using a computer in a network of a company or public wifi?

how to use cdns to cache users profile pictures (dynamic content, api responses) or static assets

rpo and rto

When serializable leads to deadlock or blocking - document it...
isolation levels is about how to take shared lock and when to release it
- read uncommited - no shared lock
- read commited - try to get shared lock, if successful, means no one is updating data, read it, release lock immediately
- repeatable read - get shared lock, hold it till end of transaction
- serializable - get range shared lock - hold it till end of transactin
serializable and repeatable read might end to dead lock because the hold a shared lock preventing other transactions to get an xlock. to prevent deadlock when transaction wnats to esclate shared lock to xlock and or getting xlocks, we can use select for update at the begining of a trasnaction with these isolation levels to hold upd lock instead of shared lock so no one else can get another update lock and prevent serializable in cost of blocking.

how to optimize for high write concurrent throughput.


## Book

Http O'Reilly 

High performance browser networking 

A book maybe from oreily or mannings about latency

