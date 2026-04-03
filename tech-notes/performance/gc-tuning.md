# GC Tuning

## What is it?

Garbage collection (GC) tuning is the practice of configuring the JVM's garbage collector to minimize pause times, maximize throughput, or reduce memory footprint for a specific workload. The JVM provides multiple garbage collectors (G1, ZGC, Shenandoah, Parallel, Serial) each with different trade-offs between pause time, throughput, and memory overhead. Tuning involves selecting the right collector, sizing the heap and generations, setting pause time targets, and analyzing GC logs to identify and fix performance problems like long pauses, frequent collections, premature promotions, and memory leaks.

## How it works?

### JVM Heap Layout

```
┌───────────────────────────────────────────────────────────┐
│                        JVM Heap                           │
│                                                           │
│  ┌─────────────────────────┐  ┌─────────────────────────┐│
│  │     Young Generation    │  │     Old Generation       ││
│  │                         │  │                          ││
│  │  ┌──────┐  ┌────┬────┐ │  │  Long-lived objects      ││
│  │  │ Eden │  │ S0 │ S1 │ │  │  (survived multiple      ││
│  │  │      │  │    │    │ │  │   young GC cycles)        ││
│  │  │ new  │  │surv│surv│ │  │                          ││
│  │  │allocs│  │ivor│ivor│ │  │                          ││
│  │  └──────┘  └────┴────┘ │  │                          ││
│  └─────────────────────────┘  └─────────────────────────┘│
│                                                           │
│  Young GC (minor): collects Eden + one survivor           │
│  Old GC (major/full): collects old generation             │
│                                                           │
│  -Xms: minimum heap    -Xmx: maximum heap                │
│  -Xmn: young gen size  -XX:SurvivorRatio: Eden/Survivor  │
└───────────────────────────────────────────────────────────┘

Object lifecycle:
  new Object() → Eden → survive minor GC → Survivor (S0↔S1)
              → survive N minor GCs → promoted to Old Gen
              → collected by major GC when unreachable
```

### GC Pause Types

```
┌─────────────────────┬──────────────────────────────────────────┐
│ Pause Type          │ Description                               │
├─────────────────────┼──────────────────────────────────────────┤
│ Minor GC            │ Collects young generation only. Fast      │
│ (Young GC)          │ (1-50ms typical). Most objects die young. │
├─────────────────────┼──────────────────────────────────────────┤
│ Major GC            │ Collects old generation. Can be long      │
│ (Old GC)            │ (100ms - seconds). G1/ZGC do this        │
│                     │ concurrently.                              │
├─────────────────────┼──────────────────────────────────────────┤
│ Full GC             │ Collects entire heap. Stop-the-world.     │
│                     │ Usually indicates a problem. Seconds.     │
├─────────────────────┼──────────────────────────────────────────┤
│ Mixed GC (G1)       │ Collects young gen + some old gen regions.│
│                     │ G1-specific incremental old gen cleanup.  │
├─────────────────────┼──────────────────────────────────────────┤
│ Concurrent phase    │ GC work done while app threads run.       │
│                     │ No pause (or very short pause).           │
└─────────────────────┴──────────────────────────────────────────┘
```

## JVM Garbage Collectors

### G1 (Garbage-First) — Default since JDK 9

```
Architecture:
  Heap divided into equal-sized regions (~2048 regions).
  Each region is Eden, Survivor, Old, or Humongous.

  ┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┐
  │ E │ E │ S │ O │ O │ O │ E │ H │ H │ O │ O │ E │
  └───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┘
   E=Eden  S=Survivor  O=Old  H=Humongous

  G1 collects the regions with the most garbage first
  (hence "Garbage-First").

Key flags:
  -XX:+UseG1GC                        (default since JDK 9)
  -XX:MaxGCPauseMillis=200            (target pause time, default 200ms)
  -XX:G1HeapRegionSize=8m             (region size, auto-tuned)
  -XX:InitiatingHeapOccupancyPercent=45  (trigger concurrent cycle)
  -XX:G1MixedGCCountTarget=8          (mixed GC count target)

When to use:
  - General-purpose workloads
  - Heap sizes 4GB - 64GB
  - Need balance between throughput and latency
  - Default choice for most applications
```

### ZGC — Sub-Millisecond Pauses

```
Architecture:
  Concurrent collector. Almost all work done while app runs.
  Uses colored pointers (metadata in pointer bits) for concurrent
  relocation without stop-the-world pauses.

  Pause times: < 1ms (regardless of heap size)
  Heap sizes: 8MB to 16TB

  ┌──────────────────────────────────────────────┐
  │  ZGC Phases                                   │
  │                                              │
  │  Pause Mark Start    (~0.1ms)  ← STW         │
  │  Concurrent Mark     (parallel with app)      │
  │  Pause Mark End      (~0.1ms)  ← STW         │
  │  Concurrent Relocate (parallel with app)      │
  │                                              │
  │  Total STW: ~0.2ms regardless of heap size   │
  └──────────────────────────────────────────────┘

Key flags:
  -XX:+UseZGC                          (enable ZGC)
  -XX:+ZGenerational                   (generational ZGC, JDK 21+)
  -XX:SoftMaxHeapSize=4g               (preferred heap size)

When to use:
  - Latency-sensitive applications (< 1ms p99 GC pause)
  - Very large heaps (100GB+)
  - Applications where consistent response time matters more
    than raw throughput
```

