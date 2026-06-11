import SwiftUI
import UIKit

/// End-of-lesson quiz. Answer every question, then finish to score it, bank XP,
/// and mark the lesson complete.
struct QuizView: View {
    let lesson: Lesson
    var accent: Color = Theme.teal

    @EnvironmentObject private var progress: ProgressStore
    @Environment(\.dismiss) private var dismiss

    @State private var results: [String: Bool] = [:]
    @State private var finished = false
    @State private var displayedScore = 0
    @State private var revealStats = false

    private var total: Int { lesson.quiz.count }
    private var correctCount: Int { results.values.filter { $0 }.count }
    private var allAnswered: Bool { results.count >= total }
    private var score: Int { total == 0 ? 0 : Int((Double(correctCount) / Double(total) * 100).rounded()) }
    private var passed: Bool { score >= 70 }

    var body: some View {
        NavigationStack {
            ZStack {
                CircuitBackground(tint: accent)
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("KNOWLEDGE CHECK").font(Theme.mono(11, .bold)).tracking(1.5).foregroundStyle(accent)
                            Text(lesson.title).font(Theme.rounded(22, .bold)).foregroundStyle(Theme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        quizProgress

                        ForEach(Array(lesson.quiz.enumerated()), id: \.element.id) { idx, q in
                            VStack(alignment: .leading, spacing: 10) {
                                Text("QUESTION \(idx + 1) / \(total)")
                                    .font(Theme.mono(10, .bold)).foregroundStyle(Theme.textDim)
                                QuestionCard(question: q, accent: accent) { correct in
                                    withAnimation { results[q.id] = correct }
                                }
                            }
                            .cipherCard()
                        }

                        Button {
                            progress.recordQuiz(lessonID: lesson.id, scorePercent: score)
                            progress.markComplete(lesson.id)
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { finished = true }
                        } label: {
                            Text(allAnswered ? "Finish quiz" : "Answer all \(total) questions")
                                .font(Theme.rounded(16, .bold))
                                .foregroundStyle(allAnswered ? .black : Theme.textDim)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(allAnswered ? accent : Theme.surfaceHi, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(!allAnswered)
                        .padding(.top, 4)
                    }
                    .padding(18)
                    .padding(.bottom, 30)
                }

                if finished { resultOverlay }
            }
            .navigationTitle("Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }.foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }

    /// Slim bar tracking how many questions are answered so far.
    private var quizProgress: some View {
        let answered = results.count
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(answered)/\(total) ANSWERED")
                    .font(Theme.mono(10, .bold)).tracking(1).foregroundStyle(Theme.textDim)
                Spacer()
                if allAnswered {
                    Text("READY TO SCORE")
                        .font(Theme.mono(10, .bold)).foregroundStyle(Theme.green)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.surfaceHi)
                    Capsule()
                        .fill(Theme.accentGradient(accent))
                        .frame(width: max(7, geo.size.width * (total == 0 ? 0 : CGFloat(answered) / CGFloat(total))))
                        .shadow(color: accent.opacity(0.5), radius: 4)
                }
            }
            .frame(height: 7)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: answered)
    }

    private var resultOverlay: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            VStack(spacing: 18) {
                ProgressRing(progress: Double(displayedScore) / 100, color: passed ? Theme.green : Theme.amber,
                             lineWidth: 12, size: 120, label: "\(displayedScore)%")
                    .padding(.top, 6)
                Text(passed ? "Nicely done." : "Good effort.")
                    .font(Theme.rounded(24, .bold)).foregroundStyle(Theme.textPrimary)
                Text(passed ? "You scored \(correctCount)/\(total). Lesson banked."
                            : "You scored \(correctCount)/\(total). Review the explanations and retake to raise your score.")
                    .font(.system(size: 14)).foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 22) {
                    resultStat("+\(100 + score / 2)", "XP earned", "bolt.fill", accent)
                    resultStat(progress.rank.title, "current rank", progress.rank.glyph, Theme.amber)
                }
                .opacity(revealStats ? 1 : 0)
                .offset(y: revealStats ? 0 : 14)

                Button { dismiss() } label: {
                    Text("Done")
                        .font(Theme.rounded(16, .bold)).foregroundStyle(.black)
                        .frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .opacity(revealStats ? 1 : 0)
                .offset(y: revealStats ? 0 : 14)
            }
            .padding(24)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(accent.opacity(0.5), lineWidth: 1))
            .padding(28)
            .transition(.scale.combined(with: .opacity))

            if passed {
                ConfettiBurst().ignoresSafeArea()
            }
        }
        .task { await celebrate() }
    }

    /// Haptic, count the ring up to the score, then reveal the stats row.
    private func celebrate() async {
        UINotificationFeedbackGenerator().notificationOccurred(passed ? .success : .warning)
        try? await Task.sleep(for: .milliseconds(250))
        let step = max(1, score / 24)
        var s = 0
        while s < score {
            s = min(score, s + step)
            displayedScore = s
            try? await Task.sleep(for: .milliseconds(30))
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) { revealStats = true }
    }

    private func resultStat(_ value: String, _ caption: String, _ glyph: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: glyph).font(.system(size: 16, weight: .bold)).foregroundStyle(color)
            Text(value).font(Theme.rounded(15, .bold)).foregroundStyle(Theme.textPrimary)
            Text(caption).font(Theme.mono(9)).foregroundStyle(Theme.textDim)
        }
    }
}
