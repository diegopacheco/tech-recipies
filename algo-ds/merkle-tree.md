# Merkle Tree

## What is it?

A Merkle Tree (also called a hash tree) is a tree data structure where every leaf node contains a cryptographic hash of a data block, and every non-leaf node contains a hash of its children's hashes. Named after Ralph Merkle who patented it in 1979, it enables efficient and secure verification of large data structures. By comparing only the root hash, you can verify if two datasets are identical, and by traversing the tree, you can identify exactly which parts differ.

## How it works?

1. Split data into blocks of fixed size
2. Compute cryptographic hash of each data block (leaf nodes)
3. Pair up adjacent hashes and concatenate them
4. Hash each pair to create parent nodes
5. Repeat until a single root hash remains
6. The root hash represents the entire dataset
7. To verify a piece of data, provide the sibling hashes along the path to root (Merkle proof)
8. Verification requires only O(log n) hashes instead of O(n)

If any data block changes, all hashes on the path to root change, making tampering detectable.

## Use cases?

- Blockchain transaction verification (Bitcoin, Ethereum)
- Git version control (commit integrity)
- Distributed file systems (IPFS)
- Certificate transparency logs
- Database synchronization (anti-entropy)
- Peer-to-peer file sharing (BitTorrent)
- Distributed databases (Cassandra, DynamoDB)
- Zero-knowledge proofs
- Secure software updates
- Data deduplication systems

## Code Sample (Rust)

