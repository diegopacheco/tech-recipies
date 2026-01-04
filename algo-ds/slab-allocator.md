# Slab Allocator

## What is it?

A Slab Allocator is a memory management mechanism designed for efficient allocation of fixed-size objects. It pre-allocates memory in large chunks called "slabs" and divides them into smaller, equally-sized slots. When an object is needed, a free slot is returned; when freed, the slot is marked available for reuse. Invented by Jeff Bonwick at Sun Microsystems in 1994 for the Solaris kernel, slab allocation eliminates fragmentation for same-sized objects and provides O(1) allocation/deallocation with minimal overhead.

## How it works?

1. Pre-allocate a contiguous block of memory (slab) divided into fixed-size slots
2. Maintain a free list of available slots (often using the slots themselves as list nodes)
3. **Allocate**: Pop the first slot from the free list, return pointer to it
4. **Deallocate**: Push the freed slot back onto the free list
5. When a slab is exhausted, allocate a new slab
6. Optionally cache freed objects to avoid reinitializing them (object caching)
7. Group slabs by object size for multi-size allocation

The free list can be implemented as an embedded linked list within unused slots, eliminating external metadata overhead.

## Use cases?

- Operating system kernel object allocation (Linux, Solaris)
- Network buffer management (sk_buff in Linux)
- Game engine memory management
- Database buffer pools
- Web server connection pools
- Embedded systems with tight memory constraints
- Real-time systems requiring deterministic allocation
- Custom allocators for specific object types
- Graphics engine resource management
- High-frequency trading systems

## Code Sample (Rust)

