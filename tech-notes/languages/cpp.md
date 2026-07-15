# Idiomatic C++

Idiomatic modern C++ uses value semantics, deterministic resource management, explicit ownership, bounded views, and compile-time constraints. These ten idioms target C++20 and rely only on the standard library.

## 1. Return values instead of transferring ownership manually

~~~cpp
#include <string>
#include <vector>

std::vector<std::string> active_names(
    const std::vector<std::string>& names
) {
    std::vector<std::string> result;
    result.reserve(names.size());

    for (const auto& name : names) {
        if (!name.empty()) {
            result.push_back(name);
        }
    }

    return result;
}
~~~

Why: standard containers own their elements and clean them up automatically. Returning by value gives the caller clear ownership while copy elision and move semantics avoid unnecessary copying.

Pros:

- Makes ownership transfer unambiguous.
- Avoids explicit allocation and deletion.
- Keeps failure cleanup automatic.

Cons:

- Copying can still occur when elision and moves do not apply.
- Large retained capacity may exceed what the caller needs.
- Shared identity requires a different design.

## 2. Bind every resource lifetime to an object

~~~cpp
#include <fstream>
#include <iterator>
#include <stdexcept>
#include <string>

std::string read_file(const std::string& path) {
    std::ifstream input{path};
    if (!input) {
        throw std::runtime_error{"cannot open " + path};
    }

    return {
        std::istreambuf_iterator<char>{input},
        std::istreambuf_iterator<char>{}
    };
}
~~~

Why: resource acquisition is initialization ties a file handle to the ifstream object's lifetime. Its destructor closes the handle on normal return and stack unwinding.

Pros:

- Makes cleanup deterministic.
- Handles early returns and exceptions safely.
- Generalizes to locks, memory, sockets, and custom handles.

Cons:

- Destructors cannot report cleanup failure through a normal return value.
- A resource lives until its owning object's scope ends.
- Custom C handles may need a small wrapper type.

## 3. Use unique_ptr for exclusive dynamic ownership

~~~cpp
#include <memory>
#include <string>

struct Renderer {
    virtual ~Renderer() = default;
    virtual std::string render() const = 0;
};

struct TextRenderer final : Renderer {
    std::string render() const override {
        return "text";
    }
};

std::unique_ptr<Renderer> make_renderer() {
    return std::make_unique<TextRenderer>();
}
~~~

Why: unique_ptr represents one owner for a dynamically allocated object and deletes it automatically. Returning it by value transfers ownership explicitly; make_unique performs construction without a raw owning pointer.

Pros:

- Encodes exclusive ownership in the type.
- Has minimal overhead compared with manual ownership.
- Supports safe polymorphic lifetime through a virtual destructor.

Cons:

- The pointer cannot be copied.
- Dynamic allocation is unnecessary when an ordinary value suffices.
- A custom deleter may enlarge the pointer object.

## 4. Pass non-owning contiguous data with span and string_view

~~~cpp
#include <span>
#include <string_view>

int sum(std::span<const int> values) {
    int total = 0;
    for (const int value : values) {
        total += value;
    }
    return total;
}

bool has_prefix(std::string_view value, std::string_view prefix) {
    return value.starts_with(prefix);
}
~~~

Why: span carries a pointer and element count, while string_view carries character data and length. Both express borrowed access without allocating or coupling the function to one owning container.

Pros:

- Accepts several compatible owning containers.
- Preserves size information.
- Makes non-ownership visible in the parameter type.

Cons:

- Neither view extends the lifetime of its source.
- A view becomes invalid when backing storage moves or is destroyed.
- string_view does not guarantee null termination.

## 5. Use const and references to state intent

~~~cpp
#include <map>
#include <string>

int total_score(const std::map<std::string, int>& scores) {
    int total = 0;

    for (const auto& [name, score] : scores) {
        if (!name.empty()) {
            total += score;
        }
    }

    return total;
}
~~~

Why: a const reference avoids copying and promises not to modify the input. A const reference structured binding gives names to each map entry without copying its string and integer.

Pros:

- Makes non-mutation visible at the interface.
- Avoids unnecessary copies in traversal.
- Keeps type spelling compact when iterator value types are verbose.

Cons:

- The reference does not own or prolong the source lifetime.
- auto can hide a type whose exact representation matters.
- Accidentally omitting the reference copies every element.

## 6. Compose transformations with ranges and views

~~~cpp
#include <ranges>
#include <vector>

std::vector<int> positive_squares(const std::vector<int>& values) {
    auto transformed =
        values
        | std::views::filter([](int value) { return value > 0; })
        | std::views::transform([](int value) { return value * value; });

    std::vector<int> result;
    for (const int value : transformed) {
        result.push_back(value);
    }
    return result;
}
~~~

