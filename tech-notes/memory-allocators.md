# Memory Allocators

## What is it?

A memory allocator is the subsystem responsible for managing dynamic memory allocation and deallocation at runtime. When a program calls malloc/free (C), new/delete (C++), or relies on a garbage collector (Java, Go), a memory allocator decides where in the process address space to place each allocation, how to recycle freed memory, and how to request more memory from the operating system. The choice of allocator directly impacts throughput, latency, memory fragmentation, and cache behavior.

The default system allocator (glibc malloc on Linux, libmalloc on macOS) works reasonably well for general workloads, but high-performance systems often replace it with specialized allocators optimized for their access patterns.

## Core Concepts

### How the OS provides memory

1. **brk/sbrk**: Extends the data segment (heap) contiguously. Simple but single-threaded and limited
2. **mmap**: Maps anonymous pages anywhere in virtual address space. More flexible, supports large allocations
3. **Page size**: OS allocates in pages (4KB default, 2MB/1GB huge pages). Allocators subdivide pages into smaller chunks

### What an allocator must solve

- **Fragmentation**: External (free memory scattered in small gaps) and internal (allocated block larger than requested)
- **Thread safety**: Multiple threads allocating concurrently must not corrupt state or serialize on a global lock
- **Cache locality**: Allocations that are used together should be placed near each other in memory
- **Metadata overhead**: Bookkeeping headers consume memory that could be used by the application
- **Syscall reduction**: Every mmap/brk call is expensive, allocators batch OS requests and recycle freed memory

## Allocator Architectures

### 1. glibc malloc (ptmalloc2)

Default allocator on most Linux systems. Based on Doug Lea's dlmalloc with per-thread arenas added for concurrency.

- Uses bins (free lists) sorted by size: fastbins (small), unsorted bin, small bins, large bins
- Per-thread arenas reduce lock contention but arenas are limited in number
- Large allocations (>128KB by default) go directly to mmap
- Free chunks are coalesced with neighbors to reduce fragmentation

```
Thread 1 → Arena 1 → [fastbins][small bins][large bins] → brk/mmap
Thread 2 → Arena 2 → [fastbins][small bins][large bins] → brk/mmap
Thread 3 → Arena 1 (shared, locked)
```

- Pros: ships everywhere, no extra dependencies, decent general performance
- Cons: arena contention under high thread counts, higher fragmentation than modern allocators, metadata overhead per chunk (16 bytes)

### 2. jemalloc (Jason Evans, 2005)

Created for FreeBSD, adopted by Facebook, Redis, Rust (until 2019). Designed for multi-threaded workloads with low fragmentation.

- Thread-local caches (tcache) for small allocations with no locking
- Size classes with slabs: small (8B-14KB), large (14KB-4MB), huge (>4MB)
- Arenas with fine-grained locking and automatic thread-to-arena assignment
- Extent-based allocation replaces contiguous heap with discrete mapped regions
- Built-in profiling via heap profiling and leak detection (mallctl API)

```
Thread → tcache (lock-free) → Arena → Extent (mmap'd region)
         [bins per size class]  [slabs]  [pages from OS]
```

- Pros: low fragmentation, excellent multi-threaded scaling, built-in profiling, transparent huge page support
- Cons: higher baseline memory usage, complex internals, tuning parameters can be overwhelming

### 3. tcmalloc (Google, 2005)

Google's thread-caching malloc. Optimized for server workloads with many threads making small frequent allocations.

- Per-thread cache for small objects (no locks for common case)
- Central free list with transfer batches between thread cache and central cache
- Page heap for large allocations organized by span (contiguous pages)
- Small objects use size classes (88 size classes up to 256KB)
- Periodic garbage collection of thread caches to return memory to central pool

```
Thread → Thread Cache → Central Free List → Page Heap → OS
         (lock-free)     (spinlock)           (page-level)
```

- Pros: very fast small allocations, minimal lock contention, well-tested at Google scale
- Cons: can hold excess memory in thread caches, large object performance is mediocre, less aggressive about returning memory to OS

### 4. mimalloc (Microsoft, 2019)

Modern allocator from Microsoft Research. Focuses on simplicity, performance, and security.

- Free list sharding: each page has its own free list, reducing false sharing
- Small and consistent metadata overhead
- Eager page reset returns physical pages to OS while keeping virtual mapping
- Secure mode randomizes allocation addresses to mitigate use-after-free exploits
- Drop-in replacement for malloc via LD_PRELOAD

- Pros: fastest on many benchmarks, compact code, security features, aggressive memory return to OS
- Cons: newer with less production track record than jemalloc/tcmalloc

### 5. Bump Allocator (Arena/Region Allocator)

Simplest possible allocator. Maintains a pointer that bumps forward on each allocation. All memory is freed at once by resetting the pointer.

```
[allocated][allocated][allocated][  free space  ]
                                  ↑ bump pointer

Allocate 32 bytes: advance pointer by 32
Free: reset pointer to start (frees everything)
```

