import SwiftUI

// MARK: - Learning paths list

/// Goal-oriented routes through the curriculum. Where the Learn tab is the
/// reference (organised by subject), this is the journey (organised by where the
/// learner wants to end up) — the front door for an aspiring student.
struct LearningPathsView: View {
    @EnvironmentObject private var progress: ProgressStore

    private func completion(_ path: LearningPath) -> Double {
        guard path.lessonCount > 0 else { return 0 }
        let done = path.lessons.filter { progress.isComplete($0.id) }.count
        return Double(done) / Double(path.lessonCount)
    }

    var body: some View {
        ZStack {
            CircuitBackground(tint: Theme.amber)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Learning Paths").font(Theme.rounded(30, .bold)).foregroundStyle(Theme.textPrimary)
                        Text("Guided routes through the curriculum, built around where you want to go. Pick a goal and follow it lesson by lesson — your progress is tracked the whole way.")
                            .font(.system(size: 14)).foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    ForEach(LearningPaths.all) { path in
                        NavigationLink(value: CipherRoute.path(path.id)) {
                            PathCard(path: path, completion: completion(path))
                        }
                        .buttonStyle(.plain)
                    }

                    CalloutView(kind: .tip, text: "New to all this? Start with the Absolute Beginner path — it assumes zero knowledge and builds the mental model everything else rests on.")
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

// MARK: - Path card

struct PathCard: View {
    let path: LearningPath
    let completion: Double

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(path.accent.opacity(0.16)).frame(width: 58, height: 58)
                Image(systemName: path.systemImage).font(.system(size: 23, weight: .bold)).foregroundStyle(path.accent)
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(path.title).font(Theme.rounded(18, .bold)).foregroundStyle(Theme.textPrimary)
                Text(path.goal)
                    .font(.system(size: 12.5)).foregroundStyle(Theme.textSecondary)
                    .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    AccentChip(text: path.level, color: path.accent)
                    Label("\(path.lessonCount) lessons", systemImage: "doc.text")
                        .font(Theme.mono(9)).foregroundStyle(Theme.textDim)
                    Label("~\(path.totalMinutes)m", systemImage: "clock")
                        .font(Theme.mono(9)).foregroundStyle(Theme.textDim)
                }
            }
            Spacer(minLength: 4)
            ProgressRing(progress: completion, color: path.accent, lineWidth: 6, size: 50,
                         label: "\(Int(completion * 100))%")
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(path.accent.opacity(0.35), lineWidth: 1))
    }
}

// MARK: - Compact path card (dashboard carousel)

struct PathMiniCard: View {
    let path: LearningPath
    let completion: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(path.accent.opacity(0.16)).frame(width: 42, height: 42)
                    Image(systemName: path.systemImage).font(.system(size: 18, weight: .bold)).foregroundStyle(path.accent)
                }
                Spacer()
                ProgressRing(progress: completion, color: path.accent, lineWidth: 5, size: 38,
                             label: "\(Int(completion * 100))%")
            }
            Text(path.title)
                .font(Theme.rounded(15, .bold)).foregroundStyle(Theme.textPrimary)
                .lineLimit(2).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            AccentChip(text: path.level, color: path.accent)
        }
        .padding(14)
        .frame(width: 172, height: 152, alignment: .topLeading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(path.accent.opacity(0.35), lineWidth: 1))
    }
}

// MARK: - Path detail (the guided journey)

struct PathDetailView: View {
    let pathID: String
    @EnvironmentObject private var progress: ProgressStore

    private var path: LearningPath? { LearningPaths.path(id: pathID) }

    var body: some View {
        ZStack {
            if let path {
                CircuitBackground(tint: path.accent)
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header(path)
                        stepList(path)
                    }
                    .padding(18)
                    .padding(.bottom, 32)
                }
            } else {
                Text("Path not found").foregroundStyle(Theme.textDim)
            }
        }
        .navigationTitle(path?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private func frac(_ path: LearningPath) -> Double {
        guard path.lessonCount > 0 else { return 0 }
        return Double(path.lessons.filter { progress.isComplete($0.id) }.count) / Double(path.lessonCount)
    }

    private func header(_ path: LearningPath) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous).fill(path.accent.opacity(0.16))
                        .frame(width: 64, height: 64)
                    Image(systemName: path.systemImage).font(.system(size: 28, weight: .bold)).foregroundStyle(path.accent)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(path.title).font(Theme.rounded(23, .bold)).foregroundStyle(Theme.textPrimary)
                    Text(path.goal).font(.system(size: 12.5)).foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 14) {
                ProgressRing(progress: frac(path), color: path.accent, lineWidth: 7, size: 56,
                             label: "\(Int(frac(path) * 100))%")
                VStack(alignment: .leading, spacing: 4) {
                    Label(path.level, systemImage: "chart.bar.fill").font(Theme.mono(11)).foregroundStyle(Theme.textSecondary)
                    Label("\(path.lessonCount) lessons", systemImage: "doc.text.fill").font(Theme.mono(11)).foregroundStyle(Theme.textSecondary)
                    Label("~\(path.totalMinutes) min total", systemImage: "clock.fill").font(Theme.mono(11)).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
            }
            continueButton(path)
        }
        .cipherCard()
    }

    @ViewBuilder private func continueButton(_ path: LearningPath) -> some View {
        if let next = path.lessons.first(where: { !progress.isComplete($0.id) }) {
            NavigationLink(value: CipherRoute.lesson(next.id)) {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                    Text(frac(path) == 0 ? "Start path" : "Continue").font(Theme.rounded(15, .bold))
                    Spacer(minLength: 6)
                    Text(next.title).font(Theme.mono(10)).foregroundStyle(.black.opacity(0.7)).lineLimit(1)
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 16).padding(.vertical, 13)
                .background(path.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: path.accent.opacity(0.4), radius: 8)
            }
            .buttonStyle(.plain)
        } else {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                Text("Path complete — nice work!").font(Theme.rounded(15, .bold))
            }
            .foregroundStyle(Theme.green)
            .frame(maxWidth: .infinity).padding(.vertical, 13)
            .background(Theme.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.green.opacity(0.4), lineWidth: 1))
        }
    }

    private func stepList(_ path: LearningPath) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "The Path · \(path.lessonCount) steps", systemImage: "signpost.right.fill", accent: path.accent)
            ForEach(Array(path.lessons.enumerated()), id: \.element.id) { idx, lesson in
                let track = Curriculum.track(forLesson: lesson.id)
                HStack(spacing: 10) {
                    Text("\(idx + 1)")
                        .font(Theme.mono(12, .bold))
                        .foregroundStyle(progress.isComplete(lesson.id) ? Theme.green : path.accent)
                        .frame(width: 20)
                    NavigationLink(value: CipherRoute.lesson(lesson.id)) {
                        LessonRow(lesson: lesson, completed: progress.isComplete(lesson.id),
                                  accent: track?.accent ?? path.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
