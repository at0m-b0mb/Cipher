import SwiftUI

/// A simulated terminal block. Types the command out character-by-character,
/// then reveals the output — so lessons *feel* like watching a real shell.
/// Tap to replay.
struct TerminalView: View {
    let prompt: String
    let command: String
    let output: String

    @State private var typed = 0
    @State private var showOutput = false
    @State private var replay = 0

    private var commandShown: String { String(command.prefix(typed)) }
    private var isTyping: Bool { typed < command.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            VStack(alignment: .leading, spacing: 10) {
                // Command line(s)
                (Text(prompt).foregroundStyle(Theme.blue)
                 + Text(" $ ").foregroundStyle(Theme.green)
                 + Text(commandShown).foregroundStyle(Theme.textPrimary)
                 + Text(isTyping ? "▌" : "").foregroundStyle(Theme.green))
                    .font(Theme.mono(12.5))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)

                if showOutput {
                    Text(output)
                        .font(Theme.mono(12))
                        .foregroundStyle(Theme.green.opacity(0.9))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity)
                }
            }
            .padding(14)
        }
        .background(Color.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.stroke, lineWidth: 1))
        .task(id: replay) { await run() }
        .onTapGesture { replay += 1 }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Terminal. Command: \(command). Output: \(output)")
    }

    private var header: some View {
        HStack(spacing: 6) {
            Circle().fill(Color(hex: "#FF5F57")).frame(width: 9, height: 9)
            Circle().fill(Color(hex: "#FEBC2E")).frame(width: 9, height: 9)
            Circle().fill(Color(hex: "#28C840")).frame(width: 9, height: 9)
            Spacer()
            Image(systemName: "terminal").font(.system(size: 10)).foregroundStyle(Theme.textDim)
            Text("zsh").font(Theme.mono(10)).foregroundStyle(Theme.textDim)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.04))
        .overlay(Rectangle().fill(Theme.stroke).frame(height: 1), alignment: .bottom)
    }

    private func run() async {
        typed = 0
        showOutput = false
        try? await Task.sleep(for: .milliseconds(280))
        let count = command.count
        for i in 0...count {
            guard !Task.isCancelled else { return }
            typed = i
            // Type punctuation a touch slower so it reads like real typing.
            try? await Task.sleep(for: .milliseconds(24))
        }
        try? await Task.sleep(for: .milliseconds(280))
        guard !Task.isCancelled else { return }
        withAnimation(.easeOut(duration: 0.4)) { showOutput = true }
    }
}
