# Streaming Protocols: HLS and MPEG-DASH

## What are HLS and MPEG-DASH?

HLS and MPEG-DASH are the two dominant **adaptive bitrate (ABR)** streaming protocols. Both deliver video and audio over ordinary HTTP by cutting the media into short segments, encoding each segment at several quality levels, and letting the player switch quality on the fly based on the viewer's real network conditions. They power the majority of internet video today, from Netflix and YouTube to live sports and video-on-demand catalogs.

Instead of one big file over a special streaming server, ABR turns video into many small files served by any plain HTTP web server or CDN. The intelligence lives in the **player** (client-side), which measures throughput and buffer level and requests the next segment at the bitrate it can sustain.

## What is HLS?

HLS (HTTP Live Streaming) is a protocol created by **Apple** and introduced in **2009** alongside the iPhone 3.0 / iOS ecosystem. It is the native streaming protocol on iOS, macOS, tvOS, and Safari. HLS describes a stream with **`.m3u8`** playlist files (text, derived from the M3U format) and delivers media as segments, originally MPEG-2 Transport Stream (`.ts`) and now also fragmented MP4 (`.m4s`). It was standardized as **RFC 8216** in 2017.

## What is MPEG-DASH?

MPEG-DASH (Dynamic Adaptive Streaming over HTTP) is a **vendor-neutral international standard** developed by the **MPEG** group and published as **ISO/IEC 23009-1** in **2012**. Unlike HLS, it is codec-agnostic and describes a stream with a single XML manifest called the **MPD** (Media Presentation Description). It was designed to unify the fragmented streaming landscape (Smooth Streaming, HDS, HLS) into one open standard.

## Who created them? When?

- **HLS**: Created by **Apple**, released **2009**. Standardized as an informational IETF spec, **RFC 8216** (August 2017). Low-Latency HLS (LL-HLS) announced at WWDC 2019 and folded into the main spec in 2020.
- **MPEG-DASH**: Developed by the **MPEG (Moving Picture Experts Group)** consortium under ISO/IEC. First edition **ISO/IEC 23009-1:2012**. Ongoing guidance is maintained by the **DASH Industry Forum (DASH-IF)**.

## What is adaptive bitrate streaming (the core idea)?

1. The source video is **encoded into a ladder** of renditions, for example 240p, 480p, 720p, 1080p, 4K, each at a fixed bitrate.
2. Each rendition is **cut into short segments** (commonly 2 to 10 seconds).
3. A **manifest** lists every rendition and every segment location.
4. The **player** downloads the manifest, picks a starting rendition, and then continuously measures download speed and buffer health.
5. If bandwidth drops, the player requests the next segment from a **lower** rendition; if it rises, it steps **up**. Because segment boundaries are aligned across renditions, the switch is seamless mid-playback.

```
Bandwidth over time:   high ─────► drops ─────► recovers

Encoding ladder:
  1080p  [seg1][seg2]                    [seg7][seg8]
  720p                [seg3]      [seg6]
  480p                      [seg4][seg5]

Player picks:  1080  1080  720   480   480   720   1080  1080
               (follows the network, boundaries aligned)
```

## How HLS works?

1. **Multivariant (master) playlist** (`.m3u8`):
   - Lists every available rendition with its bandwidth, resolution, codecs
   - The player reads this first and decides which media playlist to load

2. **Media playlist** (`.m3u8`):
   - One per rendition, listing the ordered segment URLs and their durations
   - For live streams the player re-fetches this playlist to discover new segments

3. **Segments**:
   - Originally **MPEG-2 TS** (`.ts`) files
   - Now also **fragmented MP4 / CMAF** (`.m4s`) which Apple requires for HEVC, AV1, and LL-HLS

4. **Encryption / DRM**:
   - AES-128 segment encryption via `#EXT-X-KEY`
   - Sample-level DRM through **Apple FairPlay** (and, via CMAF, Widevine/PlayReady)

5. **Low-Latency HLS (LL-HLS)**:
   - Breaks segments into smaller **partial segments** ("parts") published before the full segment is ready
   - Uses HTTP/2 or chunked transfer, blocking playlist reloads, and preload hints
   - Cuts latency from the classic 10-30s down to roughly 2-5s

```
Multivariant playlist (master.m3u8):
  #EXT-X-STREAM-INF:BANDWIDTH=800000,RESOLUTION=640x360   360p.m3u8
  #EXT-X-STREAM-INF:BANDWIDTH=2500000,RESOLUTION=1280x720 720p.m3u8
  #EXT-X-STREAM-INF:BANDWIDTH=6000000,RESOLUTION=1920x1080 1080p.m3u8

Media playlist (720p.m3u8):
  #EXTINF:6.0,   seg0.ts
  #EXTINF:6.0,   seg1.ts
  #EXTINF:6.0,   seg2.ts
```

## How MPEG-DASH works?

1. **MPD manifest** (`.mpd`, XML):
   - A single XML file describing the whole presentation as a time-and-quality hierarchy

