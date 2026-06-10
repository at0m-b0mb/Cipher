import SwiftUI

/// A standalone gallery of every animated explainer, grouped by track. Lets
/// learners replay any visualization without hunting for its lesson.
struct AnimationGalleryView: View {
    private let groups: [(title: String, accent: Color, ids: [AnimationID])] = [
        ("Fundamentals", Theme.teal,
         [.osiModel, .tcpHandshake, .packetTravel, .symmetricEncryption, .publicKeyExchange, .hashing]),
        ("Red Team", Theme.red,
         [.cyberKillChain, .portScan, .phishingFlow, .sqlInjection, .xssReflected, .privilegeEscalation,
          .passwordCracking, .kerberoasting, .lateralMovement, .bufferOverflow, .c2Beacon]),
        ("Blue Team", Theme.blue,
         [.defenseInDepth, .siemPipeline, .incidentResponse, .mitreAttack, .threatHunting])
    ]

    var body: some View {
        ZStack {
            CircuitBackground(tint: Theme.violet)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Animations").font(Theme.rounded(30, .bold)).foregroundStyle(Theme.textPrimary)
                        Text("\(AnimationID.allCases.count) interactive explainers. Tap replay on any of them; every one also appears inside its lesson.")
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
        .navigationTitle("")
        .toolbar(.hidden, for: .navigationBar)
    }
}