- Pros: O(1) allocation (pointer increment), zero fragmentation, no per-object free, excellent cache locality
- Cons: cannot free individual objects, must free all at once, wastes memory if lifetimes differ
- Used by: compilers (per-phase arenas), game engines (per-frame allocators), web servers (per-request arenas)

### 6. Pool/Slab Allocator (Bonwick, 1994)

Pre-allocates fixed-size chunks from a slab. Each pool serves one object size. Allocation is popping from a free list, deallocation is pushing back.

```
Pool for 64-byte objects:
Slab 1: [used][free][used][used][free][used]
Slab 2: [free][free][free][used][free][free]
         ↓
       free list: → slot3 → slot5 → slot7 → ...
```

- Pros: O(1) alloc/free, zero external fragmentation for fixed sizes, object caching (reuse initialized objects)
- Cons: internal fragmentation if object sizes vary, need separate pool per size class
- Used by: Linux kernel (kmem_cache), Memcached (slab allocator), nginx

## Comparison

```
┌──────────────────┬────────────┬───────────────┬──────────────┬──────────────────┐
│ Allocator        │ Best For   │ Thread Safety │ Fragmentation│ Notable Users    │
├──────────────────┼────────────┼───────────────┼──────────────┼──────────────────┤
│ glibc malloc     │ General    │ Arena-based   │ Moderate     │ Default Linux    │
├──────────────────┼────────────┼───────────────┼──────────────┼──────────────────┤
│ jemalloc         │ Multi-     │ tcache +      │ Low          │ Redis, Facebook, │
│                  │ threaded   │ fine arenas   │              │ FreeBSD          │
├──────────────────┼────────────┼───────────────┼──────────────┼──────────────────┤
│ tcmalloc         │ Server     │ Thread cache  │ Low          │ Google, gRPC,    │
│                  │ workloads  │ + central     │              │ Golang runtime   │
├──────────────────┼────────────┼───────────────┼──────────────┼──────────────────┤
│ mimalloc         │ General +  │ Per-page      │ Very low     │ Microsoft,       │
│                  │ security   │ free lists    │              │ Zig, research    │
├──────────────────┼────────────┼───────────────┼──────────────┼──────────────────┤
│ Bump/Arena       │ Batch      │ Single-thread │ None         │ Compilers, game  │
│                  │ lifetime   │ or per-arena  │              │ engines          │
├──────────────────┼────────────┼───────────────┼──────────────┼──────────────────┤
│ Pool/Slab        │ Fixed-size │ Per-pool lock │ None (fixed) │ Linux kernel,    │
│                  │ objects    │ or lock-free  │              │ Memcached        │
└──────────────────┴────────────┴───────────────┴──────────────┴──────────────────┘
```

## Pros

- **Performance**: Specialized allocators can be 2-5x faster than default malloc for specific workloads
- **Reduced Fragmentation**: Modern allocators use size classes and slabs to minimize wasted memory
- **Thread Scalability**: Thread-local caches eliminate lock contention for common allocations
- **Drop-In Replacement**: jemalloc, tcmalloc, mimalloc can replace system malloc via LD_PRELOAD without code changes
- **Profiling**: jemalloc and tcmalloc include built-in heap profiling and leak detection
- **Huge Page Support**: Modern allocators transparently use 2MB huge pages to reduce TLB misses
- **Deterministic Latency**: Arena and pool allocators provide O(1) allocation with no fragmentation
- **Cache Locality**: Allocators that place related objects together improve CPU cache hit rates

## Cons

- **Complexity**: Understanding allocator internals requires deep systems knowledge
- **Memory Overhead**: Thread caches and metadata consume memory that is not available to the application
- **Tuning Difficulty**: Wrong configuration can waste memory or degrade performance
- **RSS vs Actual Usage**: Allocators hold freed memory in caches, making RSS misleading
- **OS Return Lag**: Many allocators are slow to return memory to the OS after usage drops
- **No Universal Winner**: Best allocator depends on workload (allocation size, thread count, lifetime patterns)
- **Debugging Harder**: Custom allocators can mask or change the behavior of memory bugs
- **ABI Compatibility**: Mixing allocators in shared libraries can cause crashes

## Use Cases

- **Database Engines**: PostgreSQL uses slab allocation for fixed-size objects, MySQL uses jemalloc for InnoDB buffer pool management
- **In-Memory Caches**: Redis uses jemalloc to minimize fragmentation with millions of small key-value pairs
- **Game Engines**: Per-frame bump allocators that reset every 16ms for zero-overhead temporary allocations
- **Web Servers**: Per-request arena allocation in nginx frees all request memory at once
- **Compilers**: Per-compilation-phase arenas in LLVM and GCC avoid tracking individual AST node lifetimes
- **High-Frequency Trading**: Pool allocators for fixed-size order objects with deterministic O(1) latency
- **Embedded Systems**: Fixed pool allocators that never fragment and never call the OS
- **Container Workloads**: tcmalloc and mimalloc in containerized services where memory limits are strict
- **Language Runtimes**: Go runtime uses tcmalloc-inspired allocator, Rust standard library uses system allocator with optional jemalloc
- **Network Packet Processing**: Slab allocators for fixed-size packet buffers at line rate (DPDK)
