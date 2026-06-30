import SwiftUI

/// The bridge between content and visuals: every `AnimationID` resolves to its
/// SwiftUI view, wrapped in the standard explainer chrome with an accent and
/// stage height tuned to the animation. A lesson just writes
/// `.animation(.tcpHandshake, caption: "…")` and this renders it.
struct AnimationView: View {
    let id: AnimationID
    var caption: String = ""

    var body: some View {
        AnimatedExplainer(id: id,
                          caption: caption.isEmpty ? AnimationCatalog.blurb(id) : caption,
                          accent: AnimationCatalog.accent(id),
                          height: AnimationCatalog.height(id)) {
            inner
        }
    }

    @ViewBuilder private var inner: some View {
        switch id {
        // Fundamentals
        case .osiModel:            OSIModelView()
        case .tcpHandshake:        TCPHandshakeView()
        case .packetTravel:        PacketTravelView()
        case .encodingLayers:      EncodingLayersView()
        // Networking track
        case .internetMap:         InternetMapView()
        case .ipAddressing:        IPAddressingView()
        case .subnetMask:          SubnetMaskView()
        case .dnsResolution:       DNSResolutionView()
        case .defaultGateway:      DefaultGatewayView()
        case .routingHops:         RoutingHopsView()
        case .natTranslation:      NATTranslationView()
        case .dhcpLease:           DHCPLeaseView()
        case .tcpVsUdp:            TCPvsUDPView()
        case .wifiConnect:         WiFiConnectView()
        case .vpnTunnel:           VPNTunnelView()
        case .firewallFilter:      FirewallFilterView()
        // Expansion
        case .processMemory:       ProcessMemoryView()
        case .certChain:           CertChainView()
        case .payloadStaging:      PayloadStagingView()
        case .tokenTheft:          TokenTheftView()
        case .idsDetection:        IDSDetectionView()
        case .secureSdlc:          SecureSdlcView()
        // Advanced offensive
        case .reverseEngineering:  ReverseEngineeringView()
        case .paddingOracle:       PaddingOracleView()
        case .dnsTunneling:        DnsTunnelingView()
        case .supplyChain:         SupplyChainView()
        case .aitmProxy:           AitmProxyView()
        case .promptInjection:     PromptInjectionView()
        // Expansion wave 2
        case .clickjacking:        ClickjackingView()
        case .cachePoisoning:      CachePoisoningView()
        case .bleAttack:           BleAttackView()
        case .rfidClone:           RfidCloneView()
        case .ddosAmplification:   DdosAmplificationView()
        case .steganography:       SteganographyView()
        // Expansion wave 3
        case .tlsHandshake:        TLSHandshakeView()
        case .ipv6Address:         IPv6AddressView()
        case .loadBalancer:        LoadBalancerView()
        case .passwordSpray:       PasswordSprayView()
        case .nosqlInjection:      NoSQLInjectionView()
        case .purpleTeam:          PurpleTeamView()
        case .threatModeling:      ThreatModelingView()
        // Expansion wave 4
        case .xorCipher:           XORCipherView()
        case .sqlQuery:            SQLQueryView()
        case .regexMatch:          RegexMatchView()
        case .bgpRouting:          BGPRoutingView()
        case .emailFlow:           EmailFlowView()
        case .quicHandshake:       QUICHandshakeView()
        case .adcsEsc1:            ADCSEsc1View()
        case .ssrfAttack:          SSRFAttackView()
        case .ransomwareRecovery:  RansomwareRecoveryView()
        // Expansion wave 5
        case .mfaFactors:          MFAFactorsView()
        case .vmContainer:         VMvsContainerView()
        case .proxyFlow:           ProxyFlowView()
        case .webSocketUpgrade:    WebSocketUpgradeView()
        case .corsMisconfig:       CORSMisconfigView()
        case .bucketExposure:      BucketExposureView()
        case .soarPlaybook:        SOARPlaybookView()
        case .secretsVault:        SecretsVaultView()
        // Expansion wave 6
        case .compilePipeline:     CompilePipelineView()
        case .entropyRng:          EntropyRngView()
        case .vlanTagging:         VlanTaggingView()
        case .badusbInject:        BadUsbInjectView()
        case .dllHijack:           DllHijackView()
        case .nistCsf:             NistCsfView()
        case .riskMatrix:          RiskMatrixView()
        case .yaraMatch:           YaraMatchView()
        case .symmetricEncryption: SymmetricEncryptionView()
        case .publicKeyExchange:   PublicKeyExchangeView()
        case .hashing:             HashingView()
        case .blockCipherModes:    BlockCipherModesView()
        case .httpRequest:         HTTPRequestView()
        case .adForest:            ADForestView()
        // Red team
        case .cyberKillChain:      CyberKillChainView()
        case .portScan:            PortScanView()
        case .phishingFlow:        PhishingFlowView()
        case .sqlInjection:        SQLInjectionView()
        case .xssReflected:        XSSReflectedView()
        case .accessControl:       AccessControlView()
        case .fileInclusion:       FileInclusionView()
        case .templateInjection:   TemplateInjectionView()
        case .csrf:                CSRFView()
        case .jwtAttack:           JWTAttackView()
        case .apiBola:             ApiBolaView()
        case .oauthFlow:           OAuthFlowView()
        case .sourceReview:        SourceReviewView()
        case .clientSide:          ClientSideView()
        case .cloudMetadata:       CloudMetadataView()
        case .containerEscape:     ContainerEscapeView()
        case .subdomainTakeover:   SubdomainTakeoverView()
        case .requestSmuggling:    RequestSmugglingView()
        case .raceCondition:       RaceConditionView()
        case .fileUpload:          FileUploadView()
        case .mobileSecurity:      MobileSecurityView()
        case .privilegeEscalation: PrivilegeEscalationView()
        case .passwordCracking:    PasswordCrackingView()
        case .kerberoasting:       KerberoastingView()
        case .dcsync:              DCSyncView()
        case .attackPath:          AttackPathView()
        case .delegation:          DelegationView()
        case .forestTrust:         ForestTrustView()
        case .lateralMovement:     LateralMovementView()
        case .tunneling:           TunnelingView()
        case .amsiBypass:          AMSIBypassView()
        case .processInjection:    ProcessInjectionView()
        case .applockerBypass:     AppLockerBypassView()
        case .wifiHandshake:       WiFiHandshakeView()
        case .arpPoisoning:        ARPPoisoningView()
        case .bufferOverflow:      BufferOverflowView()
        case .ropChain:            ROPChainView()
        case .sehOverflow:         SEHOverflowView()
        case .formatString:        FormatStringView()
        case .heapExploit:         HeapExploitView()
        case .c2Beacon:            C2BeaconView()
        // Blue team
        case .defenseInDepth:      DefenseInDepthView()
        case .siemPipeline:        SiemPipelineView()
        case .incidentResponse:    IncidentResponseView()
        case .mitreAttack:         MITREAttackView()
        case .threatHunting:       ThreatHuntingView()
        case .adTiering:           ADTieringView()
        case .threatIntel:         ThreatIntelView()
        case .zeroTrust:           ZeroTrustView()
        case .emailAuth:           EmailAuthView()
        case .honeyToken:          HoneyTokenView()
        }
    }
}

