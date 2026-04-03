# SIMD

## What is it?

SIMD (Single Instruction, Multiple Data) is a parallel processing paradigm where a single CPU instruction operates on multiple data elements simultaneously. Instead of processing one number at a time, SIMD registers hold 4, 8, 16, or more values and apply the same operation to all of them in one clock cycle. A scalar addition adds two numbers; a SIMD addition adds 4 pairs of numbers in the same time. SIMD is fundamental to high-performance computing — modern CPUs dedicate significant silicon to SIMD units, and workloads like image processing, audio codecs, machine learning inference, compression, and scientific simulation rely on SIMD for 4-16x speedups over scalar code.

## How it works?

### Scalar vs SIMD

```
Scalar (one at a time):

  a[0] + b[0] = c[0]     ← 1 cycle
  a[1] + b[1] = c[1]     ← 1 cycle
  a[2] + b[2] = c[2]     ← 1 cycle
  a[3] + b[3] = c[3]     ← 1 cycle
                            Total: 4 cycles


SIMD (four at a time):

  ┌──────┬──────┬──────┬──────┐     ┌──────┬──────┬──────┬──────┐
  │ a[0] │ a[1] │ a[2] │ a[3] │  +  │ b[0] │ b[1] │ b[2] │ b[3] │
  └──────┴──────┴──────┴──────┘     └──────┴──────┴──────┴──────┘
  ──────────────────────────────────────────────────────────────────
  ┌──────┬──────┬──────┬──────┐
  │ c[0] │ c[1] │ c[2] │ c[3] │  ← 1 cycle (4x throughput)
  └──────┴──────┴──────┴──────┘
```

### SIMD Register Sizes

```
┌──────────────────┬──────────┬────────────────────────────────────┐
│ Instruction Set  │ Register │ Elements per register               │
│                  │ Width    │                                     │
├──────────────────┼──────────┼────────────────────────────────────┤
│ SSE              │ 128 bit  │ 4x float, 2x double, 4x int32,    │
│ (x86, 1999)      │          │ 16x int8                           │
├──────────────────┼──────────┼────────────────────────────────────┤
│ AVX / AVX2       │ 256 bit  │ 8x float, 4x double, 8x int32,    │
│ (x86, 2011/2013) │          │ 32x int8                           │
├──────────────────┼──────────┼────────────────────────────────────┤
│ AVX-512          │ 512 bit  │ 16x float, 8x double, 16x int32,  │
│ (x86, 2016)      │          │ 64x int8                           │
├──────────────────┼──────────┼────────────────────────────────────┤
│ NEON             │ 128 bit  │ 4x float, 2x double, 4x int32,    │
│ (ARM, 2004)      │          │ 16x int8                           │
├──────────────────┼──────────┼────────────────────────────────────┤
│ SVE / SVE2       │ 128-2048 │ Variable length (hardware decides  │
│ (ARM, 2017)      │ bit      │ width at runtime)                  │
├──────────────────┼──────────┼────────────────────────────────────┤
│ RISC-V Vector    │ Variable │ Variable length (LMUL configurable)│
│ (RVV, 2021)      │          │                                     │
└──────────────────┴──────────┴────────────────────────────────────┘
```

### SIMD Operations

```
┌──────────────────────┬──────────────────────────────────────────┐
│ Operation            │ What it does                              │
├──────────────────────┼──────────────────────────────────────────┤
│ Arithmetic           │ Add, subtract, multiply, divide, FMA     │
│                      │ (fused multiply-add) on packed elements   │
├──────────────────────┼──────────────────────────────────────────┤
│ Comparison           │ Compare packed elements, produce mask     │
│                      │ (which elements satisfy the condition)    │
├──────────────────────┼──────────────────────────────────────────┤
│ Shuffle / Permute    │ Rearrange elements within or across       │
│                      │ registers (transpose, interleave)         │
├──────────────────────┼──────────────────────────────────────────┤
│ Load / Store         │ Move data between memory and registers.  │
│                      │ Aligned (faster) vs unaligned loads.      │
├──────────────────────┼──────────────────────────────────────────┤
│ Mask / Blend         │ Conditionally select elements from two    │
│                      │ registers based on a mask.                │
├──────────────────────┼──────────────────────────────────────────┤
│ Horizontal           │ Reduce across lanes: horizontal add,      │
│                      │ horizontal min/max.                       │
├──────────────────────┼──────────────────────────────────────────┤
│ Gather / Scatter     │ Load/store from/to non-contiguous memory  │
│                      │ locations (indexed access).               │
├──────────────────────┼──────────────────────────────────────────┤
│ Conversion           │ Convert between types (float→int, int8→   │
│                      │ int32, float→double) in packed form.      │
└──────────────────────┴──────────────────────────────────────────┘
```

