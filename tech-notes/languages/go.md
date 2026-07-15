# Idiomatic Go: 10 Practical Patterns

Idiomatic Go favors clear control flow, explicit ownership, small APIs, and types that work with minimal setup. These patterns draw mainly from the Go team's documentation, blog, and review guidance. `Effective Go` remains useful for the core language, but the Go team notes that it was written in 2009 and is not actively updated, so newer guidance is included where behavior and conventions have evolved.

## 1. Handle errors early and keep the successful path flat

```go
package port

import (
	"fmt"
	"strconv"
)

func Parse(value string) (int, error) {
	port, err := strconv.Atoi(value)
	if err != nil {
		return 0, fmt.Errorf("parse port: %w", err)
	}
	if port < 1 || port > 65535 {
		return 0, fmt.Errorf("port out of range: %d", port)
	}
	return port, nil
}
```

Why it is idiomatic: Go code normally checks an error immediately, returns or continues on failure, and leaves the main path at the lowest indentation level. This makes the function easy to scan from top to bottom.

Pros:

- Keeps failure handling close to the operation that failed.
- Prevents deeply nested control flow.
- Makes every failure path explicit.

Cons:

- Repeated `if err != nil` blocks add visual weight.
- Careless early returns can skip cleanup unless resources use `defer`.

Sources: [1], [2].

## 2. Add context to errors and preserve inspectable causes

```go
package users

import (
	"errors"
	"fmt"
)

var ErrNotFound = errors.New("user not found")

func Lookup(id string, names map[string]string) (string, error) {
	name, ok := names[id]
	if !ok {
		return "", fmt.Errorf("lookup user %q: %w", id, ErrNotFound)
	}
	return name, nil
}

func Missing(err error) bool {
	return errors.Is(err, ErrNotFound)
}
```

Why it is idiomatic: errors are values. Wrapping with `%w` adds useful operation-level context while allowing callers to use `errors.Is` or `errors.As` instead of comparing text.

Pros:

- Produces useful error chains without losing the root cause.
- Lets callers branch on stable error identities or types.
- Avoids brittle string matching.

Cons:

- Wrapping exposes the wrapped error as part of the API contract.
- Excessive wrapping can produce noisy messages.
- Not every internal error should be visible to callers.

Sources: [3].

## 3. Place cleanup next to resource acquisition with `defer`

```go
package files

import (
	"io"
	"os"
)

func Read(path string) ([]byte, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()
	return io.ReadAll(file)
}
```

Why it is idiomatic: once a resource has been acquired successfully, deferring its release makes cleanup independent of later return paths. The acquisition and cleanup policy remain visibly paired.

Pros:

- Reduces resource leaks when functions gain new return paths.
- Keeps cleanup close to acquisition.
- Runs cleanup during normal returns and stack unwinding.

Cons:

- A deferred call runs at function exit, not block exit.
- Defers inside a long loop can retain resources longer than intended.
- Ignoring a close error is unsuitable when finalization can fail, especially for writes.

Sources: [1], [4].

## 4. Design types with useful zero values

```go
package counter

import "sync"

type Counter struct {
	mu     sync.Mutex
	values map[string]int
}

func (c *Counter) Increment(key string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.values == nil {
		c.values = make(map[string]int)
	}
	c.values[key]++
}

func (c *Counter) Value(key string) int {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.values[key]
}
```

Usage starts with `var c Counter`; no constructor is required. A zero `sync.Mutex` is unlocked, reading a nil map is safe, and the first mutation initializes the map.

Why it is idiomatic: useful zero values remove mandatory initialization protocols and make embedding and composition easier. Constructors remain appropriate when a valid value needs dependencies or invariants that zero values cannot supply.

Pros:

- Reduces setup and constructor boilerplate.
- Makes values safer in structs, arrays, and tests.
- Supports gradual initialization.

Cons:

- Lazy initialization adds branches and synchronization concerns.
- Some types cannot have a meaningful zero state.
- Values containing a mutex must not be copied after first use.

Sources: [1].

## 5. Use the comma-ok form when absence differs from a zero value

```go
package services

var ports = map[string]int{
	"http":  80,
	"https": 443,
	"local": 0,
}

func Port(name string) (int, bool) {
	port, ok := ports[name]
	return port, ok
}
```

Why it is idiomatic: a missing map key returns the element type's zero value. The second result distinguishes a stored zero from an absent key without a sentinel value or a separate lookup.

Pros:

- Expresses presence directly.
- Avoids sentinel values.
- Performs one map lookup.

Cons:

- Callers must remember to inspect the boolean when absence matters.
- A boolean alone carries no diagnostic context.
- Returning `(value, error)` may be clearer when lookup failure needs explanation.

Sources: [1].

## 6. Iterate with `range` and grow slices with `append`

```go
package numbers

func Positive(values []int) []int {
	var result []int
	for _, value := range values {
		if value > 0 {
			result = append(result, value)
		}
	}
	return result
}
```

Why it is idiomatic: `range` expresses traversal without manual index bookkeeping, while `append` manages slice growth. Starting with a nil slice is valid and avoids allocation when there are no matches.

Pros:

- Is concise and easy to read.
- Avoids off-by-one indexing errors.
- Allocates only when a value is retained.

Cons:

- Repeated growth may allocate several backing arrays when the final size is predictable.
- A nil result and an allocated empty slice can encode differently in formats such as JSON.
- `range` copies each element value, which matters for large structs.