2. **Hierarchy** (MPD → Period → AdaptationSet → Representation → Segment):
   - **Period**: a slot of time, for example one program, one ad break, or a whole VOD asset
   - **AdaptationSet**: one media kind for that Period, for example video, an audio language, or a subtitle track
   - **Representation**: one encoded version of that kind at a fixed bitrate/resolution/codec (a rung on the ladder)
   - **Segment**: a downloadable file or byte-range for a slice of time

3. **Segment addressing**:
   - SegmentTemplate with `$Number$` or `$Time$`, SegmentTimeline, or byte-range within a single file
   - Lets the player compute segment URLs without listing them all

4. **Codec agnostic**:
   - No codec restriction in the spec: H.264, HEVC/H.265, VP9, AV1, AAC, Opus all work

5. **Encryption / DRM**:
   - Uses **Common Encryption (CENC)**, so one encrypted set of files serves **Widevine + PlayReady** (and FairPlay via cbcs)

```
MPD (dynamic=live or static=VOD)
 └─ Period (0s → end)
     ├─ AdaptationSet (video, H.264)
     │    ├─ Representation 360p  @ 800 kbps
     │    ├─ Representation 720p  @ 2.5 Mbps
     │    └─ Representation 1080p @ 6 Mbps
     ├─ AdaptationSet (audio, en, AAC)
     └─ AdaptationSet (subtitles, en, WebVTT)
          each Representation → SegmentTemplate → seg-$Number$.m4s
```

## CMAF: the convergence layer

The big shift since 2017 is **CMAF (Common Media Application Format, ISO/IEC 23000-19)**. CMAF standardizes a fragmented-MP4 packaging that **both HLS and DASH can share**. With CMAF plus **cbcs** encryption, you encode once, package once, store one encrypted set of segments on the origin, and expose **two manifests** (an `.m3u8` and an `.mpd`) pointing at the **same media bytes**. This collapsed the old "package everything twice" workflow and is now the de-facto premium OTT stack.

- Each DASH **Representation** maps to a CMAF **track**
- Each DASH **AdaptationSet** maps to a CMAF **SwitchingSet**
- One encode → one packaging pass → one encrypted ladder → two manifests → three DRM licenses at playback

## What they do for you

- **Play everywhere over plain HTTP**: no special streaming server, works through any CDN, firewall, and cache
- **Smooth playback on real networks**: quality adapts to bandwidth, minimizing buffering
- **Scale cheaply**: static segments are trivially cacheable at CDN edges for millions of viewers
- **Device reach**: HLS is mandatory for iOS/Safari; DASH covers Android, smart TVs, and browsers via MSE
- **Content protection**: standardized DRM (FairPlay, Widevine, PlayReady) and segment encryption
- **Multi-language, multi-track**: audio languages, subtitles, and captions are first-class in both manifests

## Protocol Comparison

```
┌──────────────────────┬───────────────────────┬───────────────────────┐
│ Feature              │ HLS                   │ MPEG-DASH             │
├──────────────────────┼───────────────────────┼───────────────────────┤
│ Creator              │ Apple                 │ MPEG (ISO/IEC)        │
├──────────────────────┼───────────────────────┼───────────────────────┤
│ Standard             │ RFC 8216 (2017)       │ ISO/IEC 23009-1(2012) │
├──────────────────────┼───────────────────────┼───────────────────────┤
│ Manifest             │ .m3u8 (M3U text)      │ .mpd (XML)            │
├──────────────────────┼───────────────────────┼───────────────────────┤
│ Segment format       │ MPEG-2 TS, fMP4/CMAF  │ fMP4/CMAF, WebM       │
├──────────────────────┼───────────────────────┼───────────────────────┤
│ Codecs               │ H.264, HEVC, AV1      │ Codec-agnostic (any)  │
├──────────────────────┼───────────────────────┼───────────────────────┤
│ Transport            │ HTTP over TCP         │ HTTP over TCP         │
├──────────────────────┼───────────────────────┼───────────────────────┤
│ DRM                  │ FairPlay (+CMAF DRM)  │ Widevine, PlayReady   │
├──────────────────────┼───────────────────────┼───────────────────────┤
│ Typical latency      │ 10-30s (LL-HLS 2-5s)  │ 6-30s (LL-DASH ~3s)   │
├──────────────────────┼───────────────────────┼───────────────────────┤
│ Apple/Safari support │ Native, required      │ Not native (needs MSE)│
├──────────────────────┼───────────────────────┼───────────────────────┤
│ Segment length       │ Often 6s (was 10s)    │ Configurable, 2-10s   │
└──────────────────────┴───────────────────────┴───────────────────────┘
```

## Pros

### HLS
- **Universal device support**: the only protocol natively playable on iOS, tvOS, and Safari
- **Broad reach**: also supported on Android, Chrome (via hls.js/MSE), smart TVs, set-top boxes
- **Simple and cheap**: any web server or CDN can serve it, no special infrastructure
- **Mature ecosystem**: battle-tested players, encoders, and tooling
- **Strong DRM**: FairPlay Streaming plus AES-128 encryption
- **LL-HLS**: brings latency down to 2-5s while keeping CDN scalability

