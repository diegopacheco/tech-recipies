# Audio Codecs: AAC, Opus, MP3, FLAC, AC-3/E-AC-3

## What is an audio codec?

An audio codec encodes digital audio into a compact bitstream and decodes it back for playback. Raw PCM audio is bulky: CD-quality stereo (44.1 kHz, 16-bit) is **1.4 Mbps**. Codecs cut that dramatically. They split into two families:

- **Lossy** (AAC, Opus, MP3, AC-3/E-AC-3): discard sound the ear is unlikely to notice using a **psychoacoustic model**, achieving 5x-15x compression. The decoded signal is **not** bit-identical to the original.
- **Lossless** (FLAC, ALAC): reconstruct the original samples **exactly**, achieving only ~2x compression, used when fidelity or archival matters.

## The codecs at a glance

- **MP3** (1993): the format that made digital music mainstream. Aging but still universal.
- **AAC** (1997): MP3's successor, better quality per bit, the default for Apple, YouTube, and streaming/broadcast.
- **Opus** (2012): the modern open, royalty-free champion — best quality at low-to-mid bitrates, dominant in real-time (WebRTC, Discord).
- **FLAC** (2001): the open lossless standard for archival and audiophile playback.
- **AC-3 (Dolby Digital)** and **E-AC-3 (Dolby Digital Plus)**: the surround-sound codecs of broadcast, DVD/Blu-ray, and streaming.

## Who created them? When?

- **MP3**: **Fraunhofer IIS** (with the MPEG group), standardized in **MPEG-1 (1993)**. Patents expired **2017**.
- **AAC**: **MPEG** (Fraunhofer, Dolby, AT&T, Sony, Nokia), standardized **1997** (MPEG-2), extended in MPEG-4.
- **Opus**: **IETF / Xiph.Org** (merging Skype's SILK and Xiph's CELT), **RFC 6716**, **2012**.
- **FLAC**: **Josh Coalson**, 2001; stewarded by **Xiph.Org** since 2003.
- **AC-3 / E-AC-3**: **Dolby Laboratories**, AC-3 in **1991** (standardized as ATSC A/52), E-AC-3 in **2005**.

## How lossy audio compression works

1. **Time → frequency**: a filterbank/MDCT transforms short windows of samples into frequency coefficients.
2. **Psychoacoustic model**: models what the ear can and cannot hear — **absolute threshold of hearing** and **masking** (a loud tone hides quieter nearby tones in frequency and time).
3. **Bit allocation / quantization**: spends bits on audible content, coarsely quantizes or drops masked content.
4. **Entropy coding**: packs the quantized data (Huffman in MP3, arithmetic-style coding in others).
5. **Joint stereo**: exploits correlation between left/right channels (mid-side, intensity stereo).

Opus adds a **hybrid** twist: it runs a speech-optimized **linear-prediction (SILK)** path at low frequencies and a **transform (CELT)** path at high frequencies, and can switch or blend, which is why it excels at both voice and music.

## How lossless compression works (FLAC)

FLAC keeps every sample exactly. It uses **linear prediction** to estimate each sample from prior ones, then **Rice/Golomb entropy-codes the small residuals**. Because it only removes statistical redundancy (never audible detail), output decodes bit-for-bit identical to the input, at ~50-60% of the original size.

## Bitrate and quality ranges

```
┌──────────┬──────────┬────────────────────────────────────────────┐
│ Codec    │ Type     │ Typical bitrate & sweet spot               │
├──────────┼──────────┼────────────────────────────────────────────┤
│ MP3      │ Lossy    │ 128-320 kbps; "transparent" ~256-320       │
│ AAC-LC   │ Lossy    │ 96-256 kbps; transparent ~192-256          │
│ HE-AAC   │ Lossy    │ 32-96 kbps; great for low-bitrate radio    │
│ Opus     │ Lossy    │ 6-510 kbps; music transparent ~128-160     │
│ AC-3     │ Lossy    │ 384-640 kbps (5.1 surround)                │
│ E-AC-3   │ Lossy    │ 128-1024+ kbps (up to 7.1, Atmos carriage) │
│ FLAC     │ Lossless │ ~700-1100 kbps (source-dependent)          │
└──────────┴──────────┴────────────────────────────────────────────┘
```

At **any given low bitrate, Opus generally wins**; at high bitrate all modern lossy codecs sound transparent. FLAC is in a different category — it trades size for perfect fidelity.

## Licensing

