# Idiomatic Kotlin

Idiomatic Kotlin expresses intent through the type system, favors immutable values, uses expressions instead of mutable control-flow scaffolding, and relies on focused standard-library operations. The following ten idioms are useful defaults, not rules to apply mechanically.

## 1. Model values with data classes and `val`

```kotlin
data class Money(val cents: Long, val currency: String)

fun discount(price: Money, cents: Long): Money =
    price.copy(cents = price.cents - cents)
```

Why: a `data class` states that the type primarily carries data. Kotlin generates structural equality, hashing, a readable string form, component functions, and `copy()`. Using `val` makes the intended state stable after construction, while `copy()` provides explicit value evolution.

Pros:

- Removes repetitive value-object machinery.
- Gives tests useful structural equality and readable failures.
- Encourages immutable transformations.

Cons:

- `copy()` is shallow, so referenced mutable objects remain shared.
- Large data classes can become weak domain models with too many unrelated fields.
- Generated equality includes only primary-constructor properties.

## 2. Replace overload families with default and named arguments

```kotlin
fun connect(
    host: String,
    port: Int = 443,
    secure: Boolean = true,
): String = "$host:$port secure=$secure"

val endpoint = connect(host = "service.internal", secure = false)
```

Why: defaults keep one canonical function, and named arguments reveal what otherwise-opaque values such as booleans mean at the call site.

Pros:

- Reduces overload count.
- Makes selected arguments readable and lets callers skip defaults.
- Keeps default behavior next to the parameter declaration.

Cons:

- Parameter names become meaningful API surface for Kotlin callers.
- Named arguments are unavailable when calling Java methods because JVM bytecode does not reliably retain parameter names.
- Too many optional parameters may signal that a configuration type would be clearer.

## 3. Use expression bodies with exhaustive `when`

```kotlin
enum class Access {
    ADMIN,
    MEMBER,
    GUEST,
}

fun permissions(access: Access): Set<String> = when (access) {
    Access.ADMIN -> setOf("read", "write", "delete")
    Access.MEMBER -> setOf("read", "write")
    Access.GUEST -> setOf("read")
}
```

Why: a function that calculates one value can say so directly. Because `when` is used as an expression over an enum, every constant must be handled, and no mutable result variable is needed.

Pros:

- Makes input-to-output logic easy to scan.
- Lets the compiler detect missing enum branches.
- Avoids assignment and early-return bookkeeping.

Cons:

- Long or deeply nested expressions become harder to read.
- Branches with several side effects hide the simple value-producing shape.
- Adding an enum constant intentionally breaks every exhaustive use until it is updated.

## 4. Compose nullable operations with safe calls and Elvis

```kotlin
data class User(val displayName: String?)

fun label(user: User?): String =
    user?.displayName
        ?.trim()
        ?.takeIf { it.isNotEmpty() }
        ?: "Anonymous"
```

Why: `?.` advances only while a value is non-null, and `?:` supplies the final fallback. The nullable path is visible in the type and flow without forcing a value through `!!`.

Pros:

- Keeps null handling explicit and checked by the compiler.
- Avoids nested null checks and temporary variables.
- Evaluates the fallback only when the left side is null.

Cons:

- A long chain can hide which operation produced null.
- One fallback may collapse distinct absence cases that the domain should model separately.
- Side effects inside nullable chains are easy to overlook.

## 5. Transform read-only collections with pipelines

```kotlin
data class Order(val total: Int, val paid: Boolean)

fun paidTotals(orders: List<Order>): List<Int> =
    orders
        .filter { it.paid }
        .map { it.total }
```

Why: collection operations describe what should be selected and transformed without exposing loop indexes, mutable accumulators, or mutation of the source collection.

Pros:

- Separates selection from transformation.
- Composes cleanly with grouping, sorting, and aggregation operations.
- Preserves the original collection.

Cons:

- Eager operations can allocate an intermediate collection at each stage.
- For very large pipelines, a `Sequence` or a single fused operation may use less memory.
- Dense chains with many lambdas can be harder to debug than named steps.

## 6. Add focused behavior with extension functions

```kotlin
fun String.isValidTag(): Boolean =
    isNotBlank() && all { it.isLetterOrDigit() || it == '-' }

val valid = "kotlin-2".isValidTag()
```

Why: an extension places a domain operation next to the type it acts on and gives callers member-like syntax without inheritance or modification of the original class.

Pros:

- Works with types that cannot be changed, including library types.
- Produces fluent call sites.
- Keeps reusable conversion and validation logic out of callers.

Cons:

- Extensions are resolved statically and do not provide polymorphic overriding.
- Broad or vaguely named extensions can pollute auto-completion and clash with imports.
- Member-like syntax can obscure that the function cannot access private state.

## 7. Represent closed outcomes with sealed types

