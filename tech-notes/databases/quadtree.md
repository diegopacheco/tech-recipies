# Quadtrees

## What is it?

A quadtree is a tree data structure in which every internal node has exactly four children. It is used to index and partition a two-dimensional space by recursively subdividing a region into four equal quadrants — North-West, North-East, South-West, South-East. Each node owns a rectangular bounding box; when too many items fall inside that box, the node splits into four smaller boxes and the items are pushed down. The result is an adaptive spatial index: regions that are densely populated end up deeply subdivided, while empty regions stay shallow. This makes spatial queries — "which points are inside this rectangle?", "what is the nearest neighbor?", "which objects might collide?" — far cheaper than scanning every item, because whole quadrants that cannot intersect the query are pruned in one comparison.

## Who created it? When?

The quadtree was introduced by **Raphael Finkel** and **Jon Louis Bentley** in a **1974** paper titled *"Quad Trees: A Data Structure for Retrieval on Composite Keys"*. The region-based variant for images was formalized by **Hanan Samet**, whose work through the 1980s (*"The Quadtree and Related Hierarchical Data Structures"*, 1984) made quadtrees a cornerstone of spatial databases, GIS, and computer graphics. The three-dimensional generalization is the **octree** (eight children per node).

## How it works?

### Spatial Subdivision

```
A 2D region is recursively split into 4 equal quadrants.
A quadrant that holds more than CAPACITY items splits again.

┌──────────────────────────────┐
│              │               │
│   NW         │    NE         │
│       ●      │   ●           │
│              │        ●      │
│──────────────┼───────┬───────┤
│              │   ●   │ ┌──┬──┐│
│   SW         │       │ │● │● ││   ← dense corner keeps
│        ●     │       │ ├──┼──┤│     subdividing until each
│              │       │ │●●│● ││     leaf holds <= CAPACITY
└──────────────┴───────┴──┴──┴─┘
```

### Tree Structure

```
Each node maps to one box. Only crowded quadrants grow deeper.

                Root  (0,0 .. 100,100)
        ┌─────────┬─────────┬─────────┐
       NW        NE        SW        SE
                  │
        ┌─────────┼─────────┬─────────┐
       NW        NE        SW        SE   ← NE was crowded, so it split
                            │
                     ┌──────┼──────┬──────┐
                    NW     NE     SW     SE

Depth is data-driven: empty space stays shallow,
clusters drive deep branches.
```

### Insertion

```
insert(point):
  1. If point is outside this node's box → reject.
  2. If this node is a leaf with room (size < CAPACITY) → store it.
  3. Otherwise:
        a. Subdivide into NW, NE, SW, SE (if not already split).
        b. Hand the point to the one child whose box contains it.

         before split                  after split (CAPACITY = 4)
   ┌───────────────────┐         ┌─────────┬─────────┐
   │ ●   ●             │         │ ●   ●   │         │
   │       ●           │   →     │       ● │         │
   │   ●         ●(new)│         │   ●     │     ●   │
   │                   │         ├─────────┼─────────┤
   │                   │         │         │         │
   └───────────────────┘         └─────────┴─────────┘
```

### Range Query (Window Search)

```
query(rangeBox):
  1. If this node's box does NOT intersect rangeBox → prune (skip subtree).
  2. Collect this node's points that fall inside rangeBox.
  3. Recurse into the four children.

         ╔═══════════╗ rangeBox
   ┌─────╫─────┬─────╫─────┐
   │ ●   ║ ●   │     ║     │   Quadrants fully outside the
   │     ║     │     ║     │   window are pruned in one test.
   ├─────╫─────┼─────╫─────┤   Only shaded quadrants are visited.
   │     ║   ● │ ●   ║     │
   └─────╫─────┴─────╫─────┘
         ╚═══════════╝

Cost ≈ O(visited nodes), not O(total points).
```

### Nearest Neighbor

```
Descend to the leaf containing the query point, then expand outward.
A child box is only explored if its closest edge is nearer than the
best match found so far — most of the tree is skipped.

  query ✕ ──► nearest first searches the owning quadrant,
              then back-tracks into sibling quadrants only
              when they could contain something closer.
```

### Variants

```
┌────────────────────┬─────────────────────────────────────────────┐
│ Variant            │ How it works                                 │
├────────────────────┼─────────────────────────────────────────────┤
│ Point Quadtree     │ Each point becomes a node; the point itself  │
│ (Finkel & Bentley) │ defines the split into 4 unequal quadrants.  │
├────────────────────┼─────────────────────────────────────────────┤
│ Point-Region (PR)  │ Splits into 4 EQUAL quadrants by geometry,   │
│ Quadtree           │ not by data. Most common for point indexing. │
├────────────────────┼─────────────────────────────────────────────┤
│ Region Quadtree    │ Indexes a raster / image. A node splits when │
│ (MX Quadtree)      │ its cell is not uniform (mixed colors).      │
├────────────────────┼─────────────────────────────────────────────┤
│ Edge Quadtree      │ Stores line segments / curves; subdivides    │
│                    │ until each cell holds a single edge.         │
├────────────────────┼─────────────────────────────────────────────┤
│ Compressed /       │ Skips chains of single-child nodes to bound  │
│ Path-Compressed    │ depth on skewed data. O(n) space guarantee.  │
├────────────────────┼─────────────────────────────────────────────┤
│ Loose Quadtree     │ Child boxes overlap slightly so moving       │
│                    │ objects change nodes less often (games).     │
├────────────────────┼─────────────────────────────────────────────┤
│ Octree (3D)        │ Same idea with 8 children — 3D space, voxels,│
│                    │ point clouds, physics, rendering.            │
└────────────────────┴─────────────────────────────────────────────┘
```

