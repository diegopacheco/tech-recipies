# JSON Schema

## What is it?

JSON Schema is a declarative language for defining structure and constraints for JSON data. It allows you to describe the shape of your JSON documents, specify validation rules, data types, required fields, value ranges, string patterns, and more using a JSON-based vocabulary. A schema acts as a contract: validators check whether a given JSON instance conforms to the schema and report violations. It is both human-readable and machine-processable.

## Who created it? When?

JSON Schema was first proposed by **Kris Zyp** on **October 2, 2007**, submitted to json.com. The specification has evolved through several drafts over nearly two decades. The current latest version is **2020-12**. Key milestones:

```
┌──────────────┬──────────────────────────────────────────────────────────┐
│ Version      │ Notes                                                    │
├──────────────┼──────────────────────────────────────────────────────────┤
│ Draft-00     │ Initial proposal by Kris Zyp (2007)                     │
├──────────────┼──────────────────────────────────────────────────────────┤
│ Draft-04     │ Widely adopted, still used in many legacy systems       │
├──────────────┼──────────────────────────────────────────────────────────┤
│ Draft-06     │ Added const, contains, propertyNames, if/then/else      │
├──────────────┼──────────────────────────────────────────────────────────┤
│ Draft-07     │ Added conditional keywords, readOnly/writeOnly          │
├──────────────┼──────────────────────────────────────────────────────────┤
│ 2019-09      │ Renamed from "draft" to date-based, added $anchor       │
├──────────────┼──────────────────────────────────────────────────────────┤
│ 2020-12      │ Current version, replaced items with prefixItems        │
└──────────────┴──────────────────────────────────────────────────────────┘
```

## How it works?

A JSON Schema document is itself valid JSON. It uses keywords to describe the expected structure of a JSON instance. A validator takes the schema and an instance and checks whether the instance satisfies all the constraints.

