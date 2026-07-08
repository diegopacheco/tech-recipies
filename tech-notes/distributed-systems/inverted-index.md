# Inverted Index

## What is an Inverted Index?

An Inverted Index is a data structure that maps content (terms/tokens) to the locations where that content appears (documents, and optionally positions). It is the core data structure behind every full-text search engine. Instead of storing documents and scanning each one for a query term (a "forward index" that maps document → terms), it inverts the relationship and stores term → list of documents that contain it. This makes answering "which documents contain the word X?" an O(1) dictionary lookup followed by a walk over a pre-built list, rather than a full scan of the corpus.

The name comes from the analogy to the index at the back of a book: instead of reading every page to find where a topic is mentioned, you look up the topic in the index and it points you straight to the pages.

## Who created it? When?

The concept predates computers. The earliest inverted indexes were **biblical concordances** built by hand, most famously the concordance of the Vulgate led by **Hugh of Saint-Cher** and the Dominicans around **1230**, which listed every word in the Bible with the verses where it appeared.

The computational form emerged with the first **information retrieval systems in the 1950s and 1960s**, notably **Hans Peter Luhn** at IBM, who pioneered automatic indexing and keyword-in-context techniques. The theory was formalized by **Gerard Salton** (the SMART system at Cornell, 1960s–70s) who introduced the vector space model and TF-IDF weighting. Modern implementations trace their lineage to **Apache Lucene**, created by **Doug Cutting in 1999**, which powers Elasticsearch, OpenSearch, and Solr.

## How it works?

1. **Tokenization**: Split each document into terms (words). Lowercase, remove punctuation.
2. **Normalization / Analysis**: Apply stemming ("running" → "run"), stop-word removal ("the", "a"), lowercasing, and synonym expansion.
3. **Build the dictionary (term lookup)**: Every unique term is stored, usually with its document frequency (how many documents contain it).
4. **Build posting lists**: For each term, store a sorted list of document IDs that contain it. Optionally store term frequency, positions, and offsets.
5. **Query**: Look up each query term in the dictionary, fetch its posting list, and intersect (AND) or union (OR) the lists to find matching documents.
6. **Score and rank**: Use TF-IDF or BM25 to rank matching documents by relevance.

```
Documents:
  D1: "the quick brown fox"
  D2: "the lazy brown dog"
  D3: "quick brown foxes jump"

Forward index (document -> terms):
  D1 -> {the, quick, brown, fox}
  D2 -> {the, lazy, brown, dog}
  D3 -> {quick, brown, fox, jump}

Inverted index (term -> posting list of doc IDs):
  brown  -> [D1, D2, D3]     (df=3)
  quick  -> [D1, D3]         (df=2)
  fox    -> [D1, D3]         (df=2)
  the    -> [D1, D2]         (df=2)
  lazy   -> [D2]             (df=1)
  dog    -> [D2]             (df=1)
  jump   -> [D3]             (df=1)

Query: "quick AND brown"
  quick -> [D1, D3]
  brown -> [D1, D2, D3]
  Intersect -> [D1, D3]      (walk both sorted lists in tandem)
```

## Anatomy of a Posting List

A posting is one entry in a term's list. Depending on what the index needs to support, a posting stores progressively more:

```
Doc ID only        -> boolean search (does the term exist in the doc?)
Doc ID + freq      -> relevance scoring (TF-IDF / BM25)
Doc ID + freq + positions   -> phrase and proximity search ("quick brown"~2)
Doc ID + freq + positions + offsets  -> highlighting in results

Example posting for term "brown":
  [ (docID=1, tf=1, positions=[2]),
    (docID=2, tf=1, positions=[2]),
    (docID=3, tf=1, positions=[1]) ]
```

## Construction Algorithms

### BSBI — Blocked Sort-Based Indexing
Parse documents into (term, docID) pairs, sort blocks that fit in memory, write each sorted block to disk, then do an external merge of all blocks. Requires a global term→ID mapping.

### SPIMI — Single-Pass In-Memory Indexing
Scan documents once, build an in-memory dictionary and grow posting lists directly until memory fills, flush a compressed block to disk, repeat, then merge blocks. Avoids the expensive global sort and is the basis for how Lucene builds segments.

### Segment-Based (Lucene / Elasticsearch)
New documents are buffered in memory and periodically flushed as an immutable **segment** (a self-contained mini-index). Segments are never modified; deletes are tombstoned. A background **merge** process combines small segments into larger ones, reclaiming deleted docs. This gives cheap writes and lock-free reads at the cost of eventual-consistency-style refresh delay.

## Compression

Posting lists are huge, so they are compressed aggressively. Compression is what makes inverted indexes fit in memory and read fast.

### 1. Delta (Gap) Encoding
Doc IDs in a posting list are sorted ascending, so store the gaps between consecutive IDs instead of absolute values. Small gaps compress far better than large IDs.

```
Doc IDs:  [42, 100, 666, 700]
Deltas:   [42,  58, 566,  34]   -> smaller numbers, fewer bits
```

### 2. Variable-Byte (VByte) Encoding
Use as few bytes as possible per integer. Each byte uses 7 bits for data and 1 continuation bit. Numbers under 128 fit in a single byte.

### 3. Frame of Reference / PForDelta (PFOR)
Compress fixed-size blocks (typically 128 or 256 postings) by packing values into a minimal bit-width relative to the block minimum, with rare outliers stored as exceptions. This is what Lucene uses for dense blocks.

### 4. Adaptive / Per-Block Codecs
Modern engines (Lucene, Elasticsearch, Tantivy) choose a codec per block with a 1–2 byte header: PFOR for tightly-packed values, VByte for large irregular gaps, raw 32-bit as a fallback for pathological cases.

