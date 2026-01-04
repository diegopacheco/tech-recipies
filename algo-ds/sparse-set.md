# Sparse Set

## What is it?

A Sparse Set is a data structure for storing a set of integers from a bounded universe [0, U) with O(1) insertion, deletion, lookup, and clearing operations. It uses two arrays: a dense array that stores elements contiguously for fast iteration, and a sparse array that maps elements to their positions in the dense array. Unlike hash sets, sparse sets provide cache-friendly iteration and O(1) clearing without touching stored elements. They are heavily used in game engines, particularly in Entity Component Systems (ECS).

## How it works?

1. Maintain two arrays: `dense` (stores actual elements) and `sparse` (maps element to index in dense)
2. Track the count of elements in the set
3. **Insert**: Add element to end of dense array, record its position in sparse array
4. **Contains**: Check if sparse[x] < count AND dense[sparse[x]] == x
5. **Delete**: Swap element with last element in dense array, update sparse array accordingly
6. **Iterate**: Simply iterate through dense array from 0 to count-1
7. **Clear**: Just reset count to 0 (O(1), no memory clearing needed)

The key insight is that stale values in sparse array are detected because they fail the validation check.

## Use cases?

- Entity Component Systems in game engines
- Graph algorithms with vertex sets
- Compiler register allocation
- Sparse matrix operations
- Network flow algorithms
- Constraint solvers
- Real-time simulation systems
- Memory allocators for fixed-size pools
- Undo/redo systems with entity tracking
- Particle systems in games

## Code Sample (Rust)

