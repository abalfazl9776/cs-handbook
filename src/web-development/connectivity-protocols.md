## Protocols
### Http v1, v1.1, v2.0, v3.0
#### Version Differences
#### Verbs
#### Status Codes
%TODO%

### gRPC
isn't supported by browsers, suitable for internal communications
### Rest - Representational state transfer 
### WebSocket
has challenges in handling connection, reestablishing connection in case of failures or transferring connection to other nodes in deployments or scale outs.
WebSockets are initiated via an HTTP "upgrade" protocol, which allows an existing TCP connection to change L7 protocols. This is super convenient because it means you can utilize some of the existing HTTP session information (e.g. cookies, headers, etc.) to your advantage.

⚠️ Just because clients can upgrade from HTTP to WebSocket doesn't mean that the infrastructure will support it. Every piece of infrastructure between the client and server will need to support WebSocket connections (%TODO% support how?).
If you've ever implemented Websockets you've probably hit a bunch of issues with firewalls, proxies, load balancers, and other infrastructure that don't support WebSocket connections.

In system design interviews, launching into a WebSocket implementation without justifying why they are needed is a great way to get a "thumbs down" from your interviewer. WebSockets are powerful, but the infra required to support them can be expensive and the overhead of stateful connections (especially at scale) will require significant accommodations in your design. Hold off unless you really need them! Prefer polling or SSE where possible.
### SSE (server sent event)
%TODO% search for caveats of SSE. for example: In practice there are also some nasty, misbehaving networks that will batch up all SSE responses into a single response [making it behave a lot like what we're trying to avoid](https://dev.to/miketalbot/server-sent-events-are-still-not-production-ready-after-a-decade-a-lesson-for-me-a-warning-for-you-2gie).

SSE and WebSockets Both are stateful connections, which means you can't just throw them behind a standard load balancer. You'll need to think about connection persistence and what happens when a server goes down with thousands of active connections. Check [Load Balancers](../system-design/system-design-concepts.md#Concepts#Notes#Load%20Balancing) in System Design Concepts.

### SOAP
### WCF
### graphQL
### TCP - Transmission Control Protocol
- **Connection-oriented**: Establishes a dedicated connection before data transfer (stateful)
- **Reliable delivery**: Guarantees that data arrives in order and without errors
- **Flow control**: Prevents overwhelming receivers with too much data
- **Congestion control**: Adapts to network congestion to prevent collapse
### QUIC
### UDP - User Datagram Protocol
- **Connectionless**: No handshake or connection setup (stateless)
- **No guarantee of delivery**: Packets may be lost without notification
- **No ordering**: Packets may arrive in a different order than sent
- **Lower latency**: Less overhead means faster transmission
%TODO% how do VPNs work on UDP?
### WebRTC

### WebTransport

---
## Notes

### When to choose UDP?
- Low latency is critical (real-time applications, gaming)
- Some data loss is acceptable (media streaming)
- You're handling high-volume telemetry or logs where occasional loss is acceptable
- You don't need to support web browsers (or you have an alternative for that client)

### Long Polling vs WebSockets vs SSE
A common mistake is proposing WebSockets when HTTP with long polling or Server-Sent Events would work fine. WebSockets add significant complexity for maintaining stateful connections at scale. Only reach for them when you need bidirectional real-time communication, not just because "real-time" is mentioned in the problem.

### Long polling vs Polling (or short polling)
Long polling leaves the connection open until new data arrives or a timeout occurs. But in polling, client sends a requests and server responds instantly and sends back current state.

---
## TODO
Specify differences between protocols, standards and concepts. Then move each phrase to it's category.
%TODO%