```rust
use std::alloc::{alloc, dealloc, Layout};
use std::ptr::NonNull;
use std::marker::PhantomData;

struct FreeNode {
    next: Option<NonNull<FreeNode>>,
}

struct Slab {
    memory: NonNull<u8>,
    layout: Layout,
    slot_size: usize,
    slot_count: usize,
}

impl Slab {
    fn new(slot_size: usize, slot_count: usize) -> Option<Self> {
        let size = slot_size * slot_count;
        let layout = Layout::from_size_align(size, 8).ok()?;

        let memory = unsafe {
            let ptr = alloc(layout);
            NonNull::new(ptr)?
        };

        Some(Slab {
            memory,
            layout,
            slot_size,
            slot_count,
        })
    }

    fn slot_ptr(&self, index: usize) -> *mut u8 {
        unsafe { self.memory.as_ptr().add(index * self.slot_size) }
    }
}

impl Drop for Slab {
    fn drop(&mut self) {
        unsafe {
            dealloc(self.memory.as_ptr(), self.layout);
        }
    }
}

struct SlabAllocator {
    slabs: Vec<Slab>,
    free_list: Option<NonNull<FreeNode>>,
    slot_size: usize,
    slots_per_slab: usize,
    allocated_count: usize,
}

impl SlabAllocator {
    fn new(slot_size: usize, slots_per_slab: usize) -> Self {
        let actual_slot_size = slot_size.max(std::mem::size_of::<FreeNode>());
        let mut allocator = SlabAllocator {
            slabs: Vec::new(),
            free_list: None,
            slot_size: actual_slot_size,
            slots_per_slab,
            allocated_count: 0,
        };
        allocator.add_slab();
        allocator
    }

    fn add_slab(&mut self) -> bool {
        let Some(slab) = Slab::new(self.slot_size, self.slots_per_slab) else {
            return false;
        };

        for i in (0..self.slots_per_slab).rev() {
            let ptr = slab.slot_ptr(i) as *mut FreeNode;
            unsafe {
                (*ptr).next = self.free_list;
                self.free_list = Some(NonNull::new_unchecked(ptr));
            }
        }

        self.slabs.push(slab);
        true
    }

    fn allocate(&mut self) -> Option<NonNull<u8>> {
        if self.free_list.is_none() {
            if !self.add_slab() {
                return None;
            }
        }

        let node = self.free_list?;
        unsafe {
            self.free_list = (*node.as_ptr()).next;
        }
        self.allocated_count += 1;
        Some(node.cast())
    }

    fn deallocate(&mut self, ptr: NonNull<u8>) {
        let node = ptr.cast::<FreeNode>();
        unsafe {
            (*node.as_ptr()).next = self.free_list;
        }
        self.free_list = Some(node);
        self.allocated_count -= 1;
    }

    fn allocated(&self) -> usize {
        self.allocated_count
    }

    fn capacity(&self) -> usize {
        self.slabs.len() * self.slots_per_slab
    }
}

struct TypedSlab<T> {
    allocator: SlabAllocator,
    _marker: PhantomData<T>,
}

impl<T> TypedSlab<T> {
    fn new(slots_per_slab: usize) -> Self {
        TypedSlab {
            allocator: SlabAllocator::new(std::mem::size_of::<T>(), slots_per_slab),
            _marker: PhantomData,
        }
    }

    fn allocate(&mut self, value: T) -> Option<NonNull<T>> {
        let ptr = self.allocator.allocate()?;
        unsafe {
            std::ptr::write(ptr.as_ptr() as *mut T, value);
        }
        Some(ptr.cast())
    }

    fn deallocate(&mut self, ptr: NonNull<T>) {
        unsafe {
            std::ptr::drop_in_place(ptr.as_ptr());
        }
        self.allocator.deallocate(ptr.cast());
    }

    fn allocated(&self) -> usize {
        self.allocator.allocated()
    }
}

struct ObjectPool<T: Default> {
    slab: TypedSlab<T>,
    initializer: fn() -> T,
}

impl<T: Default> ObjectPool<T> {
    fn new(slots_per_slab: usize) -> Self {
        ObjectPool {
            slab: TypedSlab::new(slots_per_slab),
            initializer: T::default,
        }
    }

    fn acquire(&mut self) -> Option<NonNull<T>> {
        self.slab.allocate((self.initializer)())
    }

    fn release(&mut self, ptr: NonNull<T>) {
        self.slab.deallocate(ptr);
    }
}

#[derive(Debug)]
struct GameObject {
    id: u32,
    x: f32,
    y: f32,
    active: bool,
}

impl Default for GameObject {
    fn default() -> Self {
        GameObject {
            id: 0,
            x: 0.0,
            y: 0.0,
            active: false,
        }
    }
}

fn main() {
    println!("=== Basic Slab Allocator ===");
    let mut allocator = SlabAllocator::new(64, 10);

    let mut ptrs = Vec::new();
    for _ in 0..5 {
        if let Some(ptr) = allocator.allocate() {
            ptrs.push(ptr);
        }
    }

    println!("Allocated: {}/{}", allocator.allocated(), allocator.capacity());

    for ptr in ptrs.drain(..2) {
        allocator.deallocate(ptr);
    }

    println!("After freeing 2: {}/{}", allocator.allocated(), allocator.capacity());

    for _ in 0..10 {
        allocator.allocate();
    }

    println!("After allocating 10 more: {}/{}", allocator.allocated(), allocator.capacity());

    println!("\n=== Typed Slab ===");
    let mut typed_slab: TypedSlab<GameObject> = TypedSlab::new(100);

    let obj1 = typed_slab.allocate(GameObject {
        id: 1,
        x: 10.0,
        y: 20.0,
        active: true,
    });

    let obj2 = typed_slab.allocate(GameObject {
        id: 2,
        x: 30.0,
        y: 40.0,
        active: true,
    });

    if let Some(ptr) = obj1 {
        unsafe {
            println!("Object 1: {:?}", *ptr.as_ptr());
        }
        typed_slab.deallocate(ptr);
    }

    println!("Allocated GameObjects: {}", typed_slab.allocated());

    println!("\n=== Object Pool ===");
    let mut pool: ObjectPool<GameObject> = ObjectPool::new(50);

    let mut objects = Vec::new();
    for i in 0..5 {
        if let Some(ptr) = pool.acquire() {
            unsafe {
                (*ptr.as_ptr()).id = i;
                (*ptr.as_ptr()).active = true;
            }
            objects.push(ptr);
        }
    }

    println!("Pool allocated: {}", pool.slab.allocated());

    for obj in objects {
        pool.release(obj);
    }

    println!("Pool after release: {}", pool.slab.allocated());
}
```

## Pros and Cons

### Pros
- O(1) allocation and deallocation
- Zero external fragmentation for same-sized objects
- Minimal per-object metadata overhead
- Cache-friendly memory layout
- Predictable allocation times (good for real-time systems)
- Can cache initialized objects for faster reuse
- Reduces system call overhead by batching allocations

### Cons
- Only efficient for fixed-size objects
- Internal fragmentation if slot size doesn't match object size
- Memory not returned to OS until slab is completely empty
- Requires knowing object sizes in advance
- Multiple slabs needed for different object sizes
- Can waste memory if many slabs are partially used
- More complex than simple malloc/free

## Frameworks or libraries using it

- **Rust**: `slab` crate, `sharded-slab` crate, `typed-arena`
- **Linux Kernel**: SLUB/SLAB/SLOB allocators for kernel objects
- **FreeBSD**: Zone allocator based on slab concepts
- **Solaris**: Original slab allocator implementation
- **jemalloc**: Uses slab-like techniques for small objects
- **TCMalloc**: Google's malloc with slab-style thread caches
- **Memcached**: Slab allocator for cached objects
- **Nginx**: Memory pool with slab-like allocation
- **Redis**: Custom allocators for specific object types
- **Tokio**: Uses slab for managing async task handles
