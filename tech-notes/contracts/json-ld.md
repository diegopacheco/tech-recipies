# JSON-LD (JSON for Linking Data)

## What is it?

JSON-LD is a JSON-based format for serializing Linked Data. It lets you attach machine-readable meaning to ordinary JSON by mapping its keys to globally unique identifiers (IRIs) through a `@context`. The result is plain JSON that any parser can read, yet it also encodes a directed graph of typed nodes and relationships that web crawlers, search engines, and knowledge bases can understand. Its most common use is embedding structured data in a webpage so that crawlers like Googlebot can interpret the semantic structure of the page, qualify it for richer link previews, and feed it into knowledge graphs.

A JSON-LD document is both human-readable JSON and a valid serialization of RDF (the Resource Description Framework). This dual nature is the whole point: developers keep working with JSON, while the data stays unambiguous and mergeable across documents and across sites.

## Who created it? When?

JSON-LD was designed inside the **W3C**. Initial work began around **2010**, led by **Manu Sporny** (Digital Bazaar), with co-editors **Dave Longley**, **Gregg Kellogg**, **Markus Lanthaler**, and **Niklas Lindström**. It grew out of the W3C JSON-LD Community Group and was standardized by the RDF Working Group, with a goal of bringing Linked Data to web developers without forcing them to learn the heavier RDF syntaxes.

```
┌──────────────┬──────────────────────────────────────────────────────────┐
│ Version      │ Notes                                                    │
├──────────────┼──────────────────────────────────────────────────────────┤
│ 2010         │ Initial work led by Manu Sporny and collaborators        │
├──────────────┼──────────────────────────────────────────────────────────┤
│ JSON-LD 1.0  │ W3C Recommendation, 16 January 2014                      │
├──────────────┼──────────────────────────────────────────────────────────┤
│ JSON-LD 1.1  │ W3C Recommendation, 16 July 2020 (scoped contexts,       │
│              │ @nest, @json, indexing, framing improvements)            │
└──────────────┴──────────────────────────────────────────────────────────┘
```

## How it works?

JSON-LD is delivered to crawlers inside a `<script type="application/ld+json">` tag in the page `<head>`. The MIME type tells the browser not to execute it as JavaScript; specialized crawlers look for these tags and parse the contents.

