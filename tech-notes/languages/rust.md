# Idiomatic Rust

Idiomatic Rust uses ownership, algebraic data types, traits, and scope-based cleanup to move correctness checks into the compiler while keeping runtime behavior explicit. The patterns below target stable Rust and use only the standard library.

## 1. Borrow with `&str` and slices

```rust
fn normalized_length(value: &str) -> usize {
    value.trim().chars().count()
}

fn total(values: &[u32]) -> u32 {
    values.iter().sum()
}

let owned = String::from("  ferris  ");
let numbers = vec![10, 20, 30];

assert_eq!(normalized_length(&owned), 6);
assert_eq!(normalized_length("  rust  "), 4);
assert_eq!(total(&numbers), 60);
assert_eq!(total(&[1, 2, 3]), 6);
```

Why: a function should borrow when it only needs to read. `&str` accepts borrowed `String` data and string literals, while `&[T]` accepts vectors, arrays, and subslices. This avoids taking ownership or forcing an allocation.

Pros:

- Broadens the set of callers without generics.
- Avoids cloning and allocation.
- Makes the ownership contract visible in the signature.

Cons:

- Borrowed results and stored references may require explicit lifetimes.
- The function cannot retain the input after the borrow ends.
- Mutation requires an exclusive `&mut` borrow.

## 2. Return `Result` and propagate with `?`

```rust
use std::num::ParseIntError;

fn doubled_port(input: &str) -> Result<u32, ParseIntError> {
    let port = input.trim().parse::<u16>()?;
    Ok(u32::from(port) * 2)
}

assert!(matches!(doubled_port("4040"), Ok(8080)));
assert!(doubled_port("invalid").is_err());
```

Why: expected, recoverable failures belong in the return type. The `?` operator returns early on `Err` and yields the success value on `Ok`, preserving the original error without nested `match` blocks.

Pros:

- Keeps the successful path short and readable.
- Forces callers to acknowledge failure.
- Composes across calls and converts errors through `From` when suitable.

Cons:

- The enclosing function needs a compatible return type.
- A low-level error may lack useful domain context.
- Public libraries often need a deliberate error type as failure modes grow.

## 3. Model states with enums and exhaustive `match`

```rust
#[derive(Debug, PartialEq, Eq)]
enum Job {
    Queued,
    Running { percent: u8 },
    Finished(String),
}

fn status(job: &Job) -> String {
    match job {
        Job::Queued => String::from("queued"),
        Job::Running { percent } => format!("running at {percent}%"),
        Job::Finished(output) => format!("finished: {output}"),
    }
}

assert_eq!(status(&Job::Queued), "queued");
assert_eq!(status(&Job::Running { percent: 75 }), "running at 75%");
assert_eq!(status(&Job::Finished(String::from("ok"))), "finished: ok");
```

Why: an enum represents a closed set of valid states, and each variant can carry only the data relevant to that state. An exhaustive `match` makes the compiler verify that every state is handled.

Pros:

- Makes invalid state combinations harder to represent.
- Destructures data without casts or sentinel values.
- Adding a variant reveals affected code at compile time.

Cons:

- Adding variants can require edits across many matches.
- Large variant payloads can increase the enum size unless boxed.
- A closed enum is less extensible for downstream crates than a trait-based design.

## 4. Use `let...else` for early exits

```rust
fn checked_area(dimensions: Option<(u32, u32)>) -> Option<u32> {
    let Some((width, height)) = dimensions else {
        return None;
    };

    width.checked_mul(height)
}

assert_eq!(checked_area(Some((20, 30))), Some(600));
assert_eq!(checked_area(None), None);
assert_eq!(checked_area(Some((u32::MAX, 2))), None);
```

Why: `let...else` handles a rejected pattern immediately and leaves the bound values in the surrounding scope. It keeps the successful path flat when only one shape should continue.

Pros:

- Reduces indentation around the main path.
- Keeps destructuring beside validation.
- Works with `return`, `break`, `continue`, and other diverging branches.

Cons:

- The `else` branch must diverge.
- `match` is clearer when several variants need meaningful work.
- Repeated early exits can scatter failure policy across a function.

## 5. Compose iterator adapters

