# Pattern Matching

## What is it?

Pattern matching is a control flow mechanism that checks a value against a series of patterns and executes the code associated with the first matching pattern. Unlike switch/case which compares against constant values, pattern matching can destructure complex data types, bind variables to parts of the structure, apply guards (boolean conditions), and nest patterns within patterns. The compiler verifies that all possible cases are covered (exhaustiveness checking) and that no pattern is unreachable (redundancy checking). Pattern matching is the primary way to work with algebraic data types in functional languages.

## How it works?

### Basic Pattern Matching

```
Haskell:
  describe :: Int -> String
  describe 0 = "zero"
  describe 1 = "one"
  describe n = "other: " ++ show n

Rust:
  fn describe(n: i32) -> &'static str {
      match n {
          0 => "zero",
          1 => "one",
          _ => "other",
      }
  }

Scala:
  def describe(n: Int): String = n match {
      case 0 => "zero"
      case 1 => "one"
      case n => s"other: $n"
  }

Elixir:
  def describe(0), do: "zero"
  def describe(1), do: "one"
  def describe(n), do: "other: #{n}"

OCaml:
  let describe = function
    | 0 -> "zero"
    | 1 -> "one"
    | n -> "other: " ^ string_of_int n
```

### Destructuring

```
Tuples:
  Rust:   let (x, y, z) = (1, 2, 3);
  Haskell: let (x, y, z) = (1, 2, 3)
  Python:  x, y, z = (1, 2, 3)
  Kotlin:  val (x, y, z) = Triple(1, 2, 3)

Structs / Records:
  Rust:
    struct Point { x: f64, y: f64 }
    let Point { x, y } = point;

  Kotlin:
    data class Point(val x: Double, val y: Double)
    val (x, y) = point

  JavaScript:
    const { name, age } = person;

Enums / Sum Types:
  Rust:
    match shape {
        Circle(r) => pi * r * r,
        Rectangle(w, h) => w * h,
    }

  Haskell:
    case shape of
        Circle r       -> pi * r * r
        Rectangle w h  -> w * h

Lists / Arrays:
  Haskell:
    head (x:_) = x        -- first element
    tail (_:xs) = xs       -- rest of list
    isEmpty [] = True      -- empty list pattern
    isEmpty _  = False

  Elixir:
    [head | tail] = [1, 2, 3]    -- head = 1, tail = [2, 3]
    [a, b | rest] = [1, 2, 3, 4] -- a = 1, b = 2, rest = [3, 4]

  Rust:
    match slice {
        [first, .., last] => println!("{first} to {last}"),
        [single] => println!("just {single}"),
        [] => println!("empty"),
    }
```

### Guards

```
Guards add boolean conditions to patterns.

Haskell:
  classify :: Int -> String
  classify n
      | n < 0     = "negative"
      | n == 0    = "zero"
      | n < 100   = "small"
      | otherwise = "large"

Rust:
  match temperature {
      t if t < 0   => "freezing",
      t if t < 20  => "cold",
      t if t < 30  => "comfortable",
      _            => "hot",
  }

Scala:
  n match {
      case x if x < 0  => "negative"
      case 0            => "zero"
      case x if x < 100 => "small"
      case _            => "large"
  }

Elixir:
  def classify(n) when n < 0, do: "negative"
  def classify(0), do: "zero"
  def classify(n) when n < 100, do: "small"
  def classify(_), do: "large"

Swift:
  switch temperature {
  case let t where t < 0:  "freezing"
  case let t where t < 20: "cold"
  case let t where t < 30: "comfortable"
  default:                  "hot"
  }
```

### Nested Patterns

