# Profiling

## What is it?

Profiling is the practice of measuring where a program spends its time, how it uses memory, and where bottlenecks exist. A profiler instruments or samples the running program to collect data about function call frequency, execution duration, memory allocations, cache misses, lock contention, and I/O wait time. The output is then visualized as flame graphs, call trees, or statistical summaries to identify the specific code paths responsible for performance problems. Profiling replaces guessing with measurement — the actual bottleneck is almost never where you think it is.

## How it works?

### Profiling Methods

```
┌──────────────────────┬──────────────────────────────────────────┐
│ Method               │ How it works                              │
├──────────────────────┼──────────────────────────────────────────┤
│ Sampling             │ Interrupt the program at fixed intervals  │
│                      │ (e.g., every 10ms) and record the current│
│                      │ call stack. Statistical approximation.    │
│                      │ Low overhead (~2-5%).                     │
├──────────────────────┼──────────────────────────────────────────┤
│ Instrumentation      │ Insert measurement code at function       │
│                      │ entry/exit. Exact call counts and times.  │
│                      │ High overhead (~10-100x slowdown).        │
├──────────────────────┼──────────────────────────────────────────┤
│ Event-based          │ Use hardware performance counters (PMU)   │
│                      │ to count CPU cycles, cache misses, branch│
│                      │ mispredictions. Very low overhead.        │
├──────────────────────┼──────────────────────────────────────────┤
│ Tracing              │ Record every event (syscall, context      │
│                      │ switch, disk I/O). Complete picture but   │
│                      │ generates large data volumes.             │
└──────────────────────┴──────────────────────────────────────────┘


Sampling profiler timeline:

  Program execution:
  ────[func_A]────[func_B]──[func_C]────[func_A]────[func_B]──►

  Samples (every 10ms):
       ↓              ↓         ↓           ↓           ↓
     func_A         func_B    func_C      func_A      func_B

  Result: func_A = 40%, func_B = 40%, func_C = 20%
  Conclusion: func_A and func_B are the hot spots.
```

### What to Profile

```
┌──────────────────────┬──────────────────────────────────────────┐
│ Dimension            │ What it reveals                           │
├──────────────────────┼──────────────────────────────────────────┤
│ CPU time             │ Which functions consume the most CPU     │
│ (on-CPU)             │ cycles. Hot loops, expensive algorithms. │
├──────────────────────┼──────────────────────────────────────────┤
│ Wall-clock time      │ Total elapsed time including I/O waits,  │
│ (off-CPU)            │ lock contention, sleep, network wait.    │
├──────────────────────┼──────────────────────────────────────────┤
│ Memory allocations   │ Which functions allocate the most memory.│
│                      │ Allocation rate, object lifetimes, leaks.│
├──────────────────────┼──────────────────────────────────────────┤
│ Lock contention      │ Which locks are most contested. Time     │
│                      │ spent waiting for locks.                 │
├──────────────────────┼──────────────────────────────────────────┤
│ Cache misses         │ L1/L2/L3 cache miss rates. Memory access │
│                      │ patterns that defeat the cache hierarchy.│
├──────────────────────┼──────────────────────────────────────────┤
│ I/O                  │ Disk read/write latency and throughput.  │
│                      │ Network socket wait time.                │
├──────────────────────┼──────────────────────────────────────────┤
│ GC pressure          │ Garbage collection frequency, pause time,│
│                      │ promoted objects, heap growth rate.      │
└──────────────────────┴──────────────────────────────────────────┘
```

## Flame Graphs

```
Invented by Brendan Gregg (Netflix, 2011).

A flame graph is a visualization of sampled stack traces:
  - X-axis: stack frames sorted alphabetically (NOT time)
  - Y-axis: stack depth (bottom = entry point, top = leaf function)
  - Width: proportion of samples (wider = more CPU time)

┌──────────────────────────────────────────────────────┐
│                         main()                        │
├──────────────────────┬───────────────────────────────┤
│    handleRequest()   │       processQueue()           │
├──────────┬───────────┤───────────────┬───────────────┤
│ parseJSON│ validate  │ dequeue()     │  serialize()   │
├──────────┤           ├───────────────┤───────┬───────┤
│ tokenize │           │ lock.acquire()│ encode│ flush │
└──────────┘           └───────────────┘───────┘───────┘

Reading: parseJSON→tokenize is a hot path (wide).
         lock.acquire() is another hot spot (contention).

Generate:
  perf record -g -p <pid> -- sleep 30
  perf script | stackcollapse-perf.pl | flamegraph.pl > flame.svg

Types of flame graphs:
  - CPU flame graph (on-CPU time)
  - Off-CPU flame graph (time blocked on I/O, locks, sleep)
  - Memory flame graph (allocation sites)
  - Differential flame graph (compare before/after)
```

