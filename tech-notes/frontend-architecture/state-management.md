# State Management

## What is it?

State management is the practice of managing the data that drives a user interface — what the user sees, what they have entered, what the server has returned, and what is currently loading or errored. In frontend applications, state determines the rendered output. Every interaction (click, type, navigate) triggers a state change, which triggers a re-render. As applications grow, managing where state lives, how it flows, how it is updated, and how it stays consistent becomes one of the hardest problems in frontend engineering.

## State Categories

```
┌─────────────────────────────────────────────────────────────┐
│                    Frontend State                            │
│                                                             │
│  ┌─────────────┐  ┌──────────────┐  ┌───────────────────┐  │
│  │ Local State  │  │ Global State │  │ Server State      │  │
│  │              │  │              │  │                   │  │
│  │ - form input │  │ - auth user  │  │ - API responses   │  │
│  │ - open/close │  │ - theme      │  │ - cached queries  │  │
│  │ - hover      │  │ - shopping   │  │ - loading states  │  │
│  │ - animation  │  │   cart       │  │ - pagination      │  │
│  │              │  │ - feature    │  │ - optimistic      │  │
│  │ Lives in the │  │   flags      │  │   updates         │  │
│  │ component    │  │              │  │                   │  │
│  │              │  │ Shared across│  │ Owned by the      │  │
│  │              │  │ many         │  │ server, cached    │  │
│  │              │  │ components   │  │ on the client     │  │
│  └─────────────┘  └──────────────┘  └───────────────────┘  │
│                                                             │
│  ┌─────────────┐  ┌──────────────┐                          │
│  │ URL State   │  │ Form State   │                          │
│  │             │  │              │                          │
│  │ - route     │  │ - validation │                          │
│  │ - query     │  │ - dirty      │                          │
│  │   params    │  │ - touched    │                          │
│  │ - hash      │  │ - submission │                          │
│  └─────────────┘  └──────────────┘                          │
└─────────────────────────────────────────────────────────────┘
```

## Client State Solutions

### 1. React useState / useReducer

Built-in React hooks. useState for simple values, useReducer for complex state transitions.

- Local to the component
- Cannot be shared without prop drilling or context
- useReducer follows the reducer pattern (action → state transition)
- Sufficient for most component-level state

### 2. React Context

Built-in mechanism for sharing state across a component tree without prop drilling.

- Provider wraps the tree, consumers read the value
- Every consumer re-renders when the context value changes
- No built-in selectors or memoization (causes unnecessary re-renders)
- Best for low-frequency updates (theme, locale, auth)
- Not designed for high-frequency state (forms, animations, real-time data)

### 3. Redux (2015)

The original global state management library for React. Single store, immutable state, pure reducer functions, unidirectional data flow.

```
Action ──► Dispatch ──► Reducer ──► New State ──► UI Re-render
                          │
                    (pure function)
                    (state, action) => newState
```

- Redux Toolkit (RTK) is the modern API (createSlice, configureStore)
- RTK Query handles server state (caching, fetching, invalidation)
- Middleware for async (redux-thunk, redux-saga)
- DevTools with time-travel debugging
- Verbose but predictable and well-understood

### 4. Zustand (2019)

Minimal global state management. No providers, no boilerplate. A store is a hook.

```
const useStore = create((set) => ({
  count: 0,
  increment: () => set((state) => ({ count: state.count + 1 })),
}))

function Counter() {
  const count = useStore((state) => state.count)
  return <div>{count}</div>
}
```

- No Provider wrapper needed
- Built-in selectors prevent unnecessary re-renders
- Works outside React (vanilla JS)
- Middleware: persist, devtools, immer
- ~1KB bundle size

### 5. Jotai (2020)

Atomic state management. Each piece of state is an atom. Components subscribe to individual atoms.

```
const countAtom = atom(0)
const doubleAtom = atom((get) => get(countAtom) * 2)

function Counter() {
  const [count, setCount] = useAtom(countAtom)
  return <button onClick={() => setCount(c => c + 1)}>{count}</button>
}
```

- Bottom-up: compose complex state from small atoms
- Derived atoms are computed automatically
- No extra re-renders (atom-level subscriptions)
- Async atoms for server state
- Inspired by Recoil but simpler API

### 6. Signals (2022+)

A reactive primitive that tracks dependencies and updates only the DOM nodes that read the signal. No virtual DOM diffing needed for signal-driven updates.

- **Preact Signals**: @preact/signals, @preact/signals-react
- **SolidJS**: built-in signals as the core reactive primitive
- **Angular Signals**: added in Angular 16
- **Vue Reactivity**: ref/reactive are conceptually signals
- **Svelte 5 Runes**: $state is a signal-like primitive

```
const count = signal(0)
const double = computed(() => count.value * 2)

effect(() => {
  console.log(count.value)
})

count.value++
```

- Fine-grained reactivity (no component-level re-renders)
- Automatic dependency tracking
- Synchronous by default
- Smaller runtime than virtual DOM diffing

### 7. XState (State Machines)

Models state as finite state machines or statecharts. Explicit states, transitions, guards, and side effects.

