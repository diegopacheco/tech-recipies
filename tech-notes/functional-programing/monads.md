# Monads

## What is it?

A monad is a design pattern for composing functions that return wrapped values. It provides two operations: `unit` (also called `return`, `pure`, or `of`) which wraps a value into the monad, and `bind` (also called `flatMap`, `>>=`, or `chain`) which takes a wrapped value and a function that returns a wrapped value, unwraps the value, applies the function, and returns the new wrapped value. Monads solve the problem of chaining computations where each step might fail, produce side effects, return multiple values, or require context — without nested callbacks, null checks, or exception handling cluttering the code.

## How it works?

### The Three Monad Laws

```
1. Left Identity:
   unit(a).flatMap(f)  ===  f(a)

   Wrapping a value and immediately flatMapping is the same as
   just calling the function.

2. Right Identity:
   m.flatMap(unit)  ===  m

   FlatMapping with the unit function returns the same monad.

3. Associativity:
   m.flatMap(f).flatMap(g)  ===  m.flatMap(x => f(x).flatMap(g))

   Chaining flatMaps is associative (grouping does not matter).
```

### The Core Operations

```
unit (return / pure / of):
  Takes a plain value → wraps it in the monad

  Optional.of(42)         →  Some(42)
  Promise.resolve(42)     →  Promise<42>
  List.of(42)             →  [42]
  Either.right(42)        →  Right(42)


bind (flatMap / >>= / chain):
  Takes a monad + a function (a → Monad<b>) → returns Monad<b>

  Some(42).flatMap(x => Some(x + 1))     →  Some(43)
  Some(42).flatMap(x => None)            →  None
  [1,2,3].flatMap(x => [x, x*10])       →  [1,10,2,20,3,30]


map (fmap / <$>):
  Takes a monad + a function (a → b) → returns Monad<b>

  Some(42).map(x => x + 1)              →  Some(43)
  None.map(x => x + 1)                  →  None

  map is derivable from flatMap:
  m.map(f)  ===  m.flatMap(x => unit(f(x)))
```

### Without Monads vs With Monads

```
Without (nested null checks):

  User user = getUser(id);
  if (user != null) {
      Address addr = user.getAddress();
      if (addr != null) {
          String city = addr.getCity();
          if (city != null) {
              return city.toUpperCase();
          }
      }
  }
  return "UNKNOWN";


With Maybe/Optional monad:

  getUser(id)
      .flatMap(user -> user.getAddress())
      .flatMap(addr -> addr.getCity())
      .map(city -> city.toUpperCase())
      .orElse("UNKNOWN");


The monad handles the null checking at each step.
If any step returns None/Nothing, the rest of the chain is skipped.
```

## Common Monads

### Maybe / Optional

```
Represents a value that might not exist.

  Some(x)  →  value is present
  None     →  value is absent

  Some(5).flatMap(x => Some(x * 2))   →  Some(10)
  None.flatMap(x => Some(x * 2))      →  None  (short-circuits)
  Some(5).flatMap(x => None)           →  None

Use case: replacing null checks, database lookups, dictionary access

Haskell:  Maybe a  =  Just a | Nothing
Scala:    Option[A] = Some(A) | None
Rust:     Option<T> = Some(T) | None
Java:     Optional<T>
```

### Either / Result

```
Represents a value that is either a success (Right) or an error (Left).

  Right(x)   →  success
  Left(err)  →  failure with error information

  Right(5).flatMap(x => Right(x * 2))           →  Right(10)
  Left("not found").flatMap(x => Right(x * 2))  →  Left("not found")
  Right(5).flatMap(x => Left("overflow"))        →  Left("overflow")

Use case: error handling without exceptions, validation chains

Haskell:  Either e a  =  Left e | Right a
Scala:    Either[E, A]
Rust:     Result<T, E> = Ok(T) | Err(E)

Chain of operations that can each fail:

  parseInput(raw)                         // Either<Error, Input>
      .flatMap(input => validate(input))  // Either<Error, ValidInput>
      .flatMap(valid => save(valid))      // Either<Error, SaveResult>
      .map(result => result.getId())      // Either<Error, String>
```

### List / Collection

```
Represents multiple possible values (non-determinism).

  [1,2,3].flatMap(x => [x, x*10])  →  [1, 10, 2, 20, 3, 30]
  [1,2].flatMap(x => [3,4].map(y => (x,y)))  →  [(1,3),(1,4),(2,3),(2,4)]

Use case: combinatorial generation, list comprehensions

Haskell:  [a]
  do
    x <- [1,2,3]
    y <- [10,20]
    return (x + y)
  -- [11,21,12,22,13,23]

This is equivalent to nested loops but expressed as flat chaining.
```

### IO

```
Represents a computation that performs side effects.

  IO wraps an action that reads/writes to the outside world.
  The action is not executed when created — only when "run".

  readLine : IO String
  putStrLn : String -> IO ()

  Haskell:
    main :: IO ()
    main = do
        name <- getLine          -- IO String (read from stdin)
        putStrLn ("Hello " ++ name)  -- IO () (write to stdout)
        return ()

  The do notation is syntactic sugar for flatMap (>>=):
    main = getLine >>= \name -> putStrLn ("Hello " ++ name)

  IO is a monad because:
    - unit: return x creates an IO action that produces x
    - bind: (>>=) sequences IO actions

  Key insight: IO allows pure functional languages to perform
  side effects while keeping the type system honest about it.
```

### State

