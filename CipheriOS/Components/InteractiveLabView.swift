import SwiftUI
import UIKit

/// A hands-on, tap-to-play lab. The learner reads a goal, then at each step picks
/// the right command from a few options; the correct choice runs in a simulated
/// terminal that accumulates as they progress. Wrong choices give feedback and
/// let them try again. Turns "read about it" into "do it".
struct InteractiveLabView: View {
    let lab: InteractiveLab
    var accent: Color = Theme.teal
    /// Drop the title/goal from the lab's own header. The standalone lab screen
    /// already shows both above it, so repeating them here says the same thing
    /// three times on one screen.
    var compact: Bool = false
    /// Called once the learner finishes, so a host screen can reveal a debrief.
    var onComplete: (() -> Void)? = nil

    @EnvironmentObject private var progress: ProgressStore
    @State private var stepIndex = 0
    @State private var hintShown = false
    @State private var transcript: [(cmd: String, out: String)] = []
    @State private var wrongPick: UUID? = nil
    @State private var feedback: (text: String, correct: Bool)? = nil
    @State private var finished = false
    @State private var shakes: CGFloat = 0

    private var current: LabStep? { finished || stepIndex >= lab.steps.count ? nil : lab.steps[stepIndex] }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            terminal
            if let current {
                stepPrompt(current)
                ForEach(current.options) { opt in
                    optionButton(opt)
                }
                if !current.hint.isEmpty { hintRow(current) }
            }
            if let feedback {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: feedback.correct ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(feedback.correct ? Theme.green : Theme.amber)
                    Text(feedback.text.inlineMarkdown)
                        .font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .transition(.opacity)
            }
            if finished { completionBanner }
        }
        .padding(16)
        .background(accent.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(accent.opacity(0.35), lineWidth: 1))
        .overlay(alignment: .top) {
            if finished {
                ConfettiBurst(count: 60, duration: 2.4)
                    .frame(height: 220).allowsHitTesting(false)
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "flask.fill").font(.system(size: 16, weight: .bold)).foregroundStyle(accent).frame(width: 22)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text("HANDS-ON LAB").font(Theme.mono(10, .bold)).tracking(1.2).foregroundStyle(accent)
                    Spacer()
                    if !finished {
                        Text("STEP \(min(stepIndex + 1, lab.steps.count)) / \(lab.steps.count)")
                            .font(Theme.mono(9, .bold)).foregroundStyle(Theme.textDim)
                    }
                }
                if !compact {
                    Text(lab.title).font(Theme.rounded(16, .bold)).foregroundStyle(Theme.textPrimary)
                    Label(lab.goal, systemImage: "target")
                        .font(Theme.mono(10)).foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: Terminal transcript

    private var terminal: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Circle().fill(Color(hex: "#FF5F57")).frame(width: 9, height: 9)
                Circle().fill(Color(hex: "#FEBC2E")).frame(width: 9, height: 9)
                Circle().fill(Color(hex: "#28C840")).frame(width: 9, height: 9)
                Spacer()
                Image(systemName: "terminal").font(.system(size: 10)).foregroundStyle(Theme.textDim)
                if finished || !transcript.isEmpty {
                    Button { reset() } label: {
                        Image(systemName: "arrow.clockwise").font(.system(size: 11, weight: .bold)).foregroundStyle(accent)
                    }
                    .buttonStyle(.plain).accessibilityLabel("Reset lab")
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(Color.white.opacity(0.04))
            .overlay(Rectangle().fill(Theme.stroke).frame(height: 1), alignment: .bottom)

            VStack(alignment: .leading, spacing: 8) {
                if transcript.isEmpty {
                    Text("// your commands will run here — pick the right one below")
                        .font(Theme.mono(11)).foregroundStyle(Theme.textDim)
                } else {
                    ForEach(Array(transcript.enumerated()), id: \.offset) { _, entry in
                        VStack(alignment: .leading, spacing: 3) {
                            (Text("root@lab").foregroundStyle(Theme.blue)
                             + Text(" $ ").foregroundStyle(Theme.green)
                             + Text(entry.cmd).foregroundStyle(Theme.textPrimary))
                                .font(Theme.mono(12))
                            if !entry.out.isEmpty {
                                Text(entry.out).font(Theme.mono(11.5)).foregroundStyle(Theme.green.opacity(0.9))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.stroke, lineWidth: 1))
    }

    // MARK: Step prompt + options

    private func stepPrompt(_ step: LabStep) -> some View {
        Text(step.instruction.inlineMarkdown)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Theme.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func optionButton(_ opt: LabOption) -> some View {
        let isWrong = wrongPick == opt.id
        return Button { choose(opt) } label: {
            HStack(spacing: 10) {
                Image(systemName: isWrong ? "xmark.circle.fill" : "chevron.right.circle")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isWrong ? Theme.red : accent)
                Text(opt.command)
                    .font(Theme.mono(12.5, .medium))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(isWrong ? Theme.red.opacity(0.12) : Theme.surfaceHi, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(isWrong ? Theme.red.opacity(0.7) : Theme.stroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .modifier(ShakeEffect(travel: isWrong ? 7 : 0, animatableData: shakes))
    }

    private var completionBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill").font(.system(size: 20)).foregroundStyle(Theme.green)
            VStack(alignment: .leading, spacing: 2) {
                Text("Lab complete!").font(Theme.rounded(16, .bold)).foregroundStyle(Theme.textPrimary)
                Text("You worked the whole technique end to end.").font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
        .padding(12)
        .background(Theme.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.green.opacity(0.4), lineWidth: 1))
    }

    // MARK: Actions

    private func choose(_ opt: LabOption) {
        guard current != nil else { return }
        if opt.correct {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.easeOut(duration: 0.25)) {
                transcript.append((cmd: opt.command, out: opt.output))
                feedback = (opt.feedback, true)
                wrongPick = nil
                hintShown = false
                if stepIndex >= lab.steps.count - 1 {
                    finished = true
                    progress.markLabComplete(lab.id)
                    onComplete?()
                } else {
                    stepIndex += 1
                }
            }
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            withAnimation(.easeOut(duration: 0.2)) { feedback = (opt.feedback, false); wrongPick = opt.id }
            withAnimation(.linear(duration: 0.45)) { shakes += 1 }
        }
    }

    private func reset() {
        withAnimation(.easeInOut(duration: 0.25)) {
            stepIndex = 0
            transcript = []
            wrongPick = nil
            feedback = nil
            finished = false
            hintShown = false
        }
    }

    // MARK: Hint

    @ViewBuilder private func hintRow(_ step: LabStep) -> some View {
        if hintShown {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lightbulb.fill").font(.system(size: 12)).foregroundStyle(Theme.amber)
                Text(step.hint.inlineMarkdown)
                    .font(.system(size: 12.5)).foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(10)
            .background(Theme.amber.opacity(0.09), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .transition(.opacity)
        } else {
            Button { withAnimation(.easeOut(duration: 0.2)) { hintShown = true } } label: {
                Label("Need a hint?", systemImage: "lightbulb")
                    .font(Theme.mono(11, .semibold)).foregroundStyle(Theme.amber)
            }
            .buttonStyle(.plain)
        }
    }
}