```rust
fn valid_even_numbers(values: &[&str]) -> Vec<u32> {
    values
        .iter()
        .filter_map(|value| value.parse::<u32>().ok())
        .filter(|value| value % 2 == 0)
        .collect()
}

let values = ["8", "bad", "13", "20"];
assert_eq!(valid_even_numbers(&values), vec![8, 20]);
```

Why: iterator adapters express a data transformation as a lazy pipeline. `filter_map` combines conditional conversion and filtering, and `collect` chooses the final collection.

Pros:

- Separates transformation stages cleanly.
- Avoids manual indexing and temporary mutable collections.
- Retains Rust's zero-cost abstraction model in optimized builds.

Cons:

- Long chains can be harder to inspect and debug.
- `filter_map(...ok())` intentionally discards parse errors.
- Ownership differences among `iter`, `iter_mut`, and `into_iter` require care.

## 6. Update maps through the entry API

```rust
use std::collections::HashMap;

fn frequencies(input: &str) -> HashMap<&str, usize> {
    let mut counts = HashMap::new();

    for word in input.split_whitespace() {
        *counts.entry(word).or_default() += 1;
    }

    counts
}

let counts = frequencies("rust safe rust fast");
assert_eq!(counts.get("rust"), Some(&2));
assert_eq!(counts.get("safe"), Some(&1));
```

Why: `entry` represents an occupied or vacant key in one API. `or_default` inserts a zero count only when needed and returns a mutable reference for the update.

Pros:

- Avoids a separate existence check and second lookup.
- Supports lazy insertion with `or_insert_with`.
- Expresses insert-or-update intent directly.

Cons:

- The key is moved into `entry` for owned key types.
- Holding the returned mutable reference keeps the map mutably borrowed.
- Complex occupied and vacant behavior may still need an explicit `match`.

## 7. Create newtypes for domain distinctions

```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
struct UserId(u64);

impl UserId {
    fn new(value: u64) -> Option<Self> {
        (value != 0).then_some(Self(value))
    }
}

fn shard_for(user_id: UserId) -> u64 {
    user_id.0 % 16
}

let user_id = UserId::new(33);
assert_eq!(user_id.map(shard_for), Some(1));
assert_eq!(UserId::new(0), None);
```

Why: a one-field wrapper gives a primitive value domain meaning and prevents accidental interchange with other `u64` values. A constructor can enforce invariants at the boundary.

Pros:

- Provides compile-time separation with no necessary runtime overhead.
- Centralizes validation and domain behavior.
- Can selectively expose operations instead of inheriting every primitive operation.

Cons:

- Adds wrapping, unwrapping, and trait implementation work.
- Overusing tiny wrappers can make APIs noisy.
- Public tuple fields allow callers to bypass constructor validation.

## 8. Implement `From` and `TryFrom` for conversions

```rust
use std::convert::TryFrom;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
struct Percentage(u8);

#[derive(Debug, PartialEq, Eq)]
struct OutOfRange;

impl TryFrom<u8> for Percentage {
    type Error = OutOfRange;

    fn try_from(value: u8) -> Result<Self, Self::Error> {
        if value <= 100 {
            Ok(Self(value))
        } else {
            Err(OutOfRange)
        }
    }
}

impl From<Percentage> for u8 {
    fn from(value: Percentage) -> Self {
        value.0
    }
}

assert_eq!(Percentage::try_from(80), Ok(Percentage(80)));
assert_eq!(Percentage::try_from(120), Err(OutOfRange));

let raw: u8 = Percentage(65).into();
assert_eq!(raw, 65);
```

Why: standard conversion traits make conversions discoverable and interoperable with generic code. Implement `From` for infallible conversions and `TryFrom` when validation can fail; their reciprocal `Into` and `TryInto` implementations are supplied automatically.

Pros:

- Uses conventions understood across the ecosystem.
- Enables generic APIs bounded by conversion traits.
- Makes fallibility explicit in the selected trait.

Cons:

- Rust's coherence rules prevent some foreign-type implementations.
- Several possible target types may require annotations.
- A questionable `From` implementation can hide lossy or surprising behavior.

## 9. Use builders for configurable construction