```
Represents a computation that carries mutable state.

  State s a  =  s -> (a, s)

  A function that takes a state, returns a value and a new state.

  get    : State s s          -- read the state
  put    : s -> State s ()    -- replace the state
  modify : (s -> s) -> State s ()  -- transform the state

  Haskell:
    counter :: State Int [Int]
    counter = do
        x <- get           -- read state (0)
        put (x + 1)        -- set state to 1
        y <- get           -- read state (1)
        put (y + 1)        -- set state to 2
        z <- get           -- read state (2)
        return [x, y, z]   -- return [0, 1, 2]

    runState counter 0  →  ([0, 1, 2], 2)

Use case: stateful computations in pure functional languages,
          random number generation, interpreters
```

### Reader

```
Represents a computation that reads from a shared environment.

  Reader r a  =  r -> a

  ask : Reader r r              -- read the environment
  local : (r -> r) -> Reader r a -> Reader r a  -- modify env locally

  Use case: dependency injection in functional programming

  type Config = { dbUrl: String, port: Int }

  getDbUrl :: Reader Config String
  getDbUrl = do
      config <- ask
      return (dbUrl config)

  runReader getDbUrl { dbUrl: "postgres://...", port: 5432 }
  →  "postgres://..."
```

### Writer

```
Represents a computation that produces a log alongside a value.

  Writer w a  =  (a, w)    -- value + accumulated log

  tell : w -> Writer w ()   -- append to the log

  Use case: logging, accumulating metadata, building up output

  example :: Writer [String] Int
  example = do
      tell ["Starting"]
      let x = 2 + 3
      tell ["Computed x = " ++ show x]
      return x

  runWriter example  →  (5, ["Starting", "Computed x = 5"])
```

## Monad Composition

```
Problem: combining multiple monads (e.g., Maybe + IO, Either + State).

Solution: Monad Transformers (Haskell) or Effect Systems (ZIO, Cats Effect)

Monad Transformers stack monads:

  MaybeT (StateT s IO) a

  = IO action that carries state and may fail

  Example:
    lookupUser :: MaybeT IO User
    lookupUser = do
        name <- lift getLine          -- lift IO into MaybeT IO
        MaybeT (return (lookup name db))  -- Maybe result → MaybeT

  Drawback: transformer stacks are hard to read and compose.
  Modern approach: effect systems (ZIO, Cats Effect, Polysemy)
```

## Monads in Different Languages

```
┌──────────────┬─────────────────────────────────────────────────┐
│ Language     │ Monad support                                    │
├──────────────┼─────────────────────────────────────────────────┤
│ Haskell      │ First-class. do notation. Monad typeclass.      │
│              │ Maybe, Either, IO, State, Reader, Writer, List  │
├──────────────┼─────────────────────────────────────────────────┤
│ Scala        │ for comprehension = flatMap/map sugar.           │
│              │ Option, Either, Try, Future, List, IO (Cats)    │
├──────────────┼─────────────────────────────────────────────────┤
│ Rust         │ Option<T>, Result<T,E> with ? operator.          │
│              │ ? is syntactic sugar for early-return flatMap.  │
├──────────────┼─────────────────────────────────────────────────┤
│ Kotlin       │ Nullable types (?.), Result, Arrow library.      │
│              │ coroutines are monadic (continuation monad).    │
├──────────────┼─────────────────────────────────────────────────┤
│ Java         │ Optional<T>, Stream<T>, CompletableFuture<T>.   │
│              │ flatMap method on each. No unified abstraction. │
├──────────────┼─────────────────────────────────────────────────┤
│ TypeScript   │ Promise (async/await = flatMap sugar).           │
│              │ fp-ts library for Option, Either, IO, Task.     │
├──────────────┼─────────────────────────────────────────────────┤
│ F#           │ Computation expressions (monadic do notation).  │
│              │ async { }, option { }, result { }               │
├──────────────┼─────────────────────────────────────────────────┤
│ OCaml        │ let* syntax (binding operators) since 4.08.     │
│              │ Option, Result, Lwt (async IO).                 │
└──────────────┴─────────────────────────────────────────────────┘
```

## Pros

- **Composability**: chain operations cleanly without nesting or callbacks
- **Error Propagation**: Either/Result propagates errors without try-catch boilerplate
- **Null Safety**: Maybe/Optional eliminates null pointer exceptions
- **Side Effect Control**: IO monad makes side effects explicit in the type system
- **Separation of Concerns**: the monad handles plumbing (error, state, IO), functions handle logic
- **Testability**: pure functions wrapped in monads are easier to test in isolation
- **Refactoring Safety**: the type system catches broken chains at compile time
- **Universal Pattern**: the same flatMap/map interface works across Maybe, Either, IO, List, Future

## Cons

- **Learning Curve**: monad laws, transformers, and categorical terminology are hard to learn
- **Abstraction Overhead**: wrapping and unwrapping adds syntactic noise (mitigated by do notation / for comprehensions)
- **Transformer Hell**: stacking monad transformers (MaybeT (StateT s IO)) is complex and slow
- **Performance**: wrapping values in monadic containers adds allocation and indirection
- **Debugging Difficulty**: stack traces through flatMap chains are less readable than imperative code
- **Overengineering Risk**: using monads where a simple if/else would suffice adds unnecessary complexity
- **Language Support**: languages without higher-kinded types (Java, Go) cannot abstract over monads generically

## Use Cases

- **Error Handling**: Either/Result for composable error propagation without exceptions
- **Nullable Values**: Maybe/Optional for safe handling of missing data
- **Async Programming**: Future/Promise/Task for composing asynchronous operations
- **Validation**: Applicative validation that collects all errors (not just the first)
- **Configuration**: Reader monad for dependency injection without mutation
- **Logging**: Writer monad for accumulating logs alongside computation
- **State Machines**: State monad for modeling stateful computations purely
- **Parsing**: Parser monads for composing small parsers into complex grammars
- **Database Transactions**: IO/Task monads wrapping transactional operations
- **Domain Modeling**: encoding business rules as monadic pipelines with explicit failure modes
