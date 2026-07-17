# Video Codecs: H.264 vs H.265 vs AV1 vs VP9 vs VVC

## What is a video codec?

A video codec is a pair of algorithms that **encode** (compress) raw video into a compact bitstream and **decode** (decompress) it back for playback. Raw video is enormous: 1080p at 30 fps in 8-bit 4:2:0 is roughly **1.5 Gbps** uncompressed. A codec squeezes that down by 100x to 1000x while keeping the picture visually close to the original. The codec defines the **bitstream syntax and the decoder**; encoders compete on how cleverly they hit that syntax at a given quality and bitrate.

The five that matter today are **H.264/AVC**, **H.265/HEVC**, **AV1**, **VP9**, and **H.266/VVC**. They split into two lineages: the **MPEG/ITU** line (H.264 → H.265 → H.266), which is patent-licensed, and the **open/royalty-free** line from Google and the Alliance for Open Media (VP9 → AV1).

## The five codecs at a glance

- **H.264 / AVC** (2003): the universal baseline. Plays on essentially every device ever made. Least efficient of the group but unbeatable for compatibility.
- **H.265 / HEVC** (2013): ~50% better compression than H.264. Held back by a **broken, multi-pool patent licensing** situation.
- **VP9** (2013): Google's royalty-free answer to HEVC, comparable efficiency, dominant on YouTube.
- **AV1** (2018): royalty-free, ~30% better than VP9/HEVC, backed by the Alliance for Open Media (Google, Netflix, Amazon, Apple, Microsoft, Meta, and others).
- **H.266 / VVC** (2020): the newest MPEG/ITU codec, ~50% better than HEVC, aimed at 4K/8K and immersive video, but early in adoption.

## Who created them? When?

- **H.264/AVC**: Joint effort of ITU-T VCEG and ISO/IEC MPEG (the JVT), finalized **2003**.
- **H.265/HEVC**: JCT-VC (ITU-T + MPEG), finalized **2013**.
- **VP9**: **Google** (from the On2 acquisition, successor to VP8), released **2013**.
- **AV1**: **Alliance for Open Media (AOMedia)**, spec frozen **2018**. Built by merging Google's VP10, Cisco's Thor, and Mozilla/Xiph's Daala.
- **H.266/VVC**: JVET (ITU-T + MPEG), finalized **July 2020** at Fraunhofer HHI and partners.

## How they compress (shared core ideas)

All five are **block-based hybrid codecs** built on the same skeleton, each generation adding more tools and bigger, more flexible blocks:

1. **Partition the frame into blocks** (macroblocks in H.264, CTUs up to 64x64 in HEVC, 128x128 superblocks in AV1/VVC).
2. **Predict** each block from already-decoded pixels: **intra** prediction (from neighbors in the same frame) or **inter** prediction (motion-compensated from other frames).
3. **Transform** the residual (prediction error) into frequency coefficients (DCT/DST variants).
4. **Quantize** the coefficients, discarding detail the eye barely notices — this is where the lossy savings come from.
5. **Entropy code** the result (CABAC in H.264/HEVC/VVC, a custom arithmetic coder in VP9/AV1).
6. **In-loop filters** (deblocking, SAO, ALF, CDEF) clean up block artifacts before the frame becomes a reference.

Each newer codec wins by having **more prediction modes, larger and more flexibly split blocks, more reference options, and stronger filters** — at the cost of much heavier encoding.

## Efficiency (the whole point)

Bitrate needed for the same perceptual quality, taking **H.264 = 100%** as the baseline:

```
┌──────────┬──────────────┬─────────────────────────────────┐
│ Codec    │ Rel. bitrate │ Meaning                         │
├──────────┼──────────────┼─────────────────────────────────┤
│ H.264    │ 100%         │ baseline                        │
│ VP9      │ ~55-65%      │ ~40% smaller than H.264         │
│ H.265    │ ~50%         │ ~50% smaller than H.264         │
│ AV1      │ ~35-50%      │ ~30% smaller than HEVC/VP9      │
│ H.266    │ ~25-35%      │ ~50% smaller than HEVC          │
└──────────┴──────────────┴─────────────────────────────────┘
(numbers vary widely by content, encoder, preset, and metric)
```

The catch: efficiency costs **encoder compute**. A reference AV1 encode can be **hundreds to thousands of times** slower than x264 at comparable quality; VVC is heavier still. Practical deployments lean on optimized encoders (SVT-AV1, libaom, x265) and hardware.

## Licensing (often the deciding factor)

- **H.264**: Licensed via **MPEG LA / Via LA**. Well-understood terms, and browser/internet delivery is broadly royalty-free in practice, which is why it became universal.
- **H.265/HEVC**: **Three** patent pools (Via LA, HEVC Advance, MPEG LA merged) plus unpooled holders, with royalties on **content and devices**. This uncertainty is the single biggest reason HEVC never took over the web.
- **VP9**: **Royalty-free**, Google-owned patents granted openly.
- **AV1**: **Royalty-free** by design; AOMedia offers a defensive patent license. This is its core selling point over HEVC/VVC.
- **H.266/VVC**: Patent-licensed (Access Advance, MPEG LA, and others forming pools). Adoption faces the **same royalty friction that hurt HEVC**.

