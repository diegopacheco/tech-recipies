# Effect Systems

## What is it?

An effect system is a programming framework that tracks, controls, and composes computational side effects (I/O, state, concurrency, errors, logging) in the type system. Instead of performing effects directly (calling a database, writing a file), the program builds a description of the effects to perform, and a runtime interpreter executes them. This separation makes effects composable, testable, and explicit — you can see from a function's return type exactly which effects it performs. Effect systems replace monad transformer stacks with a more ergonomic and performant approach to managing side effects in functional programming.

## How it works?

### The Problem: Side Effects in FP

```
Impure (effects hidden):

  def processOrder(orderId: String): Order = {
      val order = db.findOrder(orderId)     // IO: database read
      logger.info(s"Processing $orderId")   // IO: logging
      val payment = stripe.charge(order)    // IO: HTTP call
      metrics.increment("orders.processed") // IO: metrics
      emailService.send(order.email, ...)   // IO: email
      order.copy(status = "processed")
  }

  Return type is Order — nothing in the type tells you this function
  does database reads, HTTP calls, logging, metrics, and email sending.


Pure (effects in types):

  def processOrder(orderId: String): ZIO[Database & Logger & PaymentService & Metrics & EmailService, OrderError, Order]

  The type signature declares:
    - Which effects it needs (Database, Logger, PaymentService, ...)
    - What errors it can produce (OrderError)
    - What it returns on success (Order)
```

### Effect as Description (not execution)

```
Traditional (execute immediately):

  val result = httpClient.get("https://api.example.com/data")
  //           ^^^ this line makes the HTTP call RIGHT NOW


Effect system (build description, execute later):

  val program: IO[Response] = IO(httpClient.get("https://api.example.com/data"))
  //           ^^^ this creates a DESCRIPTION of an HTTP call
  //               nothing happens until you "run" it

  // Later, at the edge of the world:
  program.unsafeRunSync()  // NOW the HTTP call happens


Why this matters:
  - The description can be composed, retried, timed out, mocked
  - You can test the program without actually making HTTP calls
  - Concurrency and resource management are handled by the runtime
```

## ZIO (Scala)

```
ZIO[R, E, A]

  R = Environment (dependencies the effect needs)
  E = Error type (what can go wrong)
  A = Success type (what the effect produces)

Common aliases:
  Task[A]      = ZIO[Any, Throwable, A]    (no deps, may throw)
  UIO[A]       = ZIO[Any, Nothing, A]       (no deps, cannot fail)
  IO[E, A]     = ZIO[Any, E, A]            (no deps, typed error)
  URIO[R, A]   = ZIO[R, Nothing, A]         (has deps, cannot fail)


Composition:

  val program: ZIO[Database & Logger, AppError, Order] =
    for {
      order   <- Database.findOrder(orderId)      // ZIO[Database, DbError, Order]
      _       <- Logger.info(s"Found $orderId")   // ZIO[Logger, Nothing, Unit]
      _       <- Database.updateStatus(order, "processing") // ZIO[Database, DbError, Unit]
    } yield order

  // for-comprehension = flatMap chain
  // R types are automatically unioned (Database & Logger)
  // E types are automatically unioned (DbError | Nothing = DbError)


Dependency injection via ZLayer:

  val dbLayer: ZLayer[Config, DbError, Database] = ...
  val loggerLayer: ZLayer[Any, Nothing, Logger] = ...

  val fullLayer = dbLayer ++ loggerLayer

  program.provide(fullLayer)  // inject all dependencies, run the program


Error handling:

  program
    .retry(Schedule.exponential(1.second) && Schedule.recurs(3))
    .timeout(30.seconds)
    .catchAll(err => Logger.error(s"Failed: $err"))
    .fork  // run on a separate fiber (green thread)
```

### ZIO Architecture

