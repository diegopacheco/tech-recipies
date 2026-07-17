# Latency in Streaming: Glass-to-Glass, LL-HLS vs LL-DASH vs WebRTC

## What is glass-to-glass latency?

**Glass-to-glass** (also "end-to-end" or "motion-to-photon") latency is the total delay from the moment light hits the **camera's glass** to the moment that image appears on the **viewer's glass** (screen). It is the number that actually matters to users — not any single component, but the sum of every stage the media passes through.

It differs from **broadcast/cable latency** (~5s), and it is the wall that classic HTTP streaming ([[streaming-protocols]]) hits: HLS and DASH were built for scale and reliability, not immediacy, and land at **10-30 seconds** by default.

## Where the latency comes from

Every stage adds delay. The end-to-end number is their sum:

```
Camera → Encode → Packaging → Ingest → CDN → Player buffer → Decode → Display
  │        │          │         │       │         │            │        │
 capture  GOP/      segment   upload  cache    buffered     frame    render
 sensor   B-frames  duration          hops     segments     reorder
```

- **Capture**: sensor + camera pipeline, ~tens of ms.
- **Encoding**: B-frames and lookahead need future frames → buffering delay. Longer GOPs = more delay (see [[how-video-compression-works]]).
- **Packaging / segmentation**: the big one for HTTP streaming. A player often waits for **whole segments** to exist and buffers **several** of them.
- **Network / CDN**: upload to ingest, origin-to-edge, edge-to-player hops.
- **Player buffer**: the deliberate cushion (usually 2-3 segments) that absorbs jitter and enables ABR — the single largest and most tunable contributor.
- **Decode + render**: reorder B-frames, decode, present.

## Why classic HLS/DASH is slow

The root cause is **segment duration times buffer depth**. With 6-second segments and a 3-segment buffer, the player is inherently **~18 seconds** behind live before anything else is counted. Bigger segments and deeper buffers give smoother, more resilient playback but push latency up. This is the fundamental **latency vs stability** trade-off of HTTP streaming.

## Low-Latency HLS (LL-HLS)

Apple's LL-HLS (2019, folded into the HLS spec) cuts latency to **~2-5s** (often under 2s) without giving up CDN scalability:

- **Partial segments (parts)**: segments are subdivided into ~200-500 ms **parts** that publish as they're produced, so the player doesn't wait for a whole segment.
- **Preload hints**: the server tells the player the next part's URL so it can request it before it exists.
- **Blocking playlist reloads**: the playlist request **holds open** on the server until the new part is ready, eliminating polling delay.
- **Delta playlists**: send only the playlist changes, not the whole thing, cutting overhead on frequent reloads.

Still HTTP-based, so it keeps CDN cacheability and massive scale.

## Low-Latency DASH (LL-DASH)

DASH's low-latency mode reaches **~2-4s** using a different mechanism:

- **Chunked CMAF**: segments are encoded and delivered as small **CMAF chunks** using HTTP **chunked transfer encoding**, so bytes stream to the player as they're produced instead of after the whole segment.
- **`availabilityTimeOffset`**: signals in the MPD that a segment can be fetched before it is fully complete.
- **Resync / target latency**: the player is told a latency target and adjusts playback rate to hold it.

Because it also rides plain HTTP and CMAF, it shares an encode/packaging path with LL-HLS (one CMAF source, two manifests).

## WebRTC (sub-second)

**WebRTC** is a different architecture entirely — built for **real-time, bidirectional** media, not file-based delivery:

- **UDP-based transport (SRTP over RTP)** instead of buffered HTTP over TCP.
- **No segmentation** — frames are sent as they're encoded.
- **Tiny buffers**, adaptive jitter buffer measured in **milliseconds**.
- Achieves **< 500 ms**, often **< 200 ms** glass-to-glass.

The cost: WebRTC does **not** ride ordinary CDNs. Scaling to large audiences needs **SFUs (Selective Forwarding Units)** and specialized real-time infrastructure, which is more expensive and complex than caching static segments. It also trades some quality/resilience for immediacy.

## The latency spectrum