## Hardware support (decode)

Hardware decode is what makes a codec practical on phones and TVs; software decode drains battery and struggles at 4K.

- **H.264**: Universal hardware decode everywhere since ~2005.
- **H.265**: Widespread hardware decode on TVs, phones (iPhone 6+, most Android since ~2016), and GPUs.
- **VP9**: Hardware decode on most Android, smart TVs, and GPUs; **not** on Apple hardware historically.
- **AV1**: Newer hardware only — Intel (11th gen+), NVIDIA (RTX 30+), AMD (RX 6000+), recent flagship phones, newer smart TVs, and **Apple A17 Pro / M3 and later**.
- **H.266/VVC**: Very limited hardware decode as of the mid-2020s; mostly software and a few dedicated chips.

## Comparison

```
┌────────────┬───────────┬───────────┬───────────┬───────────┬───────────┐
│ Feature    │ H.264     │ H.265     │ VP9       │ AV1       │ H.266/VVC │
├────────────┼───────────┼───────────┼───────────┼───────────┼───────────┤
│ Year       │ 2003      │ 2013      │ 2013      │ 2018      │ 2020      │
│ Maker      │ ITU/MPEG  │ ITU/MPEG  │ Google    │ AOMedia   │ ITU/MPEG  │
│ Royalty    │ Licensed  │ Licensed  │ Free      │ Free      │ Licensed  │
│ Efficiency │ Baseline  │ +50%      │ +40%      │ +50-60%   │ +65-75%   │
│ Encode cost│ Low       │ High      │ Medium    │ Very high │ Extreme   │
│ HW decode  │ Universal │ Broad     │ Non-Apple │ Newest    │ Rare      │
│ Max block  │ 16x16     │ 64x64     │ 64x64     │ 128x128   │ 128x128   │
│ Container  │ MP4/TS    │ MP4/TS    │ WebM/MP4  │ MP4/WebM  │ MP4       │
└────────────┴───────────┴───────────┴───────────┴───────────┴───────────┘
```

## Pros and Cons

### H.264/AVC
- **Pro**: plays literally everywhere; cheap, fast encoding; mature tooling (x264).
- **Con**: least efficient — biggest files/bitrate for the same quality.

### H.265/HEVC
- **Pro**: ~50% bitrate savings; strong hardware support; great for 4K/HDR on Apple.
- **Con**: toxic multi-pool licensing; poor web/browser support.

### VP9
- **Pro**: royalty-free; efficient; native in browsers and YouTube.
- **Con**: no Apple hardware decode; slower encode than H.264; largely superseded by AV1.

### AV1
- **Pro**: best royalty-free efficiency; broad industry backing; the web's future codec.
- **Con**: very heavy to encode; hardware decode only on recent devices.

### H.266/VVC
- **Pro**: best-in-class efficiency; strong for 8K, HDR, and immersive/360 video.
- **Con**: extreme encode cost; almost no hardware decode yet; licensing uncertainty.

## Who is using them

- **H.264**: default for WebRTC, screen recording, older devices, and any "must just work" delivery.
- **H.265**: Apple ecosystem (iPhone recording, Apple TV 4K), broadcast UHD, Blu-ray UHD.
- **VP9**: **YouTube** (billions of streams), Google Meet.
- **AV1**: **Netflix**, **YouTube** (increasingly), **Meta**, Twitch experiments, video conferencing.
- **H.266/VVC**: early broadcast trials (ATSC 3.0, DVB), Fraunhofer reference deployments.

## Use Cases

- **Maximum compatibility / legacy reach** → H.264
- **4K/HDR on Apple hardware, broadcast UHD** → H.265
- **Royalty-free web delivery at scale, today** → VP9 or AV1
- **Best bitrate savings for premium streaming (bandwidth-bound)** → AV1
- **Future 8K / immersive / next-gen broadcast** → H.266/VVC
- **Real-time conferencing (low-latency, cheap encode)** → H.264 today, AV1 emerging

Large services keep a **codec ladder**: H.264 as the universal fallback, plus VP9/HEVC/AV1 for capable devices, chosen per client at playback.

## Resources

- H.264 spec (ITU-T H.264): https://www.itu.int/rec/T-REC-H.264
- H.265/HEVC spec (ITU-T H.265): https://www.itu.int/rec/T-REC-H.265
- H.266/VVC spec (ITU-T H.266): https://www.itu.int/rec/T-REC-H.266
- Alliance for Open Media (AV1): https://aomedia.org/
- AV1 bitstream spec: https://aomediacodec.github.io/av1-spec/
- VP9 bitstream spec: https://www.webmproject.org/vp9/
- SVT-AV1 encoder: https://gitlab.com/AOMediaCodec/SVT-AV1
- x264: https://www.videolan.org/developers/x264.html
- x265: https://www.videolan.org/developers/x265.html
- Netflix on AV1: https://netflixtechblog.com/bringing-av1-streaming-to-netflix-members-tvs-b7fc88e42320
- Fraunhofer VVC (VVenC/VVdeC): https://www.hhi.fraunhofer.de/en/departments/vca/technologies-and-solutions/h266-versatile-video-coding.html
- Codec comparison (Mux): https://www.mux.com/articles/video-codecs-and-formats
