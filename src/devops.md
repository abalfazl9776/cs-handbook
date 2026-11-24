## Deployment Strategies:
**Rolling Deployment:** Gradually replaces old instances with new ones while maintaining service availability.
**Blue-Green Deployment:** Runs two separate environments and switches traffic from the old version to the new one.
**Canary Deployment:** Releases the new version to a small subset of users before expanding to everyone.
**A/B Testing:** Routes different user groups to different versions to compare their behavior and outcomes.
**Shadow Deployment:** Sends copies of production traffic to the new version without using its responses for users.
**Feature Flags:** Deploys code with features disabled and enables them selectively without redeploying.

## Service Discovery
Client side and server side (take a look at Consul Docs from Hashicorp)

## Observability
### 7 level of observability (according to an Instagram page)
1. Logs - what happened?
2. Metrics - how much? how fast?
3. Traces - where the time go? how much did each step take to complete?
4. Correlation - why did it happen? what is the source? what happened in each component?
5. Alerts - know before users do.
6. SLOs - what good means. (SLO: target, SLI: current measured status, SLA: promised to client)
7. Cardinality - what it costs? detailed information is for traces and logs, keep metric labels few.
%TODO - check the validity - search more% 

## Jargons
Incident
Blast Radius
%TODO%