Why: views describe lazy, composable transformations over a range. The pipeline does not allocate intermediate containers, and the final loop makes materialization into an owning vector explicit.

Pros:

- Separates selection and transformation.
- Avoids manual indexing.
- Does not allocate intermediate collections.

Cons:

- Views borrow their sources and can dangle.
- Work and failures occur during iteration rather than view construction.
- Long pipelines and adaptor types can produce difficult diagnostics.

## 7. Return optional when absence is the only alternate result

~~~cpp
#include <map>
#include <optional>
#include <string>
#include <string_view>

std::optional<int> find_score(
    const std::map<std::string, int>& scores,
    std::string_view name
) {
    const auto found = scores.find(std::string{name});
    if (found == scores.end()) {
        return std::nullopt;
    }
    return found->second;
}
~~~

Why: optional represents either one value or absence without a sentinel integer, output parameter, or heap allocation. Callers must test it before accessing the contained value.

Pros:

- Makes absence part of the return type.
- Stores the value directly.
- Composes with value_or and, in newer standards, monadic operations.

Cons:

- It carries no diagnostic reason.
- The value still occupies storage inside the optional object.
- Throwing or an error-bearing type is better when failure details matter.

## 8. Model closed alternatives with variant and visit

~~~cpp
#include <string>
#include <variant>

struct Pending {};
struct Settled {
    std::string receipt;
};
struct Rejected {
    std::string reason;
};

using Payment = std::variant<Pending, Settled, Rejected>;

struct PaymentLabel {
    std::string operator()(const Pending&) const {
        return "pending";
    }

    std::string operator()(const Settled& value) const {
        return "receipt: " + value.receipt;
    }

    std::string operator()(const Rejected& value) const {
        return "rejected: " + value.reason;
    }
};

std::string label(const Payment& payment) {
    return std::visit(PaymentLabel{}, payment);
}
~~~

Why: variant stores exactly one member from a closed set, and visit dispatches according to the active member. Each alternative carries only its valid data.

Pros:

- Avoids unsafe unions and manual runtime tags.
- Keeps state-specific payloads type safe.
- Requires the visitor to support every alternative.

Cons:

- Adding an alternative affects every exhaustive visitor.
- The variant is sized for its largest alternative plus bookkeeping.
- Recursive variants need indirection.

## 9. Constrain generic code with concepts

~~~cpp
#include <concepts>

template<typename T>
concept Number = std::integral<T> || std::floating_point<T>;

template<Number T>
constexpr T square(T value) {
    return value * value;
}

static_assert(square(7) == 49);
~~~

Why: a concept names the operations or categories required by a template. Constraints reject unsuitable types at the call boundary and participate in overload selection.

Pros:

- Documents template requirements in the declaration.
- Produces focused diagnostics for invalid calls.
- Supports compile-time selection among constrained overloads.

Cons:

- A broad category may promise less semantic meaning than an algorithm needs.
- Constraint design adds complexity to small internal templates.
- Concepts check valid syntax and stated semantics, not every behavioral law.

## 10. Follow the rule of zero

~~~cpp
#include <string>
#include <utility>
#include <vector>

class Inventory {
public:
    explicit Inventory(std::vector<std::string> items)
        : items_{std::move(items)} {}

    const std::vector<std::string>& items() const {
        return items_;
    }

private:
    std::vector<std::string> items_;
};
~~~

Why: when every member manages its own lifetime, the enclosing class needs no custom destructor, copy constructor, move constructor, or assignment operator. Compiler-generated operations preserve the members' value semantics.

Pros:

- Removes fragile special-member code.
- Composes tested standard-library ownership types.
- Provides correct exception-safe cleanup automatically.

Cons:

- A reference-returning accessor exposes lifetime coupling.
- Non-copyable members make the enclosing type non-copyable.
- Classes that directly own a low-level handle still need a focused resource wrapper.

## Practical guidance

Prefer ordinary values and scoped objects before dynamic allocation. Make ownership explicit only where a value cannot express the needed lifetime or polymorphism. Use const references for borrowed objects, span and string_view for borrowed ranges, ranges for clear transformations, optional and variant for closed result shapes, and concepts where generic requirements deserve a name.

## Sources

1. [C++ Core Guidelines](https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines)
2. [C++ Core Guidelines: Resource Management](https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines#S-resource)
3. [C++ Core Guidelines: Functions](https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines#S-functions)
4. [C++ Core Guidelines: Classes](https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines#S-class)
5. [C++ Core Guidelines: Generic Programming](https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines#S-templates)
6. [ISO C++ Working Draft](https://wg21.link/std)
7. [WG21 P0896R4: The One Ranges Proposal](https://wg21.link/P0896R4)
8. [WG21 P0732R2: Concepts Design](https://wg21.link/P0732R2)
