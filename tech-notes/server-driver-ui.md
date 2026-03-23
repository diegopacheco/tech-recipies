# Server-Driven UI

## What is Server-Driven UI?

Server-Driven UI (SDUI) is an architectural pattern where the server controls the structure, layout, and behavior of the user interface. Instead of the client having hardcoded UI logic, the server sends a declarative description of what the UI should look like, and the client renders it dynamically. The server response typically contains a tree of UI components with their properties, layout rules, and actions.

The client acts as a thin rendering engine that interprets the server's UI schema and maps it to native components. This shifts the control of what users see from the client codebase to the server, enabling updates without app store releases.

## How it Works

1. Client requests a screen or page from the server
2. Server returns a JSON/protobuf payload describing the UI component tree
3. Client parses the payload and maps each node to a native component
4. User interactions trigger actions defined in the payload (navigation, API calls, state changes)
5. Server can return different UI structures based on user segment, A/B test, feature flag, or device type

```
┌──────────┐       GET /home          ┌──────────────┐
│  Client   │ ──────────────────────► │    Server     │
│ (Renderer)│                         │ (UI Builder)  │
│           │ ◄────────────────────── │               │
└──────────┘   JSON UI Component Tree └──────────────┘

Response:
{
  "type": "screen",
  "children": [
    {
      "type": "header",
      "props": { "title": "Welcome" }
    },
    {
      "type": "list",
      "props": { "orientation": "vertical" },
      "children": [
        {
          "type": "card",
          "props": { "title": "Item 1", "image": "/img/1.png" },
          "action": { "type": "navigate", "target": "/detail/1" }
        }
      ]
    }
  ]
}
```

## Pros

- **Instant updates**: change the UI without deploying a new client version or waiting for app store review
- **A/B testing**: serve different UI layouts to different user segments from the server
- **Consistency**: single source of truth for UI logic across iOS, Android, and Web
- **Feature flags built-in**: enable or disable features by changing the server response
- **Reduced client complexity**: client becomes a generic renderer, less platform-specific code
- **Personalization**: tailor the UI per user, region, or device without client changes
- **Faster iteration**: product teams can ship UI changes independently from mobile release cycles

## Cons

- **Network dependency**: every screen needs a server round-trip, slower first render
- **Limited offline support**: without a cached schema, the client cannot render anything
- **Reduced client-side interactivity**: complex animations and gestures are hard to express in a schema
- **Schema complexity**: the component schema can grow large and hard to maintain
- **Debugging difficulty**: UI bugs can come from server payloads, client rendering, or schema mismatches
- **Performance overhead**: parsing and interpreting the schema adds latency compared to native hardcoded UI
- **Tooling gap**: fewer mature tools compared to traditional UI development

## Who Uses It?

- **Airbnb**: uses server-driven UI for their home screen and search results, enabling rapid experimentation
- **Lyft**: adopted SDUI for ride experience screens to iterate without app releases
- **Shopify**: uses server-driven rendering for their Shop app storefront
- **Instagram/Meta**: uses server-driven feeds and stories layout
- **Netflix**: home screen layout and content rows are server-driven
- **PhonePe**: uses SDUI extensively for their payments and financial services UI in India
- **JetBrains**: uses server-driven UI in some of their cloud-based IDE features

## Comparison with Similar Approaches

### Server-Driven UI vs Traditional Client-Side UI

| Aspect | Server-Driven UI | Traditional Client-Side UI |
|---|---|---|
| UI logic location | Server | Client |
| Update speed | Instant (server change) | Requires client release |
| Offline support | Limited | Full |
| Client complexity | Low (renderer only) | High (full UI logic) |
| Interactivity | Constrained by schema | Full native capabilities |
| Best for | Dynamic content, A/B testing | Rich interactive experiences |

### Server-Driven UI vs Micro-Frontends

| Aspect | Server-Driven UI | Micro-Frontends |
|---|---|---|
| Unit of composition | Components via schema | Independent web apps |
| Platform | Mobile + Web | Primarily Web |
| Rendering | Native components from schema | iframes, web components, or JS bundles |
| Team autonomy | Server team controls layout | Each team owns their frontend |
| Best for | Mobile apps with dynamic layouts | Large web apps with multiple teams |

### Server-Driven UI vs Backend-for-Frontend (BFF)

| Aspect | Server-Driven UI | BFF |
|---|---|---|
| Server returns | UI component tree | Data shaped for the client |
| Client responsibility | Render components | Build UI from data |
| Coupling | Client coupled to component schema | Client coupled to data schema |
| Flexibility | Server controls layout + data | Server controls data, client controls layout |
| Best for | Full UI control from server | Optimized API per client type |