### Basic Structure

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://example.com/user.schema.json",
  "title": "User",
  "description": "A user in the system",
  "type": "object",
  "properties": {
    "name": { "type": "string", "minLength": 1 },
    "age": { "type": "integer", "minimum": 0 },
    "email": { "type": "string", "format": "email" }
  },
  "required": ["name", "email"]
}
```

This schema validates JSON like:

```json
{ "name": "Alice", "age": 30, "email": "alice@example.com" }
```

And rejects JSON like:

```json
{ "age": -5 }
```

Because `name` and `email` are required, and `age` cannot be negative.

## Data Types

JSON Schema supports seven types:

```
┌───────────┬──────────────────────────────────────────────────────┐
│ Type      │ Description                                          │
├───────────┼──────────────────────────────────────────────────────┤
│ string    │ Textual data                                         │
├───────────┼──────────────────────────────────────────────────────┤
│ number    │ Any numeric value including decimals                  │
├───────────┼──────────────────────────────────────────────────────┤
│ integer   │ Whole numbers without decimal                        │
├───────────┼──────────────────────────────────────────────────────┤
│ boolean   │ true or false                                        │
├───────────┼──────────────────────────────────────────────────────┤
│ object    │ Key-value pairs                                      │
├───────────┼──────────────────────────────────────────────────────┤
│ array     │ Ordered list of values                               │
├───────────┼──────────────────────────────────────────────────────┤
│ null      │ Null value                                           │
└───────────┴──────────────────────────────────────────────────────┘
```

A property can accept multiple types: `"type": ["string", "null"]`

## Validation Keywords

### String Validation

```
┌──────────┬───────────────────────────────────────────────────────┐
│ Keyword  │ Description                                           │
├──────────┼───────────────────────────────────────────────────────┤
│ minLength│ Minimum number of characters                          │
├──────────┼───────────────────────────────────────────────────────┤
│ maxLength│ Maximum number of characters                          │
├──────────┼───────────────────────────────────────────────────────┤
│ pattern  │ ECMA-262 regular expression the string must match     │
├──────────┼───────────────────────────────────────────────────────┤
│ format   │ Semantic validation (email, uri, date-time, etc.)     │
└──────────┴───────────────────────────────────────────────────────┘
```

```json
{
  "type": "string",
  "minLength": 3,
  "maxLength": 50,
  "pattern": "^[a-zA-Z]+$"
}
```

### Numeric Validation

```
┌──────────────────┬────────────────────────────────────────────────┐
│ Keyword          │ Description                                    │
├──────────────────┼────────────────────────────────────────────────┤
│ minimum          │ Inclusive lower bound (value >= minimum)        │
├──────────────────┼────────────────────────────────────────────────┤
│ maximum          │ Inclusive upper bound (value <= maximum)        │
├──────────────────┼────────────────────────────────────────────────┤
│ exclusiveMinimum │ Exclusive lower bound (value > exclusiveMin)   │
├──────────────────┼────────────────────────────────────────────────┤
│ exclusiveMaximum │ Exclusive upper bound (value < exclusiveMax)   │
├──────────────────┼────────────────────────────────────────────────┤
│ multipleOf       │ Value must be divisible by this number         │
└──────────────────┴────────────────────────────────────────────────┘
```

```json
{
  "type": "number",
  "minimum": 0,
  "exclusiveMaximum": 100,
  "multipleOf": 0.5
}
```

### Array Validation

```
┌─────────────┬──────────────────────────────────────────────────────┐
│ Keyword     │ Description                                          │
├─────────────┼──────────────────────────────────────────────────────┤
│ items       │ Schema that all array items must match                │
├─────────────┼──────────────────────────────────────────────────────┤
│ prefixItems │ Ordered schemas for positional items (tuple)          │
├─────────────┼──────────────────────────────────────────────────────┤
│ contains    │ At least one item must match this schema              │
├─────────────┼──────────────────────────────────────────────────────┤
│ minItems    │ Minimum number of items                               │
├─────────────┼──────────────────────────────────────────────────────┤
│ maxItems    │ Maximum number of items                               │
├─────────────┼──────────────────────────────────────────────────────┤
│ uniqueItems │ All items must be distinct (true/false)               │
├─────────────┼──────────────────────────────────────────────────────┤
│ minContains │ Minimum number of items matching contains             │
├─────────────┼──────────────────────────────────────────────────────┤
│ maxContains │ Maximum number of items matching contains             │
└─────────────┴──────────────────────────────────────────────────────┘
```

```json
{
  "type": "array",
  "items": { "type": "string" },
  "minItems": 1,
  "uniqueItems": true
}
```

Tuple validation with `prefixItems` (2020-12):

```json
{
  "type": "array",
  "prefixItems": [
    { "type": "string" },
    { "type": "integer" },
    { "type": "boolean" }
  ],
  "items": false
}
```

This validates `["hello", 42, true]` and rejects extra items.

### Object Validation

```
┌──────────────────────┬──────────────────────────────────────────────┐
│ Keyword              │ Description                                  │
├──────────────────────┼──────────────────────────────────────────────┤
│ properties           │ Schema for each named property               │
├──────────────────────┼──────────────────────────────────────────────┤
│ required             │ Array of required property names              │
├──────────────────────┼──────────────────────────────────────────────┤
│ additionalProperties │ Schema for properties not in properties      │
├──────────────────────┼──────────────────────────────────────────────┤
│ patternProperties    │ Schema for properties matching regex keys     │
├──────────────────────┼──────────────────────────────────────────────┤
│ propertyNames        │ Schema that property names must match         │
├──────────────────────┼──────────────────────────────────────────────┤
│ minProperties        │ Minimum number of properties                  │
├──────────────────────┼──────────────────────────────────────────────┤
│ maxProperties        │ Maximum number of properties                  │
├──────────────────────┼──────────────────────────────────────────────┤
│ dependentRequired    │ Properties required when another is present   │
├──────────────────────┼──────────────────────────────────────────────┤
│ dependentSchemas     │ Schema applied when a property is present     │
└──────────────────────┴──────────────────────────────────────────────┘
```

```json
{
  "type": "object",
  "properties": {
    "street": { "type": "string" },
    "city": { "type": "string" },
    "zip": { "type": "string", "pattern": "^[0-9]{5}$" }
  },
  "required": ["street", "city"],
  "additionalProperties": false
}
```

### Value Constraints

```json
{ "enum": ["red", "green", "blue"] }