## Profiling Tools

### Linux: perf

```
perf is the standard Linux profiler. Uses hardware performance counters.

CPU profiling:
  perf record -g -p <pid> -- sleep 30
  perf report

Count events:
  perf stat -e cycles,instructions,cache-misses,branch-misses ./program

  Performance counter stats:
    1,234,567,890  cycles
      987,654,321  instructions    # 0.80 insn per cycle
        5,432,100  cache-misses    # 0.55% of cache refs
          123,456  branch-misses   # 0.12% of branches

Top functions by CPU:
  perf top -p <pid>

Record with call graph (dwarf):
  perf record -g --call-graph dwarf -p <pid> -- sleep 10
```

### JVM: async-profiler

```
Low-overhead sampling profiler for JVM. No safepoint bias.

CPU profiling:
  ./asprof -d 30 -f profile.html <pid>

Allocation profiling:
  ./asprof -e alloc -d 30 -f alloc.html <pid>

Lock contention:
  ./asprof -e lock -d 30 -f locks.html <pid>

Wall-clock profiling (includes I/O wait):
  ./asprof -e wall -d 30 -f wall.html <pid>

Output: interactive HTML flame graph.

Why async-profiler over JVisualVM / JFR?
  - No safepoint bias (samples at any point, not just safepoints)
  - Can profile native code (JNI, GC, compiler)
  - Very low overhead (~2%)
  - Allocation profiling without TLAB bias
```

### Go: pprof

```
Go has built-in profiling support.

Enable in code:
  import _ "net/http/pprof"
  go func() { http.ListenAndServe(":6060", nil) }()

CPU profile:
  go tool pprof http://localhost:6060/debug/pprof/profile?seconds=30

Heap profile:
  go tool pprof http://localhost:6060/debug/pprof/heap

Goroutine profile:
  go tool pprof http://localhost:6060/debug/pprof/goroutine

Block profile (lock contention):
  go tool pprof http://localhost:6060/debug/pprof/block

Interactive commands:
  (pprof) top10         # top 10 functions by CPU
  (pprof) web           # open flame graph in browser
  (pprof) list funcName # show annotated source code

Benchmark profiling:
  go test -bench=. -cpuprofile=cpu.out -memprofile=mem.out
  go tool pprof cpu.out
```

### Python: py-spy / cProfile

```
py-spy (sampling, no code changes):
  py-spy record -o profile.svg --pid <pid>
  py-spy top --pid <pid>

  Advantages:
    - No code changes required
    - Works on running processes
    - Low overhead
    - Generates flame graphs directly

cProfile (instrumentation, built-in):
  python -m cProfile -o output.prof script.py
  
  import pstats
  stats = pstats.Stats('output.prof')
  stats.sort_stats('cumulative')
  stats.print_stats(20)

  Output:
    ncalls  tottime  percall  cumtime  percall filename:lineno(function)
     1000    0.500    0.001    1.200    0.001 db.py:42(query)
      500    0.300    0.001    0.800    0.002 serialize.py:10(to_json)
```

### Rust: perf + cargo-flamegraph

```
cargo flamegraph:
  cargo install flamegraph
  cargo flamegraph --bin my_program

  Generates an SVG flame graph from perf data.
  Requires debug symbols (profile.release debug = true).

Criterion (micro-benchmarks):
  cargo bench

  Provides statistical analysis:
    - Mean, median, standard deviation
    - Comparison with previous runs
    - Regression detection
```

### Node.js

```
Built-in V8 profiler:
  node --prof app.js
  node --prof-process isolate-*.log > profile.txt

Chrome DevTools:
  node --inspect app.js
  Open chrome://inspect → Performance tab → Record

clinic.js (performance diagnostics):
  npx clinic doctor -- node app.js
  npx clinic flame -- node app.js
  npx clinic bubbleprof -- node app.js

0x (flame graph):
  npx 0x app.js
```

## Tool Comparison

