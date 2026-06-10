import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var progress: ProgressStore
    @State private var confirmReset = false

    var body: some View {
        ZStack {
            CircuitBackground(tint: Theme.amber)
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    rankCard
                    statsGrid
                    trackProgress
                    glossaryLink
                    aboutCard
                    resetButton
                }
                .padding(18)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("")
        .toolbar(.hidden, for: .navigationBar)
        .alert("Reset all progress?", isPresented: $confirmReset) {
            Button("Reset", role: .destructive) { progress.resetAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears completed lessons, quiz scores and your streak. It can't be undone.")
        }
    }

    // MARK: Rank + ladder

    private var rankCard: some View {
        let r = progress.rank
        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theme.amber.opacity(0.16)).frame(width: 58, height: 58)
                    Image(systemName: r.glyph).font(.system(size: 24, weight: .bold)).foregroundStyle(Theme.amber)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(r.title).font(Theme.rounded(24, .bold)).foregroundStyle(Theme.textPrimary)
                    Text("\(progress.xp) XP").font(Theme.mono(12)).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
            }
            // Rank ladder
            VStack(spacing: 8) {
                ForEach(Rank.ladder) { rank in
                    let reached = progress.xp >= rank.xpRequired
                    let current = rank.id == r.id
                    HStack(spacing: 10) {
                        Image(systemName: reached ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(reached ? Theme.amber : Theme.textDim).font(.system(size: 14))
                        Text(rank.title)
                            .font(Theme.mono(12, current ? .bold : .regular))
                            .foregroundStyle(current ? Theme.amber : (reached ? Theme.textPrimary : Theme.textDim))
                        Spacer()
                        Text("\(rank.xpRequired) XP").font(Theme.mono(10)).foregroundStyle(Theme.textDim)
                    }
                }
            }
        }
        .cipherCard()
    }

    // MARK: Stats grid

    private var statsGrid: some View {
        let cols = [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: cols, spacing: 12) {
            StatBadge(value: "\(progress.completedLessons.count)/\(Curriculum.lessonCount)",
                      caption: "LESSONS DONE", systemImage: "checkmark.seal.fill", color: Theme.teal)
            StatBadge(value: "\(progress.bestQuizScore.count)",
                      caption: "QUIZZES TAKEN", systemImage: "checklist", color: Theme.violet)
            StatBadge(value: "\(progress.streak)d",
                      caption: "CURRENT STREAK", systemImage: "flame.fill", color: Theme.amber)
            StatBadge(value: "\(progress.longestStreak)d",
                      caption: "LONGEST STREAK", systemImage: "trophy.fill", color: Theme.green)
        }
    }

    // MARK: Per-track progress

    private var trackProgress: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Progress by track", systemImage: "chart.bar.fill", accent: Theme.amber)
            ForEach(Curriculum.tracks) { track in
                let c = progress.completion(of: track)
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Image(systemName: track.kind.glyph).foregroundStyle(track.accent).font(.system(size: 12))
                        Text(track.title).font(Theme.mono(12, .bold)).foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text("\(Int(c * 100))%").font(Theme.mono(11, .bold)).foregroundStyle(track.accent)
                    }
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Theme.surfaceHi).frame(height: 7)
                            Capsule().fill(track.accent).frame(width: max(7, g.size.width * c), height: 7)
                        }
                    }
                    .frame(height: 7)
                }
            }
        }
        .cipherCard()
    }

    private var glossaryLink: some View {
        NavigationLink { GlossaryView() } label: {
            HStack(spacing: 12) {
                Image(systemName: "character.book.closed.fill").font(.system(size: 18)).foregroundStyle(Theme.teal).frame(width: 26)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Glossary").font(Theme.rounded(16, .bold)).foregroundStyle(Theme.textPrimary)
                    Text("\(Flashcards.deck.count) terms, searchable").font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.textDim)
            }
            .cipherCard()
        }
        .buttonStyle(.plain)
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "About & ethics", systemImage: "checkmark.shield.fill", accent: Theme.amber)
            Text("Cipher teaches offensive and defensive security for one purpose: to build skilled, ethical practitioners. Everything here is meant for systems you own or are explicitly authorized to test, and for defending the systems you protect.")
                .font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Text("Unauthorized access to computer systems is illegal. Use a lab.")
                .font(Theme.mono(11, .bold)).foregroundStyle(Theme.red)
        }
        .cipherCard()
    }

    private var resetButton: some View {
        Button(role: .destructive) { confirmReset = true } label: {
            Text("Reset progress")
                .font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.red)
                .frame(maxWidth: .infinity).padding(.vertical, 13)
                .background(Theme.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.red.opacity(0.4), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
