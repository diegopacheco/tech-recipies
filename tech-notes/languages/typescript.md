# Idiomatic TypeScript

Idiomatic TypeScript models runtime possibilities accurately, lets control-flow analysis narrow values, and preserves useful inference instead of replacing it with assertions. These ten idioms use the language and standard JavaScript APIs without external libraries.

## 1. Enable strict checking as the baseline

~~~json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitOverride": true,
    "useUnknownInCatchVariables": true
  }
}
~~~

Why: strict mode enables a coordinated set of checks for nullability, function variance, property initialization, and implicit types. The additional options make indexed access, optional properties, overrides, and caught values reflect their runtime uncertainty more precisely.

Pros:

- Finds unsafe assumptions during compilation.
- Gives editors more accurate narrowing and completion.
- Establishes one predictable safety baseline across a project.

Cons:

- Enabling it on an established codebase can reveal substantial migration work.
- Some dynamic APIs need adapters or explicit validation.
- noUncheckedIndexedAccess adds undefined to many lookup results.

## 2. Accept unknown at untrusted boundaries

~~~typescript
function parsePort(value: unknown): number {
  if (typeof value !== "string") {
    throw new TypeError("Port must be a string");
  }

  const port = Number(value);
  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    throw new RangeError("Port is out of range");
  }

  return port;
}
~~~

Why: unknown accepts any incoming value but prevents use until runtime checks narrow it. It is the safe boundary type for parsed data, caught failures, messages, and other values not yet validated.

Pros:

- Prevents unchecked property access and calls.
- Makes boundary validation visible.
- Preserves type safety without pretending the input shape is known.

Cons:

- Every useful operation needs narrowing.
- Repeated validation deserves a focused parser.
- An assertion can still bypass the protection.

## 3. Model states with discriminated unions

~~~typescript
type Payment =
  | { kind: "pending" }
  | { kind: "settled"; receipt: string }
  | { kind: "rejected"; reason: string };

function label(payment: Payment): string {
  switch (payment.kind) {
    case "pending":
      return "Payment pending";
    case "settled":
      return "Receipt: " + payment.receipt;
    case "rejected":
      return "Rejected: " + payment.reason;
  }
}
~~~

Why: each union member carries a literal discriminant and only the fields valid for that state. Checking the discriminant narrows the whole object without casts or non-null assertions.

Pros:

- Makes invalid field combinations unrepresentable.
- Gives each branch precise property types.
- Works naturally with ordinary JavaScript control flow.

Cons:

- A new member requires updates at handling sites.
- Very large unions can produce complex error messages.
- External data still needs runtime validation before it can be trusted as the union.

## 4. Enforce exhaustiveness with never

~~~typescript
type Job = "queued" | "running" | "finished";

function assertNever(value: never): never {
  throw new Error("Unexpected value: " + String(value));
}

function priority(job: Job): number {
  switch (job) {
    case "queued":
      return 1;
    case "running":
      return 2;
    case "finished":
      return 0;
    default:
      return assertNever(job);
  }
}
~~~

Why: after all known union members are handled, the remaining value has type never. Passing it to assertNever turns a newly added but unhandled member into a compile-time error while retaining a runtime guard.

Pros:

- Detects incomplete switches during compilation.
- Keeps the return type precise.
- Provides a defensive failure for unexpected runtime input.

Cons:

- Requires a small helper or an explicit never assignment.
- A broad assertion earlier in the program can defeat the check.
- It adds little when a switch already returns and no default is needed.

## 5. Preserve inference with satisfies

~~~typescript
type Environment = "local" | "production";
type Settings = Record<Environment, { url: string; retries: number }>;

const settings = {
  local: { url: "http://localhost:8080", retries: 1 },
  production: { url: "https://service.internal", retries: 4 }
} satisfies Settings;

const productionUrl = settings.production.url;
~~~

Why: satisfies checks that an expression is assignable to a target type without replacing the expression's inferred type. It is useful for validating configuration keys and values while retaining precise properties.

Pros:

- Detects missing, misspelled, or incompatible entries.
- Retains specific inferred types for later access.
- Avoids an unsafe type assertion.

Cons:

- It performs no runtime validation.
- It does not change the resulting value type to the target type.
- Literal widening can still require as const when literal identity matters.

## 6. Expose readonly inputs and state

~~~typescript
type Order = Readonly<{
  id: string;
  cents: number;
}>;

function total(orders: readonly Order[]): number {
  return orders.reduce((sum, order) => sum + order.cents, 0);
}

const orders = [
  { id: "a", cents: 1200 },
  { id: "b", cents: 800 }
] as const;

const cents = total(orders);
~~~

Why: readonly communicates that a function does not mutate its input and accepts both mutable and readonly arrays. Readonly and as const can also preserve immutable object and tuple shapes during checking.

Pros:

- Makes mutation policy visible in signatures.
- Allows callers to pass immutable arrays without copying.
- Prevents accidental assignment through the typed reference.

