# Idiomatic Java

Idiomatic modern Java uses small immutable models, explicit absence and failure, standard collection operations, and resource lifetimes enforced by syntax. The following ten idioms target Java 25 while avoiding preview features and external libraries.

## 1. Model immutable data with records

~~~java
record Customer(String name, String email) {
    public Customer {
        name = name.trim();
        email = email.toLowerCase();
        if (name.isEmpty() || !email.contains("@")) {
            throw new IllegalArgumentException("Invalid customer");
        }
    }
}

var customer = new Customer(" Ada ", "ADA@ACME.TEST");
~~~

Why: a record declares a transparent carrier for immutable data. Java supplies final fields, accessors, structural equality, hashing, and a readable string representation. A compact constructor keeps normalization and invariants at the construction boundary.

Pros:

- Removes repetitive value-object code.
- Gives collections and tests correct value semantics.
- Keeps the complete state visible in one declaration.

Cons:

- Immutability is shallow when a component refers to a mutable object.
- Records cannot extend another class.
- A large record can still become an unfocused data container.

## 2. Represent closed alternatives with sealed types and pattern switches

~~~java
sealed interface PaymentStatus {
    record Pending() implements PaymentStatus {}
    record Settled(String receipt) implements PaymentStatus {}
    record Rejected(String reason) implements PaymentStatus {}
}

static String label(PaymentStatus status) {
    return switch (status) {
        case PaymentStatus.Pending ignored -> "Payment pending";
        case PaymentStatus.Settled(var receipt) -> "Receipt: " + receipt;
        case PaymentStatus.Rejected(var reason) -> "Rejected: " + reason;
    };
}
~~~

Why: a sealed hierarchy defines the permitted cases, and record patterns expose case-specific data. A switch expression over that closed hierarchy can be exhaustive without a default branch.

Pros:

- Makes invalid combinations difficult to construct.
- Keeps case-specific fields out of unrelated states.
- Causes a compiler error when a new case is not handled.

Cons:

- A closed hierarchy is unsuitable for open extension points.
- Adding a case intentionally affects every exhaustive switch.
- Many tiny record types add files unless they are nested deliberately.

## 3. Publish immutable collection snapshots

~~~java
import java.util.List;

final class Catalog {
    private final List<String> products;

    Catalog(List<String> products) {
        this.products = List.copyOf(products);
    }

    List<String> products() {
        return products;
    }
}
~~~

Why: List.copyOf creates an unmodifiable snapshot and rejects null elements. The class neither retains a caller-owned mutable list nor exposes mutable internal state.

Pros:

- Prevents changes through shared collection references.
- Makes ownership at the constructor boundary clear.
- Avoids a second copy when the input is already a suitable immutable list.

Cons:

- The elements themselves may still be mutable.
- Copying a large mutable input has a linear cost.
- Null elements fail immediately rather than being preserved.

## 4. Express collection transformations with streams

~~~java
import java.util.List;

record Order(long cents, boolean paid) {}

static List<Long> paidTotals(List<Order> orders) {
    return orders.stream()
            .filter(Order::paid)
            .map(Order::cents)
            .toList();
}
~~~

Why: a stream pipeline states selection and transformation without manual indexing or mutation. Method references keep the operations focused, and toList returns an unmodifiable result.

Pros:

- Makes a multi-stage transformation easy to scan.
- Composes filtering, mapping, grouping, and reduction.
- Avoids a mutable accumulator in application code.

Cons:

- A loop is often clearer for complex branching or checked exceptions.
- Boxing primitive values can add allocation.
- Parallel streams require careful measurement and thread-safety analysis.

## 5. Return Optional for a possibly absent result

~~~java
import java.util.Map;
import java.util.Optional;

record User(String id, String displayName) {}

static Optional<User> findUser(Map<String, User> users, String id) {
    return Optional.ofNullable(users.get(id));
}

static String displayName(Map<String, User> users, String id) {
    return findUser(users, id)
            .map(User::displayName)
            .orElse("Anonymous");
}
~~~

Why: Optional makes absence part of a return type and provides operations for transforming or defaulting the present value. It works best as a return value rather than as a field, parameter, or substitute for every nullable local variable.

Pros:

- Forces callers to acknowledge an absent result.
- Supports concise transformation without explicit null checks.
- Avoids sentinel values.

Cons:

- It carries no reason for absence.
- Using Optional in fields and parameters often adds ceremony.
- Calling get without proving presence merely moves the failure.

## 6. Bind resource cleanup with try-with-resources

~~~java
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

static long lineCount(Path path) throws IOException {
    try (var lines = Files.lines(path)) {
        return lines.count();
    }
}
~~~

Why: try-with-resources closes every AutoCloseable value after the block, including when computation fails. A stream backed by a file owns an open resource and therefore needs this bounded lifetime.

Pros:

- Makes cleanup reliable across all exits.
- Keeps acquisition and release in one lexical scope.
- Preserves close failures as suppressed exceptions when another failure is active.

Cons:

