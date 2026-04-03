# Algebraic Data Types

## What is it?

Algebraic Data Types (ADTs) are composite types formed by combining other types using two fundamental operations: **product** (AND — a value contains field A AND field B) and **sum** (OR — a value is variant A OR variant B). The name "algebraic" comes from the correspondence with algebra: product types multiply the possible values, sum types add them. ADTs combined with pattern matching provide a type-safe, exhaustive way to model domain data — the compiler guarantees you handle every possible case, and impossible states become unrepresentable.

## How it works?

### Product Types (AND)

```
A product type contains ALL of its fields simultaneously.

  struct Point {        // Point = Float × Float
      x: Float,         // always has x AND y
      y: Float,
  }

  Number of possible values = |A| × |B|

  Bool × Bool = 2 × 2 = 4 possible values:
    (true, true), (true, false), (false, true), (false, false)

  Familiar product types:
    - Structs     (C, Rust, Go)
    - Classes     (Java, C++, Python)
    - Records     (Haskell, F#, Kotlin)
    - Tuples      (Python, Scala, Haskell)
    - Named tuples (TypeScript interfaces)

  Haskell:   data Point = Point Float Float
  Rust:      struct Point { x: f64, y: f64 }
  Scala:     case class Point(x: Double, y: Double)
  TypeScript: type Point = { x: number; y: number }
```

### Sum Types (OR)

```
A sum type is ONE of several variants at any given time.

  enum Shape {           // Shape = Circle | Rectangle | Triangle
      Circle(f64),       // radius
      Rectangle(f64, f64), // width, height
      Triangle(f64, f64, f64), // sides
  }

  Number of possible values = |A| + |B| + |C|

  Bool + Unit = 2 + 1 = 3 possible values:
    Left(true), Left(false), Right(())
    This is equivalent to: Maybe Bool = Just True | Just False | Nothing

  Familiar sum types:
    - Enums with data       (Rust, Swift, Kotlin sealed class)
    - Algebraic data types  (Haskell, OCaml, F#)
    - Union types           (TypeScript discriminated unions)
    - Sealed interfaces     (Java 17+, Kotlin)
    - Variants              (C++ std::variant)

  Haskell:    data Shape = Circle Double
                          | Rectangle Double Double
                          | Triangle Double Double Double
  Rust:       enum Shape { Circle(f64), Rectangle(f64, f64) }
  Scala:      sealed trait Shape
              case class Circle(r: Double) extends Shape
              case class Rectangle(w: Double, h: Double) extends Shape
  TypeScript: type Shape =
                | { kind: "circle"; radius: number }
                | { kind: "rectangle"; width: number; height: number }
```

### Combined: Sum of Products

```
Most real-world ADTs combine sums and products:

  data Expr
      = Literal Int                    -- product: 1 field
      | Add Expr Expr                  -- product: 2 fields
      | Multiply Expr Expr             -- product: 2 fields
      | Negate Expr                    -- product: 1 field
      | IfThenElse Bool Expr Expr      -- product: 3 fields

  The top level is a sum (OR between variants).
  Each variant is a product (AND of its fields).

  Tree structure:

        Expr (sum)
       / | \ \  \
      /  |  \ \  \
  Literal Add Mul Neg IfThenElse
    |    / \  / \  |    / | \
   Int  E  E E  E  E  Bool E  E
```

### The Algebra

```
Type algebra corresponds to number algebra:

  Type             │ Algebra    │ Values
  ─────────────────┼────────────┼──────────
  Void (empty)     │ 0          │ 0 values
  Unit / ()        │ 1          │ 1 value
  Bool             │ 2          │ 2 values
  (A, B)           │ A × B      │ product
  Either A B       │ A + B      │ sum
  A -> B           │ B^A        │ function

  Examples:
    (Bool, Bool)     = 2 × 2 = 4 values
    Either Bool Unit = 2 + 1 = 3 values  (= Maybe Bool)
    Bool -> Bool     = 2^2  = 4 values   (id, not, const T, const F)

  Algebraic laws hold:
    A × 1 = A           (struct with unit field = just A)
    A × 0 = 0           (struct with Void field = impossible)
    A + 0 = A           (Either A Void = just A)
    A × (B + C) = A×B + A×C   (distributive law)
```

