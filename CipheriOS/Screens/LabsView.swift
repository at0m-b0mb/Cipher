import SwiftUI

/// The Labs hub — every hands-on lab in the app, browsable and filterable.
///
/// Labs used to be reachable only by stumbling across them inside a lesson. This
/// screen makes practice a destination of its own: pick a side of the craft, pick
/// a level, and work a technique end to end.
struct LabsView: View {
    @EnvironmentObject private var progress: ProgressStore

    @State private var trackFilter: TrackKind? = nil
    @State private var unfinishedOnly = false

    private var filtered: [InteractiveLab] {
        Labs.all.filter { lab in
            (trackFilter == nil || lab.track == trackFilter)
            && (!unfinishedOnly || !progress.isLabComplete(lab.id))
        }
    }

    /// Labs grouped under their track, preserving `Labs.all`'s difficulty ramp.
    private var grouped: [(track: TrackKind, labs: [InteractiveLab])] {
        TrackKind.allCases.compactMap { kind in
            let labs = filtered.filter { $0.track == kind }
            return labs.isEmpty ? nil : (kind, labs)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                header
                filters

                if grouped.isEmpty {
                    emptyState
                } else {
                    ForEach(grouped, id: \.track) { group in
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "\(group.track.title) · \(group.labs.count)",
                                          systemImage: group.track.glyph,
                                          accent: group.track.accent)
                            ForEach(group.labs) { lab in
                                NavigationLink(value: CipherRoute.lab(lab.id)) {
                                    LabCard(lab: lab, completed: progress.isLabComplete(lab.id))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                CalloutView(kind: .warning, text: "These labs are simulations, so you can practise the decisions safely. Run the real commands only against your own lab machines, a platform built for it (Hack The Box, TryHackMe), or a scope you are **authorized in writing** to test.")
            }
            .padding(.bottom, 32)
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Labs").font(Theme.rounded(30, .bold)).foregroundStyle(Theme.textPrimary)
                Text("\(Labs.count) hands-on labs · about \(Labs.totalMinutes) minutes of practice. Reading a technique is not knowing it — work the decisions yourself.")
                    .font(.system(size: 14)).foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            ProgressRing(progress: progress.labCompletion,
                         color: Theme.green, lineWidth: 7, size: 62,
                         label: "\(Int(progress.labCompletion * 100))%")
        }
    }

    // MARK: Filters

    private var filters: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip(title: "All \(Labs.count)", accent: Theme.green, selected: trackFilter == nil) {
                        trackFilter = nil
                    }
                    ForEach(TrackKind.allCases, id: \.self) { kind in
                        let done = progress.labsCompleted(in: kind)
                        let total = Labs.labs(for: kind).count
                        if total > 0 {
                            filterChip(title: "\(kind.title) \(done)/\(total)",
                                       accent: kind.accent,
                                       selected: trackFilter == kind) {
                                trackFilter = trackFilter == kind ? nil : kind
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }

            Toggle(isOn: $unfinishedOnly) {
                Text("Unfinished only").font(Theme.mono(12, .medium)).foregroundStyle(Theme.textSecondary)
            }
            .toggleStyle(.switch)
            .tint(Theme.green)
        }
    }

    private func filterChip(title: String, accent: Color, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Theme.mono(11.5, .semibold))
                .foregroundStyle(selected ? Theme.background : accent)
                .padding(.horizontal, 11).padding(.vertical, 6)
                .background(selected ? accent : accent.opacity(0.13), in: Capsule())
                .overlay(Capsule().strokeBorder(accent.opacity(selected ? 0 : 0.4), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill").font(.system(size: 34)).foregroundStyle(Theme.green)
            Text("Nothing left here").font(Theme.rounded(18, .bold)).foregroundStyle(Theme.textPrimary)
            Text("You have finished every lab matching this filter. Turn off “Unfinished only” to replay one.")
                .font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .cipherCard()
    }
}

// MARK: - Lab card

/// One row in the Labs hub: what you'll do, how hard, and whether you've done it.
struct LabCard: View {
    let lab: InteractiveLab
    let completed: Bool

    private var accent: Color { lab.track.accent }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(completed ? Theme.green.opacity(0.16) : accent.opacity(0.14))
                        .frame(width: 32, height: 32)
                    Image(systemName: completed ? "checkmark" : "flask.fill")
                        .font(.system(size: completed ? 13 : 12, weight: .bold))
                        .foregroundStyle(completed ? Theme.green : accent)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(lab.title)
                        .font(Theme.rounded(16, .bold)).foregroundStyle(Theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(lab.goal)
                        .font(.system(size: 12.5)).foregroundStyle(Theme.textSecondary)
                        .lineLimit(3).fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.textDim)
            }

            HStack(spacing: 10) {
                DifficultyPips(difficulty: lab.difficulty)
                Text(lab.difficulty.label).font(Theme.mono(9.5)).foregroundStyle(lab.difficulty.tint)
                Text("·").foregroundStyle(Theme.textDim)
                Label("\(lab.steps.count) steps", systemImage: "list.number")
                    .font(Theme.mono(9.5)).foregroundStyle(Theme.textDim)
                Label("\(lab.minutes) min", systemImage: "clock")
                    .font(Theme.mono(9.5)).foregroundStyle(Theme.textDim)
                Spacer(minLength: 0)
            }

            if !lab.tools.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(lab.tools, id: \.self) { tool in
                            Text(tool)
                                .font(Theme.mono(10))
                                .foregroundStyle(accent)
                                .padding(.horizontal, 7).padding(.vertical, 3)
                                .background(accent.opacity(0.10), in: Capsule())
                        }
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder((completed ? Theme.green : accent).opacity(0.3), lineWidth: 1))
    }
}

// MARK: - Lab mini card

/// Compact lab card for the dashboard carousel.
struct LabMiniCard: View {
    let lab: InteractiveLab
    let completed: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: completed ? "checkmark.seal.fill" : "flask.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(completed ? Theme.green : lab.track.accent)
                Text(lab.track.title.uppercased())
                    .font(Theme.mono(8.5, .bold)).tracking(1).foregroundStyle(Theme.textDim)
                Spacer(minLength: 0)
            }
            Text(lab.title)
                .font(Theme.rounded(14.5, .bold)).foregroundStyle(Theme.textPrimary)
                .lineLimit(3).fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 0)
            HStack(spacing: 7) {
                DifficultyPips(difficulty: lab.difficulty)
                Text("\(lab.minutes)m").font(Theme.mono(9)).foregroundStyle(Theme.textDim)
            }
        }
        .padding(13)
        .frame(width: 178, height: 132, alignment: .topLeading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder((completed ? Theme.green : lab.track.accent).opacity(0.3), lineWidth: 1))
    }
}