### Shenandoah — Low-Pause Alternative

```
Architecture:
  Concurrent collector (similar goals to ZGC).
  Uses Brooks forwarding pointers for concurrent compaction.
  Available in OpenJDK (not Oracle JDK).

  Pause times: < 10ms typical (heap-size independent)

Key flags:
  -XX:+UseShenandoahGC
  -XX:ShenandoahGCHeuristics=adaptive  (adaptive, compact, aggressive)

When to use:
  - Low-latency requirements on OpenJDK
  - Alternative to ZGC with different performance characteristics
  - Medium to large heaps
```

### Parallel GC — Maximum Throughput

```
Architecture:
  Multi-threaded stop-the-world collector.
  All GC work done during pauses (no concurrent work).
  Maximizes application throughput at the cost of longer pauses.

  Pause times: 100ms - seconds (proportional to heap size)

Key flags:
  -XX:+UseParallelGC
  -XX:ParallelGCThreads=8
  -XX:GCTimeRatio=99                   (1% GC time target)

When to use:
  - Batch processing, data pipelines
  - Throughput matters more than latency
  - Short-lived applications (no long-running service)
```

## Comparison

```
┌──────────────────┬──────────┬──────────────┬──────────────┬──────────┐
│ Collector        │ Pause    │ Throughput   │ Max Heap     │ Overhead │
├──────────────────┼──────────┼──────────────┼──────────────┼──────────┤
│ G1               │ ~200ms   │ High         │ ~64GB sweet  │ ~5-10%   │
│ (default)        │ (target) │              │ spot         │          │
├──────────────────┼──────────┼──────────────┼──────────────┼──────────┤
│ ZGC              │ < 1ms    │ Good         │ 16TB         │ ~10-15%  │
│                  │          │              │              │          │
├──────────────────┼──────────┼──────────────┼──────────────┼──────────┤
│ Shenandoah       │ < 10ms   │ Good         │ ~100GB+      │ ~10-15%  │
│                  │          │              │              │          │
├──────────────────┼──────────┼──────────────┼──────────────┼──────────┤
│ Parallel         │ 100ms-s  │ Highest      │ ~32GB sweet  │ ~1-3%    │
│                  │          │              │ spot         │          │
├──────────────────┼──────────┼──────────────┼──────────────┼──────────┤
│ Serial           │ 100ms-s  │ Low          │ Small heaps  │ ~1%      │
│ (single-thread)  │          │ (1 GC thread)│ (< 1GB)      │          │
└──────────────────┴──────────┴──────────────┴──────────────┴──────────┘
```

## GC Log Analysis

```
Enable GC logging (JDK 17+):
  -Xlog:gc*:file=gc.log:time,uptime,level,tags:filecount=5,filesize=10m

Key things to look for in GC logs:

1. Pause times:
   [gc,pause] GC(42) Pause Young (Normal) 234M->56M(512M) 12.345ms
                                                           ^^^^^^^^
   Is this acceptable? Compare against your SLA.

2. Frequency:
   How many GC pauses per minute?
   Too frequent = heap too small or allocation rate too high.

3. Promotion rate:
   Objects moving from young to old generation.
   High promotion = objects live too long for young gen
                  = possible memory leak or cache holding references.

4. Full GC:
   [gc] GC(100) Pause Full (Ergonomics) 450M->200M(512M) 2.345s
   Full GCs should be rare. If frequent:
     - Heap too small
     - Memory leak
     - Too many long-lived objects

5. Allocation rate:
   How fast is Eden filling up?
   High allocation rate = more minor GCs = more pauses.

Tools for GC log analysis:
  - GCEasy (gceasy.io) — upload GC log, get visual analysis
  - GCViewer — open-source desktop app
  - jstat -gc <pid> — live GC statistics
  - JFR (Java Flight Recorder) — built-in profiling
```

## Common Tuning Scenarios

```
Problem: Long GC pauses (p99 latency spikes)
  Diagnosis: GC log shows pauses > target
  Fix:
    - Switch to ZGC (-XX:+UseZGC) for < 1ms pauses
    - Or reduce G1 target: -XX:MaxGCPauseMillis=50
    - Increase heap to reduce GC frequency
    - Reduce allocation rate (reuse objects, avoid autoboxing)

Problem: Frequent Full GCs
  Diagnosis: GC log shows repeated Full GC events
  Fix:
    - Increase heap (-Xmx)
    - Check for memory leaks (heap dump + MAT)
    - Lower InitiatingHeapOccupancyPercent to start concurrent
      marking earlier
    - Check for humongous allocations (objects > half a G1 region)

Problem: High allocation rate
  Diagnosis: Eden fills up in milliseconds, minor GCs very frequent
  Fix:
    - Profile allocations (async-profiler -e alloc)
    - Reuse objects (object pooling for hot paths)
    - Avoid autoboxing (int vs Integer)
    - Use primitive arrays instead of ArrayList<Integer>
    - Use StringBuilder instead of string concatenation in loops

Problem: Premature promotion
  Diagnosis: Objects promoted to old gen that die shortly after
  Fix:
    - Increase young gen size (-Xmn or -XX:NewRatio)
    - Increase MaxTenuringThreshold
    - Profile object lifetimes

Problem: GC overhead > 10% of CPU
  Diagnosis: jstat shows high GC time ratio
  Fix:
    - Increase heap (less frequent GC)
    - Reduce allocation rate
    - Switch to Parallel GC if latency is not critical
```