```
┌──────────────────┬────────────┬──────────────┬───────────┬──────────┐
│ Tool             │ Platform   │ Method       │ Overhead  │ Output   │
├──────────────────┼────────────┼──────────────┼───────────┼──────────┤
│ perf             │ Linux      │ Sampling /   │ ~1-3%     │ Report,  │
│                  │            │ HW counters  │           │ flame    │
├──────────────────┼────────────┼──────────────┼───────────┼──────────┤
│ async-profiler   │ JVM        │ Sampling     │ ~2%       │ Flame,   │
│                  │ (Linux/Mac)│ (async)      │           │ JFR, text│
├──────────────────┼────────────┼──────────────┼───────────┼──────────┤
│ JFR (Flight      │ JVM        │ Event-based  │ ~1-2%     │ JFR file │
│ Recorder)        │            │              │           │ (JMC UI) │
├──────────────────┼────────────┼──────────────┼───────────┼──────────┤
│ pprof            │ Go         │ Sampling     │ ~2-5%     │ Report,  │
│                  │            │              │           │ flame, web│
├──────────────────┼────────────┼──────────────┼───────────┼──────────┤
│ py-spy           │ Python     │ Sampling     │ ~2%       │ Flame,   │
│                  │            │              │           │ top      │
├──────────────────┼────────────┼──────────────┼───────────┼──────────┤
│ Instruments      │ macOS      │ Sampling /   │ Varies    │ Trace    │
│ (Xcode)          │            │ tracing      │           │ file, UI │
├──────────────────┼────────────┼──────────────┼───────────┼──────────┤
│ VTune            │ Intel CPUs │ Sampling /   │ ~2-5%     │ Rich UI  │
│ (Intel)          │            │ HW counters  │           │          │
├──────────────────┼────────────┼──────────────┼───────────┼──────────┤
│ Valgrind         │ Linux      │ Instrumented │ 10-50x    │ Report   │
│ (callgrind)      │            │ simulation   │ slowdown  │          │
└──────────────────┴────────────┴──────────────┴───────────┴──────────┘
```

## Continuous Profiling

```
Profile in production continuously and store profiles over time.

┌─────────────────────────────────────────────────────┐
│  Application                                         │
│  ┌─────────────────┐                                │
│  │ Profiling Agent  │──► collect samples every 10s   │
│  │ (low overhead)   │                                │
│  └────────┬─────────┘                                │
│           │                                          │
│           │ send profiles                            │
│           ▼                                          │
│  ┌─────────────────┐                                │
│  │ Backend          │──► store, index, aggregate     │
│  │ (Pyroscope,      │                                │
│  │  Datadog, Parca) │                                │
│  └────────┬─────────┘                                │
│           │                                          │
│           ▼                                          │
│  ┌─────────────────┐                                │
│  │ UI               │──► flame graphs by time range  │
│  │ Compare deploys  │    diff profiles (before/after)│
│  │ Find regressions │    tag by version, service     │
│  └─────────────────┘                                │
└─────────────────────────────────────────────────────┘

Tools:
  - Pyroscope (Grafana, open-source)
  - Parca (open-source, eBPF-based)
  - Datadog Continuous Profiler
  - Google Cloud Profiler
```

## Pros

- **Data-Driven**: replaces guessing with measurement — find the actual bottleneck
- **Low Overhead**: sampling profilers add ~2-5% overhead — safe for production
- **Visual**: flame graphs make hot paths immediately obvious
- **Multi-Dimensional**: CPU, memory, I/O, locks, GC — profile different dimensions
- **Regression Detection**: continuous profiling catches performance regressions per deploy
- **Root Cause**: profiles show the exact function and line number, not just symptoms
- **Language Support**: mature profilers exist for every major language and runtime
- **Production Safety**: sampling profilers are designed for production use

## Cons

- **Sampling Bias**: low-frequency events may not appear in samples
- **Instrumentation Overhead**: instrumentation profilers slow the program significantly
- **Observer Effect**: profiling can change timing behavior (cache effects, scheduling)
- **Symbol Resolution**: stripped binaries and JIT-compiled code complicate stack traces
- **Interpretation Skill**: reading flame graphs and identifying actionable bottlenecks requires experience
- **Micro-Optimization Trap**: profiling can lead to optimizing code that does not matter for end-user latency
- **Context Loss**: profilers show WHERE time is spent, not always WHY
- **Platform Dependency**: some profilers only work on specific OS or hardware (perf = Linux only)

## Use Cases

- **Latency Investigation**: identify why an API endpoint is slow under load
- **Memory Leak Detection**: find allocation sites that accumulate without being freed
- **GC Tuning**: identify excessive allocation rates that cause GC pauses
- **Lock Contention**: find heavily contested locks in multi-threaded applications
- **Regression Analysis**: compare profiles before and after a deploy to find regressions
- **Capacity Planning**: understand resource consumption per request to forecast scaling needs
- **Database Query Optimization**: profile application-level time spent in database calls
- **Startup Time Optimization**: profile application boot to reduce cold start latency
- **Library Evaluation**: profile candidate libraries to compare real-world performance
- **Incident Response**: attach a profiler to a misbehaving production instance for immediate diagnosis
