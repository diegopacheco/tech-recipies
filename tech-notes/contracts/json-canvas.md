# JSON Canvas

## What is it?

JSON Canvas is an open file format for infinite canvas data. It provides a standardized way to represent spatially organized information on digital whiteboards and infinite canvases. The format stores nodes (content blocks positioned in 2D space) and edges (connections between nodes) in a simple JSON structure. It prioritizes longevity, readability, interoperability, and extensibility while giving users ownership and control over their data.

## Who created it? When?

JSON Canvas was created by the **Obsidian** team and released as an open specification on **March 11, 2024** (version 1.0). It is licensed under **MIT** and maintained on GitHub at `obsidianmd/jsoncanvas`. The format was originally developed as the native canvas format for Obsidian but was opened up so any application can freely use it as an import/export format or primary storage mechanism.

## File Format

- **File Extension**: `.canvas`
- **Format**: JSON
- **Spec Version**: 1.0
- **License**: MIT

## How it works?

The root JSON object contains two optional arrays: `nodes` and `edges`.

```json
{
  "nodes": [],
  "edges": []
}
```

Node z-index ordering is determined by array position. The first node in the array appears below all others, the last node appears on top.

### Nodes

All nodes share these base properties:

```
┌────────────┬──────────────┬──────────┬─────────────────────────────────────┐
│ Property   │ Type         │ Required │ Description                         │
├────────────┼──────────────┼──────────┼─────────────────────────────────────┤
│ id         │ string       │ Yes      │ Unique identifier                   │
├────────────┼──────────────┼──────────┼─────────────────────────────────────┤
│ type       │ string       │ Yes      │ Node type (text/file/link/group)    │
├────────────┼──────────────┼──────────┼─────────────────────────────────────┤
│ x          │ integer      │ Yes      │ Horizontal position in pixels       │
├────────────┼──────────────┼──────────┼─────────────────────────────────────┤
│ y          │ integer      │ Yes      │ Vertical position in pixels         │
├────────────┼──────────────┼──────────┼─────────────────────────────────────┤
│ width      │ integer      │ Yes      │ Width in pixels                     │
├────────────┼──────────────┼──────────┼─────────────────────────────────────┤
│ height     │ integer      │ Yes      │ Height in pixels                    │
├────────────┼──────────────┼──────────┼─────────────────────────────────────┤
│ color      │ canvasColor  │ No       │ Node color (hex or preset number)   │
└────────────┴──────────────┴──────────┴─────────────────────────────────────┘
```

### Node Types

**1. Text Node** (`type: "text"`)

Contains plain text with Markdown syntax support.

```json
{
  "id": "node1",
  "type": "text",
  "x": 0,
  "y": 0,
  "width": 400,
  "height": 200,
  "text": "# Hello\nThis is a **text node** with Markdown."
}
```

| Property | Type   | Required | Description                  |
|----------|--------|----------|------------------------------|
| text     | string | Yes      | Plain text with Markdown     |

**2. File Node** (`type: "file"`)

References a file within the system.

```json
{
  "id": "node2",
  "type": "file",
  "x": 500,
  "y": 0,
  "width": 400,
  "height": 300,
  "file": "path/to/document.pdf",
  "subpath": "#section-heading"
}
```

| Property | Type   | Required | Description                                     |
|----------|--------|----------|-------------------------------------------------|
| file     | string | Yes      | File path within the system                     |
| subpath  | string | No       | Link to a heading or block, starts with `#`     |

**3. Link Node** (`type: "link"`)

Embeds a URL reference.

```json
{
  "id": "node3",
  "type": "link",
  "x": 0,
  "y": 400,
  "width": 400,
  "height": 200,
  "url": "https://jsoncanvas.org"
}
```

| Property | Type   | Required | Description |
|----------|--------|----------|-------------|
| url      | string | Yes      | URL         |

**4. Group Node** (`type: "group"`)

A visual container that groups other nodes.

```json
{
  "id": "node4",
  "type": "group",
  "x": -50,
  "y": -50,
  "width": 1000,
  "height": 800,
  "label": "My Group",
  "background": "path/to/bg.png",
  "backgroundStyle": "cover"
}
```

| Property        | Type   | Required | Description                          |
|-----------------|--------|----------|--------------------------------------|
| label           | string | No       | Group text label                     |
| background      | string | No       | Background image path                |
| backgroundStyle | string | No       | `"cover"`, `"ratio"`, or `"repeat"` |

Background style values:
- `"cover"` — fills entire node dimensions
- `"ratio"` — preserves image aspect ratio
- `"repeat"` — tiles the image as a pattern

### Edges

Edges represent connections between nodes.

```
┌────────────┬──────────────┬──────────┬──────────────────────────────────────────┐
│ Property   │ Type         │ Required │ Description                              │
├────────────┼──────────────┼──────────┼──────────────────────────────────────────┤
│ id         │ string       │ Yes      │ Unique identifier                        │
├────────────┼──────────────┼──────────┼──────────────────────────────────────────┤
│ fromNode   │ string       │ Yes      │ Source node id                           │
├────────────┼──────────────┼──────────┼──────────────────────────────────────────┤
│ toNode     │ string       │ Yes      │ Destination node id                      │
├────────────┼──────────────┼──────────┼──────────────────────────────────────────┤
│ fromSide   │ string       │ No       │ "top", "right", "bottom", "left"         │
├────────────┼──────────────┼──────────┼──────────────────────────────────────────┤
│ fromEnd    │ string       │ No       │ "none" (default) or "arrow"              │
├────────────┼──────────────┼──────────┼──────────────────────────────────────────┤
│ toSide     │ string       │ No       │ "top", "right", "bottom", "left"         │
├────────────┼──────────────┼──────────┼──────────────────────────────────────────┤
│ toEnd      │ string       │ No       │ "none" or "arrow" (default)              │
├────────────┼──────────────┼──────────┼──────────────────────────────────────────┤
│ color      │ canvasColor  │ No       │ Line color                               │
├────────────┼──────────────┼──────────┼──────────────────────────────────────────┤
│ label      │ string       │ No       │ Edge text label                          │
└────────────┴──────────────┴──────────┴──────────────────────────────────────────┘
```