## Skip Pointers

Intersecting two posting lists is a merge walk. Skip pointers add a multi-level "express lane" over a posting list so that when one list is far ahead, the other can jump forward instead of stepping one posting at a time. This turns list intersection from O(n+m) into something much faster for lists of very different lengths.

```
Posting list for "brown" with skip pointers (skip length ~= sqrt(n)):

  [D1] -> [D5] -> [D9] -> [D14] -> ...     (skip layer)
    |       |       |        |
  [D1 D2 D3 D4 D5 D6 D7 D8 D9 ...]         (base layer)

Query "quick AND brown": if the "quick" cursor is at D9,
follow skip pointers over "brown" to jump straight past D2..D8.
```

## Scoring: Ranking the Matches

Membership alone is not enough — results must be ordered by relevance. The posting-list metadata (term frequency, document frequency, document length) feeds the ranking function, accumulated as lists are traversed.

```
TF-IDF:
  tf-idf(t, d) = tf(t, d) * log(N / df(t))

  tf(t, d)  = frequency of term t in document d
  df(t)     = number of documents containing t
  N         = total number of documents
  Rare terms (low df) score higher; common terms score near zero.

BM25 (Okapi BM25 — the modern default):
                                    tf(t,d) * (k1 + 1)
  score(t, d) = IDF(t) * ----------------------------------------
                          tf(t,d) + k1 * (1 - b + b * (dl / avgdl))

  k1    ~ 1.2-2.0   controls term-frequency saturation
  b     ~ 0.75      controls document-length normalization
  dl    = length of document d
  avgdl = average document length in the corpus
  IDF(t) = log((N - df(t) + 0.5) / (df(t) + 0.5) + 1)
```

BM25 improves on raw TF-IDF by **saturating** term frequency (the 100th occurrence of a word adds little over the 10th) and **normalizing for document length** (a match in a short document counts more than the same match in a long one).

## Comparison

```
┌──────────────────────┬───────────────────┬──────────────────────┐
│ Structure            │ Answers           │ Trade-off            │
├──────────────────────┼───────────────────┼──────────────────────┤
│ Inverted Index       │ term -> documents │ Fast full-text read, │
│                      │                   │ expensive writes     │
├──────────────────────┼───────────────────┼──────────────────────┤
│ Forward Index        │ document -> terms │ Fast per-doc access, │
│                      │                   │ slow term search     │
├──────────────────────┼───────────────────┼──────────────────────┤
│ B-Tree Index         │ range / exact key │ Great for ordered    │
│                      │                   │ scans, not full-text │
├──────────────────────┼───────────────────┼──────────────────────┤
│ Trie / FST           │ prefix / term     │ Autocomplete, term   │
│                      │ dictionary        │ dictionary storage   │
├──────────────────────┼───────────────────┼──────────────────────┤
│ Vector Index (ANN)   │ semantic nearest  │ Meaning-based, not   │
│ (HNSW, IVF)          │ neighbors         │ exact keyword match  │
└──────────────────────┴───────────────────┴──────────────────────┘
```

## Pros

- **Fast Full-Text Search**: Query time depends on the number of matching documents, not the size of the corpus
- **Scales to Billions of Documents**: The structure behind web-scale search engines
- **Boolean Queries**: AND / OR / NOT reduce to intersecting and unioning sorted posting lists
- **Phrase and Proximity Search**: Positions in postings enable "quick brown"~3 queries
- **Relevance Ranking**: Stored frequencies and document lengths feed TF-IDF and BM25
- **Highly Compressible**: Delta + VByte + PFOR shrink posting lists dramatically
- **Cache and Merge Friendly**: Immutable segments allow lock-free reads and background optimization
- **Highlighting and Faceting**: Offsets and per-term metadata power result snippets and aggregations

## Cons

- **Expensive Writes**: Every insert touches many posting lists; updates are done by delete + re-insert
- **Update Latency**: Segment-based engines refresh periodically, so new documents are not instantly searchable
- **Storage Overhead**: The index can approach or exceed the size of the original text before compression
- **No Semantic Understanding**: Matches exact tokens; "car" will not match "automobile" without synonyms
- **Analysis Complexity**: Tokenization, stemming, and language handling are error-prone and language-specific
- **Merge Cost**: Background segment merges consume CPU and I/O and can cause latency spikes
- **Not for Range/Numeric Queries**: Poor fit for numeric ranges or sorting compared to B-trees
- **Rebuild Cost**: Changing the analyzer usually requires reindexing the entire corpus

## Use Cases

- **Web Search Engines**: Google, Bing, and every major search engine are built on inverted indexes
- **Full-Text Search Platforms**: Elasticsearch, OpenSearch, Apache Solr (all Lucene-based)
- **Log Search and Observability**: Elastic Stack, Splunk, Grafana Loki index log lines by term
- **Database Full-Text**: PostgreSQL GIN indexes, MySQL FULLTEXT, MongoDB text indexes
- **Code Search**: GitHub code search and Sourcegraph index source tokens for instant lookup
- **E-commerce Search**: Product catalog search with faceting, filtering, and relevance ranking
- **Document Management**: Enterprise search over emails, PDFs, and wikis
- **Autocomplete and Suggestions**: Term dictionaries (tries/FSTs) built alongside the inverted index
- **Hybrid Search**: Combined with vector (ANN) indexes to blend keyword precision with semantic recall
- **Bioinformatics and Genomics**: Indexing k-mers and sequences for fast substring lookup
