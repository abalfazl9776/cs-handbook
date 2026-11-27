## Explicit Interface Implementation
It means that the class implements a method specifically as a member of an interface which is being implmeneted, rather than exposing it as a normal public method.

For example:
```csharp
public class MyCollection<T> : ICollection<T>
{
    void ICollection<T>.Add(T value)
    {
        // Implementation
    }
}
```

Why use it?
Suppose you have these two methods:
```csharp
public void AddLast(T value)
{
    // Add to the end
}

void ICollection<T>.Add(T value)
{
    AddLast(value);
}
```

Notice that:
- `AddLast()` is publicly accessible.
- `ICollection<T>.Add()` is accessible only through the interface.
Usage:
```csharp
var list = new MyCollection<int>();

list.AddLast(10); // Works

list.Add(10); // Compilation error

ICollection<int> collection = list;
collection.Add(10); // Works
```

### When to use it?
Use it when:
- Interface members shouldn't be part of the class's normal public API.
- Two interfaces have conflicting members. You need different implementations.
- You want to implement an internal or infrastructure-oriented interface without exposing its members publicly.
- You deliberately want different behavior for different interface contracts.

Avoid it when:
- It unnecessarily makes an API harder to discover.
- Consumers frequently need to cast objects just to access essential functionality.
- You're using it to hide a poorly designed interface.

One additional detail: explicit implementations are not virtual and cannot be overridden directly in derived classes. This is worth considering when designing extensible base classes.