```
┌──────────────────────────────────────────────────┐
│                 ZIO Application                   │
│                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐      │
│  │ Service  │  │ Service  │  │ Service  │      │
│  │ (trait)  │  │ (trait)  │  │ (trait)  │      │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘      │
│       │              │              │             │
│  ┌────▼─────┐  ┌────▼─────┐  ┌────▼─────┐      │
│  │ ZLayer   │  │ ZLayer   │  │ ZLayer   │      │
│  │ (impl)   │  │ (impl)   │  │ (impl)   │      │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘      │
│       │              │              │             │
│       └──────────────┼──────────────┘             │
│                      ▼                            │
│              ┌──────────────┐                    │
│              │ ZIO Runtime  │                    │
│              │ (fiber-based │                    │
│              │  executor)   │                    │
│              └──────────────┘                    │
└──────────────────────────────────────────────────┘
```

## Cats Effect (Scala)

```
IO[A] — the core effect type

  IO wraps a computation that may perform side effects.

  val hello: IO[Unit] = IO.println("Hello, world!")
  val read: IO[String] = IO.readLine
  val delayed: IO[Int] = IO.sleep(1.second) *> IO.pure(42)

Composition:
  val program: IO[Unit] = for {
      name <- IO.readLine
      _    <- IO.println(s"Hello, $name")
  } yield ()


Resource safety:
  Resource.make(
      acquire = IO(openFile("data.txt"))
  )(
      release = file => IO(file.close())
  ).use { file =>
      IO(file.readAll())
  }
  // file is guaranteed to close even if readAll throws


Concurrency (fibers):
  val task1: IO[Int] = heavyComputation1
  val task2: IO[Int] = heavyComputation2

  val both: IO[(Int, Int)] = (task1, task2).parTupled
  // runs in parallel on fibers, returns both results


Cats Effect typeclasses:
  ┌─────────────────────────────────────┐
  │         MonadCancel                  │
  │         ┌───────────────┐           │
  │         │   Concurrent  │           │
  │         │   ┌─────────┐ │           │
  │         │   │ Temporal │ │           │
  │         │   │ ┌─────┐ │ │           │
  │         │   │ │Async│ │ │           │
  │         │   │ └─────┘ │ │           │
  │         │   └─────────┘ │           │
  │         └───────────────┘           │
  └─────────────────────────────────────┘

  Sync     → can suspend synchronous effects
  Async    → can suspend asynchronous (callback-based) effects
  Temporal → can sleep, timeout
  Concurrent → can fork, race, cancel
```

## Algebraic Effects (Research / Emerging)

```
Algebraic effects separate effect declaration from effect handling.

Effect declaration (what):
  effect Console {
      read(): String
      print(msg: String): Unit
  }

  effect Database {
      query(sql: String): List[Row]
  }

Using effects:
  fun main() {
      val name = do Console.read()
      do Console.print("Hello, " ++ name)
      val users = do Database.query("SELECT * FROM users")
  }

Handling effects (how):
  handle {
      main()
  } with ConsoleHandler {
      read() => resume(readLine())
      print(msg) => { println(msg); resume(()) }
  } with DatabaseHandler {
      query(sql) => resume(executeQuery(sql))
  }

Key insight: the SAME program can be run with different handlers:
  - Production handler: real console + real database
  - Test handler: mock console + in-memory database
  - Replay handler: recorded inputs + recorded queries


Languages with algebraic effects:
  - Eff (research)
  - Koka (Microsoft Research)
  - OCaml 5 (effect handlers)
  - Unison (abilities)
  - Scala (via libraries: ZIO, Cats Effect approximate this)
```

## Comparison

```
┌──────────────────┬──────────────┬──────────────┬──────────────────┐
│ Feature          │ ZIO          │ Cats Effect  │ Algebraic Effects│
├──────────────────┼──────────────┼──────────────┼──────────────────┤
│ Language         │ Scala        │ Scala        │ Koka, OCaml 5,   │
│                  │              │              │ Eff, Unison      │
├──────────────────┼──────────────┼──────────────┼──────────────────┤
│ Effect type      │ ZIO[R,E,A]   │ IO[A]        │ Language-level   │
│                  │ (3 params)   │ (1 param)    │ effect keyword   │
├──────────────────┼──────────────┼──────────────┼──────────────────┤
│ Dependencies     │ ZLayer (R)   │ Tagless Final│ Effect handlers  │
│                  │ built-in     │ or Resource  │ (language-level) │
├──────────────────┼──────────────┼──────────────┼──────────────────┤
│ Error handling   │ Typed (E)    │ Throwable    │ Effect-specific  │
├──────────────────┼──────────────┼──────────────┼──────────────────┤
│ Concurrency      │ Fibers       │ Fibers       │ Varies           │
├──────────────────┼──────────────┼──────────────┼──────────────────┤
│ Ecosystem        │ Large (ZIO   │ Large (http4s│ Small (research) │
│                  │ HTTP, ZIO    │ fs2, doobie, │                  │
│                  │ Quill, etc.) │ skunk, etc.) │                  │
├──────────────────┼──────────────┼──────────────┼──────────────────┤
│ Learning curve   │ Steep        │ Steep        │ Moderate         │
├──────────────────┼──────────────┼──────────────┼──────────────────┤
│ Maturity         │ Production   │ Production   │ Experimental     │
└──────────────────┴──────────────┴──────────────┴──────────────────┘
```

