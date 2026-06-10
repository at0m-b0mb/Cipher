import SwiftUI

/// One-time gate shown on first launch. Frames the whole app as ethical,
/// authorized security education — and makes the learner pledge it.
struct EthicsGateView: View {
    @EnvironmentObject private var progress: ProgressStore
    @State private var agree = false
    @State private var appeared = false

    var body: some View {
        ZStack {
            CircuitBackground(tint: Theme.teal)
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(LinearGradient(colors: [Theme.red, Theme.blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 92, height: 92)
                                .shadow(color: Theme.blue.opacity(0.5), radius: 18)
                            Image(systemName: "shield.lefthalf.filled")
                                .font(.system(size: 44, weight: .bold)).foregroundStyle(.white)
                        }
                        .scaleEffect(appeared ? 1 : 0.7)
                        .opacity(appeared ? 1 : 0)
                        Text("CIPHER").font(Theme.mono(28, .black)).tracking(10).foregroundStyle(Theme.textPrimary)
                        Text("Red & Blue Team Academy").font(Theme.rounded(16, .semibold)).foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.top, 44)

                    Text("Learn to hack — and to defend. Real offensive and defensive security, taught through animation.")
                        .font(.system(size: 15)).foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 16) {
                        pledgeRow("lock.shield.fill", "Authorized use only", "Test only systems you own or have explicit written permission to assess.", Theme.teal)
                        pledgeRow("flask.fill", "Practise in a lab", "Use your own VMs or platforms built for it — Hack The Box, TryHackMe.", Theme.violet)
                        pledgeRow("building.columns.fill", "Stay legal", "Unauthorized access to computers is a crime almost everywhere.", Theme.amber)
                        pledgeRow("heart.text.square.fill", "Build, don't break", "These skills exist to protect people, data and systems.", Theme.blue)
                    }
                    .cipherCard()

                    Toggle(isOn: $agree.animation()) {
                        Text("I understand, and I'll use what I learn ethically and legally.")
                            .font(.system(size: 13.5)).foregroundStyle(Theme.textPrimary)
                    }
                    .tint(Theme.teal)
                    .padding(.horizontal, 4)

                    Button {
                        progress.acceptEthics()
                    } label: {
                        Text("Enter Cipher")
                            .font(Theme.rounded(17, .bold)).foregroundStyle(.black)
                            .frame(maxWidth: .infinity).padding(.vertical, 15)
                            .background(agree ? Theme.teal : Theme.surfaceHi, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(!agree)
                    .opacity(agree ? 1 : 0.6)
                }
                .padding(24)
                .padding(.bottom, 30)
            }
        }
        .onAppear { withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { appeared = true } }
    }

    private func pledgeRow(_ glyph: String, _ title: String, _ body: String, _ color: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: glyph).font(.system(size: 18, weight: .semibold)).foregroundStyle(color).frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.rounded(15, .bold)).foregroundStyle(Theme.textPrimary)
                Text(body).font(.system(size: 12.5)).foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}
