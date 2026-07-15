# Idiomatic Python: 10 Practical Patterns

Idiomatic Python uses the language's built-in protocols and standard tools so intent is visible with little ceremony. The goal is not to write the fewest characters. It is to make the normal path obvious, handle edge cases deliberately, and avoid rebuilding behavior Python already provides.

The code below targets modern Python 3. `zip(..., strict=True)` requires Python 3.10 or newer.

## 1. Test truth values directly

```python
pending_jobs = []

if not pending_jobs:
    print("No work pending")
```

**Why it is idiomatic:** Python defines truth-value behavior for every object. Empty collections, zero, `None`, and `False` are false in a condition, so `if not pending_jobs` states the intent more directly than comparing its length with zero. PEP 8 specifically recommends truth-value testing for sequences. [1][2]

**Pros:** Concise, readable, and works across collection types.

**Cons:** It deliberately treats several distinct values alike. When `None` has a different meaning from an empty collection, use `value is None` instead.

## 2. Use `enumerate()` when the position matters

```python
languages = ["Python", "Rust", "Go"]

for rank, language in enumerate(languages, start=1):
    print(f"{rank}. {language}")
```

**Why it is idiomatic:** `enumerate()` produces the counter and value together. It avoids a manually maintained counter and avoids indexing back into the collection. Its `start` argument also expresses one-based display numbering directly. [3][4]

**Pros:** Removes counter bookkeeping, works with any iterable, and keeps position and value synchronized.

**Cons:** The result is a single-pass iterator. Do not add it when the position is unused, and remember that its counter is not necessarily a persistent identifier for the item.

## 3. Pair related iterables with `zip()`

```python
names = ["Ada", "Grace", "Guido"]
scores = [98, 96, 94]

for name, score in zip(names, scores, strict=True):
    print(f"{name}: {score}")
```

**Why it is idiomatic:** `zip()` models parallel traversal directly. When equal lengths are an invariant, `strict=True` turns silent truncation into a `ValueError`, making bad input fail near its source. [3][5]

**Pros:** Eliminates index arithmetic, accepts arbitrary iterables, is lazy, and can validate equal lengths.

**Cons:** It is single-pass. Without `strict=True`, it stops at the shortest input. With strict mode, a length mismatch raises only when iteration reaches the mismatch.

## 4. Unpack structured values

```python
record = ("Ada", "Lovelace", 1815, "mathematician", "writer")
first_name, last_name, birth_year, *roles = record

print(first_name, last_name, birth_year, roles)
```

**Why it is idiomatic:** Unpacking binds names to the structure of a value in one statement. A starred target captures the remaining items and avoids repeated numeric indexing. [6]

**Pros:** Documents the expected shape, produces meaningful names, and supports swapping or returning multiple values cleanly.

**Cons:** A shape mismatch raises `ValueError`. A starred target always receives a new list, and excessive unpacking can hide that the underlying data deserves a named type.

## 5. Build simple transformed collections with comprehensions

```python
scores = {"Ada": 98, "Grace": 96, "Charles": 64}
passing = [name for name, score in scores.items() if score >= 70]

print(passing)
```

**Why it is idiomatic:** A comprehension keeps selection, transformation, and collection construction in one readable expression. Python's tutorial recommends it as the concise way to create a new list from an iterable. [4]

**Pros:** Expresses a simple data transformation directly, avoids temporary mutation, and keeps loop variables local to the comprehension.

**Cons:** It eagerly creates the entire collection. Multiple nested loops, many conditions, or side effects make a normal loop clearer.

## 6. Stream values with a generator expression

```python
numbers = range(1_000_000)
sum_of_squares = sum(number * number for number in numbers)

print(sum_of_squares)
```

**Why it is idiomatic:** A generator expression feeds values to a consumer as needed instead of first allocating a full list. Python specifies that its items are evaluated lazily during iteration. [7]

