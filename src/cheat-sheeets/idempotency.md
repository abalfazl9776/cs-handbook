https://www.theserverside.com/tip/Idempotent-HTTP-methods-and-REST
https://medium.com/@pankaj_rawal/why-patch-is-considered-non-idempotent-1dfd4ca9a2
https://stackoverflow.com/questions/41390997/why-patch-is-neither-safe-nor-idempotent/51441458#51441458 

HTTP method	Safe	Idempotent
GET			Yes		Yes
QUERY		Yes		Yes
POST		No		No
PUT			No		Yes
PATCH		No		No
DELETE		No		Yes
TRACE		Yes		Yes
HEAD		Yes		Yes
OPTIONS		Yes		Yes
CONNECT		No		No
PRI			Yes		Yes



RFC specifications snippet for PATCH request

“The difference between the PUT and PATCH requests is reflected in the way the server processes the enclosed entity to modify the resource identified by the Request-URI. In a PUT request, the enclosed entity is considered to be a modified version of the resource stored on the origin server, and the client is requesting that the stored version be replaced. With PATCH, however, the enclosed entity contains a set of instructions describing how a resource currently residing on the origin server should be modified to produce a new version.”


JSON Patch format
[
  { "op": "add", "path": "/Amount", "value": -1000 },
]












stackoverflow:
Q
---
I have trouble understanding why PATCH is not safe where PUT is. Aso the idempotent part - if I update a field of the resource, wouldn't that field return the same value after update?
A
---
It's not safe because in general you can't safely execute a PATCH request without changing a resource (That's what it's for).

So why is PATCH not idempotent compared to PUT? It's because it matters how you apply your changes. If you'd like to change the name property of a resource, you might send something like {"name": "foo"} as a payload and that would indeed be idempotent since executing this request any number of times would yield the same result: The resources name attribute is now "foo".

But PATCH is much more general in how you can change a resource (check this definition on how to apply a JSON patch). It could also, for example, mean to move the resource and would look something like this: { "op": "move", "from": "/a/b/c", "path": "/a/b/d" }. This operation is obviously not idempotent since calling at a second time would result in an error.

So while most PATCH operations might be idempotent, there are some that aren't.

One remark on the other answers: Idempotence is defined by repeating an operation multiple times in a row. Saying that something is not idempotent because the effect is different if some other operation was executed in between or in parallel just isn't a valid argument (no operation would be idempotent in general if that was the case). Mathematically, an idempotent transformation is one that yields the same result, no matter how often you apply it (like rotating something 360 degrees). Of course two 360 deg rotation might yield different results if you apply any other operation in between.