Sources: [1], [2].

## 7. Define small interfaces in the consuming package

```go
package greeting

import "fmt"

type User struct {
	Name string
}

type UserFinder interface {
	FindUser(id string) (User, error)
}

func Message(finder UserFinder, id string) (string, error) {
	user, err := finder.FindUser(id)
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("hello, %s", user.Name), nil
}
```

Why it is idiomatic: Go interfaces describe behavior implicitly. A consumer can declare only the capability it needs, while providers return concrete types and gain methods later without changing that consumer.

Pros:

- Keeps contracts narrow and easy to satisfy.
- Decouples consumers from provider implementations.
- Supports focused test substitutes without framework dependencies.

Cons:

- Premature interfaces add abstraction without value.
- Many tiny interfaces can fragment an API.
- Returning an interface from a provider can unnecessarily hide concrete capabilities.

Sources: [1], [2].

## 8. Pass `context.Context` explicitly as the first parameter

```go
package fetch

import (
	"context"
	"io"
	"net/http"
)

func Get(ctx context.Context, client *http.Client, url string) ([]byte, error) {
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return nil, err
	}
	response, err := client.Do(request)
	if err != nil {
		return nil, err
	}
	defer response.Body.Close()
	return io.ReadAll(response.Body)
}
```

Why it is idiomatic: context carries cancellation, deadlines, and request-scoped values across API boundaries. Passing it explicitly makes the lifetime visible and avoids storing one request's state in a long-lived struct.

Pros:

- Propagates cancellation through call chains.
- Gives blocking work a common deadline mechanism.
- Makes request lifetime part of the function contract.

Cons:

- Adds a parameter throughout the call chain.
- Using context for ordinary optional parameters weakens type safety.
- Cancellation only works when downstream operations observe the context.

Sources: [2], [5].

## 9. Give goroutines explicit lifetimes and channel ownership

```go
package pipeline

import "context"

func Squares(ctx context.Context, values []int) <-chan int {
	out := make(chan int)
	go func() {
		defer close(out)
		for _, value := range values {
			select {
			case out <- value * value:
			case <-ctx.Done():
				return
			}
		}
	}()
	return out
}
```

The producer owns and closes `out`; callers only receive from it. Cancellation gives the goroutine an exit path if a caller stops receiving early.

Why it is idiomatic: directional channels document ownership in the type system, the sender closes its outbound channel, and cancellation prevents blocked goroutines from leaking.

Pros:

- Makes send and receive responsibilities explicit.
- Allows consumers to use `range` until completion.
- Provides a defined shutdown path.

Cons:

- A goroutine and channel are unnecessary for purely synchronous work.
- Callers that abandon the stream must cancel the context.
- Closing from the wrong side or closing twice panics.

Sources: [2], [6], [7].

## 10. Use table-driven tests for repeated behavior

```go
package slug

import (
	"strings"
	"testing"
)

func Normalize(value string) string {
	return strings.ToLower(strings.TrimSpace(value))
}

func TestNormalize(t *testing.T) {
	tests := []struct {
		name string
		in   string
		want string
	}{
		{name: "spaces", in: "  Go  ", want: "go"},
		{name: "mixed case", in: "GoLang", want: "golang"},
		{name: "empty", in: "", want: ""},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			got := Normalize(test.in)
			if got != test.want {
				t.Fatalf("Normalize(%q) = %q; want %q", test.in, got, test.want)
			}
		})
	}
}
```

Why it is idiomatic: each row contains inputs and expected results, while one carefully written loop applies the same assertion structure. Named subtests make failures easy to locate and allow targeted runs.

Pros:

- Removes repeated test scaffolding.
- Makes adding cases cheap.
- Produces clear, searchable subtest names.

Cons:

- Large tables can obscure scenario-specific setup.
- One test loop may become complicated when rows need different behavior.
- Poor failure messages make table-driven tests hard to diagnose.

Sources: [2], [8].

## Source notes and links

1. [Effective Go](https://go.dev/doc/effective_go) covers early error handling, `defer`, useful zero values, map presence checks, `range`, slices, and small interfaces. Its central aim is “clear, idiomatic Go code.”
2. [Go Code Review Comments](https://go.dev/wiki/CodeReviewComments) supplements `Effective Go` with guidance on flat error flow, interface ownership, contexts, goroutine lifetimes, nil slices, and useful test failures.
3. [Working with Errors in Go 1.13](https://go.dev/blog/go1.13-errors) explains error chains, `%w`, `errors.Is`, `errors.As`, and the API tradeoff created by wrapping.
4. [Defer, Panic, and Recover](https://go.dev/blog/defer-panic-and-recover) states that defer is commonly used to simplify cleanup and explains its execution rules.
5. [Contexts and structs](https://go.dev/blog/context-and-structs) recommends passing context to each operation instead of storing it in a struct.
6. [Go Concurrency Patterns: Pipelines and cancellation](https://go.dev/blog/pipelines) says pipeline stages close outbound channels and keep receiving until inbound channels close or senders are unblocked.
7. [Use a sync.Mutex or a channel?](https://go.dev/wiki/MutexOrChannel) recommends choosing the simpler mechanism: channels for ownership transfer and asynchronous results, mutexes for state such as caches.
8. [Table-driven tests](https://go.dev/wiki/TableDrivenTests) explains how rows of inputs and expected results reduce duplication and improve failure identification.
