# DoH (DNS over HTTPS)

## What is it?

DNS over HTTPS (DoH) is a protocol for performing DNS resolution over an encrypted HTTPS connection. Traditional DNS sends queries and responses in plaintext over UDP/TCP port 53, meaning anyone on the network path — ISPs, Wi-Fi operators, governments, on-path attackers — can see, log, and tamper with the domain names you look up. DoH wraps DNS queries inside standard HTTPS requests to a DoH-capable resolver, so the lookups are encrypted, authenticated, and indistinguishable from ordinary web traffic. This provides confidentiality and integrity for the DNS lookups that precede almost every internet connection.

## Who created it? When?

DoH was standardized by the **IETF** in **RFC 8484 (October 2018)**, authored by **Paul Hoffman (ICANN)** and **Patrick McManus (Mozilla)**. It grew out of concerns about pervasive surveillance highlighted after the **2013 Snowden disclosures** and the broader IETF push to encrypt internet traffic (RFC 7258, "Pervasive Monitoring Is an Attack"). **Mozilla** and **Cloudflare** partnered in **2018** to launch the first large-scale DoH deployment via Firefox and the `1.1.1.1` resolver. **Google** added DoH to its Public DNS around the same time. DoH is a sibling to **DoT (DNS over TLS, RFC 7858, 2016)** and the newer **DoQ (DNS over QUIC, RFC 9250, 2022)**.

## How it works?

### Plaintext DNS vs DoH

```
Classic DNS (port 53, plaintext):
┌────────┐   query "bank.com" (cleartext)  ┌──────────┐
│ Client │────────────────────────────────►│ Resolver │
│        │◄────────────────────────────────│          │
└────────┘   answer 1.2.3.4 (cleartext)    └──────────┘
   ▲  anyone on path can read + modify this
   │
┌──┴────────────────────┐
│ ISP / Wi-Fi / attacker│ sees every domain you visit
└───────────────────────┘

DNS over HTTPS (port 443, encrypted):
┌────────┐  HTTPS POST/GET (TLS encrypted)  ┌────────────┐
│ Client │─────────────────────────────────►│DoH Resolver│
│        │◄─────────────────────────────────│ /dns-query │
└────────┘   encrypted DNS answer           └────────────┘
   ▲  on-path observers only see "TLS to resolver:443"
   │  the domain names inside are hidden
┌──┴────────────────────┐
│ ISP / Wi-Fi / attacker│ blind to the actual queries
└───────────────────────┘
```

### The Request

DoH runs over HTTP/2 (or HTTP/3) to a resolver endpoint, conventionally at the path `/dns-query`. The DNS message is a normal wire-format DNS packet carried in the HTTP body or query string. The content type is `application/dns-message`.

```
GET method (query encoded in URL, base64url):
  GET /dns-query?dns=AAABAAABAAAAAAAAA3d3dwdleGFtcGxlA2NvbQAAAQAB HTTP/2
  Host: cloudflare-dns.com
  Accept: application/dns-message

POST method (query in request body):
  POST /dns-query HTTP/2
  Host: cloudflare-dns.com
  Content-Type: application/dns-message
  Content-Length: 33

  <binary DNS wire-format query>

Response:
  HTTP/2 200
  Content-Type: application/dns-message
  Cache-Control: max-age=128

  <binary DNS wire-format answer>
```

### Resolution Flow

