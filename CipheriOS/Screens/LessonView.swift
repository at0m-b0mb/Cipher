import SwiftUI

/// The lesson player: a hero header, the data-driven content blocks (text,
/// terminals, callouts, animations, checkpoints), then the end-of-lesson quiz.
struct LessonView: View {
    let lessonID: String

    @EnvironmentObject private var progress: ProgressStore
    @State private var showQuiz = false

    private var lesson: Lesson? { Curriculum.lesson(id: lessonID) }
    private var accent: Color { Curriculum.track(forLesson: lessonID)?.accent ?? Theme.teal }

    var body: some View {
        ZStack {
            CircuitBackground(tint: accent)
            if let lesson {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header(lesson)
                        ForEach(Array(lesson.blocks.enumerated()), id: \.offset) { _, block in
                            LessonBlockView(block: block, accent: accent)
                                .scrollEntrance()
                        }
                        quizCTA(lesson)
                            .scrollEntrance()
                    }
                    .padding(18)
                    .padding(.bottom, 36)
                }
                .sheet(isPresented: $showQuiz) {
                    QuizView(lesson: lesson, accent: accent)
                        .environmentObject(progress)
                }
            } else {
                Text("Lesson not found").foregroundStyle(Theme.textDim)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private func header(_ lesson: Lesson) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                DifficultyPips(difficulty: lesson.difficulty)
                Text(lesson.difficulty.label).font(Theme.mono(10, .bold)).foregroundStyle(lesson.difficulty.tint)
                Spacer()
                Label("\(lesson.minutes) min", systemImage: "clock").font(Theme.mono(10)).foregroundStyle(Theme.textDim)
                if progress.isComplete(lesson.id) {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.green)
                }
            }
            DecodeText(text: lesson.title)
            Text(lesson.subtitle)
                .font(.system(size: 15))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if !lesson.animations.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        ForEach(lesson.animations, id: \.self) { a in
                            AccentChip(text: a.label, systemImage: "play.circle.fill", color: accent)
                        }
                    }
                }
            }
            Rectangle().fill(Theme.stroke).frame(height: 1).padding(.top, 2)
        }
    }

    private func quizCTA(_ lesson: Lesson) -> some View {
        let done = progress.isComplete(lesson.id)
        let best = progress.bestQuizScore[lesson.id]
        return VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: done ? "checkmark.seal.fill" : "checklist")
                    .font(.system(size: 22)).foregroundStyle(done ? Theme.green : accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(done ? "Lesson complete" : "Check your understanding")
                        .font(Theme.rounded(16, .bold)).foregroundStyle(Theme.textPrimary)
                    Text(done && best != nil ? "Best score: \(best!)% · retake anytime"
                                             : "\(lesson.quiz.count) questions to lock it in")
                        .font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
            }
            Button {
                showQuiz = true
            } label: {
                Text(done ? "Retake quiz" : "Start quiz")
                    .font(Theme.rounded(16, .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(accent.opacity(0.4), lineWidth: 1))
        .padding(.top, 8)
    }
}

private extension View {
    /// Content blocks drift up and fade in as they scroll into view, and fade
    /// slightly as they leave — keeps long lessons feeling alive without
    /// distracting from reading.
    func scrollEntrance() -> some View {
        scrollTransition(.interactive) { content, phase in
            content
                .opacity(phase.isIdentity ? 1 : 0.25)
                .offset(y: phase == .bottomTrailing ? 16 : 0)
                .scaleEffect(phase.isIdentity ? 1 : 0.985)
        }
    }
}