/// Per-animation presentation metadata (accent colour, stage height, and a
/// one-line description used in the standalone gallery).
enum AnimationCatalog {

    private static let redIDs: Set<AnimationID> = [
        .cyberKillChain, .portScan, .phishingFlow, .sqlInjection, .xssReflected,
        .accessControl, .fileInclusion, .templateInjection, .csrf, .jwtAttack,
        .apiBola, .oauthFlow, .sourceReview, .clientSide, .cloudMetadata, .containerEscape,
        .subdomainTakeover, .requestSmuggling, .raceCondition, .fileUpload, .mobileSecurity,
        .privilegeEscalation, .passwordCracking, .kerberoasting, .dcsync, .attackPath,
        .delegation, .forestTrust, .lateralMovement, .tunneling,
        .amsiBypass, .processInjection, .applockerBypass, .wifiHandshake, .arpPoisoning,
        .bufferOverflow, .ropChain, .sehOverflow, .formatString, .heapExploit, .c2Beacon,
        .payloadStaging, .tokenTheft,
        .reverseEngineering, .paddingOracle, .dnsTunneling, .supplyChain, .aitmProxy, .promptInjection,
        .clickjacking, .cachePoisoning, .bleAttack, .rfidClone, .ddosAmplification,
        .passwordSpray, .nosqlInjection, .adcsEsc1, .ssrfAttack, .corsMisconfig, .bucketExposure,
        .badusbInject, .dllHijack
    ]
    private static let blueIDs: Set<AnimationID> = [
        .defenseInDepth, .siemPipeline, .incidentResponse, .mitreAttack, .threatHunting,
        .adTiering, .threatIntel, .zeroTrust, .emailAuth, .honeyToken,
        .idsDetection, .secureSdlc, .purpleTeam, .threatModeling, .ransomwareRecovery,
        .soarPlaybook, .secretsVault, .nistCsf, .riskMatrix, .yaraMatch
    ]
    private static let networkIDs: Set<AnimationID> = [
        .internetMap, .ipAddressing, .subnetMask, .dnsResolution, .defaultGateway,
        .routingHops, .natTranslation, .dhcpLease, .tcpVsUdp, .wifiConnect,
        .vpnTunnel, .firewallFilter, .ipv6Address, .loadBalancer,
        .bgpRouting, .emailFlow, .quicHandshake, .proxyFlow, .webSocketUpgrade, .vlanTagging
    ]

