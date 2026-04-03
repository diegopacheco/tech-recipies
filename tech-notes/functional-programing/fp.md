# What is functional Programing 

It's a paradigm, where functions are first class citzen:
* Favor discipline with state(more than just immutability)
* Backed by math and "know theories" (not my uncles abstractions)
* Focus on have correct programs (repitable == pure functions) (something LLMs cannot do).

## PROS
* Correctness
* Sound concepts via Math
* Better support for Parallelism (share nothing, immutability)
* Better for LLMs (less ambiguity)
* Shift left(besides clojure) and feedback faster with the compiler.

## CONS
* Complexity: Type Abuse
* Complexity: Effect/Reactive binary coupling and complexity 

## OOP vs FP

Common:
* Scale to large problems, lots of developers
* OOP(Consider DDD) and FP(type systems) way to isoalte and contain problems. 

OOP
* You will need to create your on "ontology" (you create a class - you can't do anything yet)
* Usually can lead to "poor" abstractions because often people "suck at design".
* Classes hide state via encapsulation
* Less feedback on the compiler, more into the runtime(i.e Reflections) requires way more testing.

FP
* You rely on Math, category theory, lambda calculus, arrows, morphisms, etc...
* People tend todo a much better work with "functions" because focus on computations and data transformations and commons "data structures" rather than creating objects.
* Immutability is slower