## Pattern Matching

```
Pattern matching deconstructs ADTs and guarantees exhaustiveness.

Rust:
  fn area(shape: Shape) -> f64 {
      match shape {
          Shape::Circle(r) => std::f64::consts::PI * r * r,
          Shape::Rectangle(w, h) => w * h,
          Shape::Triangle(a, b, c) => {
              let s = (a + b + c) / 2.0;
              (s * (s-a) * (s-b) * (s-c)).sqrt()
          }
      }
  }

If you add a new variant to Shape, the compiler errors on every
match expression that does not handle it. No runtime surprises.

Haskell:
  area :: Shape -> Double
  area (Circle r)        = pi * r * r
  area (Rectangle w h)   = w * h
  area (Triangle a b c)  = let s = (a+b+c)/2
                            in sqrt(s*(s-a)*(s-b)*(s-c))

Scala:
  def area(shape: Shape): Double = shape match {
      case Circle(r)        => math.Pi * r * r
      case Rectangle(w, h)  => w * h
  }

TypeScript (discriminated union):
  function area(shape: Shape): number {
      switch (shape.kind) {
          case "circle": return Math.PI * shape.radius ** 2;
          case "rectangle": return shape.width * shape.height;
      }
  }
```

## Making Illegal States Unrepresentable

```
Bad modeling (stringly-typed):

  struct User {
      name: String,
      email: String,
      email_verified: bool,
      verification_code: Option<String>,  // only valid if !email_verified
      admin_level: Option<u8>,            // only valid if is_admin
      is_admin: bool,
  }

  Problem: can have email_verified=true AND verification_code=Some("abc")
  Problem: can have is_admin=false AND admin_level=Some(5)
  These are impossible states that the type system allows.


Good modeling (ADTs):

  enum EmailStatus {
      Unverified { code: String },
      Verified,
  }

  enum Role {
      Regular,
      Admin { level: u8 },
  }

  struct User {
      name: String,
      email: String,
      email_status: EmailStatus,
      role: Role,
  }

  Now it is structurally impossible to have a verified email with a code,
  or a non-admin with an admin level. The compiler enforces invariants.
```

## Common ADT Patterns

```
┌──────────────────────┬──────────────────────────────────────────┐
│ Pattern              │ Structure                                 │
├──────────────────────┼──────────────────────────────────────────┤
│ Maybe / Option       │ Some(a) | None                           │
│                      │ Represents optional values               │
├──────────────────────┼──────────────────────────────────────────┤
│ Either / Result      │ Ok(a) | Err(e)                           │
│                      │ Represents success or failure            │
├──────────────────────┼──────────────────────────────────────────┤
│ List (recursive)     │ Cons(head, tail) | Nil                   │
│                      │ Linked list as recursive ADT             │
├──────────────────────┼──────────────────────────────────────────┤
│ Tree (recursive)     │ Node(value, left, right) | Leaf          │
│                      │ Binary tree as recursive ADT             │
├──────────────────────┼──────────────────────────────────────────┤
│ Expr (AST)           │ Lit(n) | Add(e,e) | Mul(e,e) | Neg(e)   │
│                      │ Abstract syntax trees for interpreters   │
├──────────────────────┼──────────────────────────────────────────┤
│ State machine        │ Idle | Loading | Loaded(data) | Error(e) │
│                      │ UI state, protocol state, workflow state │
├──────────────────────┼──────────────────────────────────────────┤
│ Command / Event      │ Create(x) | Update(x) | Delete(id)      │
│                      │ CQRS commands and domain events          │
└──────────────────────┴──────────────────────────────────────────┘
```

## ADTs Across Languages

