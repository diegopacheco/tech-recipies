# OpenAPI Specification

## What is it?

The OpenAPI Specification (OAS) is a standard for describing RESTful APIs in a machine-readable format (YAML or JSON). It defines endpoints, request/response schemas, authentication methods, parameters, headers, and error codes in a single document. Tools can consume the spec to generate documentation, client SDKs, server stubs, mock servers, and test suites. OpenAPI is the most widely adopted API description format.

## Who created it? When?

The specification started as **Swagger** in **2011**, created by **Tony Tam** at **Wordnik**. In **2015**, SmartBear Software donated the Swagger spec to the **Linux Foundation** under the **OpenAPI Initiative (OAI)**, where it was renamed to **OpenAPI Specification**. The current version is **OAS 3.1** (released **2021**), which aligns JSON Schema support with JSON Schema 2020-12. Major backers include Google, Microsoft, IBM, PayPal, and Atlassian.

```
Timeline:
  2011  Swagger 1.0 (Tony Tam)
  2014  Swagger 2.0 (widely adopted)
  2015  Donated to OpenAPI Initiative
  2017  OpenAPI 3.0 (major rewrite)
  2021  OpenAPI 3.1 (JSON Schema alignment)
```

## How it works?

### OAS 3.1 Structure

```yaml
openapi: 3.1.0
info:
  title: User Service API
  version: 1.0.0

servers:
  - url: https://api.example.com/v1

paths:
  /users:
    get:
      summary: List users
      operationId: listUsers
      parameters:
        - name: limit
          in: query
          schema:
            type: integer
            default: 20
      responses:
        '200':
          description: A list of users
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/User'

    post:
      summary: Create a user
      operationId: createUser
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateUserRequest'
      responses:
        '201':
          description: User created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
        '400':
          description: Validation error

  /users/{id}:
    get:
      summary: Get user by ID
      operationId: getUser
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: User found
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
        '404':
          description: User not found

components:
  schemas:
    User:
      type: object
      required: [id, name, email]
      properties:
        id:
          type: string
        name:
          type: string
        email:
          type: string
          format: email
        age:
          type: integer
          minimum: 0
        status:
          type: string
          enum: [active, inactive, banned]

    CreateUserRequest:
      type: object
      required: [name, email]
      properties:
        name:
          type: string
          minLength: 1
          maxLength: 100
        email:
          type: string
          format: email

  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT

security:
  - bearerAuth: []
```

### API-First Workflow

```
┌──────────────┐    ┌──────────────┐    ┌──────────────────────────┐
│ Design API   │───►│ Write OpenAPI │───►│ Generate from spec:      │
│ (team agrees │    │ spec (YAML)  │    │                          │
│  on contract)│    │              │    │  - Server stubs          │
└──────────────┘    └──────────────┘    │  - Client SDKs           │
                                        │  - Documentation         │
                                        │  - Mock servers          │
                                        │  - Test cases            │
                                        │  - API gateway config    │
                                        └──────────────────────────┘
```

## Tooling Ecosystem

```
┌──────────────────┬───────────────────────────────────────────────────┐
│ Category         │ Tools                                             │
├──────────────────┼───────────────────────────────────────────────────┤
│ Documentation    │ Swagger UI, Redoc, Stoplight Elements             │
├──────────────────┼───────────────────────────────────────────────────┤
│ Code generation  │ OpenAPI Generator, Swagger Codegen, openapi-ts,   │
│                  │ oapi-codegen (Go), Kiota (Microsoft)              │
├──────────────────┼───────────────────────────────────────────────────┤
│ Editors          │ Swagger Editor, Stoplight Studio, VS Code ext     │
├──────────────────┼───────────────────────────────────────────────────┤
│ Validation       │ Spectral (linting), openapi-diff, Prism (mock)   │
├──────────────────┼───────────────────────────────────────────────────┤
│ Testing          │ Dredd, Schemathesis, Prism (mock server)          │
├──────────────────┼───────────────────────────────────────────────────┤
│ Gateway config   │ Kong, AWS API Gateway, Apigee import OpenAPI      │
└──────────────────┴───────────────────────────────────────────────────┘
```

## Versioning Strategies

```
┌──────────────────────┬────────────────────────────────────────────────┐
│ Strategy             │ How it works                                    │
├──────────────────────┼────────────────────────────────────────────────┤
│ URL path versioning  │ /v1/users, /v2/users                           │
│                      │ Simple, explicit, most common                  │
├──────────────────────┼────────────────────────────────────────────────┤
│ Header versioning    │ Accept: application/vnd.api.v2+json            │
│                      │ Clean URLs, harder to test in browser          │
├──────────────────────┼────────────────────────────────────────────────┤
│ Query param          │ /users?version=2                               │
│                      │ Easy to add, pollutes query string             │
├──────────────────────┼────────────────────────────────────────────────┤
│ No versioning        │ Evolve in place with backward-compatible       │
│ (additive changes)   │ changes only (add fields, never remove)       │
└──────────────────────┴────────────────────────────────────────────────┘
```

## Pros

- **Industry Standard**: the most widely adopted API description format
- **Code Generation**: generate clients in 40+ languages from a single spec
- **Documentation**: auto-generated interactive docs (Swagger UI, Redoc)
- **Design First**: enables API-first development with contract agreement before coding
- **Validation**: request/response validation against the spec at runtime or in tests
- **Tooling Ecosystem**: editors, linters, mocking, testing, gateway integration
- **Human and Machine Readable**: YAML/JSON is readable by developers and parseable by tools
- **Interoperability**: API gateways, load balancers, and CDNs consume OpenAPI for routing and validation

## Cons

- **REST Only**: does not describe gRPC, GraphQL, WebSocket, or event-driven APIs
- **Spec Size**: large APIs produce massive spec files (thousands of lines)
- **Drift Risk**: spec and implementation can diverge if not enforced in CI
- **Limited Expressiveness**: some API patterns (HATEOAS, complex auth flows) are hard to describe
- **Versioning Complexity**: no built-in mechanism for describing breaking changes
- **Code Gen Quality**: generated code often needs manual adjustment for production use
- **OAS 3.0 vs 3.1**: tooling support for 3.1 is still incomplete in some ecosystems
- **Over-Specification**: teams can spend more time maintaining the spec than building the API

## Use Cases

- **API-First Development**: designing the contract before implementing backend or frontend
- **Client SDK Generation**: generating typed clients for mobile, web, and backend consumers
- **API Documentation**: hosting interactive docs for internal and external developers
- **Contract Testing**: validating that the implementation matches the spec in CI/CD
- **API Gateway Configuration**: importing OpenAPI specs into Kong, AWS API Gateway, Apigee
- **Mock Servers**: running Prism or WireMock from the spec for frontend development
- **Migration**: documenting legacy APIs as a first step toward modernization
- **Partner Integrations**: sharing machine-readable API specs with external partners
