# Idiomatic Clojure

Idiomatic Clojure treats immutable data and pure transformations as the default, uses sequence abstractions instead of index-driven loops, and isolates coordinated state changes behind explicit reference types. These ten idioms use Clojure core and the standard library.

## 1. Model domain values with maps and keywords

~~~clojure
(def customer
  {:customer/id 42
   :customer/name "Ada"
   :customer/active? true})

(defn active-name [{:customer/keys [name active?]}]
  (when active? name))

(active-name customer)
~~~

Why: maps provide immutable, associative domain data without requiring a class declaration. Namespaced keywords reduce collisions and carry meaning across function and namespace boundaries.

Pros:

- Keeps data easy to construct, inspect, compare, and transform.
- Allows functions to consume only the keys they need.
- Works uniformly with core collection operations.

Cons:

- Required keys and value types are not enforced automatically.
- Misspelled keys often produce nil rather than an immediate failure.
- Unbounded map growth can weaken the domain vocabulary.

## 2. Evolve values with assoc, update, and dissoc

~~~clojure
(def order
  {:id 7
   :status :pending
   :attempts 0
   :temporary-note "retry"})

(def settled-order
  (-> order
      (assoc :status :settled)
      (update :attempts inc)
      (dissoc :temporary-note)))

order
settled-order
~~~

Why: persistent collections return new logical values while sharing unchanged structure. The original value remains available, and each operation states the intended data change.

Pros:

- Avoids hidden mutation and defensive copying.
- Makes state transitions ordinary values.
- Supports safe sharing across functions and threads.

Cons:

- Retaining many historical roots keeps their reachable data alive.
- Repeated updates may be slower than transient mutation in a measured hot path.
- Nested updates need get-in, assoc-in, or update-in and can become path-heavy.

## 3. Use thread-first for associative data transformations

