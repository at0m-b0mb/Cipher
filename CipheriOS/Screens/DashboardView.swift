import SwiftUI

struct DashboardView: View {
    var goToLearn: () -> Void = {}
    var goToPaths: () -> Void = {}
    var goToLabs: () -> Void = {}
    @EnvironmentObject private var progress: ProgressStore

    private var featuredAnimationID: AnimationID {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        return AnimationID.allCases[day % AnimationID.allCases.count]
    }

    var body: some View {
        ZStack {
            CircuitBackground(tint: Theme.teal)
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    rankHeader
                    statsRow
                    continueCard
                    pathsSection
                    labsSection
                    tracksSection
                    termOfDay
                    featured
                }
                .padding(18)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("")
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: Rank header

    private var rankHeader: some View {
        let r = progress.rank
        let next = Rank.next(after: r)
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("CIPHER").font(Theme.mono(14, .black)).tracking(5).foregroundStyle(Theme.teal)
                Spacer()
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill").foregroundStyle(Theme.amber).font(.system(size: 13))
                    Text("\(progress.streak)").font(Theme.rounded(15, .bold)).foregroundStyle(Theme.textPrimary)
                    Text("day streak").font(Theme.mono(9)).foregroundStyle(Theme.textDim)
                }
            }
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theme.amber.opacity(0.16)).frame(width: 54, height: 54)
                    Image(systemName: r.glyph).font(.system(size: 22, weight: .bold)).foregroundStyle(Theme.amber)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(r.title).font(Theme.rounded(22, .bold)).foregroundStyle(Theme.textPrimary)
                    Text("\(progress.xp) XP earned").font(Theme.mono(11)).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
            }
            if let next {
                VStack(alignment: .leading, spacing: 6) {
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Theme.surfaceHi).frame(height: 8)
                            Capsule().fill(Theme.accentGradient(Theme.amber))
                                .frame(width: max(8, g.size.width * progress.xpIntoRank), height: 8)
                        }
                    }
                    .frame(height: 8)
                    Text("\(max(0, next.xpRequired - progress.xp)) XP to \(next.title)")
                        .font(Theme.mono(9)).foregroundStyle(Theme.textDim)
                }
            }
        }
        .cipherCard()
    }

    // MARK: Stats

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatBadge(value: "\(progress.completedLessons.count)/\(Curriculum.lessonCount)",
                      caption: "LESSONS", systemImage: "checkmark.seal.fill", color: Theme.teal)
            StatBadge(value: "\(Int(progress.overallCompletion * 100))%",
                      caption: "COMPLETE", systemImage: "chart.pie.fill", color: Theme.violet)
            StatBadge(value: "\(progress.longestStreak)d",
                      caption: "BEST RUN", systemImage: "flame.fill", color: Theme.amber)
        }
    }

    // MARK: Continue

    @ViewBuilder private var continueCard: some View {
        if let next = progress.nextLesson {
            let track = Curriculum.track(forLesson: next.id)
            let accent = track?.accent ?? Theme.teal
            NavigationLink(value: CipherRoute.lesson(next.id)) {
                HStack(spacing: 14) {
                    Image(systemName: "play.circle.fill").font(.system(size: 34)).foregroundStyle(.black)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(progress.completedLessons.isEmpty ? "START HERE" : "CONTINUE")
                            .font(Theme.mono(10, .bold)).tracking(1.5).foregroundStyle(.black.opacity(0.7))
                        Text(next.title).font(Theme.rounded(18, .bold)).foregroundStyle(.black)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(track?.title ?? "").font(Theme.mono(10)).foregroundStyle(.black.opacity(0.7))
                    }
                    Spacer(minLength: 0)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.accentGradient(accent), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: accent.opacity(0.4), radius: 14, y: 6)
            }
            .buttonStyle(.plain)
        } else {
            HStack {
                Image(systemName: "trophy.fill").font(.system(size: 30)).foregroundStyle(Theme.amber)
                VStack(alignment: .leading) {
                    Text("Curriculum complete").font(Theme.rounded(18, .bold)).foregroundStyle(Theme.textPrimary)
                    Text("Every lesson done — replay any animation anytime.").font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
            }
            .cipherCard()
        }
    }

    // MARK: Learning paths

    private func pathCompletion(_ p: LearningPath) -> Double {
        guard p.lessonCount > 0 else { return 0 }
        return Double(p.lessons.filter { progress.isComplete($0.id) }.count) / Double(p.lessonCount)
    }

    private var pathsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Learning paths", systemImage: "map.fill", accent: Theme.amber)
                Button(action: goToPaths) {
                    Text("All").font(Theme.mono(11, .bold)).foregroundStyle(Theme.amber)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(LearningPaths.all.prefix(5)) { path in
                        NavigationLink(value: CipherRoute.path(path.id)) {
                            PathMiniCard(path: path, completion: pathCompletion(path))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 1).padding(.bottom, 4)
            }
        }
    }

    // MARK: Hands-on labs

    private var labsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Hands-on labs", systemImage: "flask.fill", accent: Theme.green)
                Button(action: goToLabs) {
                    Text("All").font(Theme.mono(11, .bold)).foregroundStyle(Theme.green)
                }
            }
            Text("\(progress.completedLabs.count) of \(Labs.count) done — practise the decisions, not just the commands.")
                .font(.system(size: 12.5)).foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(suggestedLabs) { lab in
                        NavigationLink(value: CipherRoute.lab(lab.id)) {
                            LabMiniCard(lab: lab, completed: progress.isLabComplete(lab.id))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 1).padding(.bottom, 4)
            }
        }
    }

    /// Unfinished labs first (easiest-first), topped up with finished ones so the
    /// carousel is never empty once the learner has done them all.
    private var suggestedLabs: [InteractiveLab] {
        let todo = Labs.all.filter { !progress.isLabComplete($0.id) }
        return Array((todo + Labs.all.filter { progress.isLabComplete($0.id) }).prefix(6))
    }

    // MARK: Tracks

    private var tracksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Learning tracks", systemImage: "map.fill", accent: Theme.teal)
                Button(action: goToLearn) {
                    Text("All").font(Theme.mono(11, .bold)).foregroundStyle(Theme.teal)
                }
            }
            ForEach(Curriculum.tracks) { track in
                NavigationLink(value: CipherRoute.track(track.id)) {
                    TrackCard(track: track, completion: progress.completion(of: track))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Term of the day

    private var termOfDay: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Term of the day", systemImage: "character.book.closed.fill", accent: Theme.teal)
            FlashcardCardView(card: Flashcards.termOfTheDay())
        }
    }

    // MARK: Featured animation

    private var featured: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Featured animation", systemImage: "play.square.stack.fill", accent: Theme.teal)
            AnimationView(id: featuredAnimationID)
        }
    }
}