```rust
struct SparseSet {
    sparse: Vec<usize>,
    dense: Vec<usize>,
    count: usize,
    capacity: usize,
}

impl SparseSet {
    fn new(capacity: usize) -> Self {
        SparseSet {
            sparse: vec![0; capacity],
            dense: vec![0; capacity],
            count: 0,
            capacity,
        }
    }

    fn contains(&self, value: usize) -> bool {
        if value >= self.capacity {
            return false;
        }
        let index = self.sparse[value];
        index < self.count && self.dense[index] == value
    }

    fn insert(&mut self, value: usize) -> bool {
        if value >= self.capacity || self.contains(value) {
            return false;
        }
        self.sparse[value] = self.count;
        self.dense[self.count] = value;
        self.count += 1;
        true
    }

    fn remove(&mut self, value: usize) -> bool {
        if !self.contains(value) {
            return false;
        }
        let index = self.sparse[value];
        let last = self.dense[self.count - 1];
        self.dense[index] = last;
        self.sparse[last] = index;
        self.count -= 1;
        true
    }

    fn clear(&mut self) {
        self.count = 0;
    }

    fn len(&self) -> usize {
        self.count
    }

    fn is_empty(&self) -> bool {
        self.count == 0
    }

    fn iter(&self) -> impl Iterator<Item = &usize> {
        self.dense[..self.count].iter()
    }
}

struct SparseMap<V> {
    sparse: Vec<usize>,
    dense: Vec<(usize, V)>,
    count: usize,
    capacity: usize,
}

impl<V: Clone> SparseMap<V> {
    fn new(capacity: usize) -> Self {
        SparseMap {
            sparse: vec![0; capacity],
            dense: Vec::with_capacity(capacity),
            count: 0,
            capacity,
        }
    }

    fn contains(&self, key: usize) -> bool {
        if key >= self.capacity {
            return false;
        }
        let index = self.sparse[key];
        index < self.count && self.dense[index].0 == key
    }

    fn insert(&mut self, key: usize, value: V) -> Option<V> {
        if key >= self.capacity {
            return None;
        }
        if self.contains(key) {
            let index = self.sparse[key];
            let old = std::mem::replace(&mut self.dense[index].1, value);
            return Some(old);
        }
        self.sparse[key] = self.count;
        if self.count < self.dense.len() {
            self.dense[self.count] = (key, value);
        } else {
            self.dense.push((key, value));
        }
        self.count += 1;
        None
    }

    fn get(&self, key: usize) -> Option<&V> {
        if !self.contains(key) {
            return None;
        }
        Some(&self.dense[self.sparse[key]].1)
    }

    fn get_mut(&mut self, key: usize) -> Option<&mut V> {
        if !self.contains(key) {
            return None;
        }
        Some(&mut self.dense[self.sparse[key]].1)
    }

    fn remove(&mut self, key: usize) -> Option<V> {
        if !self.contains(key) {
            return None;
        }
        let index = self.sparse[key];
        self.count -= 1;
        if index != self.count {
            self.dense.swap(index, self.count);
            self.sparse[self.dense[index].0] = index;
        }
        Some(self.dense.pop().unwrap().1)
    }

    fn clear(&mut self) {
        self.dense.clear();
        self.count = 0;
    }

    fn iter(&self) -> impl Iterator<Item = (usize, &V)> {
        self.dense[..self.count].iter().map(|(k, v)| (*k, v))
    }
}

struct ComponentStorage<T> {
    components: SparseMap<T>,
}

impl<T: Clone> ComponentStorage<T> {
    fn new(max_entities: usize) -> Self {
        ComponentStorage {
            components: SparseMap::new(max_entities),
        }
    }

    fn add(&mut self, entity: usize, component: T) {
        self.components.insert(entity, component);
    }

    fn remove(&mut self, entity: usize) -> Option<T> {
        self.components.remove(entity)
    }

    fn get(&self, entity: usize) -> Option<&T> {
        self.components.get(entity)
    }

    fn get_mut(&mut self, entity: usize) -> Option<&mut T> {
        self.components.get_mut(entity)
    }

    fn has(&self, entity: usize) -> bool {
        self.components.contains(entity)
    }

    fn iter(&self) -> impl Iterator<Item = (usize, &T)> {
        self.components.iter()
    }
}

fn main() {
    println!("=== Sparse Set ===");
    let mut set = SparseSet::new(1000);

    set.insert(42);
    set.insert(7);
    set.insert(999);
    set.insert(100);

    println!("Contains 42: {}", set.contains(42));
    println!("Contains 50: {}", set.contains(50));
    println!("Length: {}", set.len());

    println!("Elements: {:?}", set.iter().collect::<Vec<_>>());

    set.remove(7);
    println!("After removing 7: {:?}", set.iter().collect::<Vec<_>>());

    set.clear();
    println!("After clear, length: {}", set.len());

    println!("\n=== Sparse Map ===");
    let mut map: SparseMap<String> = SparseMap::new(1000);

    map.insert(10, "ten".to_string());
    map.insert(20, "twenty".to_string());
    map.insert(30, "thirty".to_string());

    println!("Get 20: {:?}", map.get(20));

    for (key, value) in map.iter() {
        println!("  {} -> {}", key, value);
    }

    println!("\n=== ECS Component Storage ===");
    let mut positions: ComponentStorage<(f32, f32)> = ComponentStorage::new(10000);

    positions.add(0, (0.0, 0.0));
    positions.add(5, (10.0, 20.0));
    positions.add(100, (5.5, 3.3));

    println!("Entity 5 position: {:?}", positions.get(5));

    for (entity, pos) in positions.iter() {
        println!("Entity {}: ({}, {})", entity, pos.0, pos.1);
    }
}
```

## Pros and Cons

### Pros
- O(1) insert, delete, lookup, and clear operations
- Cache-friendly iteration (dense array is contiguous)
- No tombstones or rehashing needed
- Clear operation is O(1) without touching elements
- Iteration is always O(n) where n is actual element count
- Predictable memory layout
- No hash function required

### Cons
- O(U) memory for sparse array where U is universe size
- Not suitable for unbounded or very large universes
- Only works with integer keys
- Iteration order is not stable (changes on delete)
- Memory overhead for sparse array even when nearly empty
- Cannot store duplicate values

## Frameworks or libraries using it

- **Rust**: `sparse-set` crate, used internally by `bevy_ecs`, `hecs`, `specs`
- **Bevy**: ECS game engine uses sparse sets for component storage
- **EnTT**: C++ ECS library heavily relies on sparse sets
- **Unity DOTS**: Entity Component System implementation
- **Flecs**: High-performance ECS in C
- **Our Machinery**: Game engine ECS architecture
- **LLVM**: Register allocation algorithms
- **Godot 4**: ECS-like systems for game objects
- **Amethyst**: Rust game engine (uses specs ECS)
- **Legion**: Rust ECS library
