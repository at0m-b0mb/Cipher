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
        case .symmetricEncryption: SymmetricEncryptionView()
        case .publicKeyExchange:   PublicKeyExchangeView()
        case .hashing:             HashingView()
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
        case .sourceReview:        SourceReviewView()
        case .clientSide:          ClientSideView()
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
        }
    }
}

/// Per-animation presentation metadata (accent colour, stage height, and a
/// one-line description used in the standalone gallery).
enum AnimationCatalog {

    private static let redIDs: Set<AnimationID> = [
        .cyberKillChain, .portScan, .phishingFlow, .sqlInjection, .xssReflected,
        .accessControl, .fileInclusion, .templateInjection, .csrf, .jwtAttack,
        .sourceReview, .clientSide,
        .privilegeEscalation, .passwordCracking, .kerberoasting, .dcsync, .attackPath,
        .delegation, .forestTrust, .lateralMovement, .tunneling,
        .amsiBypass, .processInjection, .applockerBypass, .wifiHandshake, .arpPoisoning,
        .bufferOverflow, .ropChain, .sehOverflow, .formatString, .heapExploit, .c2Beacon
    ]
    private static let blueIDs: Set<AnimationID> = [
        .defenseInDepth, .siemPipeline, .incidentResponse, .mitreAttack, .threatHunting,
        .adTiering
    ]

    static func accent(_ id: AnimationID) -> Color {
        if redIDs.contains(id) { return Theme.red }
        if blueIDs.contains(id) { return Theme.blue }
        return Theme.teal
    }

    static func height(_ id: AnimationID) -> CGFloat {
        switch id {
        case .cyberKillChain:               return 300
        case .sqlInjection, .xssReflected:  return 300
        case .accessControl, .fileInclusion, .templateInjection: return 296
        case .jwtAttack, .clientSide, .formatString, .heapExploit: return 296
        case .applockerBypass:              return 292
        case .amsiBypass:                   return 288
        case .ropChain, .sehOverflow:       return 286
        case .bufferOverflow:               return 282
        case .attackPath, .forestTrust:     return 278
        case .sourceReview:                 return 270
        case .defenseInDepth:               return 272
        case .adForest, .adTiering:         return 272
        case .privilegeEscalation:          return 262
        default:                            return 250
        }
    }

    static func blurb(_ id: AnimationID) -> String {
        switch id {
        case .osiModel:            return "How each network layer wraps data in its own header — then unwraps it."
        case .tcpHandshake:        return "The SYN / SYN-ACK / ACK ritual that opens every TCP connection."
        case .packetTravel:        return "Peel a real packet apart, header by header, down to the payload."
        case .symmetricEncryption: return "One shared key turns plaintext to ciphertext and back."
        case .publicKeyExchange:   return "A public key locks a message that only the private key can open."
        case .hashing:             return "A one-way fingerprint where a tiny change avalanches the output."
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
        case .sourceReview:        return "Tracing untrusted input from its source to a dangerous sink."
        case .clientSide:          return "A macro-enabled document that runs code the moment it's opened."
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
        }
    }
}
