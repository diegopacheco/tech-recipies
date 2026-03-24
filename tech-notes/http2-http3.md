# HTTP/2 and HTTP/3

## What is HTTP/2?

HTTP/2 is the second major version of the HTTP protocol that addresses performance limitations of HTTP/1.1. It introduces binary framing, multiplexing, header compression, and server push over a single TCP connection. Instead of opening multiple TCP connections to load a page (HTTP/1.1 workaround), HTTP/2 sends multiple streams of data interleaved over one connection.

## What is HTTP/3?

HTTP/3 is the third major version of HTTP that replaces TCP with QUIC (a UDP-based transport protocol) to eliminate head-of-line blocking at the transport layer. While HTTP/2 solved application-level multiplexing, a single lost TCP packet still blocked all streams. HTTP/3 solves this by running each stream as an independent QUIC stream where packet loss on one stream does not block others.

## Who created them? When?

- **HTTP/2**: Based on Google's **SPDY** protocol (2009). Standardized as **RFC 7540** by the IETF in **May 2015**. Key contributors include Mike Belshe and Roberto Peon (Google) and Martin Thomson (Mozilla)
- **HTTP/3**: Based on Google's **QUIC** protocol (2012). Standardized as **RFC 9114** by the IETF in **June 2022**. Key contributors include Jana Iyengar (Google/Fastly) and Martin Thomson (Mozilla). The QUIC transport layer is defined in **RFC 9000**

## How HTTP/2 works?

1. **Binary Framing Layer**:
   - HTTP/1.1 is text-based, HTTP/2 uses binary frames
   - Messages are broken into small frames that can be interleaved
   - Frames are reassembled into complete messages at the other end
   - Two frame types: HEADERS frames and DATA frames

2. **Multiplexing**:
   - Multiple requests and responses share a single TCP connection
   - Each request/response pair is a stream identified by a stream ID
   - Frames from different streams are interleaved and delivered in parallel
   - No head-of-line blocking at the HTTP level (but still at TCP level)

3. **Header Compression (HPACK)**:
   - HTTP headers are compressed using HPACK algorithm
   - Maintains a dynamic table of previously sent headers on both sides
   - Repeated headers (cookies, user-agent) are sent as table references
   - Reduces header overhead from kilobytes to bytes

4. **Stream Prioritization**:
   - Clients can assign weight and dependency to streams
   - Server uses priorities to allocate bandwidth between streams
   - CSS and JS can be prioritized over images

5. **Server Push**:
   - Server can send resources before the client requests them
   - Server predicts the client will need a CSS file after requesting HTML
   - Pushed resources are cached by the client
   - Largely deprecated in practice due to complexity and cache issues

```
HTTP/1.1:                    HTTP/2:

Conn 1: GET /style.css       Single Connection:
Conn 2: GET /app.js           Stream 1: GET /style.css ─────►
Conn 3: GET /image.png        Stream 2: GET /app.js ────────►
Conn 4: GET /font.woff        Stream 3: GET /image.png ─────►
Conn 5: GET /data.json        Stream 4: GET /font.woff ─────►
Conn 6: GET /logo.svg         Stream 5: GET /data.json ─────►
(6 TCP connections)            Stream 6: GET /logo.svg ──────►
                              (1 TCP connection, interleaved)
```

## How HTTP/3 works?

1. **QUIC Transport**:
   - Runs over UDP instead of TCP
   - Built-in TLS 1.3 encryption (always encrypted, no unencrypted mode)
   - Connection establishment in 1 RTT (0-RTT for resumed connections)
   - TCP + TLS 1.3 requires 2-3 RTTs to establish

2. **Independent Streams**:
   - Each QUIC stream is independently flow-controlled
   - Packet loss on stream 3 does not block streams 1, 2, or 4
   - Eliminates transport-level head-of-line blocking that HTTP/2 suffers from

3. **Connection Migration**:
   - Connections are identified by a connection ID, not IP:port tuple
   - When a device switches networks (WiFi to cellular), the connection survives
   - No need to re-establish TCP handshake after network change

4. **Header Compression (QPACK)**:
   - Successor to HPACK, designed for out-of-order delivery
   - HPACK assumed in-order delivery (TCP), QPACK handles QUIC's independent streams
   - Uses two unidirectional streams for encoder and decoder state

5. **0-RTT Connection Resumption**:
   - Clients can send data immediately when reconnecting to a known server
   - Uses cached keys from previous connections
   - Tradeoff: 0-RTT data is vulnerable to replay attacks

```
TCP + TLS 1.3 (HTTP/2):        QUIC (HTTP/3):

Client         Server          Client         Server
  │─── SYN ──────►│              │─── Initial ────►│
  │◄── SYN-ACK ───│              │◄── Handshake ───│
  │─── ACK ───────►│              │─── Data ────────►│
  │─── ClientHello►│              (1 RTT, encrypted)
  │◄── ServerHello─│
  │─── Data ───────►│            0-RTT Resumption:
  (2-3 RTTs)                     │─── Data ────────►│
                                 (0 RTT, immediate)
```

## Protocol Comparison

