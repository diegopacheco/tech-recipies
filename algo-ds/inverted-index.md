# Inverted Index

## What is it?

An Inverted Index is a data structure that maps content (words, terms, or tokens) to their locations in a set of documents. Instead of mapping documents to words (forward index), it inverts the relationship to map words to documents. This is the core data structure behind search engines, enabling fast full-text search by allowing direct lookup of which documents contain a given term. Every major search engine from Google to Elasticsearch uses inverted indexes.

## How it works?

1. **Tokenization**: Split documents into individual terms (words)
2. **Normalization**: Apply lowercase, stemming, stop-word removal
3. **Index Building**: For each term, store a posting list containing document IDs where the term appears
4. **Posting List**: Each entry may include document ID, term frequency, and positions
5. **Query Processing**: Look up posting lists for query terms, intersect/union based on query operators
6. **Ranking**: Use TF-IDF, BM25, or other scoring algorithms to rank results
7. **Compression**: Apply delta encoding and variable-byte encoding to posting lists

Optional enhancements include skip pointers for faster intersection and positional indexes for phrase queries.

## Use cases?

- Web search engines (Google, Bing, DuckDuckGo)
- Document search (Elasticsearch, Solr, Lucene)
- Email search
- Log analysis and monitoring
- E-commerce product search
- Code search tools (GitHub, Sourcegraph)
- Database full-text search
- Content management systems
- Legal document discovery
- Genomic sequence search

## Code Sample (Rust)

