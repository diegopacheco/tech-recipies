# Idiomatic Scala 3

Idiomatic Scala 3 favors immutable data, expressions, explicit domain models, and compiler-checked composition. The following ten idioms use only the standard library and focus on code that is easy to read, test, and change.

## 1. Default to `val` and immutable collection transformations

```scala
case class Order(amount: BigDecimal, paid: Boolean)

def paidRevenue(orders: Vector[Order]): BigDecimal =
  orders
    .filter(_.paid)
    .map(_.amount)
    .sum
```

Why: `val` and immutable collections make state changes explicit. Transformations such as `filter`, `map`, and `sum` describe the result instead of the mechanics of updating a collection. Scala's immutable collections return new values rather than changing their inputs. [1]

Pros:

- Reduces hidden state changes and makes local reasoning easier.
- Composes small operations without manual loops.
- Is naturally safer when values cross thread boundaries.

Cons:

- Transformation chains can allocate intermediate collections.
- A carefully scoped mutable collection may be faster in a measured hot path.

## 2. Model immutable records with case classes

```scala
case class Customer(name: String, email: String, active: Boolean)

val customer = Customer("Ada", "ada@acme.test", active = true)
val deactivated = customer.copy(active = false)
```

Why: case class parameters are public immutable fields by default. The compiler also supplies structural equality, `hashCode`, `toString`, pattern-matching support, and `copy`, so domain records need little boilerplate. [2]

Pros:

- Gives immutable update syntax through `copy`.
- Provides useful value semantics automatically.
- Works directly with pattern matching.

Cons:

- Public construction can bypass invariants unless the constructor is restricted.
- Large case classes and long `copy` calls often signal an oversized model.

## 3. Represent closed alternatives with enums and exhaustive matches

```scala
enum PaymentStatus:
  case Pending
  case Settled(receipt: String)
  case Rejected(reason: String)

def message(status: PaymentStatus): String =
  status match
    case PaymentStatus.Pending => "Payment is pending"
    case PaymentStatus.Settled(receipt) => s"Receipt: $receipt"
    case PaymentStatus.Rejected(reason) => s"Rejected: $reason"
```

Why: an enum can model both singleton cases and cases carrying data. Because the alternatives form a closed sum type, the compiler can check whether a `match` handles every case. [3]

Pros:

- Makes invalid states harder to represent.
- Keeps the full set of alternatives discoverable in one declaration.
- Turns a newly added case into useful compiler warnings at handling sites.

Cons:

- A closed enum is unsuitable when third parties must add variants.
- Very large matches can concentrate too much behavior in one place.

## 4. Return `Either` for expected failures and compose with `for`

```scala
def parsePort(value: String): Either[String, Int] =
  value.toIntOption
    .toRight(s"Not an integer: $value")
    .flatMap(port => Either.cond(port >= 1 && port <= 65535, port, s"Invalid port: $port"))

def endpoint(host: String, port: String): Either[String, String] =
  for
    validHost <- Either.cond(host.nonEmpty, host, "Host is empty")
    validPort <- parsePort(port)
  yield s"$validHost:$validPort"
```

Why: expected failure is part of the return type rather than a hidden exception path. `Either` is right-biased, so `map`, `flatMap`, and `for` compose successful values while preserving the first `Left`. [4][5]

Pros:

- Makes callers acknowledge failure.
- Preserves an informative error value.
- Supports concise sequential validation and computation.

Cons:

- Standard `Either` stops at the first failure rather than accumulating all failures.
- It is noisy for failures that are truly unrecoverable or cannot be handled locally.

## 5. Add focused behavior with extension methods

```scala
case class Celsius(value: Double)

extension (temperature: Celsius)
  def fahrenheit: Double = temperature.value * 9.0 / 5.0 + 32.0
  def isFreezing: Boolean = temperature.value <= 0.0

val outside = Celsius(-4.0)
val alert = outside.isFreezing
```

Why: extension methods attach domain vocabulary to an existing type without inheritance, wrappers, or Scala 2 implicit-class encoding. They are especially useful when the original type is closed or owned elsewhere. [6]

Pros:

- Produces readable call-site syntax.
- Keeps optional behavior separate from core data.
- Avoids inheritance solely to gain utility methods.

Cons:

- Broad imports can make the origin of a method less obvious.
- Multiple extensions with the same name can create resolution conflicts.

## 6. Use opaque types for zero-overhead domain distinctions

```scala
object UserId:
  opaque type UserId = Long

  def from(value: Long): Either[String, UserId] =
    Either.cond(value > 0, value, "User id must be positive")

  extension (id: UserId)
    def value: Long = id

import UserId.*

val id = UserId.from(42)
```

Why: outside `UserId`, the compiler treats `UserId` as distinct from `Long`; inside, its representation is available for implementation. This prevents accidental mixing of unrelated numeric identifiers without introducing wrapper allocation. [7]

Pros:

- Enforces domain distinctions at compile time.
- Hides representation details behind a small API.
- Avoids boxing overhead for the underlying primitive representation.

Cons:

- Requires explicit construction and extraction boundaries.
- Serialization and Java interoperation may need adapters.

## 7. Express capabilities with type classes, `given`, and `using`

```scala
trait Render[A]:
  def apply(value: A): String

case class Money(amount: BigDecimal, currency: String)

object Render:
  given Render[Money] with
    def apply(value: Money): String = s"${value.currency} ${value.amount}"

  extension [A](value: A)
    def render(using renderer: Render[A]): String = renderer(value)

import Render.*

val label = Money(BigDecimal("19.95"), "USD").render
```