1. Client (browser or OS) is configured with a DoH resolver URL (e.g. `https://cloudflare-dns.com/dns-query`)
2. Client establishes a TLS connection to the resolver on port 443, validating the resolver's certificate
3. Client encodes the DNS query in wire format and sends it as an HTTP GET or POST
4. Resolver performs recursive resolution (talking to root, TLD, and authoritative servers on the client's behalf)
5. Resolver returns the DNS answer as an HTTP response with `application/dns-message`
6. Client caches the answer honoring the DNS TTL and HTTP cache headers
7. All of this is inside one encrypted HTTPS session, blended with normal web traffic

### Where DoH Runs

```
┌──────────────────────────────────────────────────────┐
│                  Application-level DoH               │
│  Browser (Firefox, Chrome, Edge) resolves its own    │
│  DNS via DoH, bypassing the OS resolver entirely     │
│  + easy to deploy, per-app control                   │
│  - OS and other apps still use plaintext DNS         │
└──────────────────────────────────────────────────────┘
┌───────────────────────────────────────────────────────┐
│                  System-level DoH                     │
│  OS stub resolver uses DoH for ALL apps               │
│  (Windows 11, Android 9+ Private DNS, systemd-resolved│
│   Apple Encrypted DNS profiles)                       │
│  + protects the whole device uniformly                │
└───────────────────────────────────────────────────────┘
┌───────────────────────────────────────────────────────┐
│                  Network-level DoH                    │
│  Local resolver / router (Pi-hole, AdGuard Home,      │
│  Unbound) forwards upstream over DoH                  │
│  + central filtering + one encrypted egress point     │
└───────────────────────────────────────────────────────┘
```

## DoH vs DoT vs DoQ vs Plaintext

```
┌───────────────┬──────────┬──────────────┬─────────────────────────┐
│ Protocol      │ Port     │ Transport    │ Key Trait               │
├───────────────┼──────────┼──────────────┼─────────────────────────┤
│ Classic DNS   │ 53       │ UDP/TCP      │ Plaintext, no privacy   │
├───────────────┼──────────┼──────────────┼─────────────────────────┤
│ DoT (RFC 7858)│ 853      │ TLS/TCP      │ Encrypted, distinct port│
│               │          │              │ easy for admins to spot │
├───────────────┼──────────┼──────────────┼─────────────────────────┤
│ DoH (RFC 8484)│ 443      │ HTTPS        │ Encrypted, hidden in    │
│               │          │ (H2/H3)      │ web traffic, hard block │
├───────────────┼──────────┼──────────────┼─────────────────────────┤
│ DoQ (RFC 9250)│ 853      │ QUIC/UDP     │ Encrypted, low latency, │
│               │          │              │ no head-of-line blocking│
└───────────────┴──────────┴──────────────┴─────────────────────────┘
```

The defining difference: **DoT uses a dedicated port (853)** that network operators can identify and block wholesale, while **DoH shares port 443 with all HTTPS traffic**, making it far harder to detect or block without breaking the web. This is DoH's biggest strength (censorship resistance) and its biggest source of controversy (loss of network visibility).

## Popular Public DoH Resolvers

```
┌─────────────────┬───────────────────────────────────────────┬──────────────┐
│ Provider        │ DoH Endpoint                              │ Notable      │
├─────────────────┼───────────────────────────────────────────┼──────────────┤
│ Cloudflare      │ https://cloudflare-dns.com/dns-query      │ privacy,     │
│                 │ https://1.1.1.1/dns-query                 │ fast         │
├─────────────────┼───────────────────────────────────────────┼──────────────┤
│ Google          │ https://dns.google/dns-query              │ global scale │
├─────────────────┼───────────────────────────────────────────┼──────────────┤
│ Quad9           │ https://dns.quad9.net/dns-query           │ malware      │
│                 │                                           │ blocking     │
├─────────────────┼───────────────────────────────────────────┼──────────────┤
│ AdGuard         │ https://dns.adguard-dns.com/dns-query     │ ad blocking  │
├─────────────────┼───────────────────────────────────────────┼──────────────┤
│ NextDNS         │ https://dns.nextdns.io/<config-id>        │ customizable │
├─────────────────┼───────────────────────────────────────────┼──────────────┤
│ Mullvad         │ https://dns.mullvad.net/dns-query         │ no-log VPN   │
└─────────────────┴───────────────────────────────────────────┴──────────────┘
```

## The DoH Controversy

DoH is unusual among security protocols because it is genuinely divisive. It moves DNS trust from your network operator to your DoH provider, and centralizes it.

- **Privacy advocates** love it: it stops ISPs from logging and selling browsing history and defeats DNS-based censorship.
- **Enterprise and network admins** dislike it: DNS is a critical security control point. Malware C2, data exfiltration, and phishing are often caught by inspecting DNS. DoH inside browsers can bypass corporate DNS filtering, split-horizon DNS, and Pi-hole style blocklists.
- **Centralization concern**: routing most of the world's DNS through a handful of large providers (Cloudflare, Google) creates new choke points and single points of surveillance/failure.
- The compromise in practice is **"canary domains"** (e.g. `use-application-dns.net`) and enterprise policy controls that let networks signal browsers to disable auto-DoH, plus running your **own** DoH resolver so you keep both encryption and control.

## Pros

- **Confidentiality**: encrypts DNS queries so ISPs, Wi-Fi operators, and on-path snoopers cannot see which domains you visit
- **Integrity**: TLS prevents on-path tampering, DNS spoofing, and cache poisoning of the client-to-resolver hop
- **Censorship Resistance**: shares port 443 with normal web traffic, making it very hard to block without breaking HTTPS
- **Authentication of Resolver**: the resolver's TLS certificate proves you are talking to the intended resolver, not an impostor
- **Uses Existing Infrastructure**: rides on HTTP/2 and HTTP/3, reusing connection reuse, multiplexing, and caching
- **Blends with Web Traffic**: harder to fingerprint or selectively throttle than DoT's dedicated port
- **Ubiquitous Client Support**: built into all major browsers and modern operating systems
- **Defeats ISP DNS Hijacking**: stops ISPs from redirecting NXDOMAIN responses to ad pages

## Cons

- **Bypasses Network Security Controls**: application-level DoH can evade corporate DNS filtering, monitoring, and malware detection
- **Trust Centralization**: shifts DNS visibility from your ISP to a few large DoH providers who can still log queries
- **Complicates Split-Horizon DNS**: internal/private domains may fail to resolve when a browser uses external DoH
- **Harder Troubleshooting**: DNS is buried inside encrypted HTTPS, invisible to standard tools like `tcpdump`/Wireshark
- **Performance Overhead**: TLS and HTTP framing add latency versus a bare UDP query, especially on connection setup
- **Malware Abuse**: attackers use DoH for stealthy command-and-control and exfiltration that evades DNS-based detection
- **Bootstrapping Problem**: the client must resolve the DoH resolver's own hostname first, often via plaintext DNS
- **Does Not Hide Destination IP**: after resolution, the connection's destination IP (and often SNI) can still reveal the site
- **Filtering Bypass**: parental controls and content filters that rely on DNS can be circumvented

## Use Cases

- **Consumer Privacy**: individuals protecting browsing history from ISPs and public Wi-Fi operators
- **Censorship Circumvention**: users in restrictive networks accessing DNS resolution that would otherwise be blocked or poisoned
- **Browser-Level Encryption**: Firefox, Chrome, and Edge encrypting DNS without OS changes
- **Mobile Privacy**: Android Private DNS and iOS/macOS Encrypted DNS profiles protecting device lookups on cellular and Wi-Fi
- **Enterprise Egress Control**: organizations running their own DoH resolver to combine encryption with internal filtering and logging
- **Malware Blocking**: security-focused resolvers (Quad9, AdGuard) blocking known-malicious domains over encrypted DoH
- **Anti-Hijacking**: preventing ISPs from injecting ads or redirecting failed lookups
- **VPN and Privacy Services**: providers offering no-log DoH endpoints alongside their tunnels
- **IoT and Edge**: securing device DNS where plaintext lookups would leak telemetry destinations

## Links

- RFC 8484 — DNS Queries over HTTPS (DoH): https://datatracker.ietf.org/doc/html/rfc8484
- RFC 7858 — DNS over TLS (DoT): https://datatracker.ietf.org/doc/html/rfc7858
- RFC 9250 — DNS over Dedicated QUIC (DoQ): https://datatracker.ietf.org/doc/html/rfc9250
- RFC 7626 — DNS Privacy Considerations: https://datatracker.ietf.org/doc/html/rfc7626
- Cloudflare — What is DNS over HTTPS: https://www.cloudflare.com/learning/dns/dns-over-tls/
- Mozilla — Firefox DoH / Trusted Recursive Resolver: https://support.mozilla.org/en-US/kb/dns-over-https
- Google Public DNS over HTTPS: https://developers.google.com/speed/public-dns/docs/doh
- Quad9 DoH: https://quad9.net/service/service-addresses-and-features/
- DNS Privacy Project: https://dnsprivacy.org/
- Curl DoH documentation: https://everything.curl.dev/usingcurl/doh