    static func accent(_ id: AnimationID) -> Color {
        if redIDs.contains(id) { return Theme.red }
        if blueIDs.contains(id) { return Theme.blue }
        if networkIDs.contains(id) { return Theme.violet }
        return Theme.teal
    }

    static func height(_ id: AnimationID) -> CGFloat {
        switch id {
        case .cyberKillChain:               return 300
        case .sqlInjection, .xssReflected:  return 300
        case .accessControl, .fileInclusion, .templateInjection: return 296
        case .jwtAttack, .clientSide, .formatString, .heapExploit: return 296
        case .apiBola, .containerEscape:    return 300
        case .subdomainTakeover, .requestSmuggling, .fileUpload: return 300
        case .mobileSecurity:               return 296
        case .raceCondition, .emailAuth:    return 286
        case .blockCipherModes:             return 272
        case .encodingLayers:               return 288
        case .zeroTrust:                    return 286
        case .threatIntel:                  return 274
        case .applockerBypass:              return 292
        case .amsiBypass:                   return 288
        case .ropChain, .sehOverflow:       return 286
        case .bufferOverflow:               return 282
        case .attackPath, .forestTrust:     return 278
        case .sourceReview:                 return 270
        case .defenseInDepth:               return 272
        case .adForest, .adTiering:         return 272
        case .privilegeEscalation:          return 262
        // Networking
        case .ipAddressing:                 return 300
        case .subnetMask:                   return 288
        case .dnsResolution:                return 286
        case .internetMap, .defaultGateway: return 290
        case .routingHops, .natTranslation: return 286
        case .vpnTunnel, .wifiConnect:      return 280
        case .firewallFilter, .tcpVsUdp:    return 280
        // Expansion
        case .processMemory, .certChain:    return 300
        case .tokenTheft, .idsDetection:    return 272
        case .secureSdlc:                   return 290
        // Advanced offensive
        case .reverseEngineering, .paddingOracle: return 300
        case .supplyChain, .promptInjection: return 296
        case .dnsTunneling:                 return 272
        // Expansion wave 2
        case .cachePoisoning:               return 300
        case .bleAttack, .ddosAmplification: return 288
        case .clickjacking:                 return 272
        case .rfidClone, .steganography:    return 270
        // Expansion wave 3
        case .threatModeling:               return 300
        case .tlsHandshake, .nosqlInjection, .purpleTeam: return 286
        case .loadBalancer, .passwordSpray: return 280
        case .ipv6Address:                  return 272
        // Expansion wave 4
        case .adcsEsc1:                     return 296
        case .bgpRouting, .emailFlow, .ssrfAttack: return 290
        case .sqlQuery, .quicHandshake:     return 286
        case .ransomwareRecovery:           return 280
        case .xorCipher:                    return 270
        case .regexMatch:                   return 262
        // Expansion wave 5
        case .corsMisconfig:                return 300
        case .proxyFlow, .bucketExposure:   return 290
        case .mfaFactors, .vmContainer:     return 286
        case .secretsVault:                 return 282
        case .webSocketUpgrade:             return 272
        case .soarPlaybook:                 return 250
        // Expansion wave 6
        case .riskMatrix:                   return 300
        case .vlanTagging, .dllHijack:      return 290
        case .compilePipeline, .badusbInject, .yaraMatch: return 286
        case .entropyRng:                   return 280
        case .nistCsf:                      return 262
        default:                            return 250
        }
    }

