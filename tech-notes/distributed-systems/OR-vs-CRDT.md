# OT vs CRDT

> Note: "OR" here means **OT — Operational Transformation**. This note compares the two
> dominant strategies for real-time collaborative editing and eventually-consistent
> replicated state: **Operational Transformation (OT)** and **Conflict-free Replicated
> Data Types (CRDTs)**.

## What are they?

Both OT and CRDTs solve the same core problem: **several replicas edit the same document
or data structure concurrently, offline or across a network, and every replica must end up
with the same result without a central lock and without losing anyone's work**. They are the
two engines behind Google Docs, Figma, Notion, Apple Notes, and multiplayer software in
general. They are what makes "eventual consistency" actually *converge* to a correct value
rather than just "some value" — the conflict-resolution layer referenced in [[cap-pacelc]].

- **Operational Transformation (OT)**: edits are expressed as **operations** (insert, delete
  at a position). When two operations were generated concurrently, an operation is
  **transformed** against the other so it can be applied on a state it wasn't originally
  written for. The transformation function rewrites indices so intent is preserved.

- **CRDT (Conflict-free Replicated Data Type)**: the data structure itself is designed so
  that concurrent updates **always merge deterministically**, regardless of order or
  duplication. Every element gets a globally unique, stable identity; merging is a pure
  mathematical operation (a join on a lattice) that is commutative, associative, and
  idempotent — so no transformation and often no central server is required.

The one-line difference: **OT transforms operations so they can be applied in a different
order; CRDTs design the data so order never matters.**

## Who created them? When?

- **OT**: introduced by **Ellis and Gibbs** in the **GROVE** system, *"Concurrency Control in
  Groupware Systems"* (**1989**). Refined for two decades — Jupiter (Xerox PARC, 1995), then
  Google Wave / Google Docs (2009+). Famous for being subtly hard to get right; several
  published OT algorithms were later shown to be incorrect.