## Effect Systems in Other Languages

```
┌──────────────┬──────────────────────────────────────────────────┐
│ Language     │ Effect approach                                    │
├──────────────┼──────────────────────────────────────────────────┤
│ Haskell      │ IO monad + monad transformers (mtl) or           │
│              │ effect libraries (polysemy, effectful, fused-effects)│
├──────────────┼──────────────────────────────────────────────────┤
│ Scala        │ ZIO, Cats Effect, Monix                           │
├──────────────┼──────────────────────────────────────────────────┤
│ OCaml 5      │ Native effect handlers (multicore OCaml)          │
├──────────────┼──────────────────────────────────────────────────┤
│ Koka         │ First-class algebraic effects (Microsoft Research) │
├──────────────┼──────────────────────────────────────────────────┤
│ Unison       │ Abilities (algebraic effects with content-         │
│              │ addressed code)                                   │
├──────────────┼──────────────────────────────────────────────────┤
│ Kotlin       │ Arrow (suspend + typed errors, inspired by ZIO)   │
├──────────────┼──────────────────────────────────────────────────┤
│ TypeScript   │ Effect-TS (port of ZIO concepts to TypeScript)    │
├──────────────┼──────────────────────────────────────────────────┤
│ Rust         │ No effect system. Ownership + traits serve a      │
│              │ similar purpose for resource safety.              │
└──────────────┴──────────────────────────────────────────────────┘
```

## Pros

- **Explicit Effects**: function types tell you exactly which side effects are performed
- **Composability**: effects compose via flatMap/for-comprehension without callback hell
- **Testability**: swap production handlers with test handlers — no mocking frameworks needed
- **Resource Safety**: guaranteed cleanup (file handles, connections, locks) even on errors/cancellation
- **Structured Concurrency**: fibers with cancellation, timeouts, and supervision trees
- **Retries and Resilience**: built-in retry schedules, circuit breakers, timeouts
- **Performance**: fiber-based runtimes (ZIO, Cats Effect) outperform thread-per-request models
- **Dependency Injection**: ZIO ZLayer / Cats Effect Resource provide compile-time DI

## Cons

- **Learning Curve**: steep — requires understanding monads, type-level programming, fiber semantics
- **Verbosity**: wrapping every effect in IO/ZIO adds syntactic overhead
- **Ecosystem Lock-In**: ZIO ecosystem vs Cats Effect ecosystem — libraries often pick one
- **Debugging**: stack traces through effect runtimes are harder to read than imperative code
- **Compile Times**: heavy type-level machinery increases Scala compile times
- **Team Adoption**: onboarding developers to effect systems requires significant training
- **Limited Language Support**: only practical in languages with strong type systems (Scala, Haskell, OCaml)
- **Overhead for Simple Programs**: effect systems add unnecessary complexity to scripts and small tools

## Use Cases

- **Backend Services**: HTTP servers with database access, caching, and external API calls (ZIO HTTP, http4s)
- **Data Pipelines**: streaming data processing with resource-safe file/connection handling
- **Concurrent Systems**: fan-out/fan-in, parallel batch processing, rate limiting
- **Microservices**: dependency injection, circuit breakers, retries, observability
- **Event Sourcing**: modeling commands and events as effects
- **Financial Systems**: typed error handling for transaction failures, timeout management
- **Compilers / Interpreters**: modeling AST evaluation effects (state, IO, errors)
- **Testing**: property-based testing with effect mocking — no test doubles needed
