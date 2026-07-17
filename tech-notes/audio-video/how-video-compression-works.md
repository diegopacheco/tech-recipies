# How Video Compression Works: Frames, Motion, DCT, GOP

## Why video must be compressed

Raw video is astronomically large. 1080p at 30 fps in 8-bit 4:2:0 needs about **1.5 Gbps**; a two-hour movie would be **~1.4 TB** uncompressed. Modern codecs shrink this by **100x-1000x** while keeping the picture visually close to the source. They do it by removing three kinds of redundancy:

- **Spatial redundancy**: neighboring pixels within a frame are similar.
- **Temporal redundancy**: consecutive frames are mostly the same.
- **Perceptual redundancy**: the eye doesn't notice certain detail, especially in color and high frequencies.

Almost every codec (H.264, HEVC, AV1, VP9, VVC) is a **block-based hybrid codec** using the same pipeline described here.

## Chroma subsampling (throw away color detail first)

The human eye is far more sensitive to **brightness (luma)** than **color (chroma)**. So video is stored in **Y′CbCr** — luma plus two chroma channels — and the chroma is downsampled:

- **4:4:4** — no subsampling, full color (mastering, screen capture).
- **4:2:2** — chroma at half horizontal resolution (broadcast, editing).
- **4:2:0** — chroma at half horizontal **and** vertical resolution (streaming, Blu-ray, almost all delivery).

Moving to 4:2:0 alone **halves** the data before any real compression starts, at almost no perceived quality loss.

```
4:4:4  every pixel has color     Y Y Y Y   Cb/Cr per pixel
4:2:2  color every 2nd column    Y Y Y Y   Cb/Cr per 2 px (horizontal)
4:2:0  color per 2x2 block       Y Y Y Y   Cb/Cr per 4 px (2x2)
```

## Frame types: I, P, and B

The core temporal trick is to not store every frame in full. Frames come in three types:

- **I-frame (Intra)**: a complete, standalone image compressed like a JPEG. Decodable on its own. Largest in bytes. Also called a **keyframe**.
- **P-frame (Predicted)**: stores only the **difference** from a previous frame using motion. Much smaller.
- **B-frame (Bi-directional)**: predicted from **both past and future** frames, giving the best compression. Smallest.

```
Display order:  I  B  B  P  B  B  P
                └──────────────────► time
I  = full picture
P  = "what changed since the last I/P"
B  = "interpolate between the frames on both sides"
```

Because B-frames reference **future** frames, the encoder reorders frames into **decode order** (different from display order) and the decoder buffers and reorders them back.

## Motion estimation and compensation

This is where temporal redundancy is exploited. Instead of re-encoding a block that simply moved, the encoder finds where it came from:

1. **Motion estimation**: for each block in the current frame, search a **reference frame** for the closest matching block.
2. **Motion vector**: record the offset (dx, dy) pointing to that match — a few bytes instead of a full block.
3. **Motion compensation**: the decoder copies the referenced block, shifted by the motion vector, as its prediction.
4. **Residual**: the encoder stores only the small **difference** between the prediction and the true block.

```
Reference frame          Current frame
  ┌───────┐                ┌───────┐
  │  car  │  ── MV(+8,0) ─►│   car │   (moved right 8 px)
  └───────┘                └───────┘
Encode: motion vector (+8,0) + tiny residual, not the whole car.
```

Newer codecs allow **sub-pixel motion** (quarter/eighth-pel), **variable block sizes**, and **multiple reference frames**, all of which improve the match and shrink the residual.

## Transform and quantization (the lossy step)

The prediction residual still has spatial redundancy. That's removed with a frequency transform, then made lossy by quantization:

1. **DCT (Discrete Cosine Transform)**: converts an NxN block of residual pixels into frequency coefficients. Most energy concentrates in the **low-frequency** coefficients (top-left); high frequencies (fine detail) are usually small. HEVC/AV1/VVC use DCT plus **DST** and multiple transform sizes.
2. **Quantization**: divides coefficients by a **quantization step (QP)** and rounds. Small high-frequency coefficients become **zero**. This is the **only lossy step** and the main quality/bitrate knob — higher QP = smaller file, more artifacts.
3. **Zig-zag scan + run-length**: orders coefficients low→high frequency so the trailing zeros cluster and compress well.