- **CRDT**: formalized by **Marc Shapiro, Nuno Preguiça, Carlos Baquero, and Marek
  Zawirski** in **2011** (*"Conflict-free Replicated Data Types"* / *"A Comprehensive Study
  of CRDTs"*). Built on earlier ideas (Amazon Dynamo shopping carts, WOOT 2006, Treedoc).

## How OT works

Operations carry a **position**. Concurrent operations were written against the same base
state, so applying one shifts the positions the other assumed. OT defines a `transform(a, b)`
function that rewrites operation `a` to account for the effect of `b`.

```
Base document: "CAT"

  Client A inserts "S" at pos 0  →  op_A = ins(0, "S")   →  "SCAT"
  Client B inserts "!" at pos 3  →  op_B = ins(3, "!")   →  "CAT!"

Both send their op to the server (or each other). Applied naively, indices are now wrong:
B's insert at 3 no longer means the same place after A shifted everything right by 1.

  transform(op_B against op_A):  A inserted before B's position → shift B right by 1
      op_B' = ins(4, "!")

  A: apply op_B'  →  "SCAT" + ins(4,"!") = "SCAT!"
  B: apply op_A   →  "CAT!" + ins(0,"S") = "SCAT!"

Both converge to "SCAT!"  ✓  (this is the TP1 convergence property)
```

- OT almost always uses a **central server** to impose a single total order on operations
  (the Jupiter / Google Docs model). Peer-to-peer OT needs the notoriously hard **TP2**
  property (transformations must compose consistently in any order) which very few
  algorithms satisfy correctly.
- State is **compact**: the document is just its text plus a position; operations are tiny.
- Correctness lives entirely in the transformation functions — one wrong case and replicas
  silently diverge.

## How CRDTs work

Every insertable element is tagged with a **globally unique, immutable identifier** that also
encodes its order (e.g. a fractional position, or a dense ordered id + a site id). Deletes
leave **tombstones** rather than shifting anything. Merge = union of elements, ordered by id.

```
Base document, each char has a stable id:

  C(1)  A(2)  T(3)

  Client A inserts "S" before C → new id between start and 1, say  S(0.5, siteA)
  Client B inserts "!" after  T → new id after 3, say              !(3.5, siteB)

No transformation. Each replica just inserts its element by its own id and later merges
the full set. Ordering by id is deterministic everywhere:

  S(0.5,A)  C(1)  A(2)  T(3)  !(3.5,B)   →  "SCAT!"

Concurrent inserts at the SAME position → tie broken by (id, siteId), same on all replicas.
Delete "A" → mark A(2) as a tombstone, never reused. Merge is commutative + idempotent, so
duplicated or out-of-order network messages are harmless.
```

Two CRDT families:

```
┌───────────────┬───────────────────────────────┬───────────────────────────────┐
│               │ State-based (CvRDT)            │ Operation-based (CmRDT)        │
├───────────────┼───────────────────────────────┼───────────────────────────────┤
│ Replicas ship │ their whole state; merge via   │ individual operations          │
│               │ a join (least-upper-bound)     │                                │
│ Network needs │ no ordering; any gossip works  │ reliable, causal delivery      │
│ Bandwidth     │ heavier (full/delta state)     │ light (just the op)            │
│ Requirement   │ merge is a semilattice join    │ ops commute; no dup delivery   │
└───────────────┴───────────────────────────────┴───────────────────────────────┘
```

Common CRDT types: **G-Counter / PN-Counter** (counters), **G-Set / OR-Set** (sets,
add-wins), **LWW-Register / MV-Register** (values), **RGA / Logoot / Treedoc / YATA / Fugue**
(ordered sequences for text). Delta-CRDTs ship only the change, not the whole state, to cut
bandwidth. CRDT gossip is a natural fit for [[gossip-swim]]-style dissemination.

## OT vs CRDT — side by side

```
┌─────────────────────┬───────────────────────────┬───────────────────────────┐
│                     │ OT                        │ CRDT                      │
├─────────────────────┼───────────────────────────┼───────────────────────────┤
│ Core idea           │ transform ops to reorder  │ design data so order       │
│                     │ them                      │ never matters              │
├─────────────────────┼───────────────────────────┼───────────────────────────┤
│ Needs central server│ usually yes (total order) │ no — true peer-to-peer     │
├─────────────────────┼───────────────────────────┼───────────────────────────┤
│ Element identity    │ positional index          │ globally unique stable id  │
├─────────────────────┼───────────────────────────┼───────────────────────────┤
│ Deletes             │ shift indices             │ tombstones (kept around)   │
├─────────────────────┼───────────────────────────┼───────────────────────────┤
│ Memory / metadata   │ small, compact document   │ larger: per-char ids +     │
│                     │                           │ tombstones                 │
├─────────────────────┼───────────────────────────┼───────────────────────────┤
│ Bandwidth per edit  │ tiny op                   │ op + id metadata           │
├─────────────────────┼───────────────────────────┼───────────────────────────┤
│ Offline / P2P       │ hard (TP2 problem)        │ natural strength           │
├─────────────────────┼───────────────────────────┼───────────────────────────┤
│ Hard part           │ correct transform funcs   │ id allocation + GC of      │
│                     │ for every op pair         │ tombstones + interleaving  │
├─────────────────────┼───────────────────────────┼───────────────────────────┤
│ Convergence proof   │ empirical / fragile       │ mathematical (lattice)     │
├─────────────────────┼───────────────────────────┼───────────────────────────┤
│ Consistency model   │ eventual, server-ordered  │ strong eventual (SEC),     │
│                     │                           │ causal                     │
└─────────────────────┴───────────────────────────┴───────────────────────────┘
```

Both give **eventual consistency** in the [[cap-pacelc]] sense; CRDTs additionally give
**Strong Eventual Consistency (SEC)** — any two replicas that have received the same set of
updates are *provably* in the same state, no consensus round needed. This is why CRDTs are
the AP/EL tool of choice, sitting opposite the [[consensus-raft-paxos]] (CP/EC) camp.

## Pros / Cons — OT

### Pros
- **Compact state**: the document is just its content; no per-character metadata bloat.
- **Small operations**: low bandwidth per keystroke.
- **Mature & proven at scale**: 15+ years in Google Docs / Wave for plain text.
- **Simple, intuitive positional model** for a single authoritative server.
- **Good UX for rich text**: fine-grained control over formatting intent.

### Cons
- **Transformation functions are hard and error-prone**: many published algorithms were
  later proven wrong; every new operation type multiplies the transform cases.
- **Effectively needs a central server** to impose total order; correct peer-to-peer OT
  (TP2) is extremely difficult.
- **Poor fit for offline-first / P2P**: long divergence is where OT breaks down.
- **Server is a scaling and availability bottleneck** and a [[cap-pacelc]] CP-ish chokepoint.
- **Hard to reason about correctness** — no clean mathematical guarantee, mostly testing.

## Pros / Cons — CRDT

### Pros
- **Provably convergent (SEC)**: correctness is a mathematical property, not a test suite.
- **True peer-to-peer, serverless, offline-first**: merge in any order, any duplication,
  any delay — a natural fit for local-first software and [[gossip-swim]] dissemination.
- **No central coordinator required**: high availability, partition-tolerant (AP/EL).
- **Composable**: build big structures from proven small CRDTs (counters, sets, maps, text).
- **Idempotent merges**: safe to re-send, replay, or gossip messages without corruption.

### Cons
- **Metadata overhead**: unique ids + tombstones can make state far larger than the visible
  document; **garbage-collecting tombstones** safely is a hard, ongoing problem.
- **Interleaving anomalies**: naive sequence CRDTs can interleave two users' concurrent words
  into gibberish; fixing it needed newer algorithms (YATA, Fugue, Peritext).
- **Higher bandwidth per op** (id metadata) unless using delta-CRDTs.
- **Rich text / complex intents are hard**: tables, tree moves, and formatting need
  specialized CRDTs and are still active research.
- **Op-based CRDTs need causal, exactly-once delivery**, pushing complexity into the network
  layer.

## Use Cases

- **Real-time collaborative documents**: text editors, wikis, note apps (both OT and CRDT).
- **Design & whiteboard tools**: multiplayer canvases where many cursors edit at once.
- **Local-first / offline-first apps**: edit on a plane, sync later — **CRDT territory**.
- **Mobile sync**: reconcile edits made on phone + laptop + web without a lock — CRDT.
- **Distributed databases & caches**: counters, sets, registers that merge across regions —
  CRDT (Riak, Redis, Cosmos DB), complementing the quorum tuning in [[cap-pacelc]].
- **Multiplayer game / presence state**: shared world state, cursors, awareness — CRDT.
- **Version-control-like merges** and configuration replication across data centers — CRDT.

## Who uses them?

### OT
- **Google Docs / Google Wave**: the canonical large-scale OT deployment (server-ordered).
- **Etherpad**: open-source collaborative editor built on OT (`easysync`).
- **Apache Wave**, **CKEditor 5** (custom OT engine), **Microsoft Office** co-authoring
  (OT-derived merge for Word/PowerPoint on the web).
- **ShareDB / ot.js**: widely used open-source OT libraries.

### CRDT
- **Figma**: multiplayer design built on a custom CRDT-like tree/property model.
- **Apple Notes** and Apple's cloud sync use CRDTs for offline merge.
- **Automerge** and **Yjs** (with **Y.js/YATA**): the two dominant CRDT libraries powering
  hundreds of local-first apps.
- **Riak** (Riak DT), **Redis** (CRDT-based Active-Active in Redis Enterprise), **Azure
  Cosmos DB**, **Cassandra**-style stores use CRDT counters/sets — see the PACELC table in
  [[cap-pacelc]].
- **Nimbus/Teletype (Atom)**, **PhoenixNAP/PouchDB-style sync**, **Linear**, and much of the
  **local-first** movement (Ink & Switch research).
- **SoundCloud** open-sourced **Roshi**, a CRDT-backed LWW-element-set store.

## Which should you pick?

- **Central server, plain/rich text, mature tooling, tight bandwidth** → **OT** (Google Docs
  model). Best when a single authoritative server already exists.
- **Offline-first, peer-to-peer, provable convergence, no server, or replicating DB state
  across regions** → **CRDT**. Best when there is no single point of coordination and you
  need mathematical guarantees.
- The industry has been **drifting toward CRDTs** for new local-first and P2P systems because
  correctness is provable and no server is required; **OT remains entrenched** where a strong
  central server and years of rich-text tuning already exist.

## Sources

* https://dl.acm.org/doi/10.1145/66926.66963 (Ellis & Gibbs, OT / GROVE, 1989)
* https://hal.inria.fr/inria-00609399/document (Shapiro et al., "A Comprehensive Study of CRDTs", 2011)
* https://crdt.tech/ (CRDT papers and resources hub)
* https://www.figma.com/blog/how-figmas-multiplayer-technology-works/ (Figma's CRDT-like model)
* https://josephg.com/blog/crdts-are-the-future/ (OT vs CRDT, from an OT author)
* https://www.inkandswitch.com/local-first/ (Ink & Switch, local-first + CRDTs)
* https://yjs.dev/ and https://automerge.org/ (the two main CRDT libraries)
* https://en.wikipedia.org/wiki/Operational_transformation (OT survey and TP1/TP2)
