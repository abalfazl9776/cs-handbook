# Concepts

These contents are from "Object-Oriented Analysis and Design with Applications Third Edition" from the author Grady Booch.

## Elements of Object Model
There are four major elements of this model:
	1. Abstraction
	2. Encapsulation
	3. Modularity
	4. Hierarchy
By major, we mean that a model without any one of these elements is not object-oriented.

There are three minor elements of the object model:
	1. Typing
	2. Concurrency
	3. Persistence
By minor, we mean that each of these elements is a useful, but not essential, part of the object model.

---

### Abstraction

*Abstraction focuses on the essential characteristics of some object, relative to the perspective of the viewer.*

A simplified description, or specification, of a system that emphasizes some of the system’s details or properties while suppressing others. A good abstraction is one that emphasizes details that are significant to the reader or user and suppresses details that are, at least for the moment, immaterial or diversionary.

An abstraction denotes the essential characteristics of an object that distinguish it
from all other kinds of objects and thus provide crisply defined conceptual
boundaries, relative to the perspective of the viewer.

An abstraction focuses on the outside view of an object and so serves to separate
an object’s essential behavior from its implementation

principle of least astonishment, through which
an abstraction captures the entire behavior of some object, no more and no less,
and offers no surprises or side effects that go beyond the scope of the abstraction

Deciding on the right set of abstractions for a given domain is the central problem
in object-oriented design

the
outside view of each object defines a contract on which other objects may depend,
and which in turn must be carried out by the inside view of the object itself (often
in collaboration with other objects). This contract thus establishes all the assumptions a client object may make about the behavior of a server object. In other
words, this contract encompasses the responsibilities of an object, namely, the
behavior for which it is held accountable 

We call the entire set
of operations that a client may perform on an object, together with the legal orderings in which they may be invoked, its protocol. 

An invariant is
some Boolean (true or false) condition whose truth must be preserved


### Encapsulation
From (Vladimir Khorikov's Refactorting from anemic domain model to rich domain model)
Encapsulation is not Information hiding.
Encapsulation is not Boundling of data and operations.
Encapsulation is an act of Protecting data integrity using information hiding and bundling of data and operations. It's Protecting invariants.
Why encapsulaiton matters? It helps control complexity.