- A lazy object returned from the block may depend on a closed resource.
- Resources close in reverse declaration order.
- Long work inside the block retains the resource for its full duration.

## 7. Use Map merge and computeIfAbsent for atomic map operations

~~~java
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

static Map<String, Integer> frequencies(List<String> words) {
    var counts = new HashMap<String, Integer>();
    words.forEach(word -> counts.merge(word, 1, Integer::sum));
    return Map.copyOf(counts);
}

static void addToGroup(Map<String, List<String>> groups, String key, String value) {
    groups.computeIfAbsent(key, ignored -> new ArrayList<>()).add(value);
}
~~~

Why: merge expresses insert-or-combine, while computeIfAbsent expresses lazy initialization. Both avoid a separate presence check and repeated lookup.

Pros:

- States the map update policy directly.
- Performs the lookup and update through one API call.
- Works with concurrent map implementations according to their contracts.

Cons:

- Mapping and remapping functions should be short and free of surprising side effects.
- A mutable value returned by computeIfAbsent still needs synchronization when shared.
- Null keys and values depend on the concrete map implementation.

## 8. Accept standard functional interfaces

~~~java
import java.util.List;
import java.util.function.Predicate;

static <T> List<T> matching(List<T> values, Predicate<? super T> condition) {
    return values.stream().filter(condition).toList();
}

var longNames = matching(List.of("Ada", "Grace", "Edsger"), name -> name.length() > 4);
~~~

Why: standard functional interfaces let callers supply behavior with lambdas or method references. The lower-bounded wildcard accepts predicates defined for T or one of its supertypes.

Pros:

- Avoids defining a new interface for a familiar function shape.
- Keeps policy separate from traversal.
- Interoperates directly with collection and stream APIs.

Cons:

- Generic interfaces such as Predicate do not describe domain intent by name.
- Checked exceptions need an explicit policy.
- Long lambdas hide behavior and deserve a named method.

## 9. Put constant-specific behavior on enums

~~~java
enum Operation {
    ADD {
        int apply(int left, int right) {
            return left + right;
        }
    },
    MULTIPLY {
        int apply(int left, int right) {
            return left * right;
        }
    };

    abstract int apply(int left, int right);
}

var result = Operation.MULTIPLY.apply(6, 7);
~~~

Why: an enum is a type-safe fixed set of instances. Constant-specific method bodies keep behavior beside each value and remove switches scattered across callers.

Pros:

- Combines identity and behavior in one closed type.
- Prevents invalid string constants.
- Supports exhaustive switch expressions when callers do need branching.

Cons:

- Enums are not suitable when variants must be added outside the declaring code.
- Stateful enum instances are global singletons and require care.
- Large constant bodies can make the declaration difficult to navigate.

## 10. Use one virtual thread per blocking task

~~~java
import java.util.concurrent.Executors;

static String load(String key) {
    return key.toUpperCase();
}

static String loadBoth() throws Exception {
    try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
        var first = executor.submit(() -> load("first"));
        var second = executor.submit(() -> load("second"));
        return first.get() + second.get();
    }
}
~~~

Why: virtual threads let straightforward blocking code scale to many concurrent I/O-bound tasks. A per-task executor creates a new virtual thread for each submission and closes cleanly through try-with-resources.

Pros:

- Preserves familiar sequential code and stack traces.
- Scales high-throughput workloads that spend time waiting on I/O.
- Avoids choosing a virtual-thread pool size.

Cons:

- Virtual threads do not make CPU-bound computation faster.
- Scarce downstream resources still need explicit admission limits.
- Thread-local state and pinned operations require attention at high concurrency.

## Practical guidance

Start with immutable data and collection snapshots, closed types for closed domains, and explicit return types for absence. Use streams when they make a transformation clearer, try-with-resources for every closeable lifetime, and virtual threads when blocking I/O concurrency is the measured constraint. Prefer standard interfaces and collection operations before creating project-specific abstractions.

## Sources

1. [Dev.java: Records](https://dev.java/learn/records/)
2. [Dev.java: Sealed Classes](https://dev.java/learn/inheritance/sealed-classes-and-interfaces/)
3. [Dev.java: Pattern Matching](https://dev.java/learn/pattern-matching/)
4. [Oracle JDK 25 Guide: Unmodifiable Collections](https://docs.oracle.com/en/java/javase/25/core/creating-immutable-lists-sets-and-maps.html)
5. [Dev.java: The Stream API](https://dev.java/learn/api/streams/)
6. [Java SE 25 API: Optional](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Optional.html)
7. [Dev.java: Releasing Resources](https://dev.java/learn/java-io/reading-writing/common-operations/)
8. [Java SE 25 API: Map](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Map.html)
9. [Dev.java: Lambda Expressions](https://dev.java/learn/lambdas/)
10. [Java Language Specification: Enum Classes](https://docs.oracle.com/javase/specs/jls/se25/html/jls-8.html#jls-8.9)
11. [Oracle JDK 25 Guide: Virtual Threads](https://docs.oracle.com/en/java/javase/25/core/virtual-threads.html)
