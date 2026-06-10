import SwiftUI

struct TracksView: View {
    @EnvironmentObject private var progress: ProgressStore

    var body: some View {
        ZStack {
            CircuitBackground(tint: Theme.teal)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Curriculum").font(Theme.rounded(30, .bold)).foregroundStyle(Theme.textPrimary)
                        Text("Three tracks · \(Curriculum.lessonCount) animated lessons. Learn the attacker's playbook and the defender's craft — the same ground professional programs charge thousands to teach.")
                            .font(.system(size: 14)).foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    ForEach(Curriculum.tracks) { track in
                        NavigationLink(value: CipherRoute.track(track.id)) {
                            TrackCard(track: track, completion: progress.completion(of: track))
                        }
                        .buttonStyle(.plain)
                    }

                    CalloutView(kind: .warning, text: "Every technique here is for authorized testing and defense only — practise on your own lab VMs or platforms built for it (Hack The Box, TryHackMe). Unauthorized access is a crime.")
                        .padding(.top, 4)
                }
                .padding(18)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("")
        .toolbar(.hidden, for: .navigationBar)
    }
}