```
┌──────────────┬──────────────────────────────────────────────────┐
│ Language     │ ADT support                                       │
├──────────────┼──────────────────────────────────────────────────┤
│ Haskell      │ data, newtype. Full ADTs. Pattern matching.      │
│              │ data Maybe a = Just a | Nothing                  │
├──────────────┼──────────────────────────────────────────────────┤
│ Rust         │ enum (sum), struct (product). Full ADTs.          │
│              │ Pattern matching with match, if let, while let.  │
├──────────────┼──────────────────────────────────────────────────┤
│ Scala        │ sealed trait/class + case class. Pattern match.  │
│              │ Scala 3: enum for sum types.                     │
├──────────────┼──────────────────────────────────────────────────┤
│ OCaml        │ type variants. Full ADTs since inception.         │
│              │ type shape = Circle of float | Rect of float*float│
├──────────────┼──────────────────────────────────────────────────┤
│ F#           │ Discriminated unions. Full ADTs.                  │
│              │ type Shape = Circle of float | Rect of float*float│
├──────────────┼──────────────────────────────────────────────────┤
│ Swift        │ enum with associated values. Full ADTs.           │
│              │ Pattern matching with switch.                    │
├──────────────┼──────────────────────────────────────────────────┤
│ Kotlin       │ sealed class/interface + data class.              │
│              │ when expression for pattern matching.            │
├──────────────┼──────────────────────────────────────────────────┤
│ Java 17+     │ sealed interface + record. Pattern matching      │
│              │ with switch (preview). Catching up.              │
├──────────────┼──────────────────────────────────────────────────┤
│ TypeScript   │ Discriminated unions (tagged unions).             │
│              │ switch on discriminant field. Exhaustiveness     │
│              │ via never type.                                  │
├──────────────┼──────────────────────────────────────────────────┤
│ Go           │ No sum types. Interfaces + type assertions.      │
│              │ No exhaustive pattern matching.                  │
├──────────────┼──────────────────────────────────────────────────┤
│ C++          │ std::variant (since C++17). std::visit for       │
│              │ pattern matching. Verbose but functional.        │
└──────────────┴──────────────────────────────────────────────────┘
```

## Pros

- **Type Safety**: impossible states are unrepresentable — compiler catches invalid combinations
- **Exhaustive Matching**: compiler warns when a pattern match does not handle all variants
- **Self-Documenting**: the type definition describes all possible shapes of the data
- **Refactoring Safety**: adding a variant breaks all incomplete match expressions (the compiler tells you what to fix)
- **No Null**: Option/Maybe replaces null — no null pointer exceptions
- **Composability**: ADTs nest naturally (tree of trees, list of eithers)
- **Domain Modeling**: map business rules directly to types
- **Immutability**: ADTs are naturally immutable (new values, not mutations)

## Cons

- **Language Support**: some languages (Go, Java pre-17) lack sum types
- **Verbosity**: defining variants and pattern matches is more code than if/else in simple cases
- **Serialization**: serializing sum types to JSON/Protobuf requires discriminator fields or custom codecs
- **Learning Curve**: the algebraic perspective and type-level thinking take time to internalize
- **Migration Cost**: retrofitting ADTs into an existing codebase with inheritance hierarchies is hard
- **Expression Problem**: adding a new operation (function) over ADTs is easy, but adding a new variant requires modifying all existing functions (the reverse of OOP)

## Use Cases

- **Domain Modeling**: orders (Pending | Confirmed | Shipped | Delivered), payments (Card | PayPal | Crypto)
- **AST / Compilers**: expression trees, statement trees, type representations
- **State Machines**: connection states (Connecting | Connected | Disconnected | Reconnecting)
- **Error Handling**: Result<T, E> for composable error types with specific failure variants
- **Protocol Messages**: request/response types with different payloads per message kind
- **Configuration**: typed config variants instead of string maps
- **UI State**: Loading | Loaded(data) | Error(message) for React/frontend state management
- **Interpreters**: modeling instruction sets, virtual machines, rule engines