**Pros:** Uses bounded additional memory, composes well with `sum()`, `any()`, `all()`, `min()`, and `max()`, and can stop early with short-circuiting consumers.

**Cons:** A generator is single-pass, has no length or random access, and can make failures appear later than the line where it was created.

## 7. Manage resources with `with`

```python
from pathlib import Path

path = Path("settings.txt")

with path.open(encoding="utf-8") as handle:
    content = handle.read()

print(content)
```

**Why it is idiomatic:** A context manager owns setup and cleanup around a block. The `with` statement guarantees that its exit operation runs after a successful entry, including when the block raises an exception. [1][8]

**Pros:** Makes the resource lifetime visible, reliably closes files and locks, and avoids duplicated cleanup logic.

**Cons:** The managed resource is no longer safe to use after the block. A context manager can also suppress exceptions, so custom managers need clear behavior.

## 8. Catch the operation that can fail

```python
def parse_port(value):
    try:
        return int(value)
    except ValueError:
        return 8000


port = parse_port("not-a-port")
print(port)
```

**Why it is idiomatic:** Python names this style EAFP: perform the intended operation and catch the specific failure. Keeping the `try` body small ensures the handler covers only the operation whose failure is expected. [9]

**Pros:** Avoids duplicated precondition checks, handles conversion according to the actual operation, and is often clear when failure is uncommon.

**Cons:** Exceptions are a poor substitute for ordinary branching when failure is frequent. Broad handlers can conceal defects, and callers may need invalid input to remain an error instead of receiving a fallback.

## 9. Use `dict.get()` for a simple default

```python
settings = {"theme": "dark"}
theme = settings.get("theme", "light")
font_size = settings.get("font_size", 14)

print(theme, font_size)
```

**Why it is idiomatic:** `dict.get()` performs a lookup and returns a chosen default when the key is absent, without separate membership testing or exception handling. [10]

**Pros:** Compact, performs one lookup, and makes the fallback adjacent to the key.

**Cons:** It cannot distinguish a missing key from a stored value equal to the default. The default expression is evaluated before the call, so expensive or stateful defaults need another approach.

## 10. Format text with f-strings

```python
user = "Ada"
completed = 0.875
message = f"{user} completed {completed:.1%}"

print(message)
```

**Why it is idiomatic:** An f-string places expressions beside the surrounding text and supports Python's format specification language. Here, `.1%` converts the ratio to a percentage with one decimal place. [11]

**Pros:** Readable, concise, supports expressions and rich formatting, and avoids keeping placeholders synchronized with a separate argument list.

**Cons:** Expressions run immediately, so f-strings are not reusable templates. Complex logic inside replacement fields harms readability and should be computed first.

## Sources

1. [PEP 8: Programming Recommendations](https://peps.python.org/pep-0008/#programming-recommendations)
2. [Python Standard Library: Truth Value Testing](https://docs.python.org/3/library/stdtypes.html#truth-value-testing)
3. [Python Tutorial: Looping Techniques](https://docs.python.org/3/tutorial/datastructures.html#looping-techniques)
4. [Python Tutorial: List Comprehensions](https://docs.python.org/3/tutorial/datastructures.html#list-comprehensions)
5. [Python Standard Library: `zip()`](https://docs.python.org/3/library/functions.html#zip)
6. [Python Language Reference: Assignment Statements](https://docs.python.org/3/reference/simple_stmts.html#assignment-statements)
7. [Python Language Reference: Generator Expressions](https://docs.python.org/3/reference/expressions.html#generator-expressions)
8. [Python Language Reference: The `with` Statement](https://docs.python.org/3/reference/compound_stmts.html#the-with-statement)
9. [Python Glossary: EAFP](https://docs.python.org/3/glossary.html#term-EAFP)
10. [Python Standard Library: `dict.get()`](https://docs.python.org/3/library/stdtypes.html#dict.get)
11. [Python Tutorial: Formatted String Literals](https://docs.python.org/3/tutorial/inputoutput.html#formatted-string-literals)
