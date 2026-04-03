# Summary JVM Threads vs Vritual Threads

Threads

* Threads are wrapper around OS Threads
* Have a cost and consume memory
* Can't have many, need a thread pool
* Good for CPU Bound, not good for IO Bound.
* 2k metadata, 1MB stack, 1-10us context switch

Code Sample (dont do this - use thread pools)
```java
public class JDKThread extends Thread {
  public void run(){
     System.out.println("running");
  }
}
JDKThread thread = new JDKThread();
thread.start();
```

Virtual Threads (Green Threads)

* Not 1:1 between Virtual/OS Threads (N:1 create millions of virtual threads)
* Virtual thread blocks, does not block the OS thread
* Virtual Threas are very good in waiting(suspend), it's a concurrency model like (Reactive programing, actors, STM). Make async looks like sync.
* Massive nun of virtual threads can lead to large cache misses and GC work(ThreadLocal on many virutal threads).
* Good for IO Bound, not good for CPU Bound(not pre-emptive - cant deschedulled while running).
* 200-300B metadata, Allocated on the heap, bellow 1us context switch

Code Sample
```java
Thread thread = Thread.ofVirtual().start(() -> System.out.println("Hello"));
thread.join();
```

#### Great Resources

* https://www.infoq.com/articles/java-virtual-threads/
* https://blog.rockthejvm.com/ultimate-guide-to-java-virtual-threads/
* https://www.youtube.com/watch?v=YRn10DR1sDM
* https://blog.fastthread.io/2023/11/18/virtual-threads-a-definite-advantage/
* https://openjdk.org/jeps/444
* https://docs.oracle.com/en/java/javase/21/core/virtual-threads.html

#### About me

* https://diegopacheco.github.io/
* http://diego-pacheco.blogspot.com/