## Ways to Use SIMD

### 1. Auto-Vectorization (Compiler)

```
The compiler detects loops that can be SIMD-ified and generates
vector instructions automatically.

C:
  void add_arrays(float* a, float* b, float* c, int n) {
      for (int i = 0; i < n; i++) {
          c[i] = a[i] + b[i];
      }
  }

Compile with: gcc -O3 -march=native

The compiler transforms this into SIMD instructions automatically.

Check if vectorized:
  gcc -O3 -march=native -fopt-info-vec-optimized  → shows which loops vectorized
  gcc -O3 -march=native -fopt-info-vec-missed     → shows which loops did NOT vectorize

What prevents auto-vectorization:
  - Data dependencies between iterations
  - Pointer aliasing (use restrict keyword)
  - Complex control flow (branches inside loops)
  - Function calls inside loops (unless inlined)
  - Non-contiguous memory access patterns
```

### 2. Intrinsics (Manual)

```
C intrinsics map directly to SIMD instructions.

#include <immintrin.h>  // AVX2

void add_arrays_avx2(float* a, float* b, float* c, int n) {
    for (int i = 0; i < n; i += 8) {
        __m256 va = _mm256_loadu_ps(&a[i]);   // load 8 floats from a
        __m256 vb = _mm256_loadu_ps(&b[i]);   // load 8 floats from b
        __m256 vc = _mm256_add_ps(va, vb);    // add 8 pairs
        _mm256_storeu_ps(&c[i], vc);          // store 8 results
    }
}

Naming convention:
  _mm256_add_ps
   │    │    │  └── ps = packed single-precision float
   │    │    └───── add = operation
   │    └────────── 256 = register width (AVX2)
   └─────────────── _mm = x86 SIMD prefix

Common suffixes:
  ps = packed single (float)
  pd = packed double
  epi32 = packed 32-bit integer
  epi8 = packed 8-bit integer
  si256 = 256-bit integer
```

### 3. Rust SIMD

```
std::simd (nightly):
  use std::simd::f32x8;

  fn add_arrays(a: &[f32], b: &[f32], c: &mut [f32]) {
      for i in (0..a.len()).step_by(8) {
          let va = f32x8::from_slice(&a[i..]);
          let vb = f32x8::from_slice(&b[i..]);
          let vc = va + vb;
          vc.copy_to_slice(&mut c[i..]);
      }
  }

Target-specific intrinsics (stable):
  #[cfg(target_arch = "x86_64")]
  use std::arch::x86_64::*;

  unsafe fn add_avx2(a: *const f32, b: *const f32, c: *mut f32) {
      let va = _mm256_loadu_ps(a);
      let vb = _mm256_loadu_ps(b);
      let vc = _mm256_add_ps(va, vb);
      _mm256_storeu_ps(c, vc);
  }
```

### 4. Java Vector API (JEP 338 / JEP 489)

```
import jdk.incubator.vector.*;

static final VectorSpecies<Float> SPECIES = FloatVector.SPECIES_256;

void addArrays(float[] a, float[] b, float[] c) {
    int i = 0;
    for (; i < SPECIES.loopBound(a.length); i += SPECIES.length()) {
        FloatVector va = FloatVector.fromArray(SPECIES, a, i);
        FloatVector vb = FloatVector.fromArray(SPECIES, b, i);
        va.add(vb).intoArray(c, i);
    }
    for (; i < a.length; i++) {
        c[i] = a[i] + b[i];
    }
}
```

## Data Layout for SIMD

```
Array of Structs (AoS) — bad for SIMD:

  struct Particle { float x, y, z, mass; }
  Particle particles[1000];

  Memory layout: [x0,y0,z0,m0, x1,y1,z1,m1, x2,y2,z2,m2, ...]

  To load all x values → need gather (slow) or shuffle (complex)


Struct of Arrays (SoA) — good for SIMD:

  struct Particles {
      float x[1000];
      float y[1000];
      float z[1000];
      float mass[1000];
  }

  Memory layout:
    x: [x0, x1, x2, x3, x4, x5, x6, x7, ...]  ← contiguous
    y: [y0, y1, y2, y3, y4, y5, y6, y7, ...]  ← contiguous

  To load 8 x values → single aligned load (fast)

  SIMD processes 8 particles at once:
    load x[0..7], y[0..7], z[0..7]
    compute distances for all 8 simultaneously
```