## Key JVM Flags

```
Heap sizing:
  -Xms4g                              Initial heap size
  -Xmx4g                              Maximum heap size
  -Xmn1g                              Young generation size
  -XX:MaxMetaspaceSize=256m            Metaspace limit

G1 tuning:
  -XX:MaxGCPauseMillis=200             Pause time target
  -XX:G1HeapRegionSize=8m              Region size (1-32MB)
  -XX:InitiatingHeapOccupancyPercent=45  Start concurrent marking
  -XX:G1MixedGCCountTarget=8           Mixed GC iterations
  -XX:G1ReservePercent=10              Reserve for promotion

ZGC tuning:
  -XX:+UseZGC                          Enable ZGC
  -XX:+ZGenerational                   Generational mode (JDK 21+)
  -XX:SoftMaxHeapSize=4g               Target heap size
  -XX:ZCollectionInterval=0            Force periodic GC (0=off)

Diagnostics:
  -Xlog:gc*:file=gc.log                GC logging
  -XX:+HeapDumpOnOutOfMemoryError      Heap dump on OOM
  -XX:HeapDumpPath=/tmp/heap.hprof     Heap dump location
  -XX:NativeMemoryTracking=summary     Track native memory

General:
  -XX:+AlwaysPreTouch                  Pre-touch heap pages at startup
  -XX:+UseStringDeduplication          Deduplicate strings (G1/ZGC)
  -XX:+UseCompressedOops               Compress object pointers (< 32GB)
```

## Decision Flowchart

```
What matters most?

  Latency (< 1ms p99 GC pause)?
    └─► ZGC (-XX:+UseZGC -XX:+ZGenerational)

  Latency (< 10ms p99)?
    └─► Shenandoah (-XX:+UseShenandoahGC)
        or G1 with tuned pause target

  Throughput (batch, data pipeline)?
    └─► Parallel GC (-XX:+UseParallelGC)

  General purpose / unsure?
    └─► G1 (default, no flag needed)

  Tiny heap (< 512MB)?
    └─► Serial GC (-XX:+UseSerialGC)
        or G1

  Huge heap (> 32GB)?
    └─► ZGC (scales to 16TB, constant pause times)
```

## Pros

- **Predictable Latency**: ZGC/Shenandoah deliver sub-millisecond pauses regardless of heap size
- **Throughput Optimization**: Parallel GC maximizes batch processing speed
- **Automatic Memory Management**: no manual free/malloc — GC handles it
- **Modern Defaults**: G1 is well-tuned out of the box for most workloads since JDK 9
- **Observability**: GC logs, JFR, jstat provide detailed runtime visibility
- **No Memory Leaks** (mostly): GC eliminates use-after-free and double-free bugs
- **Concurrent Collection**: G1, ZGC, Shenandoah do most work without stopping the application
- **Adaptive**: collectors self-tune based on observed behavior

## Cons

- **Stop-the-World Pauses**: even ZGC has brief pauses (~0.2ms) — not zero
- **Throughput Tax**: concurrent collectors use 10-15% of CPU for GC work
- **Memory Overhead**: GC metadata (card tables, remembered sets) consumes extra memory
- **Tuning Complexity**: wrong settings can make performance worse than defaults
- **Unpredictable Full GC**: even well-tuned systems can hit Full GC under memory pressure
- **Warm-Up**: JIT + GC ergonomics need time to stabilize after startup
- **Allocation Rate Sensitivity**: high allocation rate overwhelms any collector
- **Not Deterministic**: GC timing is non-deterministic — hard to guarantee worst-case latency

## Use Cases

- **Web Services**: G1 or ZGC for consistent API response times under load
- **Trading Systems**: ZGC for sub-millisecond GC pauses on latency-critical paths
- **Big Data Processing**: Parallel GC for Spark/Flink batch jobs maximizing throughput
- **Microservices**: ZGC with smaller heaps for containerized services
- **Kafka Brokers**: G1 with tuned region size and IHOP for stable broker performance
- **Elasticsearch Nodes**: G1 with large heaps, careful survivor ratio tuning
- **Application Servers**: G1 as default, ZGC if p99 latency is critical
- **CI/CD Build Servers**: Parallel GC for build tools (Maven, Gradle) maximizing throughput
