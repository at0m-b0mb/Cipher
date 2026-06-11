import SwiftUI

/// The lesson player: a slim reading-progress bar, a hero header, the data-driven
/// content blocks (text, terminals, callouts, animations, checkpoints), the
/// end-of-lesson quiz, and an "Up next" hand-off to keep learning on a phone.
struct LessonView: View {
    let lessonID: String

    @EnvironmentObject private var progress: ProgressStore
    @State private var showQuiz = false
    @State private var readProgress: CGFloat = 0

    private var lesson: Lesson? { Curriculum.lesson(id: lessonID) }
    private var accent: Color { Curriculum.track(forLesson: lessonID)?.accent ?? Theme.teal }

    var body: some View {
        ZStack(alignment: .top) {
            CircuitBackground(tint: accent)
            if let lesson {
                GeometryReader { outer in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            header(lesson)
                            ForEach(Array(lesson.blocks.enumerated()), id: \.offset) { _, block in
                                LessonBlockView(block: block, accent: accent)
                                    .scrollEntrance()
                            }
                            quizCTA(lesson)
                                .scrollEntrance()
                            upNext(after: lesson)
                                .scrollEntrance()
                        }
                        .padding(18)
                        .padding(.bottom, 36)
                        .background(
                            GeometryReader { inner in
                                Color.clear.preference(
                                    key: ReadProgressKey.self,
                                    value: scrollProgress(viewport: outer.size.height, content: inner))
                            }
                        )
                    }
                    .coordinateSpace(name: "lessonScroll")
                }
                .onPreferenceChange(ReadProgressKey.self) { readProgress = $0 }
                .sheet(isPresented: $showQuiz) {
                    QuizView(lesson: lesson, accent: accent)
                        .environmentObject(progress)
                }
            } else {
                Text("Lesson not found").foregroundStyle(Theme.textDim)
            }

            readingBar
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    // MARK: Reading-progress bar

    private var readingBar: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Rectangle().fill(Theme.stroke.opacity(0.4))
                Rectangle()
                    .fill(Theme.accentGradient(accent))
                    .frame(width: max(0, g.size.width * readProgress))
                    .shadow(color: accent.opacity(0.6), radius: 4)
            }
        }
        .frame(height: 3)
        .animation(.easeOut(duration: 0.12), value: readProgress)
        .accessibilityHidden(true)
    }

    private func scrollProgress(viewport: CGFloat, content: GeometryProxy) -> CGFloat {
        let minY = content.frame(in: .named("lessonScroll")).minY
        let scrollable = max(1, content.size.height - viewport)
        return min(1, max(0, -minY / scrollable))
    }

    // MARK: Header

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

    // MARK: Quiz call-to-action

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

    // MARK: Up-next hand-off

    @ViewBuilder private func upNext(after lesson: Lesson) -> some View {
        if let next = Curriculum.lessonAfter(id: lesson.id) {
            let nextAccent = Curriculum.track(forLesson: next.id)?.accent ?? Theme.teal
            let crossesTrack = Curriculum.track(forLesson: next.id)?.id != Curriculum.track(forLesson: lesson.id)?.id
            NavigationLink(value: CipherRoute.lesson(next.id)) {
                HStack(spacing: 13) {
                    ZStack {
                        Circle().fill(nextAccent.opacity(0.16)).frame(width: 44, height: 44)
                        Image(systemName: "forward.fill").font(.system(size: 17, weight: .bold)).foregroundStyle(nextAccent)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(crossesTrack ? "UP NEXT · NEW TRACK" : "UP NEXT")
                            .font(Theme.mono(9, .bold)).tracking(1.4).foregroundStyle(nextAccent)
                        Text(next.title).font(Theme.rounded(16, .bold)).foregroundStyle(Theme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 6) {
                            if let m = next.parentModule {
                                Text(m.title).font(Theme.mono(10)).foregroundStyle(Theme.textSecondary)
                            }
                            Text("· \(next.minutes) min").font(Theme.mono(10)).foregroundStyle(Theme.textDim)
                        }
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.textDim)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(nextAccent.opacity(0.35), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }
}

/// Carries the lesson's scroll-read fraction (0…1) up to the progress bar.
private struct ReadProgressKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
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