### Quadtree vs Other Spatial Indexes

```
┌──────────────┬───────────────────────────────────────────────────┐
│ Structure    │ Trade-offs                                         │
├──────────────┼───────────────────────────────────────────────────┤
│ Quadtree     │ Space-driven, simple, fast dynamic insert/delete.  │
│              │ Can get deep/unbalanced on clustered data.         │
├──────────────┼───────────────────────────────────────────────────┤
│ k-d Tree     │ Binary split on alternating axes. Great for static │
│              │ nearest-neighbor; costly to rebalance on updates.  │
├──────────────┼───────────────────────────────────────────────────┤
│ R-Tree       │ Data-driven bounding boxes that may overlap.       │
│              │ Balanced, handles rectangles/regions, used by      │
│              │ PostGIS, SQLite. Heavier inserts.                  │
├──────────────┼───────────────────────────────────────────────────┤
│ Geohash /    │ Encodes the quadtree path as a string/integer.     │
│ Z-order curve│ Maps 2D to 1D for B-tree / sharded storage.        │
├──────────────┼───────────────────────────────────────────────────┤
│ Grid / Hash  │ Uniform fixed cells. O(1) lookups but wastes       │
│              │ memory on sparse or skewed distributions.          │
└──────────────┴───────────────────────────────────────────────────┘
```

## Who is using Quadtrees

```
┌──────────────────┬────────────────────────────────────────────────┐
│ System           │ Details                                         │
├──────────────────┼────────────────────────────────────────────────┤
│ PostgreSQL       │ SP-GiST index access method implements          │
│ (SP-GiST)        │ quadtrees and k-d trees for points.            │
├──────────────────┼────────────────────────────────────────────────┤
│ Apache Lucene /  │ QuadPrefixTree and geohash prefix trees power   │
│ Elasticsearch    │ older geo_shape spatial search (recursive grid).│
├──────────────────┼────────────────────────────────────────────────┤
│ Google S2        │ Quadtree over the 6 faces of a cube projected   │
│ Geometry         │ onto a sphere; cells ordered by a Hilbert curve.│
├──────────────────┼────────────────────────────────────────────────┤
│ HEVC / H.265,    │ Video codecs partition each frame into coding   │
│ AV1, VP9         │ blocks via quadtree (and multi-tree) splitting. │
├──────────────────┼────────────────────────────────────────────────┤
│ Game Engines     │ Unity, Unreal, Box2D use quadtrees/octrees for  │
│ (Unity, Unreal)  │ broad-phase collision and frustum culling.      │
├──────────────────┼────────────────────────────────────────────────┤
│ GIS / Mapping    │ ArcGIS, QGIS, Mapbox tiling, OpenStreetMap      │
│                  │ tools use quadtree tiles (XYZ slippy-map tiles).│
├──────────────────┼────────────────────────────────────────────────┤
│ Image Processing │ Region quadtrees for compression, morphology,   │
│                  │ and connected-component labeling.               │
├──────────────────┼────────────────────────────────────────────────┤
│ Simulations      │ Barnes-Hut N-body (quadtree/octree) approximates│
│                  │ gravity for clusters of distant bodies.         │
└──────────────────┴────────────────────────────────────────────────┘
```

## Pros

- **Simple to Implement**: the recursive four-way split is short and easy to reason about
- **Adaptive**: depth follows data density — sparse regions stay shallow, dense ones subdivide
- **Fast Spatial Queries**: range and window searches prune entire quadrants in one comparison
- **Dynamic**: supports incremental insert and delete without rebuilding the whole index
- **Efficient Nearest-Neighbor**: back-tracking search visits only quadrants that could be closer
- **Natural for 2D**: maps directly onto screens, maps, images, and game worlds
- **Composable**: the same idea scales to octrees (3D) and to disk via Z-order / geohash encoding
- **Cache of Locality**: nearby points share a subtree, which helps memory and tile access patterns

## Cons

- **Unbalanced on Clusters**: heavily clustered points create deep, lopsided branches
- **Worst-Case O(n)**: nearly coincident points can degrade lookups to a linear scan
- **Fixed to the Plane**: a basic quadtree handles 2D points well but not rectangles/regions (R-tree is better there)
- **Sensitive to Capacity**: bucket size and max depth must be tuned to the workload
- **Memory Overhead**: many internal nodes for sparse or skewed data; pointers cost space
- **Moving Objects Churn**: objects crossing quadrant borders force frequent re-insertion (loose quadtrees mitigate this)
- **Not Self-Balancing**: unlike B-trees/R-trees there is no rebalance step — compression variants are needed
- **Boundary Cases**: points exactly on split lines need a consistent containment rule to avoid loss