### Basic Structure

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "WebSite",
      "@id": "https://yoursite.dev/#website",
      "url": "https://yoursite.dev/",
      "name": "Your Name"
    }
  ]
}
</script>
```

The `@context` declares which vocabulary the keys belong to. Crawlers are standardized on **schema.org**, which defines the valid types and key/value pairs. The `@graph` holds the nodes that describe the page.

### The @-Keywords

```
┌──────────────┬──────────────────────────────────────────────────────────┐
│ Keyword      │ Meaning                                                  │
├──────────────┼──────────────────────────────────────────────────────────┤
│ @context     │ Maps short terms to global IRIs / a vocabulary           │
├──────────────┼──────────────────────────────────────────────────────────┤
│ @id          │ Unique identifier for a node, usually a URL + #hash      │
├──────────────┼──────────────────────────────────────────────────────────┤
│ @type        │ The kind of node (WebSite, Person, BlogPosting, ...)     │
├──────────────┼──────────────────────────────────────────────────────────┤
│ @graph       │ A set of nodes, the labelled directed graph itself       │
├──────────────┼──────────────────────────────────────────────────────────┤
│ @value       │ The literal value of a typed/language-tagged value       │
├──────────────┼──────────────────────────────────────────────────────────┤
│ @language    │ Language tag for a string literal (en-GB, pt-BR, ...)    │
├──────────────┼──────────────────────────────────────────────────────────┤
│ @container   │ Declares a term as a list, set, language map, or index   │
├──────────────┼──────────────────────────────────────────────────────────┤
│ @vocab       │ Default vocabulary for otherwise-unmapped terms          │
├──────────────┼──────────────────────────────────────────────────────────┤
│ @reverse     │ Expresses a relationship in the opposite direction       │
└──────────────┴──────────────────────────────────────────────────────────┘
```

### The Graph Model

A JSON-LD document is a labelled, directed graph. Nodes carry a `@type` and an `@id`, plus properties. Properties whose value is a `{ "@id": ... }` reference become arcs pointing from one node to another. Crawlers merge properties of nodes that share an `@id` across pages, building a single picture of an entity from many documents.

```
@graph
   │
   ├─ Node: WebSite   (@id .../#website)
   │     ├─ name ──────────► "Your Name"
   │     └─ publisher ─────► (@id .../#person)
   │
   ├─ Node: Person    (@id .../#person)
   │     ├─ name ──────────► "Your Name"
   │     └─ sameAs ────────► [ github, linkedin, ... ]
   │
   └─ Node: WebPage   (@id .../#webpage)
         ├─ isPartOf ──────► (@id .../#website)
         └─ about ─────────► (@id .../#person)
```

A node referenced by `@id` but defined elsewhere lets you link entities without repeating them. The convention is a URL followed by a hash (`#website`, `#person`) that uniquely names the node.

### Expansion, Compaction, Flattening, Framing

The four canonical algorithms in the spec let processors normalize a document or reshape it without losing meaning.

```
┌──────────────┬──────────────────────────────────────────────────────────┐
│ Algorithm    │ What it does                                             │
├──────────────┼──────────────────────────────────────────────────────────┤
│ Expansion    │ Removes the @context, replaces every term with full IRIs │
├──────────────┼──────────────────────────────────────────────────────────┤
│ Compaction   │ Re-applies a @context to make the document compact again │
├──────────────┼──────────────────────────────────────────────────────────┤
│ Flattening   │ Collects all nodes into a single flat @graph with @ids   │
├──────────────┼──────────────────────────────────────────────────────────┤
│ Framing      │ Forces a document into a specific tree/shape via a frame │
└──────────────┴──────────────────────────────────────────────────────────┘
```

Two documents that look different but expand to the same form are semantically identical, which is what makes JSON-LD safe to merge across sources.

## Schema.org Nodes for SEO

The highest-impact use of JSON-LD is structured data for search and social previews. The graph below is what a personal site typically publishes. Only a handful of node types matter for SEO; the rest of schema.org is a deep rabbit hole.

```
┌──────────────────┬──────────────────────────────────────────────────────┐
│ Node             │ Where to put it                                      │
├──────────────────┼──────────────────────────────────────────────────────┤
│ WebSite          │ Every page (full on root, slimmed elsewhere)         │
├──────────────────┼──────────────────────────────────────────────────────┤
│ Person           │ Every page (you are key context for crawlers/LLMs)   │
├──────────────────┼──────────────────────────────────────────────────────┤
│ WebPage          │ Every page, describes the HTML page itself           │
├──────────────────┼──────────────────────────────────────────────────────┤
│ ProfilePage      │ Home or about page (a page about a person)           │
├──────────────────┼──────────────────────────────────────────────────────┤
│ CollectionPage   │ Pages that are mostly lists (blog index, links)      │
├──────────────────┼──────────────────────────────────────────────────────┤
│ BreadcrumbList   │ All pages except the root, controls the result path  │
├──────────────────┼──────────────────────────────────────────────────────┤
│ Blog             │ Blog index, a stepping stone to individual posts     │
├──────────────────┼──────────────────────────────────────────────────────┤
│ BlogPosting      │ Each published post                                  │
├──────────────────┼──────────────────────────────────────────────────────┤
│ SoftwareApplic.. │ Pages that showcase a project or tool                │
└──────────────────┴──────────────────────────────────────────────────────┘
```

### WebSite and Person

The root page carries the full `WebSite`; inner pages can carry a slimmed version with just `@type`, `@id`, `url`, and `name`. `Person` is worth keeping full on every page, and `sameAs` is the single most useful property for disambiguation.

```json
{
  "@type": "Person",
  "@id": "https://yoursite.dev/#person",
  "url": "https://yoursite.dev/",
  "name": "Your Name",
  "givenName": "Your",
  "familyName": "Name",
  "jobTitle": "Software Engineer",
  "image": {
    "@type": "ImageObject",
    "@id": "https://yoursite.dev/#person-image",
    "url": "https://yoursite.dev/me.png",
    "width": 1200,
    "height": 1200
  },
  "sameAs": [
    "https://github.com/yourhandle",
    "https://www.linkedin.com/in/yourhandle"
  ]
}
```

`sameAs` cleanly tells crawlers which other profiles are you, letting them build one knowledge-graph identity across many pages, even if your name is common.

### WebPage / ProfilePage

`WebPage` represents the physical HTML page and links up to the site with `isPartOf`. `ProfilePage` is a subtype used where the page is about a person, with `mainEntity` pointing at the `Person` node.

```json
{
  "@type": "ProfilePage",
  "@id": "https://yoursite.dev/#webpage",
  "url": "https://yoursite.dev/",
  "isPartOf": { "@id": "https://yoursite.dev/#website" },
  "name": "About Your Name",
  "inLanguage": "en-GB",
  "dateModified": "2026-05-17T00:00:00.000Z",
  "mainEntity": { "@id": "https://yoursite.dev/#person" }
}
```

### BreadcrumbList

Controls how the search result represents the page path. It describes the categorisation of a page, which need not match the real URL path.

```json
{
  "@type": "BreadcrumbList",
  "@id": "https://yoursite.dev/blog/a-post/#breadcrumb",
  "itemListElement": [
    { "@type": "ListItem", "item": "https://yoursite.dev/", "position": 1, "name": "Home" },
    { "@type": "ListItem", "item": "https://yoursite.dev/blog/", "position": 2, "name": "Blog" },
    { "@type": "ListItem", "item": "https://yoursite.dev/blog/a-post/", "position": 3, "name": "A Post" }
  ]
}
```

### BlogPosting

Added to every published post. On a personal site `author` and `publisher` can both point at the same `Person`, and `image` should mirror the post's Open Graph preview image.

```json
{
  "@type": "BlogPosting",
  "@id": "https://yoursite.dev/blog/a-post/#blogposting",
  "url": "https://yoursite.dev/blog/a-post/",
  "mainEntityOfPage": { "@id": "https://yoursite.dev/blog/a-post/#webpage" },
  "isPartOf": { "@id": "https://yoursite.dev/blog/#blog" },
  "headline": "A Post",
  "description": "A short summary of the post.",
  "keywords": "systems, rust",
  "inLanguage": "en-GB",
  "datePublished": "2026-04-13T00:00:00.000Z",
  "dateModified": "2026-04-17T00:00:00.000Z",
  "author": { "@id": "https://yoursite.dev/#person" },
  "publisher": { "@id": "https://yoursite.dev/#person" },
  "license": "https://creativecommons.org/licenses/by/4.0/"
}
```

A key caveat: web crawlers merge nodes that share an `@id` across pages, but single-page scrapers such as LLMs read one page in isolation and will not merge. When you reuse nodes across pages, repeat enough context on each page to stand alone while keeping the shared `@id` stable.

## Comparison with Other Formats

```
┌────────────────┬──────────┬───────────┬──────────┬──────────┬────────────┐
│ Feature        │ JSON-LD  │ Microdata │ RDFa     │ Turtle   │ Plain JSON │
├────────────────┼──────────┼───────────┼──────────┼──────────┼────────────┤
│ Syntax base    │ JSON     │ HTML attr │ HTML attr│ Text/RDF │ JSON       │
├────────────────┼──────────┼───────────┼──────────┼──────────┼────────────┤
│ Is RDF         │ Yes      │ Yes       │ Yes      │ Yes      │ No         │
├────────────────┼──────────┼───────────┼──────────┼──────────┼────────────┤
│ Lives in       │ <script> │ Tangled   │ Tangled  │ Separate │ Anywhere   │
│                │ block    │ in markup │ in markup│ file     │            │
├────────────────┼──────────┼───────────┼──────────┼──────────┼────────────┤
│ Decoupled from │ Yes      │ No        │ No       │ Yes      │ Yes        │
│ HTML content   │          │           │          │          │            │
├────────────────┼──────────┼───────────┼──────────┼──────────┼────────────┤
│ Google's       │ Yes      │ Supported │ Supported│ No       │ No         │
│ preferred form │          │           │          │          │            │
├────────────────┼──────────┼───────────┼──────────┼──────────┼────────────┤
│ Mergeable by   │ Yes      │ Yes       │ Yes      │ Yes      │ No         │
│ global @id     │          │           │          │          │            │
├────────────────┼──────────┼───────────┼──────────┼──────────┼────────────┤
│ Human readable │ Yes      │ Hard      │ Hard     │ Yes      │ Yes        │
└────────────────┴──────────┴───────────┴──────────┴──────────┴────────────┘
```

JSON Schema and JSON-LD are often confused: JSON Schema constrains and validates the *shape* of a JSON document, while JSON-LD adds *semantic meaning* to its keys. They solve different problems and can be used together.

## Pros

- **Valid JSON**: any existing JSON parser reads it, no new toolchain required
- **Decoupled from markup**: lives in a `<script>` block, so structured data does not tangle with HTML content like Microdata and RDFa do
- **Unambiguous keys**: `@context` maps terms to global IRIs, so meaning is portable across systems
- **Mergeable graph**: shared `@id` values let crawlers fuse facts about an entity from many pages and sites
- **SEO-native**: the form Google and other crawlers prefer for rich results and knowledge panels
- **W3C standard**: stable spec, mature processors, and online playgrounds and validators
- **Incremental**: add a single node to one page and start benefiting immediately

## Cons

- **Verbose**: nested IRIs, `@`-keywords, and reference objects make documents larger than plain JSON
- **Conceptual overhead**: RDF, IRIs, contexts, and expansion/compaction are a real learning curve
- **Sync burden**: structured data must match the visible page or crawlers flag a mismatch
- **No single-page merge**: LLM-style scrapers read one page and do not join nodes by `@id`, so reuse needs balancing
- **Loose validation**: schema.org does not enforce value correctness; you need SHACL, ShEx, or vendor validators
- **Easy to misuse**: technically valid markup can still carry zero SEO value if the wrong properties are filled

## Use Cases

- **SEO structured data**: rich results, sitelinks, and knowledge panels in Google and Bing
- **Personal websites**: at minimum `WebSite`, `ProfilePage`, and `Person` on the root page to anchor identity
- **Knowledge graphs**: feeding entity data into Google's Knowledge Graph and interoperating with Wikidata via `sameAs`
- **Linked Open Data**: publishing semantic-web datasets that other systems can consume and join
- **Verifiable Credentials and DIDs**: W3C decentralized-identity standards are built on JSON-LD
- **ActivityPub**: the fediverse (Mastodon and friends) exchanges JSON-LD activity objects
- **Dataset discovery**: describing datasets for Google Dataset Search via schema.org `Dataset`
- **E-commerce and content**: products, offers, reviews, recipes, events, and FAQ markup for richer listings
