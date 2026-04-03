# GraphQL Schema

## What is it?

A GraphQL schema defines the types, queries, mutations, and subscriptions available in a GraphQL API. It is written in the Schema Definition Language (SDL) and serves as the contract between client and server. The schema is strongly typed — every field has a defined type, and the server enforces that the response matches the schema exactly. Clients request only the fields they need, and the schema describes everything that is possible to request.

## Who created it? When?

GraphQL was created at **Facebook** by **Lee Byron, Dan Schafer, and Nick Schrock** starting in **2012** to solve problems with their mobile news feed API. It was open-sourced in **2015** and transferred to the **GraphQL Foundation** (under the Linux Foundation) in **2018**. The specification is maintained as an open standard. Major adopters include GitHub, Shopify, Stripe, Airbnb, and Netflix.

## How it works?

### Schema Definition Language (SDL)

```graphql
type User {
  id: ID!
  name: String!
  email: String!
  age: Int
  posts: [Post!]!
  status: UserStatus!
}

type Post {
  id: ID!
  title: String!
  body: String!
  author: User!
  comments: [Comment!]!
  createdAt: DateTime!
}

type Comment {
  id: ID!
  text: String!
  author: User!
}

enum UserStatus {
  ACTIVE
  INACTIVE
  BANNED
}

scalar DateTime

type Query {
  user(id: ID!): User
  users(limit: Int = 20, offset: Int = 0): [User!]!
  post(id: ID!): Post
}

type Mutation {
  createUser(input: CreateUserInput!): User!
  updateUser(id: ID!, input: UpdateUserInput!): User!
  deleteUser(id: ID!): Boolean!
}

input CreateUserInput {
  name: String!
  email: String!
  age: Int
}

input UpdateUserInput {
  name: String
  email: String
  age: Int
}

type Subscription {
  postCreated: Post!
  commentAdded(postId: ID!): Comment!
}
```

### Type System

```
┌──────────────────┬───────────────────────────────────────────────────┐
│ Type             │ Description                                       │
├──────────────────┼───────────────────────────────────────────────────┤
│ Scalar           │ Int, Float, String, Boolean, ID, custom scalars  │
├──────────────────┼───────────────────────────────────────────────────┤
│ Object           │ Named type with fields (User, Post)              │
├──────────────────┼───────────────────────────────────────────────────┤
│ Input            │ Object type for arguments (CreateUserInput)      │
├──────────────────┼───────────────────────────────────────────────────┤
│ Enum             │ Fixed set of values (UserStatus)                 │
├──────────────────┼───────────────────────────────────────────────────┤
│ Interface        │ Abstract type with shared fields                 │
├──────────────────┼───────────────────────────────────────────────────┤
│ Union            │ One of several object types (SearchResult =      │
│                  │ User | Post | Comment)                           │
├──────────────────┼───────────────────────────────────────────────────┤
│ List             │ [Type] — array of items                          │
├──────────────────┼───────────────────────────────────────────────────┤
│ Non-Null         │ Type! — guaranteed non-null                      │
└──────────────────┴───────────────────────────────────────────────────┘

Nullability:
  String   → nullable string (can be null)
  String!  → non-null string (never null)
  [String] → nullable list of nullable strings
  [String!]! → non-null list of non-null strings
```

### Query Execution

```
Client Query:                    Server Response:

query {                          {
  user(id: "123") {                "data": {
    name                             "user": {
    email                              "name": "alice",
    posts {                            "email": "a@b.com",
      title                            "posts": [
    }                                    { "title": "Hello" },
  }                                      { "title": "World" }
}                                      ]
                                     }
                                   }
                                 }

Client gets exactly the fields it asked for.
No over-fetching (extra fields), no under-fetching (missing fields).
```

### Introspection

GraphQL APIs are self-documenting. Any client can query the schema itself.

```graphql
query {
  __schema {
    types {
      name
      fields {
        name
        type { name }
      }
    }
  }
}
```

## Schema Composition

### Schema Stitching

Combines multiple GraphQL schemas into one by merging types and resolvers. The gateway delegates queries to the appropriate source schema.

```
┌──────────┐  ┌──────────┐  ┌──────────┐
│ Users    │  │ Posts     │  │ Comments │
│ Schema   │  │ Schema   │  │ Schema   │
└────┬─────┘  └────┬─────┘  └────┬─────┘
     │             │             │
     └──────┬──────┴──────┬──────┘
            ▼             ▼
     ┌──────────────────────────┐
     │    Stitched Gateway      │
     │   (merged schema)        │
     └──────────────────────────┘
```

### Apollo Federation (v2)

A structured approach to schema composition for microservices. Each service owns a portion of the graph and extends types from other services using directives.

