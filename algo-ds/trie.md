# Trie

## What is it?

A Trie (pronounced "try", from retrieval) is a tree-like data structure used for storing and searching strings efficiently. Also called a prefix tree or digital tree, each node represents a single character, and paths from root to nodes represent prefixes of stored strings. Unlike hash tables, tries enable prefix-based operations and maintain lexicographic ordering. Invented by Edward Fredkin in 1960, tries are fundamental in autocomplete systems, spell checkers, and IP routing tables.

## How it works?

1. The root node represents an empty string
2. Each edge is labeled with a character
3. Each node contains an array or map of child pointers (one per possible character)
4. A flag marks nodes that represent complete words
5. To insert: traverse/create nodes for each character, mark the last node as a word
6. To search: traverse nodes following characters, return true if path exists and ends at word node
7. To find prefixes: traverse to prefix end, then collect all words in subtree
8. Deletion removes nodes that are no longer part of any word

Common optimizations include compressed tries (radix trees) that merge single-child chains.

## Use cases?

- Autocomplete and typeahead suggestions
- Spell checkers and correction
- IP routing tables (longest prefix matching)
- Dictionary implementations
- T9 predictive text input
- DNA sequence matching
- Command-line tab completion
- Search engine query suggestions
- Contact search in phones
- Word games (Scrabble, Boggle solvers)

## Code Sample (Rust)

```rust
use std::collections::HashMap;

struct TrieNode {
    children: HashMap<char, TrieNode>,
    is_end: bool,
}

impl TrieNode {
    fn new() -> Self {
        TrieNode {
            children: HashMap::new(),
            is_end: false,
        }
    }
}

struct Trie {
    root: TrieNode,
}

impl Trie {
    fn new() -> Self {
        Trie { root: TrieNode::new() }
    }

    fn insert(&mut self, word: &str) {
        let mut node = &mut self.root;
        for ch in word.chars() {
            node = node.children.entry(ch).or_insert_with(TrieNode::new);
        }
        node.is_end = true;
    }

    fn search(&self, word: &str) -> bool {
        self.find_node(word).map_or(false, |n| n.is_end)
    }

    fn starts_with(&self, prefix: &str) -> bool {
        self.find_node(prefix).is_some()
    }

    fn find_node(&self, prefix: &str) -> Option<&TrieNode> {
        let mut node = &self.root;
        for ch in prefix.chars() {
            match node.children.get(&ch) {
                Some(next) => node = next,
                None => return None,
            }
        }
        Some(node)
    }

    fn autocomplete(&self, prefix: &str) -> Vec<String> {
        let mut results = Vec::new();
        if let Some(node) = self.find_node(prefix) {
            self.collect_words(node, prefix.to_string(), &mut results);
        }
        results
    }

    fn collect_words(&self, node: &TrieNode, current: String, results: &mut Vec<String>) {
        if node.is_end {
            results.push(current.clone());
        }
        for (&ch, child) in &node.children {
            let mut next = current.clone();
            next.push(ch);
            self.collect_words(child, next, results);
        }
    }

    fn delete(&mut self, word: &str) -> bool {
        Self::delete_helper(&mut self.root, word, 0)
    }

    fn delete_helper(node: &mut TrieNode, word: &str, depth: usize) -> bool {
        let chars: Vec<char> = word.chars().collect();

        if depth == chars.len() {
            if !node.is_end {
                return false;
            }
            node.is_end = false;
            return node.children.is_empty();
        }

        let ch = chars[depth];
        if let Some(child) = node.children.get_mut(&ch) {
            if Self::delete_helper(child, word, depth + 1) {
                node.children.remove(&ch);
                return !node.is_end && node.children.is_empty();
            }
        }

        false
    }

    fn count_words(&self) -> usize {
        self.count_helper(&self.root)
    }

    fn count_helper(&self, node: &TrieNode) -> usize {
        let mut count = if node.is_end { 1 } else { 0 };
        for child in node.children.values() {
            count += self.count_helper(child);
        }
        count
    }
}

fn main() {
    let mut trie = Trie::new();

    let words = ["apple", "app", "application", "apply", "banana", "band", "bandana"];
    for word in &words {
        trie.insert(word);
    }

    println!("Word count: {}", trie.count_words());
    println!("Search 'apple': {}", trie.search("apple"));
    println!("Search 'app': {}", trie.search("app"));
    println!("Search 'appl': {}", trie.search("appl"));
    println!("Starts with 'app': {}", trie.starts_with("app"));

    println!("\nAutocomplete 'app': {:?}", trie.autocomplete("app"));
    println!("Autocomplete 'ban': {:?}", trie.autocomplete("ban"));

    trie.delete("app");
    println!("\nAfter deleting 'app':");
    println!("Search 'app': {}", trie.search("app"));
    println!("Search 'apple': {}", trie.search("apple"));
}
```

## Pros and Cons

### Pros
- O(m) time complexity for insert/search/delete where m is key length
- Efficient prefix-based operations (autocomplete, prefix search)
- No hash collisions unlike hash tables
- Lexicographic ordering of keys
- Supports longest prefix matching
- Can represent all keys with common prefixes space-efficiently

### Cons
- High memory usage (pointer overhead per character)
- Cache-unfriendly due to pointer chasing
- Slower than hash tables for exact lookups
- Wasted space for sparse character distributions
- Not suitable for floating-point or complex keys
- Implementation complexity for deletion

## Frameworks or libraries using it

- **Rust**: `trie-rs` crate, `radix_trie` crate, `qp-trie`
- **Linux Kernel**: Radix trees for page cache and routing
- **Apache Lucene**: Finite state transducers (FST) based on tries
- **Redis**: Radix tree for cluster slot management
- **Google Chrome**: Autocomplete suggestions
- **Elasticsearch**: Completion suggester uses FST
- **ClickHouse**: Trie dictionary for string optimization
- **Hyperscan**: Intel's regex matching engine
- **Iptables/nftables**: IP routing with longest prefix match
- **T9 Input**: Predictive text on feature phones
