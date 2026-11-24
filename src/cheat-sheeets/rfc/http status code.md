----------------
--409 Conflict--
----------------
Indicates that the request could not be processed because of conflict in the current state of the resource, such as an edit conflict between multiple simultaneous updates.[26]

   The 409 (Conflict) status code indicates that the request could not
   be completed due to a conflict with the current state of the target
   resource.  This code is used in situations where the user might be
   able to resolve the conflict and resubmit the request.  The server
   SHOULD generate a payload that includes enough information for a user
   to recognize the source of the conflict.

   Conflicts are most likely to occur in response to a PUT request.  For
   example, if versioning were being used and the representation being
   PUT included changes to a resource that conflict with those made by
   an earlier (third-party) request, the origin server might use a 409
   response to indicate that it can't complete the request.  In this
   case, the response representation would likely contain information
   useful for merging the differences based on the revision history.


----------------------------------------
--428 Precondition Required (RFC 6585)--
----------------------------------------
The origin server requires the request to be conditional. Intended to prevent the 'lost update' problem, where a client GETs a resource's state, modifies it, and PUTs it back to the server, when meanwhile a third party has modified the state on the server, leading to a conflict.[34]

   The 428 status code indicates that the origin server requires the
   request to be conditional.

   Its typical use is to avoid the "lost update" problem, where a client
   GETs a resource's state, modifies it, and PUTs it back to the server,
   when meanwhile a third party has modified the state on the server,
   leading to a conflict.  By requiring requests to be conditional, the
   server can assure that clients are working with the correct copies.

   Responses using this status code SHOULD explain how to resubmit the
   request successfully.  For example:

HTTP/1.1 428 Precondition Required
Content-Type: text/html
   <html>
      <head>
         <title>Precondition Required</title>
      </head>
      <body>
         <h1>Precondition Required</h1>
         <p>This request is required to be conditional;
         try using "If-Match".</p>
      </body>
   </html>

   Responses with the 428 status code MUST NOT be stored by a cache.


------------------------------------
--429 Too Many Requests (RFC 6585)--
------------------------------------
The user has sent too many requests in a given amount of time. Intended for use with rate-limiting schemes.[34]

The 429 status code indicates that the user has sent too many
   requests in a given amount of time ("rate limiting").

   The response representations SHOULD include details explaining the
   condition, and MAY include a Retry-After header indicating how long
   to wait before making a new request.

   For example:

   HTTP/1.1 429 Too Many Requests
   Content-Type: text/html
   Retry-After: 3600

   <html>
      <head>
         <title>Too Many Requests</title>
      </head>
      <body>
         <h1>Too Many Requests</h1>
         <p>I only allow 50 requests per hour to this Web site per
            logged in user.  Try again soon.</p>
      </body>
   </html>

   Note that this specification does not define how the origin server
   identifies the user, nor how it counts requests.  For example, an
   origin server that is limiting request rates can do so based upon
   counts of requests on a per-resource basis, across the entire server,
   or even among a set of servers.  Likewise, it might identify the user
   by its authentication credentials, or a stateful cookie.

   Responses with the 429 status code MUST NOT be stored by a cache.