Why: a type class adds behavior to types without requiring them to share a superclass or be editable. `given` declares the canonical capability, while `using` requests it from the calling context. [8][9]

Pros:

- Separates data from independently selectable behavior.
- Supports types owned by the standard library or another project.
- Keeps dependencies visible in types while avoiding repetitive argument passing.

Cons:

- Competing instances can cause ambiguity or surprising selection.
- Excessive contextual resolution makes control flow harder to follow.

## 8. Use union types for small, local alternatives

```scala
case class UserName(value: String)
case class Email(value: String)

def lookupKey(identity: UserName | Email): String =
  identity match
    case UserName(value) => value.toLowerCase
    case Email(value) => value.trim.toLowerCase
```

Why: `A | B` accepts either type without forcing unrelated classes into a shared hierarchy or wrapper. It is a good fit for narrow input boundaries where the alternatives already have clear meanings. [10]

Pros:

- Adds a precise constraint without modifying either type.
- Avoids marker traits and explicit wrapping.
- Supports exhaustivity checking over the declared alternatives.

Cons:

- The compiler generally needs an explicit union annotation.
- Common operations are limited to members available on the union's shared supertype.
- A named enum is clearer when the alternatives form a lasting domain concept.

## 9. Build small facades with `export`

```scala
final class Counter:
  private var current = 0
  def increment(): Unit = current += 1
  def value: Int = current

final class RequestMetrics:
  private val requests = Counter()
  export requests.{increment as recordRequest, value as requestCount}

val metrics = RequestMetrics()
metrics.recordRequest()
val count = metrics.requestCount
```

Why: `export` creates aliases for selected members of a stable value. It supports composition and facade APIs without hand-written forwarding methods or inheritance. [11]

Pros:

- Removes repetitive delegation code.
- Exposes only the selected surface of an internal component.
- Allows renaming at the public boundary.

Cons:

- Wildcard exports can unintentionally widen an API.
- Heavy delegation can obscure which component owns the behavior.

## 10. Derive `CanEqual` for type-safe equality

```scala
import scala.language.strictEquality

case class Coordinate(x: Int, y: Int) derives CanEqual

def samePosition(left: Coordinate, right: Coordinate): Boolean =
  left == right
```

Why: strict equality requires `CanEqual[A, B]` evidence before values of `A` and `B` can be compared with `==` or `!=`. Deriving `CanEqual` places the required evidence in the companion and prevents unrelated domain types from being compared accidentally. [12]

Pros:

- Catches nonsensical comparisons during compilation.
- Requires no runtime equality wrapper or custom operator.
- Keeps equality support visible on the type declaration.

Cons:

- Full enforcement requires opting into `strictEquality`.
- Intentional comparisons between different types need explicit `CanEqual` evidence.
- Runtime behavior still delegates to ordinary `equals` semantics.

## Practical selection guide

Start with immutable values, immutable collections, case classes, enums, and explicit error values. Add extension methods when they sharpen the call-site vocabulary. Reach for opaque types when primitive values have distinct domain meanings, and for type classes when behavior must vary independently of the data. Use union types for narrow local boundaries, `export` for deliberate facades, and derived `CanEqual` when stronger equality checks justify the opt-in.

## Sources

1. [Scala 3 Book: Immutable Values](https://docs.scala-lang.org/scala3/book/fp-immutable-values.html) — “All variables are created as `val` fields.”
2. [Scala 3 Book: Domain Modeling Tools](https://docs.scala-lang.org/scala3/book/domain-modeling-tools.html) — “Case classes are used to model immutable data structures.”
3. [Scala 3 Book: Domain Modeling](https://docs.scala-lang.org/scala3/book/taste-modeling.html) — “Scala 3 offers the `enum` construct for defining enumerations.”
4. [Scala 3 Book: Functional Error Handling](https://docs.scala-lang.org/scala3/book/fp-functional-error-handling.html) — “Functional methods don’t throw exceptions; instead they return values like `Option`, `Try`, or `Either`.”
5. [Scala API: Either](https://www.scala-lang.org/api/current/scala/util/Either.html) — “Either is right-biased.”
6. [Scala 3 Book: Extension Methods](https://docs.scala-lang.org/scala3/book/ca-extension-methods.html) — “Extension methods let you add methods to a type after the type is defined.”
7. [Scala 3 Book: Opaque Types](https://docs.scala-lang.org/scala3/book/types-opaque-types.html) — “Opaque type aliases provide type abstraction without any overhead.”
8. [Scala 3 Book: Type Classes](https://docs.scala-lang.org/scala3/book/ca-type-classes.html) — “Type classes are traits with one or more parameters.”
9. [Scala 3 Book: Contextual Abstractions](https://docs.scala-lang.org/scala3/book/ca-contextual-abstractions-intro.html) — “Given instances allow programmers to define the canonical value of a certain type.”
10. [Scala 3 Book: Union Types](https://docs.scala-lang.org/scala3/book/types-union.html) — “The type `A | B` represents values that are either of the type `A` or `B`.”
11. [Scala 3 Reference: Export Clauses](https://docs.scala-lang.org/scala3/reference/other-new-features/export.html) — “An export clause defines aliases for selected members of an object.”
12. [Scala 3 Reference: Multiversal Equality](https://docs.scala-lang.org/scala3/reference/contextual/multiversal-equality.html) — “Multiversal equality is an opt-in way to make universal equality safer.”