### MPEG-DASH
- **Open standard**: vendor-neutral, no single company controls it
- **Codec-agnostic**: free to use VP9, AV1, HEVC without licensing tied to the protocol
- **Flexible manifest**: templated segment addressing keeps the MPD compact even for long content
- **Common Encryption (CENC)**: one encrypted set serves both Widevine and PlayReady
- **Fine-grained control**: rich metadata, ad insertion via multiple Periods, multi-DRM signaling
- **Efficient for large ladders**: SegmentTemplate avoids listing thousands of segment URLs

## Cons

### HLS
- **Higher default latency**: classic HLS is 10-30s; LL-HLS adds implementation complexity
- **Apple-driven**: spec direction is controlled by Apple, not a neutral body
- **Playback only**: no browser-publish path (unlike WebRTC), it is a delivery protocol
- **Legacy TS overhead**: MPEG-2 TS segments carry more container overhead than fMP4
- **Storage duplication**: multiple renditions plus optional TS+fMP4 packaging inflate storage

### MPEG-DASH
- **No native Apple support**: does not play on iOS/Safari without workarounds; forces HLS anyway there
- **Complexity**: the XML MPD and its options (timelines, templates, multi-period) are harder to author
- **Fragmentation of profiles**: many optional features mean interop pitfalls between packagers/players
- **DRM gaps on Apple**: FairPlay integration is less straightforward than on the HLS side
- **Player required**: browsers need an MSE-based player (dash.js, Shaka) rather than native `<video>`

## Latency and Low-Latency variants

- **Classic HLS / DASH**: 10-30s glass-to-glass, fine for VOD and non-interactive live
- **LL-HLS**: partial segments + preload hints + blocking reloads → ~2-5s (often <2s)
- **LL-DASH**: chunked CMAF + `availabilityTimeOffset` → ~3s
- **When you need sub-second** (video chat, auctions, betting): neither fits well, use **WebRTC** instead

```
Latency spectrum (glass to glass):

WebRTC        < 0.5s   ██
LL-HLS/DASH   2 - 5s   ██████
Classic HLS   10 - 30s ██████████████████████
Cable TV      ~5s      ██████
```

## Who is using them

### HLS
- **Apple** ecosystem (Apple TV+, all iOS/Safari playback)
- **Twitch**, **YouTube** (HLS among its formats), **Disney+**, **Hulu**
- Most live sports and news delivery where Apple device reach matters
- Any platform that must reach iPhones (which effectively means almost everyone)

### MPEG-DASH
- **YouTube** (primary desktop/Android delivery), **Netflix**, **Amazon Prime Video**
- **DAZN**, and most premium OTT services on Android/smart-TV/browser
- Broadcasters wanting an open, codec-flexible standard with CENC multi-DRM

Most large services ship **both**: DASH (with Widevine/PlayReady) for Android, TVs, and browsers, and HLS (with FairPlay) for Apple devices, usually from a **single CMAF** source.

## Use Cases

- **Video on demand (VOD)**: movie/TV catalogs where a few seconds of latency is irrelevant
- **Large-scale live events**: concerts, keynotes, sports streamed to millions via CDN
- **Live sports and betting**: LL-HLS / LL-DASH for near-real-time delivery at scale
- **OTT and subscription platforms**: multi-DRM premium content across all device classes
- **User-generated video**: platforms transcoding uploads into ABR ladders
- **E-learning and webinars**: reliable playback across varied networks and devices
- **Broadcast replacement**: 24/7 linear channels delivered over the internet

## Resources

- HLS RFC 8216: https://datatracker.ietf.org/doc/html/rfc8216
- Apple HTTP Live Streaming: https://developer.apple.com/streaming/
- Enabling Low-Latency HLS (Apple): https://developer.apple.com/documentation/http-live-streaming/enabling-low-latency-http-live-streaming-hls
- MPEG-DASH standard (ISO/IEC 23009-1): https://www.iso.org/standard/83314.html
- DASH Industry Forum: https://dashif.org/
- What is MPEG-DASH? (Cloudflare): https://www.cloudflare.com/learning/video/what-is-mpeg-dash/
- HLS vs DASH (Mux): https://www.mux.com/articles/hls-vs-dash-what-s-the-difference-between-the-video-streaming-protocols
- Structure of an MPEG-DASH MPD (OTTVerse): https://ottverse.com/structure-of-an-mpeg-dash-mpd/
- HLS in Depth (Forasoft): https://www.forasoft.com/learn/video-streaming/articles-streaming/hls-deep-dive
- MPEG-DASH deep dive (Forasoft): https://www.forasoft.com/learn/video-streaming/articles-streaming/mpeg-dash-deep-dive
- CMAF multi-DRM packaging (Unified Streaming): https://docs.unified-streaming.com/documentation/package/multi-format-drm.html
- hls.js player: https://github.com/video-dev/hls.js/
- dash.js player: https://github.com/Dash-Industry-Forum/dash.js
- Shaka Player: https://github.com/shaka-project/shaka-player
