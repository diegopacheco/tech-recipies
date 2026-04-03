# Supply Chain Attack

## What is it?

A supply chain attack is an attack that targets the less-secure elements in the software or hardware supply chain rather than attacking the target directly. The attacker compromises a trusted vendor, library, build system, or update mechanism to inject malicious code that is then distributed to all downstream consumers. The attack leverages the trust relationship between the target and their suppliers — when a trusted dependency is compromised, every system that uses it becomes vulnerable.

## Notable Incidents

**SolarWinds (2020)**: attackers (attributed to Russian intelligence) inserted a backdoor into the SolarWinds Orion build system. The trojanized update (SUNBURST) was distributed to ~18,000 organizations including US government agencies (Treasury, Commerce, DHS) and Fortune 500 companies. The attackers had access for 9+ months before detection.

**Codecov (2021)**: attackers modified the Codecov Bash Uploader script to exfiltrate environment variables (including CI/CD secrets and tokens) from every CI pipeline that used it. Affected thousands of repositories over 2 months.

**Log4Shell / Log4j (2021)**: a critical RCE vulnerability (CVE-2021-44228) in Apache Log4j, a ubiquitous Java logging library. Not an intentional supply chain attack but demonstrated how a single transitive dependency vulnerability can impact millions of applications.

**event-stream (2018)**: an attacker gained maintainership of a popular npm package (2M weekly downloads), added a malicious dependency (flatmap-stream) that targeted the Copay Bitcoin wallet to steal cryptocurrency.

**NotPetya (2017)**: attackers compromised the update mechanism of M.E.Doc, a Ukrainian accounting software. The malicious update deployed the NotPetya wiper disguised as ransomware, causing $10B+ in global damages.

**3CX (2023)**: the 3CX desktop app (a VoIP/PBX client used by 600K+ organizations) was trojanized through a compromised upstream dependency. The official signed installer delivered malware.

**xz Utils (2024)**: a multi-year social engineering attack where an attacker gained co-maintainership of xz, a core Linux compression library, and inserted a backdoor targeting OpenSSH authentication. Caught by a Microsoft engineer who noticed a 500ms latency anomaly.

**Trivy GitHub Actions (March 2026)**: attacker force-pushed 76 of 77 version tags in aquasecurity/trivy-action and all 7 tags in aquasecurity/setup-trivy, redirecting trusted references to malicious commits. The malware read directly from GitHub Actions Runner memory (/proc/\<pid\>/mem), bypassing log-masking, and harvested SSH keys, cloud credentials (AWS, GCP, Azure), Kubernetes tokens, Docker registry credentials, database passwords, TLS private keys, and cryptocurrency wallet files. Stolen data was encrypted with AES-256-CBC and wrapped with RSA-4096 and exfiltrated to a typosquatted domain (scan.aquasecurtiy[.]org). Every CI/CD pipeline that referenced trivy-action by tag became a credential harvester. Attributed to TeamPCP (also tracked as DeadCatx3, PCPcat, ShellForce), a cloud-native threat actor. The downstream impact cascaded into the litellm breach (March 24, 2026) where the Python dependency with 97M+ monthly downloads was compromised because its maintainers used Trivy in their CI/CD pipeline. Safe versions: trivy v0.69.3, trivy-action v0.35.0, setup-trivy v0.2.6.

**Axios npm Compromise (March 2026)**: attacker gained access to the lead maintainer's PC through a targeted social engineering campaign and RAT malware, which provided npm publishing credentials despite 2FA being enabled. Two poisoned versions were published — axios@1.14.1 (tagged latest) and axios@0.30.4 (tagged legacy) — both injecting a hidden dependency called plain-crypto-js@4.2.1. The postinstall hook in plain-crypto-js executed setup.js which used string reversal, Base64 decoding, and XOR encryption to conceal its operations, then downloaded and executed platform-specific RATs: a PowerShell variant for Windows (persistence via Registry Run keys), a C++ binary for macOS (stored in /Library/Caches/com.apple.act.mond), and a Python script for Linux (stored in /tmp/ld.py). All three shared an identical C2 protocol with 60-second beacon interval, a spoofed IE8/Windows XP User-Agent string, and communicated via HTTP POST with Base64-encoded JSON to sfrclak[.]com (142.11.206[.]73). RAT capabilities included script execution, binary payload injection, directory enumeration, and self-termination. The dropper performed anti-forensic cleanup by deleting itself and replacing the malicious package.json with a clean version, leaving only lockfiles and npm audit logs as evidence. The malicious versions were live for ~3 hours before npm removed them. Attributed to Sapphire Sleet (Microsoft) / UNC1069 (Google), both North Korean state-linked threat actors, based on infrastructure overlaps and the macOS variant's overlap with the WAVESHAPER backdoor. Axios has 70M+ weekly downloads. Safe versions: axios@1.14.0 and axios@0.30.3.