```rust
use std::collections::hash_map::DefaultHasher;
use std::hash::{Hash, Hasher};

fn hash_data<T: Hash>(data: &T) -> u64 {
    let mut hasher = DefaultHasher::new();
    data.hash(&mut hasher);
    hasher.finish()
}

fn hash_pair(left: u64, right: u64) -> u64 {
    let mut hasher = DefaultHasher::new();
    left.hash(&mut hasher);
    right.hash(&mut hasher);
    hasher.finish()
}

#[derive(Debug, Clone)]
struct MerkleNode {
    hash: u64,
    left: Option<Box<MerkleNode>>,
    right: Option<Box<MerkleNode>>,
}

struct MerkleTree {
    root: Option<MerkleNode>,
    leaves: Vec<u64>,
}

impl MerkleTree {
    fn new<T: Hash>(data: &[T]) -> Self {
        if data.is_empty() {
            return MerkleTree { root: None, leaves: Vec::new() };
        }

        let leaves: Vec<u64> = data.iter().map(|d| hash_data(d)).collect();
        let root = Self::build_tree(&leaves);

        MerkleTree { root: Some(root), leaves }
    }

    fn build_tree(hashes: &[u64]) -> MerkleNode {
        if hashes.len() == 1 {
            return MerkleNode {
                hash: hashes[0],
                left: None,
                right: None,
            };
        }

        let mut nodes: Vec<MerkleNode> = hashes
            .iter()
            .map(|&h| MerkleNode { hash: h, left: None, right: None })
            .collect();

        while nodes.len() > 1 {
            let mut next_level = Vec::new();

            for chunk in nodes.chunks(2) {
                let left = chunk[0].clone();
                let right = if chunk.len() > 1 {
                    chunk[1].clone()
                } else {
                    chunk[0].clone()
                };

                let parent_hash = hash_pair(left.hash, right.hash);
                next_level.push(MerkleNode {
                    hash: parent_hash,
                    left: Some(Box::new(left)),
                    right: Some(Box::new(right)),
                });
            }

            nodes = next_level;
        }

        nodes.remove(0)
    }

    fn root_hash(&self) -> Option<u64> {
        self.root.as_ref().map(|r| r.hash)
    }

    fn get_proof(&self, index: usize) -> Option<Vec<(u64, bool)>> {
        if index >= self.leaves.len() {
            return None;
        }

        let mut proof = Vec::new();
        let mut current_index = index;
        let mut level_size = self.leaves.len();
        let mut level_hashes = self.leaves.clone();

        while level_size > 1 {
            let sibling_index = if current_index % 2 == 0 {
                current_index + 1
            } else {
                current_index - 1
            };

            let sibling_hash = if sibling_index < level_hashes.len() {
                level_hashes[sibling_index]
            } else {
                level_hashes[current_index]
            };

            let is_right = current_index % 2 == 0;
            proof.push((sibling_hash, is_right));

            let mut next_level = Vec::new();
            for chunk in level_hashes.chunks(2) {
                let left = chunk[0];
                let right = if chunk.len() > 1 { chunk[1] } else { chunk[0] };
                next_level.push(hash_pair(left, right));
            }

            level_hashes = next_level;
            level_size = level_hashes.len();
            current_index /= 2;
        }

        Some(proof)
    }

    fn verify_proof<T: Hash>(data: &T, proof: &[(u64, bool)], root_hash: u64) -> bool {
        let mut current_hash = hash_data(data);

        for (sibling_hash, is_right) in proof {
            current_hash = if *is_right {
                hash_pair(current_hash, *sibling_hash)
            } else {
                hash_pair(*sibling_hash, current_hash)
            };
        }

        current_hash == root_hash
    }

    fn verify_equal(&self, other: &MerkleTree) -> bool {
        match (&self.root, &other.root) {
            (Some(a), Some(b)) => a.hash == b.hash,
            (None, None) => true,
            _ => false,
        }
    }

    fn find_differences(&self, other: &MerkleTree) -> Vec<usize> {
        let mut differences = Vec::new();

        if self.leaves.len() != other.leaves.len() {
            return (0..self.leaves.len().max(other.leaves.len())).collect();
        }

        for (i, (&a, &b)) in self.leaves.iter().zip(other.leaves.iter()).enumerate() {
            if a != b {
                differences.push(i);
            }
        }

        differences
    }
}

fn main() {
    let data = vec!["block1", "block2", "block3", "block4"];
    let tree = MerkleTree::new(&data);

    println!("Root hash: {:?}", tree.root_hash());

    let proof = tree.get_proof(2).unwrap();
    println!("Proof for index 2: {:?}", proof);

    let is_valid = MerkleTree::verify_proof(&"block3", &proof, tree.root_hash().unwrap());
    println!("Proof valid: {}", is_valid);

    let is_invalid = MerkleTree::verify_proof(&"fake_data", &proof, tree.root_hash().unwrap());
    println!("Fake data proof valid: {}", is_invalid);

    let data2 = vec!["block1", "block2", "modified", "block4"];
    let tree2 = MerkleTree::new(&data2);

    println!("\nTrees equal: {}", tree.verify_equal(&tree2));
    println!("Differences at indices: {:?}", tree.find_differences(&tree2));
}
```

## Pros and Cons

### Pros
- Efficient verification with O(log n) proof size
- Tamper-evident (any change propagates to root)
- Enables partial verification without full data
- Efficient comparison of large datasets
- Parallelizable tree construction
- Works well for distributed systems synchronization
- Cryptographically secure when using proper hash functions

### Cons
- Requires storing additional hash nodes
- Updates require recomputing path to root
- Not efficient for frequently changing data
- Proof generation requires access to sibling nodes
- Overhead for small datasets
- Order-dependent (different ordering = different root)
- Vulnerable if weak hash function is used

## Frameworks or libraries using it

- **Rust**: `merkle-tree` crate, `rs-merkle` crate, `merkle_light`
- **Bitcoin**: Transaction verification in blocks
- **Ethereum**: State trie (Patricia Merkle Trie)
- **Git**: Commit and tree object integrity
- **IPFS**: Content addressing and verification
- **Apache Cassandra**: Anti-entropy repair protocol
- **Amazon DynamoDB**: Merkle trees for replica sync
- **ZFS**: Data integrity verification
- **Certificate Transparency**: Append-only logs
- **Apache Kafka**: Log compaction verification