{ "const": "active" }
```

`enum` restricts to a fixed set of values. `const` restricts to exactly one value.

## Composition Keywords

JSON Schema supports combining schemas using boolean logic:

```
┌──────────┬────────────────────────────────────────────────────────┐
│ Keyword  │ Description                                            │
├──────────┼────────────────────────────────────────────────────────┤
│ allOf    │ Must match ALL of the listed schemas (AND)              │
├──────────┼────────────────────────────────────────────────────────┤
│ anyOf    │ Must match at least ONE schema (OR)                     │
├──────────┼────────────────────────────────────────────────────────┤
│ oneOf    │ Must match exactly ONE schema (XOR)                     │
├──────────┼────────────────────────────────────────────────────────┤
│ not      │ Must NOT match the schema                               │
└──────────┴────────────────────────────────────────────────────────┘
```

```json
{
  "oneOf": [
    { "type": "string", "maxLength": 5 },
    { "type": "number", "minimum": 0 }
  ]
}
```

## Conditional Schemas

```json
{
  "type": "object",
  "properties": {
    "country": { "type": "string" },
    "postal_code": { "type": "string" }
  },
  "if": {
    "properties": { "country": { "const": "US" } }
  },
  "then": {
    "properties": { "postal_code": { "pattern": "^[0-9]{5}$" } }
  },
  "else": {
    "properties": { "postal_code": { "pattern": "^[A-Z][0-9][A-Z] [0-9][A-Z][0-9]$" } }
  }
}
```

If `country` is `"US"`, postal code must be 5 digits. Otherwise it must match Canadian format.

## References and Reuse

`$ref` references another schema by URI. `$defs` defines reusable sub-schemas within the same document.

```json
{
  "$defs": {
    "address": {
      "type": "object",
      "properties": {
        "street": { "type": "string" },
        "city": { "type": "string" }
      },
      "required": ["street", "city"]
    }
  },
  "type": "object",
  "properties": {
    "home": { "$ref": "#/$defs/address" },
    "work": { "$ref": "#/$defs/address" }
  }
}
```

## Format Values

Built-in semantic format annotations:

```
┌──────────────────────┬───────────────────────────────────────────┐
│ Category             │ Format Values                             │
├──────────────────────┼───────────────────────────────────────────┤
│ Date/Time            │ date-time, date, time, duration           │
├──────────────────────┼───────────────────────────────────────────┤
│ Email                │ email, idn-email                          │
├──────────────────────┼───────────────────────────────────────────┤
│ Hostname             │ hostname, idn-hostname                    │
├──────────────────────┼───────────────────────────────────────────┤
│ IP Address           │ ipv4, ipv6                                │
├──────────────────────┼───────────────────────────────────────────┤
│ URI                  │ uri, uri-reference, iri, iri-reference    │
├──────────────────────┼───────────────────────────────────────────┤
│ URI Template         │ uri-template                              │
├──────────────────────┼───────────────────────────────────────────┤
│ UUID                 │ uuid                                      │
├──────────────────────┼───────────────────────────────────────────┤
│ JSON Pointer         │ json-pointer, relative-json-pointer       │
├──────────────────────┼───────────────────────────────────────────┤
│ Regex                │ regex                                     │
└──────────────────────┴───────────────────────────────────────────┘
```

Format is an annotation by default in 2020-12. Validators may optionally enforce it.

## Meta Keywords

```
┌──────────────┬─────────────────────────────────────────────────────┐
│ Keyword      │ Description                                         │
├──────────────┼─────────────────────────────────────────────────────┤
│ $schema      │ Declares which JSON Schema draft is being used       │
├──────────────┼─────────────────────────────────────────────────────┤
│ $id          │ Unique URI identifier for the schema                 │
├──────────────┼─────────────────────────────────────────────────────┤
│ $ref         │ Reference to another schema                          │
├──────────────┼─────────────────────────────────────────────────────┤
│ $defs        │ Container for reusable sub-schema definitions        │
├──────────────┼─────────────────────────────────────────────────────┤
│ $anchor      │ Named anchor within a schema for $ref targets        │
├──────────────┼─────────────────────────────────────────────────────┤
│ $comment     │ Developer comments (ignored by validators)           │
├──────────────┼─────────────────────────────────────────────────────┤
│ title        │ Short human-readable label                           │
├──────────────┼─────────────────────────────────────────────────────┤
│ description  │ Longer human-readable explanation                    │
├──────────────┼─────────────────────────────────────────────────────┤
│ default      │ Default value annotation                             │
├──────────────┼─────────────────────────────────────────────────────┤
│ deprecated   │ Marks a field as deprecated                          │
├──────────────┼─────────────────────────────────────────────────────┤
│ readOnly     │ Indicates value should not be modified               │
├──────────────┼─────────────────────────────────────────────────────┤
│ writeOnly    │ Indicates value should not be returned in responses  │
├──────────────┼─────────────────────────────────────────────────────┤
│ examples     │ Array of valid values for documentation              │
└──────────────┴─────────────────────────────────────────────────────┘
```

## Pros

- **Language Agnostic**: Validators exist for JavaScript, Python, Java, Go, Rust, Ruby, C#, PHP, and many more
- **Self-Documenting**: Schemas serve as both validation rules and API documentation
- **Composable**: `$ref`, `allOf`, `anyOf`, `oneOf` allow building complex schemas from reusable parts
- **Widely Adopted**: Used by OpenAPI/Swagger, AsyncAPI, MongoDB, and many API frameworks
- **IDE Support**: Editors like VS Code provide autocomplete and inline validation from JSON Schema
- **Code Generation**: Tools can generate types, classes, and form UIs directly from schemas
- **Precise Constraints**: Fine-grained control over string patterns, numeric ranges, array structure, and object shape
- **Conditional Logic**: `if`/`then`/`else` enables context-dependent validation rules
- **Standard Formats**: Built-in format annotations for common types like email, URI, date-time, and IP addresses
- **Backward Compatible**: Each draft builds on the previous, older schemas remain valid

## Cons

- **Verbose**: Schemas for complex objects become large and deeply nested
- **Learning Curve**: Advanced features like `$ref` composition, `anyOf` vs `oneOf`, and conditional schemas take time to master
- **Draft Fragmentation**: Multiple drafts in production (draft-04, draft-07, 2019-09, 2020-12) cause confusion about which keywords are available
- **Format Not Enforced**: `format` is an annotation by default in 2020-12, not a validation assertion
- **No Cross-Field Validation**: Cannot express "field A must be less than field B" without custom extensions
- **Error Messages**: Default validator error messages are often cryptic and hard to present to end users
- **Performance**: Deeply recursive schemas with many `$ref` and combinators can slow validation
- **No Arithmetic**: Cannot express computed defaults or derived values (e.g., total = price * quantity)
- **Tooling Inconsistency**: Not all validators implement every keyword from every draft identically
- **Schema Sprawl**: Large projects end up with dozens of schema files that become hard to navigate

## Use Cases

- **API Validation**: Validating request and response bodies in REST and GraphQL APIs
- **OpenAPI / Swagger**: JSON Schema is the foundation of OpenAPI specification for describing API payloads
- **Configuration Files**: Validating application config files (VS Code settings, ESLint configs, package.json)
- **Form Generation**: Automatically generating HTML forms and UI from schema definitions
- **Code Generation**: Generating TypeScript interfaces, Java POJOs, Go structs, or Python dataclasses from schemas
- **Database Validation**: MongoDB uses JSON Schema for document validation at the collection level
- **Data Pipelines**: Validating data at ingestion boundaries in ETL and streaming pipelines
- **Contract Testing**: Ensuring API producers and consumers agree on data shape without end-to-end tests
- **Documentation**: Auto-generating human-readable API documentation from schema annotations
- **IDE Autocomplete**: Providing autocomplete and error highlighting for JSON and YAML config files