~~~clojure
(require '[clojure.string :as str])

(defn normalize-customer [customer]
  (-> customer
      (update :name str/trim)
      (update :email str/lower-case)
      (assoc :active? true)
      (select-keys [:name :email :active?])))

(normalize-customer
  {:name " Ada "
   :email "ADA@ACME.TEST"
   :legacy-id 9})
~~~

Why: thread-first inserts the prior result as the first argument of each form. Core associative operations place the collection first, so the transformation reads from input through each named step.

Pros:

- Flattens nested calls into a readable pipeline.
- Keeps each data change on its own line.
- Makes it easy to add or reorder steps.

Cons:

- It is purely syntactic and does not inspect function signatures.
- Mixing first-argument and last-argument APIs can produce awkward forms.
- A pipeline with unrelated responsibilities should become named functions.

## 4. Use thread-last for sequence pipelines

~~~clojure
(def orders
  [{:id 1 :paid? true :cents 1200}
   {:id 2 :paid? false :cents 900}
   {:id 3 :paid? true :cents 800}])

(def paid-total
  (->> orders
       (filter :paid?)
       (map :cents)
       (reduce + 0)))
~~~

Why: thread-last inserts the prior result as the final argument. Sequence functions conventionally receive the collection last, so the data flows through filtering, mapping, and reduction without nesting.

Pros:

- Separates selection, transformation, and aggregation.
- Works across lists, vectors, sets, maps, and lazy sequence sources.
- Avoids manual indexing and mutable accumulators.

Cons:

- A long pipeline can hide intermediate shapes.
- Lazy stages may delay both work and failures.
- A single reduce may be clearer when several stages share state.

## 5. Destructure at function boundaries

~~~clojure
(defn endpoint
  [{:keys [host port] :or {port 443}}
   [scheme secure?]]
  {:url (str scheme "://" host ":" port)
   :secure? secure?})

(endpoint
  {:host "service.internal"}
  ["https" true])
~~~

Why: associative and sequential destructuring bind meaningful local names directly from input structure. Defaults and remaining values can be expressed beside those bindings.

Pros:

- Documents the shape a function consumes.
- Removes repetitive lookup and positional access.
- Supports namespaced keys, defaults, and nested structures.

Cons:

- Deep destructuring can obscure the original value and absent paths.
- :or defaults apply only to missing keys, so an explicit nil remains nil.
- Positional destructuring is brittle when the input is not truly positional.

## 6. Use if-let and when-let for meaningful presence

~~~clojure
(def users
  {42 {:name "Ada" :active? true}
   51 {:name "Grace" :active? false}})

(defn greeting [id]
  (if-let [{:keys [name active?]} (get users id)]
    (if active?
      (str "Hello, " name)
      "Account inactive")
    "User missing"))

(greeting 42)
~~~

Why: if-let combines a lookup, a truthiness check, and a binding. The successful branch receives the value without repeating the expression, while the other branch handles absence.

Pros:

- Keeps lookup and binding adjacent.
- Avoids duplicated evaluation.
- Leaves the successful value available under a focused name.

Cons:

- false and nil both take the absent branch.
- Several dependent bindings may be clearer with some-> or explicit conditionals.
- It should not replace ordinary if when no binding is needed.

## 7. Build results with into

~~~clojure
(def scores
  {:ada 98
   :grace 96
   :charles 64})

(def passing
  (into #{}
        (comp
          (filter (fn [[_ score]] (>= score 70)))
          (map key))
        scores))
~~~

Why: into separates the destination collection from the transformation. The transducer composes filtering and mapping without creating intermediate lazy sequences.

Pros:

- Makes the desired result type explicit.
- Avoids intermediate collections.
- Reuses the same transformation with different sources and destinations.

Cons:

- A short sequence pipeline may be easier to read.
- Stateful transducers have completion and reuse rules.
- Transducer arities are unfamiliar to readers who only know lazy sequence operations.

## 8. Prefer reduce-kv for key-value aggregation

~~~clojure
(def inventory
  {:apples 4
   :oranges 3
   :pears 5})

(def total-items
  (reduce-kv
    (fn [total _ quantity]
      (+ total quantity))
    0
    inventory))
~~~

Why: reduce-kv passes map keys and values directly to the reducing function. It avoids allocating a sequence of map entries when a reduction needs both parts or only the value.

Pros:

- States key-value traversal directly.
- Avoids destructuring every map entry.
- Works with vectors by supplying indexes as keys.

Cons:

- It is specialized to associative collections that support IKVReduce.
- reduce over entries may be more familiar.
- Complex reducers should be extracted into named functions.

## 9. Define open behavior with protocols and records

~~~clojure
(defprotocol Render
  (render [value]))

(defrecord Money [cents currency]
  Render
  (render [_]
    (str currency " " (/ cents 100.0))))

(extend-protocol Render
  java.lang.String
  (render [value] value))

(render (->Money 1995 "USD"))
~~~

Why: a protocol defines a named operation independently of one class hierarchy. Records provide map-like immutable values with efficient fields, and existing types can gain protocol implementations without modification.

Pros:

- Supports polymorphism without forcing shared data representation.
- Keeps domain values associative and immutable.
- Allows extension to types owned elsewhere.

Cons:

- Protocol dispatch is based on the first argument's concrete type.
- Records introduce nominal identity that ordinary maps do not have.
- A protocol is unnecessary when one higher-order function argument is enough.

## 10. Isolate shared state with atoms and swap!

~~~clojure
(def counters
  (atom {:requests 0 :failures 0}))

(defn record-request [failed?]
  (swap! counters
         (fn [state]
           (cond-> (update state :requests inc)
             failed? (update :failures inc)))))

(record-request true)
@counters
~~~

Why: an atom manages independent synchronous state transitions. swap! applies a pure function atomically and may retry it, so the function calculates the next immutable value without performing external effects.

Pros:

- Makes mutable identity explicit and localized.
- Provides atomic compare-and-set semantics.
- Lets readers obtain a consistent immutable snapshot by dereferencing.

Cons:

- The swap function can run more than once and must be free of external effects.
- Several coordinated identities may require a different reference model.
- Global atoms can become hidden dependencies.

## Practical guidance

Represent information as immutable maps, vectors, sets, and sequences before creating nominal types. Keep transformations pure and linear with the threading macro that matches argument position. Use destructuring to clarify boundaries, into and transducers when collection construction benefits from fusion, protocols for genuinely open polymorphism, and atoms only around the smallest necessary shared identity.

## Sources

1. [Clojure Reference: Data Structures](https://clojure.org/reference/data_structures)
2. [Clojure Guide: Threading Macros](https://clojure.org/guides/threading_macros)
3. [Clojure Guide: Destructuring](https://clojure.org/guides/destructuring)
4. [Clojure Reference: Sequences](https://clojure.org/reference/sequences)
5. [Clojure Reference: Transducers](https://clojure.org/reference/transducers)
6. [Clojure Reference: Protocols](https://clojure.org/reference/protocols)
7. [Clojure Reference: Datatypes](https://clojure.org/reference/datatypes)
8. [Clojure Reference: Atoms](https://clojure.org/reference/atoms)
9. [Clojure Reference: Special Forms](https://clojure.org/reference/special_forms)