```rust
#[derive(Debug, PartialEq, Eq)]
struct Request {
    endpoint: String,
    retries: u8,
    compression: bool,
}

struct RequestBuilder {
    endpoint: String,
    retries: u8,
    compression: bool,
}

impl RequestBuilder {
    fn new(endpoint: impl Into<String>) -> Self {
        Self {
            endpoint: endpoint.into(),
            retries: 3,
            compression: false,
        }
    }

    fn retries(mut self, retries: u8) -> Self {
        self.retries = retries;
        self
    }

    fn compression(mut self, compression: bool) -> Self {
        self.compression = compression;
        self
    }

    fn build(self) -> Request {
        Request {
            endpoint: self.endpoint,
            retries: self.retries,
            compression: self.compression,
        }
    }
}

let request = RequestBuilder::new("/health")
    .retries(5)
    .compression(true)
    .build();

assert_eq!(request.retries, 5);
assert!(request.compression);
```

Why: a builder gives optional settings names, defaults, and chainable construction while keeping required input in `new`. A fallible terminal method can return `Result` when settings need cross-field validation.

Pros:

- Avoids long positional argument lists.
- Supports defaults and future optional fields.
- Makes call sites readable through named methods.

Cons:

- Adds another type and a group of forwarding methods.
- Required fields can remain unset unless the design prevents it.
- Consuming and non-consuming builder styles have different reuse ergonomics.

## 10. Let scope manage resources with guards

```rust
use std::sync::Mutex;

fn increment(counter: &Mutex<u32>) {
    let mut value = counter
        .lock()
        .unwrap_or_else(|poisoned| poisoned.into_inner());
    *value += 1;
}

let counter = Mutex::new(0);
increment(&counter);
increment(&counter);

let value = counter
    .lock()
    .unwrap_or_else(|poisoned| poisoned.into_inner());
assert_eq!(*value, 2);
```

Why: the mutex guard owns the lock and releases it through `Drop` when the guard leaves scope. This resource-acquisition-is-initialization style ties cleanup to ownership, including early returns.

Pros:

- Makes forgotten unlock or close calls far less likely.
- Cleanup follows lexical scope and ownership.
- The same principle covers memory, files, sockets, and other guards.

Cons:

- A guard that lives longer than intended can hold a scarce resource.
- Destructor failures cannot be returned normally.
- Explicit `drop(value)` or a smaller scope may be needed for precise release timing.

## Practical guidance

These patterns are defaults, not absolute rules. Prefer signatures that state ownership and failure clearly, types that rule out invalid states, standard traits that improve interoperability, and control flow that keeps every meaningful case visible. Run `cargo fmt` for consistent formatting and `cargo clippy --all-targets --all-features` to catch common correctness, style, complexity, and performance issues.

## Sources

1. [The Rust Programming Language: The Slice Type](https://doc.rust-lang.org/book/ch04-03-slices.html)
2. [The Rust Programming Language: Recoverable Errors with `Result`](https://doc.rust-lang.org/book/ch09-02-recoverable-errors-with-result.html)
3. [The Rust Programming Language: The `match` Control Flow Construct](https://doc.rust-lang.org/book/ch06-02-match.html)
4. [The Rust Programming Language: Concise Control Flow with `if let` and `let...else`](https://doc.rust-lang.org/book/ch06-03-if-let.html)
5. [The Rust Programming Language: Processing a Series of Items with Iterators](https://doc.rust-lang.org/book/ch13-02-iterators.html)
6. [Rust standard library: `HashMap::Entry`](https://doc.rust-lang.org/std/collections/hash_map/enum.Entry.html)
7. [Rust API Guidelines: Type safety](https://rust-lang.github.io/api-guidelines/type-safety.html)
8. [Rust API Guidelines: Interoperability](https://rust-lang.github.io/api-guidelines/interoperability.html)
9. [Rust API Guidelines: Builders](https://rust-lang.github.io/api-guidelines/type-safety.html#builders-enable-construction-of-complex-values-c-builder)
10. [The Rust Programming Language: Running Code on Cleanup with the `Drop` Trait](https://doc.rust-lang.org/book/ch15-03-drop.html)
11. [Clippy Documentation](https://doc.rust-lang.org/stable/clippy/)
