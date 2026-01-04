# Ring Buffer

## What is it?

A Ring Buffer (also called circular buffer, circular queue, or cyclic buffer) is a fixed-size data structure that uses a single, contiguous block of memory as if it were connected end-to-end in a circle. It has two pointers: a head for reading and a tail for writing. When either pointer reaches the end of the buffer, it wraps around to the beginning. Ring buffers are fundamental in systems programming for implementing FIFO queues, streaming data, and producer-consumer patterns with bounded memory.

## How it works?

1. Allocate a fixed-size array with head and tail indices starting at 0
2. To write (enqueue): store data at tail position, increment tail with wraparound (tail = (tail + 1) % size)
3. To read (dequeue): read data at head position, increment head with wraparound
4. Buffer is empty when head == tail
5. Buffer is full when (tail + 1) % size == head (one slot kept empty to distinguish full from empty)
6. Alternatively, use a separate count variable to track occupancy
7. No memory allocation or deallocation during operation

The circular nature allows continuous operation without shifting elements.

## Use cases?

- Audio and video streaming buffers
- Network packet buffering
- Producer-consumer queues
- Keyboard input buffers
- Logging systems with fixed memory
- Real-time data acquisition
- Inter-process communication
- DMA transfer buffers
- Undo/redo history with limited depth
- Moving average calculations

## Code Sample (Rust)

```rust
struct RingBuffer<T> {
    buffer: Vec<Option<T>>,
    head: usize,
    tail: usize,
    capacity: usize,
    len: usize,
}

impl<T: Clone> RingBuffer<T> {
    fn new(capacity: usize) -> Self {
        RingBuffer {
            buffer: vec![None; capacity],
            head: 0,
            tail: 0,
            capacity,
            len: 0,
        }
    }

    fn push(&mut self, item: T) -> Option<T> {
        let overwritten = if self.is_full() {
            let old = self.buffer[self.head].take();
            self.head = (self.head + 1) % self.capacity;
            old
        } else {
            self.len += 1;
            None
        };

        self.buffer[self.tail] = Some(item);
        self.tail = (self.tail + 1) % self.capacity;
        overwritten
    }

    fn pop(&mut self) -> Option<T> {
        if self.is_empty() {
            return None;
        }

        let item = self.buffer[self.head].take();
        self.head = (self.head + 1) % self.capacity;
        self.len -= 1;
        item
    }

    fn peek(&self) -> Option<&T> {
        if self.is_empty() {
            None
        } else {
            self.buffer[self.head].as_ref()
        }
    }

    fn peek_back(&self) -> Option<&T> {
        if self.is_empty() {
            None
        } else {
            let idx = if self.tail == 0 { self.capacity - 1 } else { self.tail - 1 };
            self.buffer[idx].as_ref()
        }
    }

    fn is_empty(&self) -> bool {
        self.len == 0
    }

    fn is_full(&self) -> bool {
        self.len == self.capacity
    }

    fn len(&self) -> usize {
        self.len
    }

    fn capacity(&self) -> usize {
        self.capacity
    }

    fn clear(&mut self) {
        for slot in &mut self.buffer {
            *slot = None;
        }
        self.head = 0;
        self.tail = 0;
        self.len = 0;
    }

    fn iter(&self) -> RingBufferIter<T> {
        RingBufferIter {
            buffer: self,
            index: 0,
            remaining: self.len,
        }
    }
}

struct RingBufferIter<'a, T> {
    buffer: &'a RingBuffer<T>,
    index: usize,
    remaining: usize,
}

impl<'a, T: Clone> Iterator for RingBufferIter<'a, T> {
    type Item = &'a T;

    fn next(&mut self) -> Option<Self::Item> {
        if self.remaining == 0 {
            return None;
        }

        let actual_index = (self.buffer.head + self.index) % self.buffer.capacity;
        self.index += 1;
        self.remaining -= 1;
        self.buffer.buffer[actual_index].as_ref()
    }
}

struct MovingAverage {
    buffer: RingBuffer<f64>,
    sum: f64,
}

impl MovingAverage {
    fn new(window_size: usize) -> Self {
        MovingAverage {
            buffer: RingBuffer::new(window_size),
            sum: 0.0,
        }
    }

    fn add(&mut self, value: f64) {
        if let Some(old) = self.buffer.push(value) {
            self.sum -= old;
        }
        self.sum += value;
    }

    fn average(&self) -> Option<f64> {
        if self.buffer.is_empty() {
            None
        } else {
            Some(self.sum / self.buffer.len() as f64)
        }
    }
}

fn main() {
    let mut rb: RingBuffer<i32> = RingBuffer::new(5);

    for i in 1..=7 {
        let overwritten = rb.push(i);
        if let Some(old) = overwritten {
            println!("Pushed {}, overwrote {}", i, old);
        } else {
            println!("Pushed {}", i);
        }
    }

    println!("\nBuffer contents:");
    for item in rb.iter() {
        println!("  {}", item);
    }

    println!("\nPopping: {:?}", rb.pop());
    println!("Popping: {:?}", rb.pop());
    println!("Length after pops: {}", rb.len());

    println!("\n--- Moving Average ---");
    let mut ma = MovingAverage::new(3);
    for val in [1.0, 2.0, 3.0, 4.0, 5.0] {
        ma.add(val);
        println!("Added {}, average: {:?}", val, ma.average());
    }
}
```

## Pros and Cons

### Pros
- O(1) time complexity for enqueue and dequeue
- Fixed memory usage (no allocations after initialization)
- Cache-friendly contiguous memory layout
- Simple and efficient implementation
- No memory fragmentation
- Predictable performance (no GC pauses)
- Naturally handles overwrite policy for bounded buffers

### Cons
- Fixed capacity must be known in advance
- Cannot grow dynamically without reallocation
- One slot typically wasted to distinguish full from empty
- Not suitable for variable-size elements without wrapper
- Random access is less intuitive (requires index calculation)
- Concurrent access requires synchronization
- Overwrites old data when full (may lose data)

## Frameworks or libraries using it

- **Rust**: `ringbuf` crate, `circular-queue` crate, `bounded-spsc-queue`
- **Linux Kernel**: kfifo for device driver buffers
- **LMAX Disruptor**: High-performance inter-thread messaging
- **Java NIO**: ByteBuffer for network I/O
- **Apache Kafka**: Log segments use circular buffer concepts
- **ZeroMQ**: Message queuing buffers
- **FFmpeg**: Audio/video frame buffering
- **PortAudio**: Real-time audio streaming
- **JACK Audio**: Low-latency audio connections
- **io_uring**: Linux async I/O submission/completion rings