```
Match on deeply nested structures:

Haskell:
  simplify :: Expr -> Expr
  simplify (Add (Literal 0) e) = simplify e         -- 0 + e = e
  simplify (Add e (Literal 0)) = simplify e         -- e + 0 = e
  simplify (Multiply (Literal 1) e) = simplify e    -- 1 * e = e
  simplify (Multiply (Literal 0) _) = Literal 0     -- 0 * e = 0
  simplify (Negate (Negate e)) = simplify e          -- --e = e
  simplify e = e

Rust:
  fn simplify(expr: Expr) -> Expr {
      match expr {
          Add(box Literal(0), box e) => simplify(e),
          Add(box e, box Literal(0)) => simplify(e),
          Multiply(box Literal(1), box e) => simplify(e),
          Multiply(box Literal(0), _) => Literal(0),
          Negate(box Negate(box e)) => simplify(e),
          e => e,
      }
  }

Elixir:
  def simplify({:add, {:literal, 0}, e}), do: simplify(e)
  def simplify({:add, e, {:literal, 0}}), do: simplify(e)
  def simplify({:multiply, {:literal, 0}, _}), do: {:literal, 0}
  def simplify(e), do: e
```

### Or-Patterns and And-Patterns

```
Or-pattern (match any of several patterns):

Rust:
  match direction {
      North | South => "vertical",
      East | West   => "horizontal",
  }

OCaml:
  match direction with
  | North | South -> "vertical"
  | East | West -> "horizontal"

Haskell (using guards):
  classify North = "vertical"
  classify South = "vertical"
  classify _     = "horizontal"

And-pattern (bind whole + destructure):

Rust:
  match point {
      p @ Point { x: 0, .. } => println!("on y-axis: {p:?}"),
      p @ Point { y: 0, .. } => println!("on x-axis: {p:?}"),
      p => println!("off-axis: {p:?}"),
  }

Haskell:
  case expr of
      whole@(Add left right) -> ...  -- 'whole' binds the entire Add value
```

## Exhaustiveness Checking

```
The compiler verifies that all cases are handled.

Rust (compiler error):
  enum Color { Red, Green, Blue }

  match color {
      Red   => "red",
      Green => "green",
      // ERROR: non-exhaustive patterns: `Blue` not covered
  }

Haskell (compiler warning):
  data Color = Red | Green | Blue

  name Red   = "red"
  name Green = "green"
  -- Warning: Pattern match(es) are non-exhaustive
  -- In an equation for 'name': Patterns not matched: Blue

TypeScript (exhaustiveness via never):
  type Color = "red" | "green" | "blue";

  function name(c: Color): string {
      switch (c) {
          case "red": return "red";
          case "green": return "green";
          default:
              const _exhaustive: never = c;
              // ERROR if "blue" case is missing
              return _exhaustive;
      }
  }

Adding a new variant to the sum type:
  → compiler errors at EVERY unhandled match
  → no runtime surprises
```

## Pattern Matching Across Languages

```
┌──────────────┬──────────────────────────────────────────────────┐
│ Language     │ Pattern matching support                          │
├──────────────┼──────────────────────────────────────────────────┤
│ Haskell      │ First-class. case/of, function equations,        │
│              │ guards, as-patterns, wildcard. Exhaustive.       │
├──────────────┼──────────────────────────────────────────────────┤
│ Rust         │ match, if let, while let, let-else. Exhaustive. │
│              │ Destructure enums, structs, tuples, slices.      │
├──────────────┼──────────────────────────────────────────────────┤
│ Scala        │ match/case. Sealed traits for exhaustiveness.    │
│              │ Extractors (unapply) for custom patterns.        │
├──────────────┼──────────────────────────────────────────────────┤
│ OCaml        │ match/with. Exhaustive. Or-patterns. Guards.     │
│              │ As-patterns. Very mature.                        │
├──────────────┼──────────────────────────────────────────────────┤
│ F#           │ match/with. Active patterns for custom matching. │
│              │ Exhaustive. Guards.                              │
├──────────────┼──────────────────────────────────────────────────┤
│ Elixir       │ Pattern matching in function heads, case, with.  │
│              │ Pin operator (^) for matching existing values.   │
├──────────────┼──────────────────────────────────────────────────┤
│ Swift        │ switch with value binding, where guards,         │
│              │ tuple patterns. Exhaustive for enums.            │
├──────────────┼──────────────────────────────────────────────────┤
│ Kotlin       │ when expression. Smart casts for sealed classes. │
│              │ Destructuring via componentN().                  │
├──────────────┼──────────────────────────────────────────────────┤
│ Java 21+     │ Switch with pattern matching (record patterns,  │
│              │ guarded patterns, sealed class exhaustiveness).  │
├──────────────┼──────────────────────────────────────────────────┤
│ Python 3.10+ │ match/case (structural pattern matching).        │
│              │ Sequence, mapping, class, and or-patterns.       │
│              │ No exhaustiveness checking.                      │
├──────────────┼──────────────────────────────────────────────────┤
│ C#           │ Switch expression with property, tuple,          │
│              │ positional, and relational patterns. Guards.     │
├──────────────┼──────────────────────────────────────────────────┤
│ TypeScript   │ No native match. Discriminated unions + switch.  │
│              │ Exhaustiveness via never type.                   │
├──────────────┼──────────────────────────────────────────────────┤
│ Go           │ No pattern matching. Type switches only.         │
│              │ No destructuring, no exhaustiveness.             │
└──────────────┴──────────────────────────────────────────────────┘
```