## Use Cases

- **Geospatial Indexing**: "find all stores within this map viewport", ride-hailing driver lookup
- **Collision Detection**: broad-phase culling in 2D games and physics engines
- **Image Compression**: region quadtrees encode uniform blocks compactly
- **Video Coding**: quadtree block partitioning in HEVC/AV1 for variable-size coding units
- **Map Tiling**: XYZ slippy-map tiles are a quadtree of the world projection
- **Nearest-Neighbor Search**: closest point of interest, k-NN over 2D coordinates
- **Mesh and Terrain Generation**: level-of-detail and adaptive subdivision of surfaces
- **N-Body Simulation**: Barnes-Hut approximation of gravitational/electrostatic forces
- **Sensor / IoT Data**: indexing fixed-location readings for spatial aggregation
- **Procedural Generation**: spatial partitioning for world streaming and culling

## Simple Java Implementation

A bucket Point-Region quadtree with insert and range query.

```java
import java.util.ArrayList;
import java.util.List;

public class Quadtree {

    static final class Point {
        final double x;
        final double y;
        Point(double x, double y) {
            this.x = x;
            this.y = y;
        }
    }

    static final class Box {
        final double x;
        final double y;
        final double w;
        final double h;
        Box(double x, double y, double w, double h) {
            this.x = x;
            this.y = y;
            this.w = w;
            this.h = h;
        }
        boolean contains(Point p) {
            return p.x >= x && p.x < x + w && p.y >= y && p.y < y + h;
        }
        boolean intersects(Box o) {
            return !(o.x > x + w || o.x + o.w < x || o.y > y + h || o.y + o.h < y);
        }
    }

    private static final int CAPACITY = 4;

    private final Box boundary;
    private final List<Point> points = new ArrayList<>();
    private boolean divided = false;
    private Quadtree nw, ne, sw, se;

    public Quadtree(Box boundary) {
        this.boundary = boundary;
    }

    public boolean insert(Point p) {
        if (!boundary.contains(p)) {
            return false;
        }
        if (points.size() < CAPACITY && !divided) {
            points.add(p);
            return true;
        }
        if (!divided) {
            subdivide();
        }
        return nw.insert(p) || ne.insert(p) || sw.insert(p) || se.insert(p);
    }

    private void subdivide() {
        double hw = boundary.w / 2;
        double hh = boundary.h / 2;
        double x = boundary.x;
        double y = boundary.y;
        nw = new Quadtree(new Box(x, y, hw, hh));
        ne = new Quadtree(new Box(x + hw, y, hw, hh));
        sw = new Quadtree(new Box(x, y + hh, hw, hh));
        se = new Quadtree(new Box(x + hw, y + hh, hw, hh));
        divided = true;
    }

    public List<Point> query(Box range, List<Point> found) {
        if (!boundary.intersects(range)) {
            return found;
        }
        for (Point p : points) {
            if (range.contains(p)) {
                found.add(p);
            }
        }
        if (divided) {
            nw.query(range, found);
            ne.query(range, found);
            sw.query(range, found);
            se.query(range, found);
        }
        return found;
    }

    public static void main(String[] args) {
        Quadtree tree = new Quadtree(new Box(0, 0, 100, 100));
        double[][] coords = {
            {10, 10}, {20, 20}, {30, 30}, {15, 75},
            {70, 70}, {80, 85}, {90, 10}, {5, 5}, {25, 60}
        };
        for (double[] c : coords) {
            tree.insert(new Point(c[0], c[1]));
        }
        List<Point> found = tree.query(new Box(0, 0, 35, 35), new ArrayList<>());
        for (Point p : found) {
            System.out.println(p.x + ", " + p.y);
        }
    }
}
```

## Links

- Finkel & Bentley (1974), *Quad Trees: A Data Structure for Retrieval on Composite Keys* — https://dl.acm.org/doi/10.1007/BF00288933
- Hanan Samet, *The Quadtree and Related Hierarchical Data Structures* — https://dl.acm.org/doi/10.1145/356924.356930
- Wikipedia — Quadtree — https://en.wikipedia.org/wiki/Quadtree
- PostgreSQL SP-GiST (quadtree/k-d tree indexes) — https://www.postgresql.org/docs/current/spgist.html
- Apache Lucene spatial prefix trees — https://lucene.apache.org/core/9_0_0/spatial-extras/org/apache/lucene/spatial/prefix/tree/QuadPrefixTree.html
- Google S2 Geometry (spherical quadtree) — https://s2geometry.io/
- Hanan Samet, *Foundations of Multidimensional and Metric Data Structures* — https://www.cs.umd.edu/~hjs/quadtree/
- The Coding Train — Quadtree visualization — https://www.youtube.com/watch?v=OJxEcs0w_kE
