# Idiomatic Zig

Idiomatic Zig makes mutability, failure, allocation, and compile-time behavior explicit. The following ten idioms target Zig 0.16.0 and use only the standard library.

## 1. Default to const and introduce var only for mutation

~~~zig
fn sum(values: []const u32) u32 {
    var total: u32 = 0;
    for (values) |value| {
        total += value;
    }
    return total;
}

const values = [_]u32{ 10, 20, 30 };
const total = sum(&values);
~~~

Why: const prevents rebinding and makes stable local state obvious. var is required when a value changes, so mutation remains visible at the declaration rather than being a property readers must infer.

Pros:

- Makes local state transitions easy to identify.
- Lets the compiler reject accidental reassignment.
- Works with type inference to keep declarations compact.

Cons:

- const does not make referenced memory immutable unless the pointer or slice type also says const.
- A mutable value may still be hidden behind a function call.
- Overly broad scopes make even explicit mutation harder to track.

## 2. Accept slices instead of pointer-and-length pairs

~~~zig
fn firstPositive(values: []const i32) ?i32 {
    for (values) |value| {
        if (value > 0) return value;
    }
    return null;
}

const values = [_]i32{ -4, 0, 9 };
const found = firstPositive(values[0..]);
~~~

Why: a slice carries a pointer and length together. A []const T parameter accepts mutable or immutable backing storage while promising that the function will not modify elements through that slice.

Pros:

- Preserves bounds information.
- Accepts arrays and subslices without allocation.
- Makes element mutability part of the type.

Cons:

- A slice does not own or extend the lifetime of its backing memory.
- Returning a slice requires a clear lifetime relationship.
- A sentinel-terminated protocol may need a sentinel slice instead.

## 3. Model absence with optionals

~~~zig
fn displayName(name: ?[]const u8) []const u8 {
    return if (name) |value| value else "Anonymous";
}

const known = displayName("Ada");
const missing = displayName(null);
~~~

Why: ?T represents either a T value or null. Optional capture unwraps the value only inside the successful branch, preventing ordinary non-optional values and pointers from silently carrying null.

Pros:

- Makes absence visible in the type.
- Avoids sentinel values.
- Supports concise if, while, and orelse unwrapping.

Cons:

- An optional carries no reason for absence.
- Repeated unwrapping can signal that validation belongs at an earlier boundary.
- Optional pointers require attention because both the pointer and referenced data have lifetimes.

## 4. Return error unions and propagate with try

~~~zig
const std = @import("std");

fn parsePort(text: []const u8) !u16 {
    const port = try std.fmt.parseInt(u16, text, 10);
    if (port == 0) return error.InvalidPort;
    return port;
}

fn doubledPort(text: []const u8) !u32 {
    const port = try parsePort(text);
    return @as(u32, port) * 2;
}
~~~

Why: an error union states that a function returns either a value or an error. try unwraps the success value and returns the error immediately, keeping the main path flat without discarding failure information.

Pros:

- Makes recoverable failure part of the signature.
- Keeps propagation concise.
- Allows inferred or explicit error sets according to the API boundary.

Cons:

- An inferred error set can become unstable in a public API.
- Propagating every low-level error may expose unwanted implementation detail.
- Errors do not carry arbitrary payload data.

## 5. Handle selected errors with catch

~~~zig
const std = @import("std");

fn portOrDefault(text: []const u8) u16 {
    return std.fmt.parseInt(u16, text, 10) catch 8080;
}

fn portOrReport(text: []const u8) !u16 {
    return std.fmt.parseInt(u16, text, 10) catch |err| switch (err) {
        error.InvalidCharacter => error.InvalidPortText,
        error.Overflow => error.PortOutOfRange,
    };
}
~~~

Why: catch handles an error union at the expression where policy is known. It can supply a fallback, return a translated error, or inspect the captured error with a switch.

Pros:

- Keeps recovery close to the operation.
- Supports exhaustive handling of a known error set.
- Makes error translation explicit at abstraction boundaries.

Cons:

- A fallback can conceal bad input when failure should remain visible.
- Catching any error with one value loses distinctions.
- Error-set changes can require updates to exhaustive switches.

## 6. Tie unconditional cleanup to scope with defer

~~~zig
const Guard = struct {
    active: bool,

    fn acquire() Guard {
        return .{ .active = true };
    }

    fn release(self: *Guard) void {
        self.active = false;
    }
};

