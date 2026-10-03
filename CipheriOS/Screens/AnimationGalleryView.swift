import SwiftUI

/// A standalone gallery of every animated explainer, grouped by track. Lets
/// learners replay any visualization without hunting for its lesson.
struct AnimationGalleryView: View {
    /// When embedded in the Practice tab the host already draws the backdrop and
    /// the section title, so skip both and render just the gallery.
    var embedded: Bool = false

    /// The gallery's groups: a hand-curated opening order per track (so the first
    /// thing a learner sees is the right first thing), with every animation not
    /// named in that curation appended to its track group automatically.
    ///
    /// Before this was derived, 39 of 133 animations silently never appeared here.
    private var groups: [(title: String, accent: Color, ids: [AnimationID])] {
        let curatedIDs = Set(curated.flatMap(\.ids))
        let leftovers = AnimationID.allCases.filter { !curatedIDs.contains($0) }
        return curated.map { group in
            let extra = leftovers.filter { AnimationCatalog.track($0).title == group.title }
            return (group.title, group.accent, group.ids + extra)
        }
    }

    private let curated: [(title: String, accent: Color, ids: [AnimationID])] = [
        ("Fundamentals", Theme.teal,
         [.ciaTriad, .threatActors, .osiModel, .tcpHandshake, .packetTravel, .symmetricEncryption, .publicKeyExchange, .hashing,
          .processMemory, .certChain, .tlsHandshake, .steganography,
          .xorCipher, .sqlQuery, .regexMatch, .mfaFactors, .vmContainer,
          .compilePipeline, .entropyRng,
          .numberBases, .endianness, .charEncoding, .booleanLogic,
          .filePermissions, .saltHashing]),
        ("Networking", Theme.violet,
         [.internetMap, .ipAddressing, .subnetMask, .dnsResolution, .defaultGateway, .routingHops,
          .natTranslation, .dhcpLease, .tcpVsUdp, .wifiConnect, .vpnTunnel, .firewallFilter,
          .ipv6Address, .loadBalancer, .bgpRouting, .emailFlow, .quicHandshake,
          .proxyFlow, .webSocketUpgrade, .vlanTagging]),
        ("Red Team", Theme.red,
         [.cyberKillChain, .portScan, .phishingFlow, .passwordSpray, .sqlInjection, .nosqlInjection,
          .xssReflected, .ssrfAttack, .payloadStaging,
          .privilegeEscalation, .tokenTheft, .passwordCracking, .kerberoasting, .lateralMovement, .adcsEsc1,
          .bufferOverflow, .reverseEngineering, .paddingOracle, .c2Beacon, .dnsTunneling, .supplyChain,
          .aitmProxy, .promptInjection, .clickjacking, .cachePoisoning, .bleAttack, .rfidClone,
          .ddosAmplification, .corsMisconfig, .bucketExposure, .badusbInject, .dllHijack, .socialEngineering]),
        ("Blue Team", Theme.blue,
         [.defenseInDepth, .siemPipeline, .idsDetection, .secureSdlc, .incidentResponse, .mitreAttack,
          .threatHunting, .threatModeling, .purpleTeam, .ransomwareRecovery, .soarPlaybook, .secretsVault,
          .nistCsf, .riskMatrix, .yaraMatch, .logAnalysis])
    ]

    var body: some View {
        Group {
            if embedded { gallery } else {
                ZStack {
                    CircuitBackground(tint: Theme.violet)
                    gallery
                }
            }
        }
        .navigationTitle("")
        .toolbar(.hidden, for: .navigationBar)
    }

    private var gallery: some View {
        ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(embedded ? "Animated explainers" : "Animations")
                            .font(Theme.rounded(embedded ? 22 : 30, .bold)).foregroundStyle(Theme.textPrimary)
                        Text("\(AnimationID.allCases.count) interactive explainers. Play, pause, scrub and change speed on any of them; every one also appears inside its lesson.")
                            .font(.system(size: 14)).foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    ForEach(groups.indices, id: \.self) { gi in
                        let group = groups[gi]
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeader(title: "\(group.title) · \(group.ids.count)", systemImage: "play.fill", accent: group.accent)
                            ForEach(group.ids, id: \.self) { id in
                                AnimationView(id: id)
                            }
                        }
                    }
                }
                .padding(18)
                .padding(.bottom, 32)
        }
    }
}