```graphql
# Users Service
type User @key(fields: "id") {
  id: ID!
  name: String!
  email: String!
}

# Posts Service
type Post @key(fields: "id") {
  id: ID!
  title: String!
  author: User!
}

extend type User @key(fields: "id") {
  id: ID! @external
  posts: [Post!]!
}
```

```
┌──────────────┐  ┌──────────────┐
│ Users Service│  │ Posts Service │
│ (subgraph)   │  │ (subgraph)   │
└──────┬───────┘  └──────┬───────┘
       │                 │
       └────────┬────────┘
                ▼
     ┌─────────────────────┐
     │   Apollo Router     │
     │   (supergraph)      │
     │   Composes schemas  │
     │   Routes queries    │
     └─────────────────────┘
```

## Versioning

GraphQL APIs are typically **not versioned**. Instead, they evolve additively:

- Add new fields, types, and arguments freely (non-breaking)
- Mark deprecated fields with `@deprecated(reason: "Use newField")`
- Never remove fields until all clients have migrated
- Monitor field usage to identify when deprecated fields can be removed

```graphql
type User {
  id: ID!
  name: String!
  fullName: String!
  username: String @deprecated(reason: "Use name instead")
}
```

## Comparison with REST and gRPC

```
┌──────────────────┬──────────────┬──────────────┬──────────────┐
│ Aspect           │ GraphQL      │ REST         │ gRPC         │
├──────────────────┼──────────────┼──────────────┼──────────────┤
│ Schema/Contract  │ SDL          │ OpenAPI      │ .proto       │
├──────────────────┼──────────────┼──────────────┼──────────────┤
│ Data fetching    │ Client picks │ Server       │ Server       │
│                  │ fields       │ decides      │ decides      │
├──────────────────┼──────────────┼──────────────┼──────────────┤
│ Over-fetching    │ None         │ Common       │ None         │
├──────────────────┼──────────────┼──────────────┼──────────────┤
│ Under-fetching   │ None         │ Common       │ None         │
├──────────────────┼──────────────┼──────────────┼──────────────┤
│ Versioning       │ Additive     │ URL/header   │ Package      │
│                  │ evolution    │ versioning   │ versioning   │
├──────────────────┼──────────────┼──────────────┼──────────────┤
│ Transport        │ HTTP (POST)  │ HTTP         │ HTTP/2       │
├──────────────────┼──────────────┼──────────────┼──────────────┤
│ Format           │ JSON         │ JSON/XML     │ Protobuf     │
├──────────────────┼──────────────┼──────────────┼──────────────┤
│ Real-time        │ Subscriptions│ SSE/WS       │ Streaming    │
├──────────────────┼──────────────┼──────────────┼──────────────┤
│ Caching          │ Hard (POST)  │ Easy (HTTP)  │ Custom       │
├──────────────────┼──────────────┼──────────────┼──────────────┤
│ Best for         │ Client-driven│ CRUD APIs    │ Internal     │
│                  │ data needs   │              │ microservices│
└──────────────────┴──────────────┴──────────────┴──────────────┘
```

## Pros

- **No Over-Fetching**: clients request only the fields they need
- **No Under-Fetching**: get all related data in a single request (no N+1 REST calls)
- **Strongly Typed**: schema enforces types and validates queries at compile time
- **Self-Documenting**: introspection makes the schema explorable without external docs
- **Additive Evolution**: no versioning needed, deprecate fields gracefully
- **Federation**: compose microservice schemas into a unified graph
- **Tooling**: GraphiQL, Apollo Studio, code generators, type-safe clients
- **Real-Time**: subscriptions provide built-in real-time data streaming

## Cons

- **N+1 Problem**: naive resolvers cause N+1 database queries (solved by DataLoader)
- **Caching Difficulty**: POST-based queries bypass HTTP caching (use persisted queries)
- **Complexity**: more complex than REST for simple CRUD APIs
- **Security**: malicious queries can request deeply nested data (use depth/complexity limits)
- **File Upload**: no native file upload support (use multipart spec extension)
- **Learning Curve**: SDL, resolvers, DataLoader, federation require study
- **Error Handling**: partial success responses (data + errors) differ from REST's HTTP status codes
- **Performance Overhead**: query parsing, validation, and execution add latency vs direct REST

## Use Cases

- **Mobile Applications**: fetch exactly the data needed per screen, reducing bandwidth
- **BFF (Backend for Frontend)**: GraphQL as an aggregation layer over REST microservices
- **E-Commerce**: product pages with product details, reviews, recommendations in one query
- **Content Platforms**: GitHub (API v4), Shopify, and Contentful expose GraphQL APIs
- **Micro Frontend Data**: each frontend fragment fetches its own data requirements via fragments
- **Real-Time Dashboards**: subscriptions for live metrics, notifications, chat
- **API Gateway**: Apollo Federation as a unified entry point for microservices
- **Developer Portals**: self-documenting APIs with interactive GraphiQL explorers