fn guardedWork() bool {
    var guard = Guard.acquire();
    defer guard.release();
    return guard.active;
}
~~~

Why: defer schedules cleanup for the end of the current scope, regardless of which return path is taken. Placing it immediately after acquisition keeps ownership and release policy adjacent.

Pros:

- Prevents cleanup from being skipped by an early return.
- Runs in reverse declaration order for nested resources.
- Requires no heap allocation or runtime exception machinery.

Cons:

- Cleanup happens at scope exit, which may be later than the final use.
- A wide scope can retain a resource longer than intended.
- Deferred expressions cannot return a cleanup failure normally.

## 7. Roll back partial acquisition with errdefer

~~~zig
const std = @import("std");

fn zeroedBuffer(allocator: std.mem.Allocator, size: usize) ![]u8 {
    const data = try allocator.alloc(u8, size);
    errdefer allocator.free(data);

    if (size == 0) return error.EmptyBuffer;
    @memset(data, 0);
    return data;
}
~~~

Why: errdefer runs only when the current function returns an error. It is suited to undoing successful partial work while transferring ownership to the caller on success.

Pros:

- Keeps rollback next to the acquisition it protects.
- Simplifies functions with several fallible construction steps.
- Avoids freeing successfully returned memory.

Cons:

- The caller still needs a documented ownership and release rule.
- Several errdefer statements run in reverse order and require deliberate ordering.
- It does not run for traps or forced process termination.

## 8. Pass allocators explicitly

~~~zig
const std = @import("std");

fn ownedLabel(allocator: std.mem.Allocator, label: []const u8) ![]u8 {
    return allocator.dupe(u8, label);
}

fn useLabel(allocator: std.mem.Allocator) !usize {
    const label = try ownedLabel(allocator, "zig");
    defer allocator.free(label);
    return label.len;
}
~~~

Why: Zig performs no implicit heap allocation. Receiving an allocator makes allocation policy, failure, ownership transfer, and testability visible in the API.

Pros:

- Lets callers choose lifetime and allocation strategy.
- Makes allocation failure explicit.
- Avoids a hidden process-wide allocator policy.

Cons:

- Allocator parameters and cleanup add ceremony.
- Returning allocated memory requires precise ownership documentation.
- Mixing allocators during release is invalid.

## 9. Represent closed states with tagged unions

~~~zig
const FetchResult = union(enum) {
    ready: []const u8,
    missing,
    failed: anyerror,
};

fn status(result: FetchResult) []const u8 {
    return switch (result) {
        .ready => |value| value,
        .missing => "missing",
        .failed => "failed",
    };
}
~~~

Why: a tagged union stores one active payload and its tag. A switch can capture the payload for each case and must cover the complete set of tags.

Pros:

- Keeps payload data specific to the active state.
- Enables compiler-checked exhaustive handling.
- Avoids manual tags and unsafe field access.

Cons:

- Adding a field requires updating exhaustive switches.
- anyerror is broad; a focused error set is better when practical.
- The union size follows its largest payload plus tag and alignment.

## 10. Use comptime parameters for type-safe generic code

~~~zig
fn maximum(comptime T: type, left: T, right: T) T {
    return if (left > right) left else right;
}

const integerMax = maximum(i32, 8, 13);
const floatMax = maximum(f64, 2.5, 1.5);
~~~

Why: a comptime type parameter creates specialized, checked code for each supplied type. Generic behavior uses the same language constructs as ordinary functions instead of a separate template language.

Pros:

- Produces type-safe specialization without runtime type metadata.
- Allows values as well as types to guide compilation.
- Enables compile-time validation and reflection.

Cons:

- Each specialization can increase compile time and binary size.
- Invalid operations may produce deep compile-time diagnostics.
- Excessive compile-time execution can make builds difficult to understand.

## Practical guidance

Use const unless mutation is required, slices for bounded borrowed data, optionals for absence, and error unions for recoverable failure. Put defer or errdefer immediately after acquisition. Make every allocation policy and ownership transfer explicit, and use tagged unions and comptime only where their type-level precision improves the interface.

## Sources

1. [Zig 0.16.0 Language Reference](https://ziglang.org/documentation/0.16.0/)
2. [Zig Language Overview](https://ziglang.org/learn/overview/)
3. [Zig 0.16.0 Standard Library](https://ziglang.org/documentation/0.16.0/std/)
4. [Zig 0.16.0 Release Notes](https://ziglang.org/download/0.16.0/release-notes.html)