```rust
use std::collections::{HashMap, HashSet, BTreeMap};

#[derive(Debug, Clone)]
struct Posting {
    doc_id: usize,
    frequency: usize,
    positions: Vec<usize>,
}

struct InvertedIndex {
    index: HashMap<String, Vec<Posting>>,
    documents: Vec<String>,
    doc_lengths: Vec<usize>,
    avg_doc_length: f64,
}

impl InvertedIndex {
    fn new() -> Self {
        InvertedIndex {
            index: HashMap::new(),
            documents: Vec::new(),
            doc_lengths: Vec::new(),
            avg_doc_length: 0.0,
        }
    }

    fn tokenize(text: &str) -> Vec<String> {
        text.to_lowercase()
            .split(|c: char| !c.is_alphanumeric())
            .filter(|s| !s.is_empty() && s.len() > 1)
            .map(|s| s.to_string())
            .collect()
    }

    fn add_document(&mut self, doc: &str) {
        let doc_id = self.documents.len();
        self.documents.push(doc.to_string());

        let tokens = Self::tokenize(doc);
        self.doc_lengths.push(tokens.len());

        let total_length: usize = self.doc_lengths.iter().sum();
        self.avg_doc_length = total_length as f64 / self.documents.len() as f64;

        let mut term_positions: HashMap<String, Vec<usize>> = HashMap::new();
        for (pos, token) in tokens.iter().enumerate() {
            term_positions.entry(token.clone()).or_default().push(pos);
        }

        for (term, positions) in term_positions {
            let posting = Posting {
                doc_id,
                frequency: positions.len(),
                positions,
            };
            self.index.entry(term).or_default().push(posting);
        }
    }

    fn search(&self, query: &str) -> Vec<(usize, f64)> {
        let terms = Self::tokenize(query);
        let mut scores: HashMap<usize, f64> = HashMap::new();

        for term in &terms {
            if let Some(postings) = self.index.get(term) {
                let idf = self.calculate_idf(postings.len());
                for posting in postings {
                    let tf = self.calculate_tf(posting.frequency);
                    *scores.entry(posting.doc_id).or_insert(0.0) += tf * idf;
                }
            }
        }

        let mut results: Vec<(usize, f64)> = scores.into_iter().collect();
        results.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap());
        results
    }

    fn search_bm25(&self, query: &str, k1: f64, b: f64) -> Vec<(usize, f64)> {
        let terms = Self::tokenize(query);
        let mut scores: HashMap<usize, f64> = HashMap::new();
        let n = self.documents.len() as f64;

        for term in &terms {
            if let Some(postings) = self.index.get(term) {
                let df = postings.len() as f64;
                let idf = ((n - df + 0.5) / (df + 0.5) + 1.0).ln();

                for posting in postings {
                    let doc_len = self.doc_lengths[posting.doc_id] as f64;
                    let tf = posting.frequency as f64;
                    let numerator = tf * (k1 + 1.0);
                    let denominator = tf + k1 * (1.0 - b + b * doc_len / self.avg_doc_length);
                    let score = idf * numerator / denominator;
                    *scores.entry(posting.doc_id).or_insert(0.0) += score;
                }
            }
        }

        let mut results: Vec<(usize, f64)> = scores.into_iter().collect();
        results.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap());
        results
    }

    fn calculate_tf(&self, frequency: usize) -> f64 {
        1.0 + (frequency as f64).ln()
    }

    fn calculate_idf(&self, doc_frequency: usize) -> f64 {
        (self.documents.len() as f64 / doc_frequency as f64).ln()
    }

    fn boolean_and(&self, terms: &[&str]) -> HashSet<usize> {
        let mut result: Option<HashSet<usize>> = None;

        for term in terms {
            let term_lower = term.to_lowercase();
            let doc_ids: HashSet<usize> = self.index
                .get(&term_lower)
                .map(|postings| postings.iter().map(|p| p.doc_id).collect())
                .unwrap_or_default();

            result = match result {
                None => Some(doc_ids),
                Some(r) => Some(r.intersection(&doc_ids).cloned().collect()),
            };
        }

        result.unwrap_or_default()
    }

    fn boolean_or(&self, terms: &[&str]) -> HashSet<usize> {
        let mut result: HashSet<usize> = HashSet::new();

        for term in terms {
            let term_lower = term.to_lowercase();
            if let Some(postings) = self.index.get(&term_lower) {
                for posting in postings {
                    result.insert(posting.doc_id);
                }
            }
        }

        result
    }

    fn phrase_search(&self, phrase: &str) -> Vec<usize> {
        let terms = Self::tokenize(phrase);
        if terms.is_empty() {
            return Vec::new();
        }

        let first_term = &terms[0];
        let Some(first_postings) = self.index.get(first_term) else {
            return Vec::new();
        };

        let mut results = Vec::new();

        for posting in first_postings {
            let doc_id = posting.doc_id;
            'positions: for &start_pos in &posting.positions {
                for (offset, term) in terms.iter().enumerate().skip(1) {
                    let expected_pos = start_pos + offset;
                    let Some(term_postings) = self.index.get(term) else {
                        continue 'positions;
                    };
                    let Some(doc_posting) = term_postings.iter().find(|p| p.doc_id == doc_id) else {
                        continue 'positions;
                    };
                    if !doc_posting.positions.contains(&expected_pos) {
                        continue 'positions;
                    }
                }
                results.push(doc_id);
                break;
            }
        }

        results
    }

    fn get_document(&self, doc_id: usize) -> Option<&String> {
        self.documents.get(doc_id)
    }

    fn stats(&self) -> (usize, usize) {
        (self.documents.len(), self.index.len())
    }
}

fn main() {
    let mut index = InvertedIndex::new();

    index.add_document("The quick brown fox jumps over the lazy dog");
    index.add_document("A quick brown dog runs in the park");
    index.add_document("The lazy cat sleeps all day long");
    index.add_document("Fox and dog are both animals");
    index.add_document("Quick sorting algorithm is very fast");

    let (doc_count, term_count) = index.stats();
    println!("Documents: {}, Unique terms: {}", doc_count, term_count);

    println!("\n=== TF-IDF Search ===");
    let results = index.search("quick brown");
    for (doc_id, score) in &results {
        println!("Doc {}: {:.4} - {}", doc_id, score, index.get_document(*doc_id).unwrap());
    }

    println!("\n=== BM25 Search ===");
    let results = index.search_bm25("quick brown", 1.2, 0.75);
    for (doc_id, score) in &results {
        println!("Doc {}: {:.4} - {}", doc_id, score, index.get_document(*doc_id).unwrap());
    }

    println!("\n=== Boolean AND ===");
    let and_results = index.boolean_and(&["quick", "brown"]);
    println!("Documents with 'quick' AND 'brown': {:?}", and_results);

    println!("\n=== Boolean OR ===");
    let or_results = index.boolean_or(&["cat", "fox"]);
    println!("Documents with 'cat' OR 'fox': {:?}", or_results);

    println!("\n=== Phrase Search ===");
    let phrase_results = index.phrase_search("quick brown");
    println!("Documents with phrase 'quick brown': {:?}", phrase_results);
}
```

## Pros and Cons

### Pros
- O(1) lookup for term to documents mapping
- Enables fast boolean and ranked search
- Supports complex query operations (AND, OR, phrase)
- Efficient compression techniques available
- Scales to billions of documents
- Foundation of all modern search engines

### Cons
- High memory usage for large vocabularies
- Index building is CPU and I/O intensive
- Updates require index rebuilding or complex merge strategies
- Phrase queries require positional information (more storage)
- Not suitable for fuzzy matching without additional structures
- Maintaining index consistency with source data

## Frameworks or libraries using it

- **Rust**: `tantivy` (full-text search library), `meilisearch`
- **Apache Lucene**: Foundation for Elasticsearch and Solr
- **Elasticsearch**: Distributed search and analytics engine
- **Apache Solr**: Enterprise search platform
- **Sphinx**: Full-text search engine
- **Meilisearch**: Fast, typo-tolerant search engine
- **Typesense**: Open-source search engine
- **Bleve**: Go full-text search library
- **PostgreSQL**: GIN indexes for full-text search
- **SQLite FTS5**: Full-text search extension