```
Residual block ──DCT──► [ big  small small ... ]
                        [ small  0    0    ... ]   low freq → top-left
                        [  0     0    0    ... ]   high freq → mostly 0
                └──Quantize (÷QP, round)──► many zeros ──► tiny payload
```

## Entropy coding (lossless packing)

The quantized coefficients, motion vectors, and modes are packed with a **lossless** entropy coder — **CABAC** (context-adaptive binary arithmetic coding) in H.264/HEVC/VVC, or arithmetic coding in VP9/AV1. This assigns shorter bit patterns to more probable symbols, squeezing out the last redundancy with **no** quality loss.

## GOP structure (Group of Pictures)

A **GOP** is the repeating pattern of frame types between keyframes, for instance `I B B P B B P B B P...`. It defines the trade-offs:

- **GOP length**: distance between I-frames. **Long GOP** = better compression (fewer expensive I-frames) but slower seeking and more error propagation. **Short GOP** = easier seeking/streaming, larger files.
- **Closed GOP**: frames never reference across the GOP boundary — clean cut points, needed for **ad insertion** and **ABR segment boundaries**.
- **Open GOP**: allows references across boundaries for slightly better compression, but harder to splice.
- Streaming (HLS/DASH) typically forces a **keyframe at each segment boundary** so any segment starts independently and quality can switch cleanly.

```
GOP (length 9, closed):
  I  B  B  P  B  B  P  B  B  │  I  B  B  P ...
  └──── one GOP ────────────┘  └── next GOP
  cut / seek / ABR switch only clean at the I boundaries
```

## Putting the pipeline together

```
Raw frame
  │
  ├─► Y'CbCr + 4:2:0 chroma subsampling
  │
  ├─► Split into blocks (CTU/superblock)
  │
  ├─► Predict: Intra (I) or Inter/motion-comp (P,B)  ──► residual
  │
  ├─► DCT/DST transform ──► Quantize (QP)   ◄── the lossy step
  │
  ├─► Zig-zag scan + entropy code (CABAC / arithmetic)
  │
  └─► In-loop filters (deblock, SAO/ALF/CDEF) ──► reference frame buffer
                                                    │
                            (feeds motion estimation for future frames)
```

## The key trade-offs

- **Bitrate vs quality**: controlled mainly by QP; higher QP → smaller, blockier.
- **Compression vs latency**: B-frames and long GOPs compress better but add buffering delay, bad for real-time (see [[latency-in-streaming]]).
- **Compression vs compute**: bigger search ranges, more reference frames, and more block modes shrink files but cost far more encode time (see [[video-codecs]]).
- **Compression vs error resilience**: long GOPs propagate errors; frequent I-frames recover faster but cost bits.

## Use Cases

- **Streaming/VOD**: long-ish closed GOPs, B-frames, aggressive quantization for bandwidth.
- **Live/low-latency**: short GOPs, few/no B-frames to cut delay.
- **Editing/mastering**: all-intra (I-frame-only) or 4:2:2/4:4:4 for clean cuts and grading.
- **Video conferencing**: no B-frames, frequent references, error-resilient prediction.

## Resources

- H.264/AVC overview (Richardson): https://www.vcodex.com/h264avc-intra-precision-over-prediction/
- HEVC overview (IEEE, Sullivan et al.): https://ieeexplore.ieee.org/document/6316136
- Digital Video Introduction (leandromoreira): https://github.com/leandromoreira/digital_video_introduction
- Chroma subsampling explained: https://en.wikipedia.org/wiki/Chroma_subsampling
- DCT and JPEG basics: https://en.wikipedia.org/wiki/JPEG#Discrete_cosine_transform
- CABAC (context-adaptive binary arithmetic coding): https://en.wikipedia.org/wiki/Context-adaptive_binary_arithmetic_coding
- FFmpeg encoding guide (x264/x265): https://trac.ffmpeg.org/wiki/Encode/H.264
- Motion estimation overview: https://en.wikipedia.org/wiki/Motion_estimation
