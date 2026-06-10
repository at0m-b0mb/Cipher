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
        // Red team
        case .cyberKillChain:      CyberKillChainView()
        case .portScan:            PortScanView()
        case .phishingFlow:        PhishingFlowView()
        case .sqlInjection:        SQLInjectionView()
        case .xssReflected:        XSSReflectedView()
        case .privilegeEscalation: PrivilegeEscalationView()
        case .passwordCracking:    PasswordCrackingView()
        case .kerberoasting:       KerberoastingView()
        case .lateralMovement:     LateralMovementView()
        case .bufferOverflow:      BufferOverflowView()
        case .c2Beacon:            C2BeaconView()
        // Blue team
        case .defenseInDepth:      DefenseInDepthView()
        case .siemPipeline:        SiemPipelineView()
        case .incidentResponse:    IncidentResponseView()
        case .mitreAttack:         MITREAttackView()
        case .threatHunting:       ThreatHuntingView()
        }
    }
}

/// Per-animation presentation metadata (accent colour, stage height, and a
/// one-line description used in the standalone gallery).
enum AnimationCatalog {

    private static let redIDs: Set<AnimationID> = [
        .cyberKillChain, .portScan, .phishingFlow, .sqlInjection, .xssReflected,
        .privilegeEscalation, .passwordCracking, .kerberoasting, .lateralMovement,
        .bufferOverflow, .c2Beacon
    ]
    private static let blueIDs: Set<AnimationID> = [
        .defenseInDepth, .siemPipeline, .incidentResponse, .mitreAttack, .threatHunting
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
        case .bufferOverflow:               return 282
        case .defenseInDepth:               return 272
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
        case .cyberKillChain:      return "The seven stages of an intrusion — and where defenders break it."
        case .portScan:            return "Probing a host's ports to reveal open, closed and filtered services."
        case .phishingFlow:        return "From a phishing email to the attacker's first reverse shell."
        case .sqlInjection:        return "How injected input rewrites a SQL query into an auth bypass."
        case .xssReflected:        return "Injected script runs in a victim's browser and steals their session."
        case .privilegeEscalation: return "Climbing from a low-privilege foothold to full root access."
        case .passwordCracking:    return "Streaming a wordlist through a hash until a password matches."
        case .kerberoasting:       return "Requesting a service ticket and cracking it offline."
        case .lateralMovement:     return "Hopping host to host with reused credentials toward the DC."
        case .bufferOverflow:      return "Overflowing a buffer to overwrite the return address and hijack execution."
        case .c2Beacon:            return "A covert implant beaconing home over jittered HTTPS check-ins."
        case .defenseInDepth:      return "Layered controls that slow an attacker and catch them in the act."
        case .siemPipeline:        return "Telemetry flowing into a SIEM until a rule fires an alert."
        case .incidentResponse:    return "The six-phase loop that turns a breach into a managed event."
        case .mitreAttack:         return "Plotting an intrusion across the ATT&CK tactics matrix."
        case .threatHunting:       return "The proactive loop: hypothesize, query, investigate, automate."
        }
    }
}