    static func blurb(_ id: AnimationID) -> String {
        switch id {
        case .osiModel:            return "How each network layer wraps data in its own header — then unwraps it."
        case .tcpHandshake:        return "The SYN / SYN-ACK / ACK ritual that opens every TCP connection."
        case .packetTravel:        return "Peel a real packet apart, header by header, down to the payload."
        case .encodingLayers:      return "The same message re-dressed as hex, Base64 and URL encoding — reversible, not secret."
        case .internetMap:         return "Your data hops laptop → home router → ISP → the internet backbone → a server."
        case .ipAddressing:        return "An IPv4 address is four octets (32 bits); the MAC names the physical card."
        case .subnetMask:          return "The mask splits an address into a network part and a host part — and sets how many hosts fit."
        case .dnsResolution:       return "A resolver walks root → TLD → authoritative name server to turn a name into an IP."
        case .defaultGateway:      return "Local traffic stays on the switch; anything off-subnet goes to the default gateway."
        case .routingHops:         return "A packet hops router to router, its TTL ticking down — exactly what traceroute reveals."
        case .natTranslation:      return "One public IP shared by many private devices — the router rewrites addresses both ways."
        case .dhcpLease:           return "DORA: a new device gets its IP, gateway and DNS automatically in four messages."
        case .tcpVsUdp:            return "TCP acknowledges and reorders; UDP just fires and forgets — speed over guarantees."
        case .wifiConnect:         return "Scan, authenticate with WPA2, associate — then your phone is on the network."
        case .vpnTunnel:           return "An encrypted tunnel hides your traffic from anyone watching the network in between."
        case .firewallFilter:      return "Packets are checked against a ruleset — allowed ports pass, the rest are dropped."
        case .processMemory:       return "A process's memory: stack growing down, heap growing up, with static data and code below."
        case .certChain:           return "A TLS certificate chain — Root signs Intermediate signs the server — validated up to a trusted root."
        case .payloadStaging:      return "A tiny stager lands, calls home, and pulls down the full Meterpreter payload."
        case .tokenTheft:          return "Abusing SeImpersonatePrivilege to steal a SYSTEM token and elevate on Windows."
        case .idsDetection:        return "Traffic streams past an IDS sensor; a malicious request matches a signature and fires an alert."
        case .secureSdlc:          return "A CI/CD pipeline where SAST, dependency and DAST gates block a vulnerable build from shipping."
        case .reverseEngineering:  return "Raw bytes become disassembly; patching one conditional jump bypasses a license check."
        case .paddingOracle:       return "A server's padding-error responses leak a CBC ciphertext one byte at a time — no key needed."
        case .dnsTunneling:        return "Stolen data is base32-encoded into DNS queries that slip out through an allowed port 53."
        case .supplyChain:         return "Dependency confusion — a malicious higher-version public package outranks the real internal one."
        case .aitmProxy:           return "A reverse proxy relays the login and MFA code, then steals the live session cookie."
        case .promptInjection:     return "Untrusted text in an LLM's context overrides its system prompt and hijacks the model."
        case .clickjacking:        return "An invisible iframe of a real action is layered under a friendly button — your click lands on the trap."
        case .cachePoisoning:      return "An unkeyed header is reflected into a cacheable response, so one request poisons the page for everyone."
        case .bleAttack:           return "A plaintext BLE unlock command is sniffed off the air and replayed verbatim — no key needed."
        case .rfidClone:           return "A covert reader lifts a badge's UID, writes it to a blank card, and the clone opens the door."
        case .ddosAmplification:   return "A spoofed source makes open resolvers fire huge replies at the victim — a tiny query becomes a flood."
        case .steganography:       return "The secret hides in the least-significant bit of each pixel — invisible to the eye, trivial to extract."
        case .tlsHandshake:        return "ClientHello and ServerHello each carry a key share, so TLS 1.3 agrees a secret in one round trip — then encrypts everything."
        case .ipv6Address:         return "128 bits split into a routing prefix, a subnet id and an interface id — enough addresses to retire NAT for good."
        case .loadBalancer:        return "One balancer spreads requests across a pool of healthy backends and skips any node that fails its health check."
        case .passwordSpray:       return "One common password tried once against many accounts — under the lockout threshold, and one reuse is enough."
        case .nosqlInjection:      return "A smuggled `$ne` operator turns 'password must equal X' into 'password just has to exist' — an auth bypass."
        case .purpleTeam:          return "Red emulates, blue checks, the gap is closed with a tested detection — and measured coverage climbs."
        case .threatModeling:      return "Walk a design's trust boundaries through STRIDE — six prompts, each tied to the security property it breaks."
        case .xorCipher:           return "Combine plaintext with a key bit by bit — and XOR-ing with the same key again returns the original."
        case .sqlQuery:            return "A SELECT scans the table; the WHERE clause keeps the rows that match and drops the rest."
        case .regexMatch:          return "A pattern of classes, quantifiers and literals sweeps the text and captures the part that fits."
        case .bgpRouting:          return "Autonomous Systems announce the prefixes they can reach; BGP picks the shortest AS-path to the destination."
        case .emailFlow:           return "SMTP submits, a DNS MX lookup finds the server, SMTP delivers, and IMAP/POP pulls it down."
        case .quicHandshake:       return "TCP+TLS spends two round trips before any data; QUIC folds them into one over UDP — and survives a network switch."
        case .adcsEsc1:            return "A misconfigured cert template lets a normal user enroll as Administrator, then authenticate as Domain Admin."
        case .ssrfAttack:          return "The app fetches any URL you give it from inside the network — reaching internal services and reflecting the secret back."
        case .ransomwareRecovery:  return "Files fall to encryption one by one; an offline, immutable backup is the only thing that brings them back."
        case .mfaFactors:          return "Verify something you know, then something you have — a phished password alone never gets past factor two."
        case .vmContainer:         return "VMs ship a whole guest OS for strong isolation; containers share the host kernel — light and fast, thinner boundary."
        case .proxyFlow:           return "A forward proxy fronts the clients; a reverse proxy fronts the servers — same box, opposite direction."
        case .webSocketUpgrade:    return "An HTTP request asks to UPGRADE; after a 101 the connection becomes a persistent two-way channel."
        case .corsMisconfig:       return "A server that reflects an untrusted Origin and allows credentials lets evil.com read the victim's data."
        case .bucketExposure:      return "A world-readable bucket answers an anonymous LIST and serves the files — misconfiguration, not exploit."
        case .soarPlaybook:        return "An alert is enriched, judged, contained and ticketed automatically — seconds instead of hours."
        case .secretsVault:        return "A hardcoded secret leaks forever; a vault issues short-lived, auto-expiring credentials at runtime."
        case .compilePipeline:     return "Source you write becomes the CPU's binary instructions, run one at a time in a fetch-decode-execute loop."
        case .entropyRng:          return "A seeded PRNG is predictable; a CSPRNG fed by hardware entropy isn't — and keys depend on the difference."
        case .vlanTagging:         return "One switch, many isolated networks: an 802.1Q tag keeps VLAN 10 from ever reaching VLAN 20."
        case .badusbInject:        return "A USB device declares itself a keyboard — trusted with no prompt — and types a payload at machine speed."
        case .dllHijack:           return "Windows checks the app's own folder first, so a planted DLL of the right name loads instead of the real one."
        case .nistCsf:             return "The five continuous functions of the NIST CSF — Identify, Protect, Detect, Respond, Recover — as a cycle."
        case .riskMatrix:          return "Plot each risk by likelihood × impact; the top-right (likely and damaging) is what you fix first."
        case .yaraMatch:           return "A rule of strings plus a condition scans a file — match enough patterns and it's flagged as malware."
        case .symmetricEncryption: return "One shared key turns plaintext to ciphertext and back."
        case .publicKeyExchange:   return "A public key locks a message that only the private key can open."
        case .hashing:             return "A one-way fingerprint where a tiny change avalanches the output."
        case .blockCipherModes:    return "Why ECB leaks structure — identical blocks encrypt identically — and CBC/GCM don't."
        case .httpRequest:         return "A browser and server trade requests — and a cookie carries the session."
        case .adForest:            return "How a domain nests under a forest, with every secret resting on the DC."
        case .cyberKillChain:      return "The seven stages of an intrusion — and where defenders break it."
        case .portScan:            return "Probing a host's ports to reveal open, closed and filtered services."
        case .phishingFlow:        return "From a phishing email to the attacker's first reverse shell."
        case .sqlInjection:        return "How injected input rewrites a SQL query into an auth bypass."
        case .xssReflected:        return "Injected script runs in a victim's browser and steals their session."
        case .accessControl:       return "Tampering with an object id to read another user's data — IDOR."
        case .fileInclusion:       return "Path traversal makes the server read and include files it shouldn't."
        case .templateInjection:   return "Input the template engine evaluates — from {{7*7}} to code execution."
        case .csrf:                return "An attacker page rides the victim's cookie to forge a real request."
        case .jwtAttack:           return "Tampering a JWT's claims and dropping the signature to forge admin."
        case .apiBola:             return "GraphQL introspection plus one id swap returns another tenant's data."
        case .oauthFlow:           return "A tampered redirect_uri leaks the OAuth code straight to the attacker."
        case .sourceReview:        return "Tracing untrusted input from its source to a dangerous sink."
        case .clientSide:          return "A macro-enabled document that runs code the moment it's opened."
        case .cloudMetadata:       return "An SSRF walks the cloud metadata service back to temporary IAM keys."
        case .containerEscape:     return "A mounted Docker socket turns a container foothold into root on the node."
        case .subdomainTakeover:   return "A dangling DNS record lets an attacker claim a subdomain's abandoned service."
        case .requestSmuggling:    return "Front-end and back-end disagree on a request's length, poisoning the next visitor."
        case .raceCondition:       return "Parallel requests slip through the check-then-act gap to redeem a card five times."
        case .fileUpload:          return "A disguised script slips past an upload filter and runs as a web shell."
        case .mobileSecurity:      return "Plaintext token storage and a bypassed pin lay the app's API bare to a proxy."
        case .privilegeEscalation: return "Climbing from a low-privilege foothold to full root access."
        case .passwordCracking:    return "Streaming a wordlist through a hash until a password matches."
        case .kerberoasting:       return "Requesting a service ticket and cracking it offline."
        case .dcsync:              return "Replicating the krbtgt hash from the DC to forge a Golden Ticket."
        case .attackPath:          return "A BloodHound chain of AD edges lighting up the path to Domain Admin."
        case .delegation:          return "Abusing S4U delegation to impersonate an admin to a target service."
        case .forestTrust:         return "Crossing a domain trust with a forged SID-history ticket to own the forest."
        case .lateralMovement:     return "Hopping host to host with reused credentials toward the DC."
        case .tunneling:           return "Routing tools through a pivot host to reach a hidden internal subnet."
        case .amsiBypass:          return "Patching the in-memory scanner so a blocked payload runs clean."
        case .processInjection:    return "Hiding shellcode inside a trusted process to dodge detection."
        case .applockerBypass:     return "Running blocked code through a trusted, whitelisted Microsoft binary."
        case .wifiHandshake:       return "Deauth, capture the WPA2 4-way handshake, then crack the PSK offline."
        case .arpPoisoning:        return "Poisoning ARP caches to sit in the middle of victim and gateway."
        case .bufferOverflow:      return "Overflowing a buffer to overwrite the return address and hijack execution."
        case .ropChain:            return "Chaining existing code gadgets to bypass a non-executable stack."
        case .sehOverflow:         return "Clobbering the SEH chain so a thrown exception hijacks execution."
        case .formatString:        return "A format string that leaks the stack and then writes anywhere."
        case .heapExploit:         return "A use-after-free where freed memory is reclaimed with attacker data."
        case .c2Beacon:            return "A covert implant beaconing home over jittered HTTPS check-ins."
        case .defenseInDepth:      return "Layered controls that slow an attacker and catch them in the act."
        case .siemPipeline:        return "Telemetry flowing into a SIEM until a rule fires an alert."
        case .incidentResponse:    return "The six-phase loop that turns a breach into a managed event."
        case .mitreAttack:         return "Plotting an intrusion across the ATT&CK tactics matrix."
        case .threatHunting:       return "The proactive loop: hypothesize, query, investigate, automate."
        case .adTiering:           return "Admin tiers that stop a stolen low-tier credential reaching the DC."
        case .threatIntel:         return "The intelligence lifecycle turning raw data into decisions, then back again."
        case .zeroTrust:           return "Every request scored on identity, device and risk before least-privilege access."
        case .emailAuth:           return "A spoofed sender fails SPF, DKIM and DMARC — and never reaches the inbox."
        case .honeyToken:          return "A planted canary file fires a silent, near-zero-false-positive alert when touched."
        }
    }
}