## Practical SIMD Applications

```
┌──────────────────────┬──────────────────────────────────────────┐
│ Application          │ SIMD usage                                │
├──────────────────────┼──────────────────────────────────────────┤
│ String search        │ Compare 16/32/64 characters at once      │
│ (memchr, strstr)     │ (used by ripgrep, simdjson)              │
├──────────────────────┼──────────────────────────────────────────┤
│ JSON parsing         │ simdjson: 2-4 GB/s JSON parsing using    │
│                      │ SIMD to find structural characters       │
├──────────────────────┼──────────────────────────────────────────┤
│ Image processing     │ Apply filters, color conversion, resize  │
│                      │ on 4-16 pixels simultaneously            │
├──────────────────────┼──────────────────────────────────────────┤
│ Audio/Video codecs   │ H.264/H.265 decoding, audio DSP,        │
│                      │ FFT computation                          │
├──────────────────────┼──────────────────────────────────────────┤
│ Compression          │ zstd, lz4, snappy use SIMD for matching  │
│                      │ and encoding                             │
├──────────────────────┼──────────────────────────────────────────┤
│ Cryptography         │ AES-NI (hardware AES), SHA extensions,   │
│                      │ ChaCha20 vectorized                      │
├──────────────────────┼──────────────────────────────────────────┤
│ Database engines     │ Vectorized query execution (ClickHouse,  │
│                      │ DuckDB, Velox). Scan/filter/aggregate.   │
├──────────────────────┼──────────────────────────────────────────┤
│ ML inference         │ Matrix multiply, dot products, activation│
│                      │ functions on batched data                │
├──────────────────────┼──────────────────────────────────────────┤
│ Physics simulation   │ Particle systems, collision detection,    │
│                      │ force computation on multiple bodies     │
├──────────────────────┼──────────────────────────────────────────┤
│ Base64 encoding      │ Process 12→16 bytes at once using        │
│                      │ shuffle and lookup instructions          │
└──────────────────────┴──────────────────────────────────────────┘
```

## Pros

- **Throughput**: 4-16x speedup for data-parallel operations on a single core
- **Energy Efficient**: more work per clock cycle means less energy per operation
- **Available Everywhere**: all modern CPUs (x86, ARM, RISC-V) have SIMD units
- **Auto-Vectorization**: compilers can generate SIMD code from scalar loops automatically
- **Complements Threading**: SIMD is within-core parallelism, threads are across-core — both combine
- **Deterministic**: unlike threads, SIMD has no race conditions or synchronization issues
- **Hardware Accelerated**: dedicated silicon for SIMD operations (not emulated)
- **Free with -O3**: compiler auto-vectorization extracts SIMD performance with no code changes

## Cons

- **Data Layout Sensitivity**: requires contiguous, aligned data (SoA over AoS)
- **Branch-Unfriendly**: SIMD operates on all lanes — conditional logic requires masking (branchless)
- **Portability**: intrinsics are architecture-specific (SSE vs NEON vs SVE)
- **Diminishing Returns**: irregular data, small arrays, and memory-bound code see little benefit
- **Complexity**: manual intrinsics are hard to write, read, and debug
- **Register Pressure**: limited number of SIMD registers — spilling to memory kills performance
- **Remainder Handling**: when N is not a multiple of vector width, need scalar fallback
- **Frequency Throttling**: AVX-512 on some Intel CPUs causes clock speed reduction

## Use Cases

- **Scientific Computing**: linear algebra, FFT, matrix operations, simulation
- **Data Processing**: columnar databases, analytics engines, data transformation pipelines
- **Media**: image filters, video encoding/decoding, audio processing, game physics
- **Networking**: packet parsing, checksum computation, pattern matching in firewalls
- **Compression/Decompression**: zstd, lz4, zlib use SIMD for throughput
- **Cryptography**: AES, SHA, ChaCha20 with hardware-accelerated SIMD instructions
- **String Processing**: fast search, comparison, validation (UTF-8, JSON, CSV parsing)
- **Machine Learning**: inference on CPU (ONNX Runtime, PyTorch CPU backend)
