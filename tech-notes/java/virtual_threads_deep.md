# Virtual Threads in Spring Boot with Tomcat - Complete Guide

## Table of Contents
- [How Virtual Threads Work](#how-virtual-threads-work)
- [Carrier Thread Blocking and Starvation](#carrier-thread-blocking-and-starvation)
- [Pros and Cons of Virtual Threads](#pros-and-cons-of-virtual-threads)

---

## How Virtual Threads Work

### The Basics

**Virtual threads** (from Project Loom, Java 21+) are lightweight threads managed by the JVM rather than the OS. Unlike traditional platform threads that map 1:1 to OS threads, thousands or even millions of virtual threads can run on a small number of platform threads.

### How It Works in Spring Boot + Tomcat

#### 1. Request Handling Flow

When you enable virtual threads in Spring Boot:

- Tomcat receives an HTTP request
- Instead of assigning it to a traditional platform thread from the thread pool, it creates/uses a **virtual thread**
- That virtual thread handles the entire request lifecycle
- When the thread hits a blocking operation (I/O, database call, sleep), it doesn't block a platform thread—it gets **unmounted**
- The underlying platform thread is freed to do other work
- When the I/O completes, the virtual thread **remounts** on any available platform thread

#### 2. Configuration

In Spring Boot 3.2+, you can enable virtual threads simply:

```properties
spring.threads.virtual.enabled=true
```

This tells Spring Boot to use virtual threads for:
- Tomcat's request processing
- `@Async` methods
- Scheduled tasks

#### 3. Benefits with Tomcat

Traditional Tomcat uses a thread pool (default ~200 threads). With virtual threads:

- You can handle **thousands of concurrent requests** without increasing the thread pool
- No more thread pool exhaustion under high load
- Blocking I/O operations (database queries, HTTP calls, file I/O) no longer waste threads
- Particularly beneficial for I/O-heavy applications

#### 4. What Doesn't Change

Your application code remains the same! You can still write blocking code naturally—no need for reactive programming. The virtual thread magic happens at the JVM level.

**Key Point**: Virtual threads shine when your app does lots of blocking I/O. For CPU-intensive work, they don't provide much benefit over platform threads.

---

## Carrier Thread Blocking and Starvation

### Question
> What if I have 200 platform threads in my Tomcat with Spring Boot + virtual threads but all 200 carrier threads are blocked because I have all requests that take 60s? Will I have starvation?

### Important Clarification

When you enable virtual threads in Spring Boot with Tomcat, you **don't configure 200 platform threads**. The carrier threads (platform threads) are managed by the **JVM's ForkJoinPool** and typically equal your **CPU cores** (not 200).

For example, on a system with 64 vCPUs, you have **64 carrier threads**, not 200.

### The Critical Distinction: WHAT KIND of Blocking?

#### Scenario 1: 60s of BLOCKING I/O (Database, HTTP calls, sleep) ✅ NO STARVATION

```
Request 1-200 hit database call (60s) → All virtual threads UNMOUNT
→ All 64 carrier threads are FREE
→ Request 201 arrives → Processes immediately
→ NO STARVATION ✅
```

**Why?** This is the whole magic of virtual threads! When a virtual thread hits blocking I/O, it **unmounts** from the carrier thread. The carrier thread is freed to run other virtual threads.

#### Scenario 2: 60s of CPU-INTENSIVE work (tight loops, heavy computation) ❌ YES STARVATION

```
Request 1-64 doing heavy CPU computation (60s) → Virtual threads stay MOUNTED
→ All 64 carrier threads are BLOCKED
→ Request 65 arrives → Must WAIT
→ STARVATION ❌
```

**Why?** CPU-intensive work keeps the virtual thread mounted on the carrier thread. If all carrier threads are doing CPU work, new virtual threads must wait.

### What Are Your 60s Requests Doing?

#### Unmounts (No Starvation) ✅

If they're waiting on:
- Database queries → Unmounts → No starvation ✅
- HTTP API calls → Unmounts → No starvation ✅
- File I/O → Unmounts → No starvation ✅
- `Thread.sleep()` → Unmounts → No starvation ✅
- Reading from sockets → Unmounts → No starvation ✅

#### Stays Mounted (Potential Starvation) ❌

If they're doing:
- Heavy computation (CPU-bound) → Stays mounted → Starvation ❌
- Tight loops → Stays mounted → Starvation ❌
- Synchronized blocks (see below) → May stay mounted → Potential starvation ⚠️

### Special Case: Pinned Virtual Threads

There are some scenarios where virtual threads can get **"pinned"** to carrier threads even during blocking operations:

1. **Synchronized blocks** - While inside a `synchronized` block, the virtual thread may not unmount
2. **Native methods** - Some JNI calls can pin threads

#### Example: Pinned Thread (Bad)

```java
// This can cause pinning! ⚠️
synchronized(lock) {
    database.query(); // Virtual thread STAYS MOUNTED during this I/O
}
```

#### Example: Unpinned Thread (Good)

```java
// This is better ✅
ReentrantLock lock = new ReentrantLock();
lock.lock();
try {
    database.query(); // Virtual thread can UNMOUNT during this I/O
} finally {
    lock.unlock();
}
```

### Direct Answer

**If all 64 carrier threads are truly blocked:**

- **Scenario A:** All 64 requests doing I/O blocking → Virtual threads unmount → **NO starvation** (this is the normal case)
- **Scenario B:** All 64 requests doing CPU work OR pinned in synchronized blocks → Virtual threads stay mounted → **YES, starvation** (new requests queue up)

### How to Avoid This Issue

1. **Avoid long-running CPU-intensive work** on virtual threads
2. **Use `ReentrantLock` instead of `synchronized`** for better unmounting behavior
3. **Monitor for thread pinning** - JVM provides warnings if this happens frequently
4. **Offload CPU-intensive work** to a separate thread pool if needed

### Bottom Line

For typical **I/O-bound web applications** (which is 99% of Spring Boot apps), you **won't have starvation** even with thousands of 60s blocking requests. Virtual threads unmount during I/O, keeping carrier threads free.

You'd only get starvation if your 60s requests are doing actual **CPU computation** or are **pinned** inside synchronized blocks - which is unlikely in most web apps.

---

## Pros and Cons of Virtual Threads

### ✅ Pros

#### 1. Massive Concurrency
- Handle **thousands to millions** of concurrent requests
- No thread pool exhaustion
- Each virtual thread uses only ~1-10 KB of memory vs ~1 MB for platform threads

#### 2. Simple Programming Model
- Write **blocking code** naturally (no reactive complexity)
- No need to learn Reactor, WebFlux, or async/await patterns
- Easier to read, debug, and maintain

#### 3. Efficient Resource Utilization
- Blocking I/O doesn't waste threads
- Carrier threads stay busy with useful work
- Better CPU utilization

#### 4. Drop-in Replacement
- Minimal code changes required
- Just enable in configuration: `spring.threads.virtual.enabled=true`
- Existing blocking code works as-is

#### 5. Perfect for I/O-Bound Applications
- Database queries
- HTTP API calls
- File I/O operations
- Microservices communication

#### 6. Better Than Thread Pools
- No need to tune thread pool sizes
- No guessing optimal pool size for different workloads
- Scales automatically based on actual concurrency needs

#### 7. Lower Latency Under Load
- Fast requests don't wait behind slow requests
- No head-of-line blocking in thread pools

### ❌ Cons

#### 1. Java 21+ Requirement
- Must upgrade to Java 21 or later
- Not available in older Java versions
- May require application and dependency updates

#### 2. Thread Pinning Issues
- **Synchronized blocks** can cause pinning
- Pinned threads can't unmount during I/O
- May need to refactor code to use `ReentrantLock` instead

```java
// Problematic
synchronized(lock) {
    blockingIO(); // May pin thread
}

// Better
ReentrantLock lock = new ReentrantLock();
lock.lock();
try {
    blockingIO(); // Can unmount
} finally {
    lock.unlock();
}
```

#### 3. Limited Benefit for CPU-Bound Work
- Virtual threads don't help with pure computation
- Still limited by number of CPU cores
- May actually add overhead for CPU-intensive tasks

#### 4. ThreadLocal Overhead
- Each virtual thread has its own ThreadLocal storage
- With millions of virtual threads, ThreadLocal memory usage can grow
- May need to reconsider ThreadLocal-heavy code

#### 5. Monitoring and Observability Challenges
- Traditional thread monitoring tools may not work well
- Harder to debug with millions of threads
- Stack traces can be more complex
- Need new monitoring strategies

#### 6. Library Compatibility
- Some libraries may not work well with virtual threads
- Pooling mechanisms (connection pools) need reconsideration
- Native code (JNI) can cause pinning issues

#### 7. Not a Silver Bullet for All Problems
- Doesn't fix poorly designed architectures
- Won't help with database connection limits
- Other resources (DB connections, network sockets) can still bottleneck

#### 8. Learning Curve for Advanced Usage
- Understanding unmounting/mounting behavior
- Identifying and fixing thread pinning
- Knowing when NOT to use virtual threads (CPU-bound work)

#### 9. Potential for Resource Exhaustion
- Easy to create millions of threads without realizing it
- Can overwhelm downstream services
- May need rate limiting or circuit breakers
- Memory usage can still grow (though less than platform threads)

### 📊 When to Use Virtual Threads

| Use Case | Recommendation |
|----------|----------------|
| I/O-bound microservices | ✅ Excellent choice |
| RESTful APIs with DB calls | ✅ Excellent choice |
| High-concurrency web servers | ✅ Excellent choice |
| CPU-intensive processing | ❌ Use platform threads or ForkJoinPool |
| Legacy Java < 21 applications | ❌ Not available |
| Apps with heavy synchronized usage | ⚠️ Use with caution, refactor to ReentrantLock |
| Reactive apps (WebFlux) | ⚠️ Usually unnecessary, virtual threads compete with reactive |

### 🎯 Best Practices

1. **Use for I/O-bound workloads** - This is where they shine
2. **Avoid `synchronized`** - Use `ReentrantLock` instead to prevent pinning
3. **Monitor thread pinning** - Enable JVM flags to detect pinning events
4. **Don't pool virtual threads** - Create them on-demand, they're cheap
5. **Keep ThreadLocal usage minimal** - Can consume memory with many threads
6. **Use appropriate connection pooling** - Don't create one connection per virtual thread
7. **Add rate limiting** - Protect downstream services from being overwhelmed
8. **Test under load** - Verify expected performance improvements

### 🔍 Key Metrics to Monitor

- **Thread pinning events** - Should be minimal
- **Memory usage** - Should be much lower than platform threads
- **Request latency** - Fast requests should stay fast even during slow request spikes
- **Throughput** - Should handle much higher concurrent requests
- **Carrier thread utilization** - Should stay high without blocking

---

## Netty vs Virtual Threads

Where Netty Might Win 🏆
* Absolute maximum throughput - Netty's zero-copy, direct buffer manipulation can be faster for pure network I/O
* Very low latency requirements - Event loop has less overhead than virtual thread mounting/unmounting
* Protocol-level control - Custom protocols, WebSockets, TCP servers benefit from Netty's control

Where Virtual Threads Win 🏆

* Development velocity - 10x easier to write and maintain
* Debugging - Stack traces are normal, not callback hell
* Mixed workloads - Easy to call blocking APIs (JDBC, legacy libraries)
* Team productivity - Most developers understand blocking code

# Threading Model Comparison: Mixed Fast & Slow Requests

## Question

Let's say I have a mix of fast and slow requests. Most fast requests get delivered in ~1ms, the slow ones take 60s, but are very few. Consider 3 scenarios:

- **Scenario A:** Spring Boot 3.5.6 + Tomcat + Virtual Threads + 64 vCPUs
- **Scenario B:** Spring Boot 3.5.6 + Tomcat (no virtual threads) = thread-per-request model + 64 vCPUs
- **Scenario C:** Spring Boot 3.5.6 + Netty with I/O worker pool = 64 and Hikari CP pool = 64 and also 64 vCPUs

Which one is best or worst and why?

---

## Analysis

### Key Factors

- Mix of fast (1ms) and slow (60s) requests
- Slow requests are rare
- 64 vCPUs available
- Need to consider throughput, resource utilization, and handling of slow requests

---

## Ranking: Best to Worst

### 🥇 Scenario A: Virtual Threads - BEST

#### Why It Wins

- When slow requests block (DB, I/O), virtual threads **unmount** and free the underlying platform thread
- Fast requests continue processing unimpeded on those freed platform threads
- Can handle thousands of concurrent slow requests without thread exhaustion
- Zero code changes needed—write simple blocking code
- With 64 vCPUs, you have 64 carrier threads that can efficiently multiplex thousands of virtual threads

#### Trade-offs

- Slight overhead for virtual thread creation/scheduling (negligible)
- Requires Java 21+

---

### 🥈 Scenario C: Netty + Worker Pool - MIDDLE (with a BIG caveat)

#### The Problem

You mentioned **Hikari CP pool = 64**. Hikari is a JDBC connection pool—that's **blocking I/O**. Using blocking JDBC calls with Netty is an **anti-pattern** that kills performance.

#### IF Using R2DBC (Non-blocking DB Driver)

**Good:**
- 64 event loop threads efficiently handle thousands of concurrent requests
- Slow requests don't block worker threads (everything is async/reactive)
- Excellent throughput for I/O-bound workloads

#### IF Using JDBC (Blocking)

**Terrible:**
- Each slow 60s request blocks one of your 64 worker threads
- Just a few slow requests can starve your entire event loop
- Fast requests get queued behind blocked workers
- This scenario becomes **worse than platform threads**

#### Complexity Cost

- Requires reactive programming (Reactor, WebFlux, R2DBC)
- Much harder to write and debug
- Any blocking call (JDBC, blocking APIs) breaks the model

---

### 🥉 Scenario B: Platform Threads - WORST

#### Why It Struggles

- Default Tomcat thread pool ≈ 200 threads
- Each 60s slow request holds a thread for the entire duration
- With only ~4 concurrent slow requests, you've tied up 240 seconds of thread time
- If slow requests spike even slightly, thread pool exhaustion occurs
- Fast requests get queued waiting for available threads

#### You Could Tune It

- Increase thread pool to 1000+ threads
- But now you're wasting memory and context-switching overhead
- Still fundamentally inefficient—threads just sitting idle during I/O

---

## The Verdict

**For your scenario: A > C > B**

Virtual Threads (A) is the clear winner because:

1. ✅ Handles slow requests gracefully without blocking threads
2. ✅ Fast requests stay fast
3. ✅ Simple blocking code (no reactive complexity)
4. ✅ Efficient resource utilization

**Scenario C** could be competitive if you're using a fully non-blocking stack (R2DBC, reactive HTTP clients), but the complexity cost is high. If you're using JDBC (Hikari suggests you are), it's actually worse than platform threads.

**Scenario B** is the worst here specifically because slow requests starve the thread pool, impacting fast requests.

Virtual threads emerge as the optimal solution. They elegantly handle the mixed workload by dynamically managing thread resources. When slow requests block, they free up platform threads, allowing fast requests to continue processing seamlessly. This approach prevents thread pool exhaustion and maximizes system responsiveness, making it the most efficient threading model for scenarios with varied request durations.

## CPU Pinning Considerations

Java 24 improves virtual thread performance with CPU pinning optimizations. By pinning carrier threads to specific CPU cores, the JVM reduces context-switching overhead and enhances cache locality. This is particularly beneficial in high-concurrency environments where virtual threads frequently unmount and remount on carrier threads.

Also look: https://mikemybytes.com/2025/04/09/java24-thread-pinning-revisited/

## Summary

Virtual threads represent a **paradigm shift** in how we handle concurrency in Java applications. They make it possible to write simple, blocking code that scales to handle massive concurrency—something previously only possible with complex reactive programming.

For I/O-bound Spring Boot applications, virtual threads offer:
- **Simpler code** (blocking style)
- **Better scalability** (thousands of concurrent requests)
- **Efficient resource usage** (no wasted threads)
- **Easy adoption** (minimal code changes)

However, they're not magic and won't solve every problem. Understanding when and how to use them effectively is key to getting the best results.

**Bottom line:** If you're building I/O-heavy microservices with Spring Boot and can use Java 21+, virtual threads should be your default choice.

---

*Document created: October 21, 2025*