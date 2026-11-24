# HttpClient in .NET — Practical Guidelines

A reference for developers choosing how to call external HTTP services. The goal is to understand the available approaches, their trade-offs, and the problems they help prevent.

## 1. Ways to make HTTP calls

There are four common approaches:

| Approach | Description |
|---|---|
| `HttpClient` per request | Create and dispose a new client for every call |
| Long-lived `HttpClient` | Reuse a client for the application's lifetime |
| Named client | Create clients through `IHttpClientFactory` using a name |
| Typed client | A dedicated class wrapping `HttpClient` for a particular API |

Named and typed clients are both provided by `IHttpClientFactory`. They differ mainly in how the application uses and organizes them.

## 2. Problems developers should understand

Before choosing an approach, understand these important behaviors.

### Connection pooling and socket exhaustion

Each `HttpClient` instance normally owns a connection pool through its handler.

Creating and disposing clients repeatedly can create unnecessary TCP connections. When connections close, their ports may remain temporarily unavailable in `TIME_WAIT`.

Under high request rates, this can exhaust available ephemeral ports, causing connection failures.

**The solution:** Reuse connection pools rather than creating a new one for every request.

### DNS changes and stale connections

`HttpClient` resolves DNS when establishing a connection. It does not continuously monitor DNS changes or TTLs.

If a service's IP address changes, existing connections may continue using the old address. This can cause failures during deployments, failovers, or infrastructure changes.

**The solution:** Allow connections to be periodically replaced so new connections can resolve DNS again.

### Shared state and cross-request leakage

An `HttpClient` is designed to be shared. Its default headers apply to all requests using it.

Changing shared headers per request can cause concurrent requests to overwrite one another.

For example, one user's authorization token might accidentally be sent with another user's request.

**The solution:** Keep shared configuration stable and put request-specific values on `HttpRequestMessage`.

### Cookies and session state

Cookies are stored in the handler's `CookieContainer`.

When handlers are shared, cookie state may also be shared. This can cause cookies to leak between users or sessions.

Handler replacement can also discard stored cookies, potentially breaking sessions.

**The solution:** Decide whether cookies are required and whether their state must be isolated.

### Singleton services and client lifetime

Factory-created clients are intended to be short-lived so the factory can provide updated handlers.

If a singleton captures a typed client, that client may remain alive indefinitely and prevent handler rotation from benefiting the application.

**The solution:** Use named clients through `IHttpClientFactory` in long-lived services, or deliberately configure connection lifetime on a long-lived client.

### Handler state and DI scopes

`IHttpClientFactory` creates separate DI scopes for message handlers. These are not the same as ASP.NET request scopes and may outlive individual requests.

Caching `HttpContext`, user identity, or tenant information inside a handler can cause information to be reused across requests.

**The solution:** Keep handlers stateless and pass request-specific data through the HTTP request.

## 3. Compare the approaches

### A. Long-lived HttpClient

```csharp
var handler = new SocketsHttpHandler
{
    PooledConnectionLifetime = TimeSpan.FromMinutes(5)
};

var client = new HttpClient(handler);
```

**Advantages**
- Simple and efficient.
- Reuses connections.
- Avoids repeated client and handler creation.
- Supports connection rotation for DNS changes.

**Disadvantages**
- Configuration and lifecycle management are manual.
- Multiple APIs may require multiple clients.
- Requires deliberate management of cookies and handler settings.

**Use when:** You need a simple, long-lived client with stable configuration, such as a background worker or small application.

### B. Named clients with IHttpClientFactory

```csharp
services.AddHttpClient("Payments", client =>
{
    client.BaseAddress = new Uri("https://payments.example/");
});
```

```csharp
using var client = factory.CreateClient("Payments");
```

**Advantages**
- Centralized configuration.
- Supports multiple independently configured clients.
- Handler pooling prevents unnecessary connection pools.
- Handler rotation helps address DNS changes.
- Integrates with DI, logging, and outgoing middleware.

**Disadvantages**
- Requires factory registration and configuration.
- Handler lifetime and cookie behavior need consideration.
- A client retained indefinitely may not benefit from handler rotation.

**Use when:** You need multiple external services, centralized configuration, or flexible client creation—especially in applications using DI.

### C. Typed clients

```csharp
services.AddHttpClient<PaymentsClient>();
```

