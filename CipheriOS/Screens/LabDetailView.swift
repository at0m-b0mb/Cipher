import SwiftUI

/// A standalone lab, played full-screen: the briefing, the lab itself, and — once
/// finished — the debrief that turns "I picked the right commands" into "I
/// understand why, and I know how the other side sees this".
struct LabDetailView: View {
    let labID: String
    @EnvironmentObject private var progress: ProgressStore
    @State private var finished = false

    private var lab: InteractiveLab? { Labs.lab(id: labID) }

    var body: some View {
        ZStack {
            CircuitBackground(tint: lab?.track.accent ?? Theme.green)
            if let lab {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header(lab)
                        if !lab.scenario.isEmpty { briefing(lab) }
                        InteractiveLabView(lab: lab, accent: lab.track.accent, compact: true) {
                            withAnimation(.easeOut(duration: 0.35)) { finished = true }
                        }
                        if finished, !lab.debrief.isEmpty { debrief(lab) }
                        if let lessonID = lab.relatedLessonID,
                           let lesson = Curriculum.lesson(id: lessonID) {
                            theoryLink(lesson, accent: lab.track.accent)
                        }
                    }
                    .padding(18)
                    .padding(.bottom, 40)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "questionmark.folder").font(.system(size: 30)).foregroundStyle(Theme.textDim)
                    Text("Lab not found").font(Theme.rounded(17, .bold)).foregroundStyle(Theme.textPrimary)
                }
            }
        }
        .navigationTitle(lab?.title ?? "Lab")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { finished = progress.isLabComplete(labID) }
    }

    // MARK: Sections

    private func header(_ lab: InteractiveLab) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                AccentChip(text: lab.track.title, systemImage: lab.track.glyph, color: lab.track.accent)
                if progress.isLabComplete(lab.id) {
                    AccentChip(text: "Completed", systemImage: "checkmark.seal.fill", color: Theme.green)
                }
                Spacer(minLength: 0)
            }
            Text(lab.title).font(Theme.rounded(26, .bold)).foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 10) {
                DifficultyPips(difficulty: lab.difficulty)
                Text(lab.difficulty.label).font(Theme.mono(10)).foregroundStyle(lab.difficulty.tint)
                Label("\(lab.minutes) min", systemImage: "clock").font(Theme.mono(10)).foregroundStyle(Theme.textDim)
                Label("\(lab.steps.count) steps", systemImage: "list.number").font(Theme.mono(10)).foregroundStyle(Theme.textDim)
            }
            if !lab.tools.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 10)).foregroundStyle(Theme.textDim)
                    Text(lab.tools.joined(separator: " · "))
                        .font(Theme.mono(10.5)).foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func briefing(_ lab: InteractiveLab) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 7) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 12, weight: .bold)).foregroundStyle(lab.track.accent)
                Text("BRIEFING").font(Theme.mono(10, .bold)).tracking(1.2).foregroundStyle(lab.track.accent)
            }
            Text(lab.scenario.inlineMarkdown)
                .font(.system(size: 14)).foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(lab.track.accent.opacity(0.25), lineWidth: 1))
    }

    private func debrief(_ lab: InteractiveLab) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 7) {
                Image(systemName: "lightbulb.fill").font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.amber)
                Text("DEBRIEF").font(Theme.mono(10, .bold)).tracking(1.2).foregroundStyle(Theme.amber)
            }
            Text(lab.debrief.inlineMarkdown)
                .font(.system(size: 14)).foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.amber.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(Theme.amber.opacity(0.3), lineWidth: 1))
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private func theoryLink(_ lesson: Lesson, accent: Color) -> some View {
        NavigationLink(value: CipherRoute.lesson(lesson.id)) {
            HStack(spacing: 12) {
                Image(systemName: "book.fill").font(.system(size: 15, weight: .bold)).foregroundStyle(accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("The theory behind this lab").font(Theme.mono(9.5, .bold)).tracking(1).foregroundStyle(Theme.textDim)
                    Text(lesson.title).font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.textDim)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Theme.stroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
