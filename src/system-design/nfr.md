## Common Non-Functional Requirements (NFRs) — the “-ilities”

- Performance: latency and throughput.
- Scalability: handling growth in workload.
- Availability: service accessibility.
- Reliability: correct, consistent operation over time.
- Resilience and fault tolerance: handling failures and recovering.
- Robustness: handling unexpected inputs and conditions.
- Security and privacy: protecting systems and data.
- Consistency and durability: data correctness and persistence. 
- Maintainability and modifiability: ease and safety of change.
- Observability and operability: understanding and running the system in production.
- Deployability and testability: releasing changes and verifying behavior.
- Interoperability and portability: integrating with other systems and environments.
- Usability and accessibility: enabling people to use the system effectively.

Interview tip: NFRs should be measurable whenever possible. Instead of saying “the system must be fast,” specify something like **Latency percentiles** “p99 API latency must remain below 200 ms at 2,000 requests per second.” Also distinguish availability (whether the system is usable), reliability (whether it works correctly over time), and resilience (how it handles and recovers from failures).

## How to articulate about NFRs?
### Performance terminology
| Term                      | Meaning                                                                                |
| ------------------------- | -------------------------------------------------------------------------------------- |
| Latency                   | Time taken for an operation or request to complete. (%TODO% Check DDIA book)           |
| Throughput                | Amount of work completed per unit of time, e.g. requests per second (RPS).             |
| Concurrency               | Number of operations being processed or in progress simultaneously.                    |
| Response time             | Time between a request and its response, typically as experienced by the caller.       |
| Tail latency              | Latency in the slow end of the distribution, often discussed using p95, p99, or p99.9. |
| Time to first byte (TTFB) | Time until the first response byte arrives.                                            |
| Saturation                | How close a resource is to its capacity limit.                                         |
| Load (Workload)           | Work being offered to or handled by the system.                                        |
Instead of saying, “The API should be fast,” define measurable targets.
For example:

> “The API should sustain 2,000 requests per second, with p95 latency below 100 ms and p99 latency below 250 ms under the expected production workload.”

A more complete requirement can specify:
- Workload: 2,000 requests per second, with a defined request mix.
- Latency objective: p99 below 250 ms.
- Error rate: below 0.1%.
- Test conditions: representative data, realistic concurrency, and a specified deployment environment.