```csharp
public class PaymentsClient(HttpClient client)
{
    public Task<Order?> GetOrderAsync(int id, CancellationToken ct) =>
        client.GetFromJsonAsync<Order>($"orders/{id}", ct);
}
```

**Advantages**
- Encapsulates API-specific operations.
- Makes application code cleaner and easier to test.
- Keeps HTTP details out of business services.
- Uses factory-managed handlers.

**Disadvantages**
- Requires a dedicated class per API.
- Must be used with the intended lifetime.
- Capturing it in a singleton can defeat handler rotation.

**Use when:** You have a well-defined external API and want a clean, maintainable application boundary.

### D. Dedicated client and handler

```csharp
var handler = new HttpClientHandler
{
    CookieContainer = new CookieContainer()
};

var client = new HttpClient(handler);
```

**Advantages**
- Explicit control over cookies and handler configuration.
- Suitable for isolated sessions.

**Disadvantages**
- You manage its lifecycle.
- Poor lifecycle management can cause connection problems.
- Requires careful isolation when multiple users are involved.

**Use when:** You need persistent, isolated cookie sessions or specialized handler behavior.

## 4. Additional guidelines

### Headers

Use `DefaultRequestHeaders` for values that are genuinely shared.

```csharp
client.DefaultRequestHeaders.Accept
    .Add(new MediaTypeWithQualityHeaderValue("application/json"));
```

Use request-specific headers for tokens, tenant IDs, and correlation IDs:

```csharp
using var request = new HttpRequestMessage(HttpMethod.Get, "orders");

request.Headers.Authorization =
    new AuthenticationHeaderValue("Bearer", token);

await client.SendAsync(request, ct);
```

Never mutate shared default headers per request.

### Cookies

If cookies are unnecessary, consider disabling automatic cookie handling:

```csharp
new HttpClientHandler { UseCookies = false };
```

If cookies are required, carefully manage their isolation and lifetime. Avoid sharing a cookie container between unrelated users.

Microsoft recommends avoiding `IHttpClientFactory` for applications requiring cookies unless cookie sharing and handler lifetime are deliberately managed.

### DelegatingHandler

Use handlers for cross-cutting concerns such as logging, tracing, authentication, and resilience.

```csharp
services.AddTransient<LoggingHandler>();

services.AddHttpClient<PaymentsClient>()
    .AddHttpMessageHandler<LoggingHandler>();
```

Keep handlers stateless. Avoid storing request-specific data in handler fields, and never log sensitive tokens or cookies.

### Other important considerations

- Always propagate `CancellationToken` where applicable.
- Configure appropriate timeouts.
- Dispose manually handled `HttpResponseMessage` instances.
- Retry only when appropriate; retrying non-idempotent operations can duplicate side effects.
- Consider connection limits and downstream capacity under high concurrency.
- Don't assume `IHttpClientFactory` automatically solves every networking problem.

## 5. Decision guide

| Question | Recommendation |
|---|---|
| Is this a simple client with stable configuration? | Long-lived `HttpClient` + `PooledConnectionLifetime` |
| Do I need multiple configured clients? | Named clients + `IHttpClientFactory` |
| Am I integrating a well-defined external API? | Typed client |
| Does a singleton need to make HTTP calls? | Inject factory and create named clients as needed |
| Do I need isolated, persistent cookie sessions? | Dedicated client/handler with isolated cookie state |
| Do I need logging, authentication, or tracing middleware? | `DelegatingHandler` |
| Does DNS change need to be picked up? | Configure connection or handler rotation |

**Default recommendation for most DI-based .NET applications:** Use `IHttpClientFactory` with typed clients for API integrations, and named clients for flexible client creation in long-lived services.

Further reading
- [HttpClient guidelines — Microsoft](https://learn.microsoft.com/en-us/dotnet/fundamentals/networking/http/httpclient-guidelines)
- [IHttpClientFactory — Microsoft](https://learn.microsoft.com/en-us/dotnet/core/extensions/httpclient-factory)
- [IHttpClientFactory troubleshooting](https://learn.microsoft.com/en-us/dotnet/core/extensions/httpclient-factory-troubleshooting)

The document is intended to give a developer enough context to make a sound initial choice, while the Microsoft references provide the deeper configuration details when needed.