```kotlin
sealed interface PaymentResult {
    data class Approved(val receiptId: String) : PaymentResult
    data class Declined(val reason: String) : PaymentResult
    data object Offline : PaymentResult
}

fun message(result: PaymentResult): String = when (result) {
    is PaymentResult.Approved -> "Receipt ${result.receiptId}"
    is PaymentResult.Declined -> "Declined: ${result.reason}"
    PaymentResult.Offline -> "Service unavailable"
}
```

Why: a sealed hierarchy models a finite set of distinct cases, each with its own data. An exhaustive `when` lets the compiler verify that every known result is handled.

Pros:

- Makes illegal outcome combinations difficult to represent.
- Carries case-specific data without nullable fields or status flags.
- Forces consumers to react when a new direct case is introduced.

Cons:

- The closed hierarchy is unsuitable for third-party extension points.
- Direct subclasses are constrained by package and module rules.
- Excessive subtype nesting can be heavier than an enum when cases carry no distinct data.

## 8. Defer and memoize work with `by lazy`

```kotlin
class WordIndex(words: List<String>) {
    private val words = words.toList()

    val byLength: Map<Int, List<String>> by lazy {
        words.groupBy { it.length }
    }
}
```

Why: `lazy` runs the initializer on first access, stores its result, and returns that same result on later access. Copying the input first keeps the cached index consistent with its source snapshot.

Pros:

- Avoids work when the property is never read.
- Centralizes one-time initialization at the property declaration.
- Uses synchronized initialization by default.

Cons:

- The cached value and captured objects remain retained.
- Default synchronization has overhead when single-thread access is guaranteed.
- It is wrong for values that must reflect changing input.

## 9. Bound resource lifetime with `use`

```kotlin
import java.nio.file.Files
import java.nio.file.Path

fun firstLine(path: Path): String? =
    Files.newBufferedReader(path).use { reader ->
        reader.readLine()
    }
```

Why: `use` closes an `AutoCloseable` resource after the block finishes, including when the block throws. It also returns the block result, so resource management fits naturally into an expression. This sample targets the JVM.

Pros:

- Makes cleanup deterministic.
- Keeps acquisition, use, and release in one lexical scope.
- Preserves a block failure and records a close failure as suppressed.

Cons:

- A lazy value returned from the block may try to read an already closed resource.
- Nested resources still require deliberate ordering.
- Long-running work inside the block keeps the resource open for the entire duration.

## 10. State contracts with `require` and `check`

```kotlin
class Counter(private val limit: Int) {
    private var value = 0

    init {
        require(limit > 0) { "Limit must be positive" }
    }

    fun increment(): Int {
        check(value < limit) { "Counter reached its limit" }
        return ++value
    }
}
```

Why: `require` communicates invalid input and throws `IllegalArgumentException`; `check` communicates invalid state and throws `IllegalStateException`. Their message lambdas run only on failure.

Pros:

- Documents executable preconditions beside the protected operation.
- Fails early with the conventional exception category.
- Supports compiler contracts such as smart casts after successful checks.

Cons:

- Exceptions are inappropriate for expected business outcomes that callers should handle normally.
- Vague messages make contract failures difficult to diagnose.
- Repeating checks at every layer can add noise without improving ownership of validation.

## Closing guidance

Prefer the smallest idiom that clarifies intent. A compact construct stops being idiomatic when it hides domain distinctions, resource lifetime, performance cost, or control flow. Kotlin's conventions also favor `val`, read-only collection interfaces, omitted `Unit`, and expression bodies for genuinely single-expression functions.

## Sources and links

1. [Kotlin documentation: Idioms](https://kotlinlang.org/docs/idioms.html)
2. [Kotlin documentation: Coding conventions](https://kotlinlang.org/docs/coding-conventions.html)
3. [Kotlin documentation: Data classes](https://kotlinlang.org/docs/data-classes.html)
4. [Kotlin documentation: Functions](https://kotlinlang.org/docs/functions.html)
5. [Kotlin documentation: Conditions and loops](https://kotlinlang.org/docs/control-flow.html)
6. [Kotlin documentation: Null safety](https://kotlinlang.org/docs/null-safety.html)
7. [Kotlin documentation: Scope functions](https://kotlinlang.org/docs/scope-functions.html)
8. [Kotlin documentation: Collection operations overview](https://kotlinlang.org/docs/collection-operations.html)
9. [Kotlin documentation: Filtering collections](https://kotlinlang.org/docs/collection-filtering.html)
10. [Kotlin documentation: Collection transformation operations](https://kotlinlang.org/docs/collection-transformations.html)
11. [Kotlin documentation: Extensions](https://kotlinlang.org/docs/extensions.html)
12. [Kotlin documentation: Sealed classes and interfaces](https://kotlinlang.org/docs/sealed-classes.html)
13. [Kotlin documentation: Delegated properties](https://kotlinlang.org/docs/delegated-properties.html)
14. [Kotlin standard library API: `use`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/use.html)
15. [Kotlin documentation: Exception and error handling](https://kotlinlang.org/docs/exceptions.html)