## Attack Vectors

### 1. Compromised Dependencies

Injecting malicious code into open source packages or libraries that targets consume.

```
Attacker                          Victims
   │                                │
   │  compromises popular           │
   │  package (npm, PyPI, etc.)     │
   │                                │
   ▼                                │
┌──────────┐    install/update    ┌─▼───────────┐
│ Malicious │───────────────────►│ App A        │
│ Package   │                    │ App B        │
│ v2.1.0    │                    │ App C        │
│           │                    │ ... 10K apps │
└──────────┘                    └──────────────┘
```

- **Typosquatting**: publishing packages with similar names (e.g., `lodash` → `lodahs`)
- **Dependency Confusion**: publishing public packages with the same name as private internal packages, exploiting package manager resolution order
- **Maintainer Takeover**: gaining trust/access to an existing popular package through social engineering
- **Abandoned Package Hijacking**: taking over unmaintained packages that still have high download counts

### 2. Compromised Build Systems

Injecting malicious code during the build or compilation process so the source code looks clean but the compiled artifact is malicious (the Ken Thompson "Trusting Trust" attack pattern).

- CI/CD pipeline compromise (stolen credentials, poisoned build agents)
- Compiler backdoors
- Tampered build tools or plugins
- Malicious build scripts in Makefiles, Dockerfiles, or CI configs

### 3. Compromised Update Mechanisms

Hijacking software update channels to distribute malicious updates to all users.

- Compromised update servers
- Man-in-the-middle on unsigned updates
- Stolen code signing certificates
- DNS hijacking of update endpoints

### 4. Hardware Supply Chain

Inserting malicious components or firmware at the manufacturing or distribution stage.

- Tampered chips or firmware at the factory
- Intercepted shipments with modified hardware
- Counterfeit components with hidden functionality
- Pre-installed malware on devices

## Defense Mechanisms

### 1. Software Bill of Materials (SBOM)

A complete inventory of all components, libraries, and dependencies in your software. Formats include SPDX and CycloneDX. Enables rapid vulnerability identification when a dependency is compromised.

### 2. Dependency Pinning and Lock Files

Pin exact versions of all dependencies. Use lock files (package-lock.json, Cargo.lock, go.sum) to ensure reproducible builds and detect unexpected changes.

### 3. Signature Verification

Verify cryptographic signatures on packages, binaries, and updates. Use Sigstore/cosign for container image signing. Verify GPG signatures on source releases.

### 4. Reproducible Builds

Ensure that building the same source code always produces the identical binary. Allows independent verification that a binary matches its source. Used by Debian, Tor, Bitcoin Core.

### 5. Supply Chain Security Frameworks

- **SLSA (Supply chain Levels for Software Artifacts)**: graduated security levels for build integrity (Level 1-4)
- **in-toto**: framework for securing the entire software supply chain with cryptographic attestations
- **The Update Framework (TUF)**: specification for secure software update systems

### 6. Dependency Scanning

Automated tools that scan dependencies for known vulnerabilities and malicious patterns.

- Dependabot, Renovate (automated dependency updates)
- Snyk, Grype, Trivy (vulnerability scanning)
- Socket.dev (behavior analysis of npm/PyPI packages)
- OSV (open source vulnerability database)

### 7. Build Isolation

Run builds in isolated, ephemeral environments. No persistent state between builds. Minimize build-time network access. Hermetic builds (Bazel, Nix).

## Comparison of Attack Vectors