```
const toggleMachine = createMachine({
  initial: 'inactive',
  states: {
    inactive: { on: { TOGGLE: 'active' } },
    active: { on: { TOGGLE: 'inactive' } }
  }
})

Fetch Machine:
  idle ──FETCH──► loading ──SUCCESS──► success
                     │                    │
                     └──FAILURE──► error ──RETRY──► loading
```

- Impossible states are impossible (no invalid combinations)
- Visual editor (Stately.ai) for designing flows
- Actions, guards, and services for side effects
- Best for complex workflows (multi-step forms, auth flows, wizards)
- Overkill for simple toggle/counter state

## Server State Solutions

### React Query / TanStack Query (2019)

Treats server data as a separate concern from client state. Manages fetching, caching, synchronization, and garbage collection of server state.

```
function Users() {
  const { data, isLoading, error } = useQuery({
    queryKey: ['users'],
    queryFn: () => fetch('/api/users').then(r => r.json()),
    staleTime: 5 * 60 * 1000,
  })
}
```

- Automatic caching with configurable stale time
- Background refetching on window focus, network reconnect
- Pagination, infinite scroll, optimistic updates
- Query invalidation and manual refetching
- Framework-agnostic (React, Vue, Svelte, Solid, Angular)

### SWR (2019)

Vercel's data fetching library. Name comes from "stale-while-revalidate" HTTP cache strategy.

- Returns cached data immediately, revalidates in background
- Simpler API than React Query, fewer features
- Built-in deduplication, focus revalidation, interval polling
- Lightweight (~4KB)

## Comparison

```
┌──────────────────┬──────────┬────────────┬───────────┬──────────────────┐
│ Library          │ Type     │ Bundle Size│ Boilerplate│ Best For        │
├──────────────────┼──────────┼────────────┼───────────┼──────────────────┤
│ useState/Context │ Local/   │ 0KB        │ Low       │ Simple apps,     │
│                  │ shared   │ (built-in) │           │ low-freq global  │
├──────────────────┼──────────┼────────────┼───────────┼──────────────────┤
│ Redux Toolkit    │ Global   │ ~11KB      │ Medium    │ Large apps,      │
│                  │          │            │           │ complex logic    │
├──────────────────┼──────────┼────────────┼───────────┼──────────────────┤
│ Zustand          │ Global   │ ~1KB       │ Very Low  │ Most apps,       │
│                  │          │            │           │ simple global    │
├──────────────────┼──────────┼────────────┼───────────┼──────────────────┤
│ Jotai            │ Atomic   │ ~2KB       │ Low       │ Derived state,   │
│                  │          │            │           │ fine-grained     │
├──────────────────┼──────────┼────────────┼───────────┼──────────────────┤
│ Signals          │ Reactive │ ~1-2KB     │ Very Low  │ Fine-grained     │
│                  │          │            │           │ DOM updates      │
├──────────────────┼──────────┼────────────┼───────────┼──────────────────┤
│ XState           │ Machine  │ ~15KB      │ High      │ Complex flows,   │
│                  │          │            │           │ multi-step UIs   │
├──────────────────┼──────────┼────────────┼───────────┼──────────────────┤
│ TanStack Query   │ Server   │ ~13KB      │ Low       │ API data,        │
│                  │          │            │           │ caching, sync    │
├──────────────────┼──────────┼────────────┼───────────┼──────────────────┤
│ SWR              │ Server   │ ~4KB       │ Very Low  │ Simple fetching, │
│                  │          │            │           │ stale-while-rev  │
└──────────────────┴──────────┴────────────┴───────────┴──────────────────┘
```

## Pros

- **Predictable Updates**: unidirectional data flow makes state changes traceable
- **DevTools**: Redux, Zustand, TanStack Query all have browser DevTools for debugging
- **Separation of Concerns**: server state libraries separate fetching from UI logic
- **Performance**: fine-grained subscriptions (Zustand selectors, atoms, signals) prevent unnecessary re-renders
- **Testability**: pure reducers and state machines are easy to unit test
- **Framework Agnostic**: Zustand, Jotai, TanStack Query, XState work across React, Vue, Svelte
- **Caching**: server state libraries handle cache invalidation, deduplication, and background sync

## Cons

- **Choice Overload**: too many options with overlapping capabilities
- **Over-Engineering**: many apps use global state managers when useState is sufficient
- **Learning Curve**: Redux middleware, XState statecharts, and atomic models require study
- **Bundle Size**: adding multiple state libraries increases JavaScript payload
- **Abstraction Mismatch**: forcing all state into one paradigm (global store, atoms, machines) leads to awkward patterns
- **Migration Cost**: switching state libraries requires rewriting significant application logic
- **Server/Client Boundary**: SSR and React Server Components complicate state hydration

## Use Cases

- **E-Commerce**: shopping cart (Zustand/Redux), product catalog (TanStack Query), checkout wizard (XState)
- **Dashboards**: real-time data (TanStack Query with polling), filter state (URL params + Zustand)
- **Forms**: multi-step forms (XState), field validation (React Hook Form), autosave (debounced mutations)
- **Auth Flows**: login/logout/refresh token state machines (XState), current user (Context/Zustand)
- **Real-Time Apps**: WebSocket data (TanStack Query with manual cache updates), optimistic UI
- **Content Management**: document editing state (Zustand), server sync (TanStack Query mutations)