```
Glass-to-glass latency:

WebRTC          < 0.5s   ██
LL-DASH         2 - 4s   ██████
LL-HLS          2 - 5s   ██████
Cable/broadcast  ~5s     ██████
Classic DASH    6 - 30s  ████████████████████
Classic HLS     10 - 30s ██████████████████████████
```

## Comparison

```
┌──────────────────┬──────────────┬──────────────┬──────────────────┐
│ Aspect           │ LL-HLS       │ LL-DASH      │ WebRTC           │
├──────────────────┼──────────────┼──────────────┼──────────────────┤
│ Latency          │ 2-5s         │ 2-4s         │ < 0.5s           │
│ Transport        │ HTTP/TCP     │ HTTP/TCP     │ UDP (SRTP/RTP)   │
│ Mechanism        │ Parts +      │ Chunked CMAF │ Real-time frames │
│                  │ preload hints│ + ATO        │                  │
│ CDN scalable     │ Yes          │ Yes          │ No (needs SFU)   │
│ Audience scale   │ Millions     │ Millions     │ Hundreds-thousands│
│                  │              │              │ per SFU tier     │
│ Cost             │ Low (CDN)    │ Low (CDN)    │ High (RT infra)  │
│ Bidirectional    │ No           │ No           │ Yes              │
│ ABR quality      │ Strong       │ Strong       │ Weaker/simpler   │
│ Apple support    │ Native       │ Via MSE      │ Native (browser) │
└──────────────────┴──────────────┴──────────────┴──────────────────┘
```

## How to reduce latency (levers)

- **Shorter segments/parts** → less buffering (2s segments, 200-500 ms parts).
- **Smaller player buffer** → closer to live, but more rebuffering risk.
- **Chunked/CMAF delivery** → send bytes before the segment finishes.
- **Encoder tuning** → fewer/no B-frames, shorter GOP, low-latency preset.
- **Playback-rate control** → speed up slightly to catch up to the live edge.
- **Pick the right protocol** → don't fight HTTP streaming for sub-second; use WebRTC.

Every lever trades latency against **stability, quality, or cost**. There is no free lunch: lower latency means smaller buffers, which means less headroom for network jitter.

## Choosing by use case

- **VOD / non-interactive live** (movies, replays): classic HLS/DASH — latency doesn't matter, maximize quality and scale.
- **Live sports, news, large events** (want "near-live" at scale): **LL-HLS / LL-DASH**, ~2-5s.
- **Betting, auctions, live shopping, second-screen sync**: **LL-HLS/DASH** if a few seconds is OK, **WebRTC** if it must beat the broadcast.
- **Video conferencing, telepresence, cloud gaming, remote control**: **WebRTC** — sub-second and bidirectional is non-negotiable.
- **Interactive watch parties / live Q&A**: often **WebRTC for the interactive tier + LL-HLS for the scaled audience**.

## Who is using them

- **LL-HLS**: Apple ecosystem, Twitch (low-latency mode), live sports OTT.
- **LL-DASH**: DAZN, broadcasters, large European OTT platforms.
- **WebRTC**: Zoom, Google Meet, Discord, cloud gaming (GeForce NOW), real-time auction/betting platforms, Millicast/Phenix-style real-time CDNs.

## Resources

- Enabling Low-Latency HLS (Apple): https://developer.apple.com/documentation/http-live-streaming/enabling-low-latency-http-live-streaming-hls
- Low-Latency DASH (DASH-IF): https://dashif.org/docs/CR-Low-Latency-Live-r8.pdf
- WebRTC standard: https://webrtc.org/
- RTP (RFC 3550): https://datatracker.ietf.org/doc/html/rfc3550
- SRTP (RFC 3711): https://datatracker.ietf.org/doc/html/rfc3711
- Ultra-low-latency streaming (Mux): https://www.mux.com/articles/low-latency-live-streaming
- LL-HLS vs LL-DASH vs WebRTC (Wowza): https://www.wowza.com/blog/latency-in-live-streaming
- Chunked CMAF explained: https://ottverse.com/chunked-cmaf-low-latency-streaming/
- WebRTC vs HLS latency (Ant Media): https://antmedia.io/webrtc-vs-hls/