```
┌──────────────────────┬─────────────┬─────────────────┬───────────────────────┐
│ Vector               │ Scale       │ Detection       │ Notable Incident      │
├──────────────────────┼─────────────┼─────────────────┼───────────────────────┤
│ Dependency Poisoning │ Very High   │ Hard            │ event-stream, xz      │
├──────────────────────┼─────────────┼─────────────────┼───────────────────────┤
│ Build System         │ Very High   │ Very Hard       │ SolarWinds            │
├──────────────────────┼─────────────┼─────────────────┼───────────────────────┤
│ Update Mechanism     │ High        │ Hard            │ NotPetya, 3CX         │
├──────────────────────┼─────────────┼─────────────────┼───────────────────────┤
│ Typosquatting        │ Low-Medium  │ Medium          │ Various npm/PyPI      │
├──────────────────────┼─────────────┼─────────────────┼───────────────────────┤
│ Dependency Confusion │ Medium      │ Medium          │ Alex Birsan research  │
├──────────────────────┼─────────────┼─────────────────┼───────────────────────┤
│ Hardware Tampering   │ Targeted    │ Very Hard       │ Supermicro alleged    │
├──────────────────────┼─────────────┼─────────────────┼───────────────────────┤
│ Stolen Signing Keys  │ High        │ Hard            │ Asus ShadowHammer     │
└──────────────────────┴─────────────┴─────────────────┴───────────────────────┘
```

## Pros (of understanding and defending against supply chain attacks)

- **Risk Awareness**: understanding the attack surface beyond your own code
- **Transitive Trust Mapping**: knowing what you implicitly trust and where trust can be violated
- **Defense in Depth**: supply chain security complements application and network security
- **Regulatory Compliance**: SBOM requirements are becoming mandated (US Executive Order 14028)
- **Early Detection**: monitoring dependency changes catches attacks before they reach production
- **Community Resilience**: shared tooling and practices raise the bar for attackers

## Cons (challenges in defending)

- **Massive Attack Surface**: modern applications have hundreds to thousands of transitive dependencies
- **Trust Transitivity**: you trust your dependencies, which trust their dependencies, recursively
- **Open Source Maintainer Burden**: most critical open source is maintained by volunteers with limited security resources
- **Detection Difficulty**: sophisticated attacks (xz, SolarWinds) operate within trusted channels and signed artifacts
- **Speed vs Security**: pinning and reviewing every dependency update slows development velocity
- **No Silver Bullet**: no single tool or practice covers all supply chain attack vectors
- **Legacy Exposure**: older systems have untracked dependencies and no SBOM
- **False Sense of Security**: having a vulnerability scanner does not mean you are safe from novel attacks

## Use Cases for Supply Chain Security

- **Enterprise Software Procurement**: evaluating vendor security practices before adopting third-party software
- **Open Source Consumption**: organizations auditing and securing their open source dependency intake
- **CI/CD Pipeline Hardening**: securing build systems, artifact registries, and deployment pipelines
- **Government and Defense**: NIST, CISA, and DoD requirements for software supply chain integrity
- **Financial Services**: regulatory requirements for third-party risk management
- **Critical Infrastructure**: protecting power grids, water systems, and transportation from supply chain compromise
- **Container Security**: scanning base images and layers for vulnerabilities and malicious content
- **Package Registry Security**: npm, PyPI, crates.io, Maven Central implementing security controls
- **Firmware Security**: verifying firmware integrity in IoT, networking equipment, and embedded systems

## References

- [Chainguard Libraries - Supply Chain Prevention](https://get.chainguard.dev/libraries-and-actions-signup)
- [Microsoft - Mitigating the Axios npm Supply Chain Compromise](https://www.microsoft.com/en-us/security/blog/2026/04/01/mitigating-the-axios-npm-supply-chain-compromise/)
- [Elastic - Inside the Axios Supply Chain Compromise](https://www.elastic.co/security-labs/axios-one-rat-to-rule-them-all)
- [Axios Post-Mortem - GitHub Issue #10636](https://github.com/axios/axios/issues/10636)
- [Google - North Korea-Nexus Threat Actor Targets Axios](https://cloud.google.com/blog/topics/threat-intelligence/north-korea-threat-actor-targets-axios-npm-package)
- [Palo Alto - Breaking Down the Trivy Supply Chain Attack](https://www.paloaltonetworks.com/blog/cloud-security/trivy-supply-chain-attack/)
- [Aqua Security - Trivy Supply Chain Attack](https://www.aquasec.com/blog/trivy-supply-chain-attack-what-you-need-to-know/)
- [CrowdStrike - From Scanner to Stealer: Inside the trivy-action Compromise](https://www.crowdstrike.com/en-us/blog/from-scanner-to-stealer-inside-the-trivy-action-supply-chain-compromise/)
- [GitGuardian - Trivy's March Supply Chain Attack](https://blog.gitguardian.com/trivys-march-supply-chain-attack-shows-where-secret-exposure-hurts-most/)