## Pattern Matching vs Alternatives

```
┌─────────────────────┬─────────────────────────────────────────────┐
│ Approach            │ Comparison with pattern matching             │
├─────────────────────┼─────────────────────────────────────────────┤
│ if/else chains      │ No destructuring. No exhaustiveness check.  │
│                     │ Verbose for multiple conditions.            │
├─────────────────────┼─────────────────────────────────────────────┤
│ switch/case         │ Constants only (no destructuring in most    │
│ (traditional)       │ languages). Fall-through bugs.              │
├─────────────────────┼─────────────────────────────────────────────┤
│ Visitor pattern     │ OOP equivalent of pattern matching.         │
│ (OOP)               │ Requires boilerplate (accept/visit methods).│
│                     │ Achieves exhaustiveness via interface.      │
├─────────────────────┼─────────────────────────────────────────────┤
│ instanceof chain    │ Runtime type checking. No exhaustiveness.   │
│ (Java pre-17)       │ Verbose casting. Error-prone.              │
├─────────────────────┼─────────────────────────────────────────────┤
│ Dynamic dispatch    │ OOP polymorphism. Adding new types is easy  │
│ (virtual methods)   │ but adding new operations requires touching │
│                     │ all types (expression problem, inverse).    │
└─────────────────────┴─────────────────────────────────────────────┘
```

## Pros

- **Exhaustiveness**: compiler guarantees all cases are handled
- **Destructuring**: extract and bind parts of complex structures in one step
- **Readability**: pattern + action on one line — clearer than nested if/else
- **Refactoring Safety**: adding a variant produces compiler errors at every unhandled match
- **Conciseness**: replaces verbose instanceof/casting/null-checking chains
- **Composable**: nested patterns match arbitrarily deep structures
- **Variable Binding**: bind parts of the match to names for use in the body
- **Guard Integration**: combine structural matching with boolean conditions

## Cons

- **Expression Problem**: adding a new variant is easy but adding a new operation requires modifying all match sites (opposite of OOP polymorphism)
- **Order Dependence**: patterns are checked top to bottom — reordering changes behavior
- **Language Support**: some languages (Go, older Java) lack pattern matching entirely
- **Complexity**: deeply nested patterns can become hard to read
- **Performance**: naive implementations may not optimize well (good compilers generate decision trees)
- **Learning Curve**: or-patterns, as-patterns, guards, and nested matches have syntax to learn per language

## Use Cases

- **ADT Processing**: the primary way to work with sum types (Option, Result, custom enums)
- **Compiler / Interpreter**: AST traversal, optimization passes, code generation
- **Protocol Parsing**: matching on message types and extracting fields
- **State Machines**: matching on current state + event to determine next state
- **JSON / XML Processing**: matching on structure shapes (Python match, Elixir)
- **Error Handling**: matching on specific error variants for different recovery strategies
- **Game Logic**: matching on game events, player actions, entity types
- **Recursive Data**: traversing trees, lists, and graphs with base case + recursive case patterns