```
┌─────────────────────┬──────────────┬──────────────┬──────────────┐
│ Feature             │ HTTP/1.1     │ HTTP/2       │ HTTP/3       │
├─────────────────────┼──────────────┼──────────────┼──────────────┤
│ Transport           │ TCP          │ TCP          │ QUIC (UDP)   │
├─────────────────────┼──────────────┼──────────────┼──────────────┤
│ Multiplexing        │ No           │ Yes          │ Yes          │
├─────────────────────┼──────────────┼──────────────┼──────────────┤
│ Head-of-line block  │ Yes (HTTP)   │ Yes (TCP)    │ No           │
├─────────────────────┼──────────────┼──────────────┼──────────────┤
│ Header compression  │ No           │ HPACK        │ QPACK        │
├─────────────────────┼──────────────┼──────────────┼──────────────┤
│ Encryption          │ Optional     │ Practically  │ Always       │
│                     │              │ required     │ (built-in)   │
├─────────────────────┼──────────────┼──────────────┼──────────────┤
│ Connection setup    │ 1-3 RTT      │ 2-3 RTT      │ 1 RTT / 0   │
├─────────────────────┼──────────────┼──────────────┼──────────────┤
│ Connection migrate  │ No           │ No           │ Yes          │
├─────────────────────┼──────────────┼──────────────┼──────────────┤
│ Server push         │ No           │ Yes          │ Deprecated   │
├─────────────────────┼──────────────┼──────────────┼──────────────┤
│ Format              │ Text         │ Binary       │ Binary       │
├─────────────────────┼──────────────┼──────────────┼──────────────┤
│ Connections needed  │ 6+ per host  │ 1 per host   │ 1 per host   │
├─────────────────────┼──────────────┼──────────────┼──────────────┤
│ RFC                 │ 9112 (2022)  │ 9113 (2022)  │ 9114 (2022)  │
└─────────────────────┴──────────────┴──────────────┴──────────────┘
```

## Pros

### HTTP/2
- **Multiplexing**: Multiple requests over one connection eliminates connection overhead
- **Header Compression**: HPACK dramatically reduces repeated header bytes
- **Backward Compatible**: Same semantics as HTTP/1.1, works with existing APIs
- **Prioritization**: Critical resources can be delivered first
- **Reduced Latency**: Fewer round trips and no head-of-line blocking at HTTP level
- **Single Connection**: Less state on servers, fewer sockets, less memory

### HTTP/3
- **No HOL Blocking**: Independent streams mean one lost packet does not stall everything
- **Faster Connections**: 1-RTT handshake, 0-RTT resumption
- **Connection Migration**: Survives network changes without reconnection
- **Always Encrypted**: TLS 1.3 built into the protocol, no downgrade attacks
- **Better on Lossy Networks**: Mobile, WiFi, and congested networks benefit significantly
- **User-Space Protocol**: QUIC runs in user space, can be updated without OS kernel changes

## Cons

### HTTP/2
- **TCP HOL Blocking**: Single TCP connection means one lost packet stalls all streams
- **Server Push Complexity**: Hard to use correctly, often wastes bandwidth, effectively deprecated
- **Priority Implementation**: Browsers and servers implement prioritization inconsistently
- **Debugging Harder**: Binary protocol is harder to inspect than text-based HTTP/1.1
- **TLS Required**: Practically mandatory (browsers only support HTTP/2 over TLS)
- **Middlebox Issues**: Some proxies and firewalls do not handle HTTP/2 well

### HTTP/3
- **UDP Blocking**: Some corporate firewalls and networks block or throttle UDP traffic
- **CPU Overhead**: QUIC in user space uses more CPU than kernel-optimized TCP
- **Ecosystem Maturity**: Libraries, proxies, and debugging tools are still catching up
- **No Kernel Optimization**: TCP has decades of kernel-level optimization that QUIC lacks
- **Fallback Needed**: Must fall back to HTTP/2 when QUIC is blocked (Alt-Svc header)
- **Amplification Risk**: UDP-based protocols need careful anti-amplification measures
- **Operational Complexity**: Running both TCP (HTTP/2 fallback) and UDP (HTTP/3) adds complexity
- **Middlebox Interference**: NAT devices and firewalls may not handle QUIC connections correctly

## Adoption

```
┌─────────────────────┬──────────────────────┬──────────────────────┐
│ Category            │ HTTP/2               │ HTTP/3               │
├─────────────────────┼──────────────────────┼──────────────────────┤
│ Browser support     │ All major browsers   │ All major browsers   │
├─────────────────────┼──────────────────────┼──────────────────────┤
│ Web servers         │ Nginx, Apache,       │ Nginx (exp), Caddy,  │
│                     │ Caddy, H2O           │ LiteSpeed, Envoy     │
├─────────────────────┼──────────────────────┼──────────────────────┤
│ CDNs                │ Cloudflare, Akamai,  │ Cloudflare, Akamai,  │
│                     │ Fastly, AWS CF       │ Fastly, Google Cloud  │
├─────────────────────┼──────────────────────┼──────────────────────┤
│ Load balancers      │ AWS ALB, HAProxy,    │ AWS ALB (partial),   │
│                     │ Envoy                │ Envoy, Caddy         │
├─────────────────────┼──────────────────────┼──────────────────────┤
│ Libraries           │ All HTTP clients     │ quiche, ngtcp2,      │
│                     │                      │ msquic, quinn (Rust) │
└─────────────────────┴──────────────────────┴──────────────────────┘
```

## Use Cases

- **Web Applications**: Faster page loads from multiplexing and header compression
- **Mobile Applications**: HTTP/3 connection migration handles network switching gracefully
- **API Gateways**: Reduced connection overhead for high-throughput API traffic
- **CDN Edge Delivery**: HTTP/3 improves performance on last-mile lossy connections
- **Real-Time Applications**: Lower latency from 0-RTT and independent streams
- **Microservices Communication**: gRPC runs natively over HTTP/2 for service-to-service calls
- **Video Streaming**: Adaptive bitrate streaming benefits from multiplexed connections
- **IoT Devices**: HTTP/3 handles intermittent connectivity better than TCP-based protocols
- **Global Applications**: Users on high-latency intercontinental links benefit from fewer round trips
- **Progressive Web Apps**: Faster resource loading and better offline-to-online transitions