```json
{
  "id": "edge1",
  "fromNode": "node1",
  "fromSide": "right",
  "fromEnd": "none",
  "toNode": "node2",
  "toSide": "left",
  "toEnd": "arrow",
  "color": "#FF0000",
  "label": "relates to"
}
```

### Color Specification (canvasColor)

Colors can be specified in two ways:

**Hex format**: `"#RRGGBB"` — six hex digit color code

**Preset numbers**:

```
┌────────┬─────────┐
│ Value  │ Color   │
├────────┼─────────┤
│ "1"    │ Red     │
├────────┼─────────┤
│ "2"    │ Orange  │
├────────┼─────────┤
│ "3"    │ Yellow  │
├────────┼─────────┤
│ "4"    │ Green   │
├────────┼─────────┤
│ "5"    │ Cyan    │
├────────┼─────────┤
│ "6"    │ Purple  │
└────────┴─────────┘
```

Specific RGB values for preset colors are intentionally left undefined so each application can choose its own theme-appropriate values.

## Full Structure

```json
{
  "nodes": [
    {
      "id": "text1",
      "type": "text",
      "x": 0,
      "y": 0,
      "width": 300,
      "height": 200,
      "color": "4",
      "text": "# Architecture\nMain service components."
    },
    {
      "id": "file1",
      "type": "file",
      "x": 400,
      "y": 0,
      "width": 300,
      "height": 200,
      "file": "diagrams/arch.png"
    },
    {
      "id": "link1",
      "type": "link",
      "x": 0,
      "y": 300,
      "width": 300,
      "height": 200,
      "url": "https://docs.example.com/api"
    },
    {
      "id": "group1",
      "type": "group",
      "x": -20,
      "y": -20,
      "width": 740,
      "height": 540,
      "label": "System Overview"
    }
  ],
  "edges": [
    {
      "id": "edge1",
      "fromNode": "text1",
      "fromSide": "right",
      "toNode": "file1",
      "toSide": "left",
      "toEnd": "arrow",
      "label": "describes"
    },
    {
      "id": "edge2",
      "fromNode": "text1",
      "fromSide": "bottom",
      "toNode": "link1",
      "toSide": "top",
      "color": "5"
    }
  ]
}
```

## Pros

- **Simple Format**: Plain JSON that is easy to read, write, and parse in any language
- **Open Standard**: MIT licensed, no vendor lock-in, any application can implement it
- **Human Readable**: JSON is text-based and can be inspected or edited with any text editor
- **Spatial Organization**: Represents 2D spatial layouts that linear formats cannot capture
- **Extensible**: New node types and properties can be added without breaking existing implementations
- **Version Controllable**: Being plain text JSON, canvas files work well with git and diff tools
- **Lightweight**: No binary blobs or proprietary encoding, just a small JSON file
- **Interoperable**: Applications can import and export the same format for canvas data exchange
- **Markdown Support**: Text nodes use Markdown, leveraging an already widely adopted syntax
- **Flexible Connections**: Edges support directional arrows, labels, colors, and side-specific attachment points

## Cons

- **No Standard Styling**: Beyond color, there is no built-in support for fonts, borders, or node styling
- **No Layout Engine**: The format stores positions but defines no layout algorithms, each app must implement its own
- **Limited Edge Types**: Only `"none"` and `"arrow"` endpoints, no support for diamond, circle, or other UML shapes
- **No Nesting Depth**: Group nodes contain other nodes by spatial overlap, not by explicit parent-child references
- **No Animation or Interaction**: Static format with no support for transitions, interactions, or dynamic behavior
- **Limited Color Presets**: Only 6 preset colors, and their RGB values are undefined across implementations
- **No Constraints**: No way to express alignment, snapping, spacing, or layout constraints between nodes
- **Young Specification**: Version 1.0 is the first release, ecosystem and tooling are still growing
- **File References**: File nodes use paths, which break when files are moved or shared across systems
- **No Schema Validation**: No official JSON Schema for automated validation of canvas files

## Use Cases

- **Knowledge Management**: Organizing notes, ideas, and research spatially in tools like Obsidian
- **Brainstorming**: Visual brainstorming with text nodes, links, and connections on an infinite canvas
- **Architecture Diagrams**: Laying out system components and their relationships
- **Project Planning**: Visual boards for planning sprints, features, and task dependencies
- **Mind Mapping**: Hierarchical idea exploration with connected nodes branching outward
- **Mood Boards**: Collecting images, links, and text in a spatial collage
- **Research Boards**: Combining file references, web links, and notes for research projects
- **Data Interchange**: Exporting and importing canvas data between different infinite canvas applications
- **Documentation**: Visual documentation that combines text, file references, and diagrams
- **Workflow Design**: Mapping out processes and workflows with directed edges between steps