- **MP3**: patents **expired** — fully free to use now.
- **AAC**: **patent-licensed** (Via LA pool) for encoders/decoders; broadly deployed but not royalty-free.
- **Opus**: **royalty-free**, open, IETF standard — a key reason it's mandatory in WebRTC.
- **FLAC**: **royalty-free**, open source (BSD), free format.
- **AC-3 / E-AC-3**: **proprietary Dolby**, licensed per device/decoder.

## Channels and surround

- **MP3 / AAC-LC / Opus / FLAC**: primarily stereo, but support multichannel (AAC and Opus up to 5.1/7.1+).
- **AC-3**: up to **5.1**; the mandatory audio for ATSC broadcast and DVD.
- **E-AC-3**: up to **7.1** and carries **Dolby Atmos** (object audio) as a substream; used by Netflix, Disney+, and broadcast.

## Comparison

```
┌──────────┬─────────┬──────────┬───────────┬──────────────┬─────────────┐
│ Codec    │ Year    │ Type     │ Royalty   │ Best at      │ Home turf   │
├──────────┼─────────┼──────────┼───────────┼──────────────┼─────────────┤
│ MP3      │ 1993    │ Lossy    │ Free      │ Compat.      │ Legacy music│
│ AAC      │ 1997    │ Lossy    │ Licensed  │ Streaming    │ Apple/YouTube│
│ Opus     │ 2012    │ Lossy    │ Free      │ Low-latency  │ WebRTC/VoIP │
│ FLAC     │ 2001    │ Lossless │ Free      │ Fidelity     │ Archival    │
│ AC-3     │ 1991    │ Lossy    │ Dolby     │ 5.1 broadcast│ TV/DVD      │
│ E-AC-3   │ 2005    │ Lossy    │ Dolby     │ 7.1/Atmos    │ OTT/Blu-ray │
└──────────┴─────────┴──────────┴───────────┴──────────────┴─────────────┘
```

## Pros and Cons

### MP3
- **Pro**: universal playback; patent-free; simple.
- **Con**: worst efficiency of the group; poor at low bitrates; no modern surround.

### AAC
- **Pro**: better than MP3 at every bitrate; broad hardware/browser support; HE-AAC excels at low bitrate.
- **Con**: patent-licensed; edged out by Opus in quality-per-bit.

### Opus
- **Pro**: best low/mid-bitrate quality; very low latency (down to ~5-20 ms); royalty-free; handles voice and music.
- **Con**: not natively supported in some legacy/broadcast pipelines and older hardware.

### FLAC
- **Pro**: perfect fidelity; open; wide software support; fast decode.
- **Con**: large files vs lossy; not for bandwidth-constrained delivery.

### AC-3 / E-AC-3
- **Pro**: the de-facto surround standard for TV/streaming; strong hardware/AVR support; Atmos via E-AC-3.
- **Con**: proprietary/licensed; less efficient than Opus/AAC for stereo.

## Who is using them

- **AAC**: Apple Music, iTunes, YouTube, most HLS audio, digital radio (DAB+).
- **Opus**: **WebRTC (mandatory)**, Discord, Google Meet, Zoom, Signal, YouTube (as WebM audio).
- **MP3**: podcasts, legacy libraries, anywhere maximum compatibility beats efficiency.
- **FLAC**: Bandcamp, Qobuz, Tidal (lossless), audiophile archiving, CD ripping.
- **AC-3/E-AC-3**: ATSC/DVB broadcast, Blu-ray/DVD, Netflix/Disney+ surround and Atmos.

## Use Cases

- **Real-time voice/video chat** → Opus
- **Music streaming (lossy)** → AAC or Opus
- **Podcasts / max compatibility** → MP3 or AAC
- **Archival, mastering, audiophile** → FLAC (or ALAC on Apple)
- **Home-theater surround / broadcast** → AC-3, E-AC-3 (Atmos)

## Resources

- Opus (RFC 6716): https://datatracker.ietf.org/doc/html/rfc6716
- Opus project: https://opus-codec.org/
- FLAC format: https://xiph.org/flac/
- AAC overview (Fraunhofer IIS): https://www.iis.fraunhofer.de/en/ff/amm/consumer-electronics/aac.html
- MP3 history (Fraunhofer): https://www.iis.fraunhofer.de/en/ff/amm/consumer-electronics/mp3.html
- Dolby Digital / AC-3 (ATSC A/52): https://www.atsc.org/atsc-documents/a522018-digital-audio-compression-ac-3-e-ac-3-standard/
- Dolby E-AC-3 & Atmos: https://professional.dolby.com/
- Opus vs AAC listening tests: https://opus-codec.org/comparison/
- ALAC (Apple Lossless): https://macosforge.github.io/alac/
