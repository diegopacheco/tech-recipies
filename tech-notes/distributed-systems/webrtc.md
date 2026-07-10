# WebRTC

## What is WebRTC?

WebRTC (Web Real-Time Communication) is an open standard and set of APIs that enable direct peer-to-peer communication of audio, video, and arbitrary data between browsers and applications without requiring plugins. Unlike client-server protocols, WebRTC establishes a direct connection between peers whenever possible, using a signaling channel only to exchange the metadata needed to negotiate the connection. It relies on ICE, STUN, and TURN to traverse NATs and firewalls, and secures all media and data with mandatory DTLS/SRTP encryption.

## How is WebRTC Different from WebSockets?

| Aspect | WebRTC | WebSocket |
|--------|--------|-----------|
| Topology | Peer-to-peer | Client-server |
| Transport | UDP (SRTP) or TCP fallback | TCP |
| Media support | Native audio/video | Data only |
| Encryption | Mandatory (DTLS/SRTP) | Optional (WSS) |
| NAT traversal | ICE/STUN/TURN | Not needed |
| Signaling | External, developer-provided | Built into handshake |
| Latency | Very low (UDP) | Low (TCP) |
| Complexity | High | Moderate |

## Pros and Cons of WebRTC

### Pros
- Direct peer-to-peer reduces server bandwidth and latency
- Native support for audio and video streaming
- Mandatory end-to-end encryption for media
- UDP-based transport ideal for real-time media
- Data channels for low-latency arbitrary data
- Native browser support without plugins

### Cons
- Complex to set up (signaling, ICE, STUN/TURN)
- Requires TURN relay servers when P2P fails (adds cost)
- Peer-to-peer scaling is hard for many participants
- Signaling protocol is not specified (must build your own)
- Connection negotiation can be slow and unreliable on bad networks
- Debugging NAT traversal issues is difficult

## Libraries Using WebRTC

### Java
- webrtc-java (dev.onvoid)
- Kurento Client
- Jitsi (libjitsi)
- Ice4J

### Scala
- webrtc-java (via JVM interop)
- Akka HTTP (signaling)
- http4s (signaling)
- Play Framework (signaling)

### Rust
- webrtc (webrtc-rs)
- str0m
- medea
- gstreamer-rs (webrtcbin)

### Go
- pion/webrtc
- gortc
- livekit
- ion-sfu

### Node.js/TypeScript
- node-webrtc (wrtc)
- mediasoup
- simple-peer
- PeerJS

## Alternatives

- **WebSockets** - Bidirectional client-server messaging over TCP
- **WebTransport** - Modern low-latency transport over HTTP/3 and QUIC
- **SIP/RTP** - Traditional VoIP signaling and media transport
- **HLS/DASH** - HTTP-based adaptive streaming (higher latency)
- **RTMP** - Legacy low-latency streaming protocol
- **gRPC Streaming** - Bidirectional streaming over HTTP/2

## How WebRTC Works Under the Hood

1. Each peer creates an `RTCPeerConnection` and adds media tracks or data channels
2. The offering peer generates an SDP offer describing its media and capabilities
3. The offer is sent to the remote peer over a developer-provided signaling channel
4. The answering peer sets the remote description and generates an SDP answer
5. The answer is sent back over signaling and set as the remote description
6. Each peer gathers ICE candidates (host, STUN-reflexive, TURN-relay addresses)
7. ICE candidates are exchanged over signaling as they are discovered
8. ICE performs connectivity checks to find the best working candidate pair
9. DTLS handshake establishes keys, and SRTP secures the media streams
10. Media and data flow directly peer-to-peer, relayed through TURN only if needed

## WebRTC Code in Rust

```rust
use webrtc::api::APIBuilder;
use webrtc::peer_connection::configuration::RTCConfiguration;
use webrtc::ice_transport::ice_server::RTCIceServer;

#[tokio::main]
async fn main() {
    let api = APIBuilder::new().build();

    let config = RTCConfiguration {
        ice_servers: vec![RTCIceServer {
            urls: vec!["stun:stun.l.google.com:19302".to_owned()],
            ..Default::default()
        }],
        ..Default::default()
    };

    let peer_connection = api.new_peer_connection(config).await.unwrap();

    let data_channel = peer_connection.create_data_channel("data", None).await.unwrap();

    data_channel.on_open(Box::new(|| {
        Box::pin(async move { println!("Data channel open"); })
    }));

    let offer = peer_connection.create_offer(None).await.unwrap();
    peer_connection.set_local_description(offer).await.unwrap();

    println!("Local description set, ready to signal");
}
```

Dependencies in `Cargo.toml`:
```toml
[dependencies]
webrtc = "0.11"
tokio = { version = "1", features = ["full"] }
```