Cons:

- Readonly is compile-time only and shallow.
- A mutable alias can still change the same runtime object.
- Excessive literal preservation can produce types narrower than callers need.

## 7. Use optional chaining with nullish coalescing

~~~typescript
type User = {
  profile?: {
    displayName?: string;
  };
};

function displayName(user: User | undefined): string {
  return user?.profile?.displayName?.trim() ?? "Anonymous";
}
~~~

Why: optional chaining stops only on null or undefined, and nullish coalescing supplies a fallback only for those two values. Valid values such as an empty string, zero, and false are not replaced accidentally.

Pros:

- Keeps nullable traversal compact.
- Preserves falsy values that are not absent.
- Avoids repeated temporary checks.

Cons:

- A long chain can hide which property was absent.
- One fallback may collapse domain states that need distinct handling.
- It does not validate the runtime shape of untrusted data.

## 8. Write reusable type predicates for runtime checks

~~~typescript
type Customer = {
  id: string;
  active: boolean;
};

function isCustomer(value: unknown): value is Customer {
  if (typeof value !== "object" || value === null) {
    return false;
  }

  const candidate = value as Record<string, unknown>;
  return typeof candidate.id === "string"
    && typeof candidate.active === "boolean";
}

function activeId(value: unknown): string | undefined {
  return isCustomer(value) && value.active ? value.id : undefined;
}
~~~

Why: a type predicate connects a runtime boolean check to control-flow narrowing. Keeping the assertion inside a small validator prevents unchecked access from spreading through callers.

Pros:

- Reuses one boundary check across many callers.
- Gives narrowed types in ordinary conditions and array filters.
- Keeps runtime validation separate from business logic.

Cons:

- TypeScript trusts the predicate implementation.
- Handwritten validators grow quickly for nested schemas.
- The cast inside the validator must remain tightly scoped.

## 9. Use keyof and generic constraints to relate inputs

~~~typescript
function property<T extends object, K extends keyof T>(value: T, key: K): T[K] {
  return value[key];
}

const server = {
  host: "localhost",
  port: 8080,
  secure: false
};

const port = property(server, "port");
~~~

Why: K extends keyof T states that the key must exist on the supplied object, and T[K] preserves the exact property type in the result. The relationship between arguments carries more information than object and string.

Pros:

- Rejects misspelled or unrelated keys.
- Returns the correct property type without overloads.
- Reuses the same function across object shapes.

Cons:

- Generics can obscure a function that does not need type relationships.
- Index signatures make keyof broader than explicit property names.
- Runtime keys from external input still require validation.

## 10. Start independent asynchronous work together

~~~typescript
async function loadUser(id: string): Promise<string> {
  return "user-" + id;
}

async function loadPermissions(id: string): Promise<readonly string[]> {
  return ["read", "write"];
}

async function loadAccount(id: string) {
  const [user, permissions] = await Promise.all([
    loadUser(id),
    loadPermissions(id)
  ]);

  return { user, permissions };
}
~~~

Why: creating independent promises together lets their work overlap, while Promise.all preserves tuple order and rejects when one input rejects. async and await keep the surrounding control flow readable.

Pros:

- Avoids unnecessary sequential waiting.
- Preserves inferred result types by tuple position.
- Centralizes failure propagation.

Cons:

- One rejection rejects the combined promise.
- Already-started work is not cancelled automatically.
- Concurrency can overload a downstream service without admission control.

## Practical guidance

Start with strict compiler settings, unknown at untrusted boundaries, and union types that reflect actual runtime states. Let narrowing and inference do the work before reaching for assertions. Use readonly to document non-mutation, related generic parameters when inputs constrain one another, and concurrent promise composition only when operations are truly independent.

## Sources

1. [TypeScript Handbook: TSConfig Options](https://www.typescriptlang.org/tsconfig/)
2. [TypeScript Handbook: The Basics](https://www.typescriptlang.org/docs/handbook/2/basic-types.html)
3. [TypeScript Handbook: Narrowing](https://www.typescriptlang.org/docs/handbook/2/narrowing.html)
4. [TypeScript Handbook: The never Type](https://www.typescriptlang.org/docs/handbook/2/functions.html#never)
5. [TypeScript 4.9: The satisfies Operator](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-9.html)
6. [TypeScript Handbook: Object Types](https://www.typescriptlang.org/docs/handbook/2/objects.html)
7. [TypeScript 3.7: Optional Chaining](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-3-7.html)
8. [TypeScript Handbook: Type Predicates](https://www.typescriptlang.org/docs/handbook/2/narrowing.html#using-type-predicates)
9. [TypeScript Handbook: keyof](https://www.typescriptlang.org/docs/handbook/2/keyof-types.html)
10. [TypeScript Handbook: Generics](https://www.typescriptlang.org/docs/handbook/2/generics.html)
11. [ECMAScript Specification: Promise.all](https://tc39.es/ecma262/multipage/control-abstraction-objects.html#sec-promise.all)
