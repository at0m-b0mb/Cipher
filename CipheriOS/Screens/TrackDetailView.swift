import SwiftUI

struct TrackDetailView: View {
    let trackID: String
    @EnvironmentObject private var progress: ProgressStore

    private var track: Track? { Curriculum.tracks.first { $0.id == trackID } }

    var body: some View {
        ZStack {
            if let track {
                CircuitBackground(tint: track.accent)
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header(track)
                        ForEach(track.modules) { module in
                            moduleSection(module, accent: track.accent)
                        }
                    }
                    .padding(18)
                    .padding(.bottom, 32)
                }
            } else {
                Text("Track not found").foregroundStyle(Theme.textDim)
            }
        }
        .navigationTitle(track?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private func header(_ track: Track) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous).fill(track.accent.opacity(0.16))
                        .frame(width: 64, height: 64)
                    Image(systemName: track.kind.glyph).font(.system(size: 28, weight: .bold)).foregroundStyle(track.accent)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.title).font(Theme.rounded(24, .bold)).foregroundStyle(Theme.textPrimary)
                    Text(track.tagline).font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 14) {
                ProgressRing(progress: progress.completion(of: track), color: track.accent, lineWidth: 7, size: 56,
                             label: "\(Int(progress.completion(of: track) * 100))%")
                VStack(alignment: .leading, spacing: 4) {
                    Label("\(track.lessons.count) lessons", systemImage: "doc.text.fill").font(Theme.mono(11)).foregroundStyle(Theme.textSecondary)
                    Label("\(track.modules.count) modules", systemImage: "square.stack.3d.up.fill").font(Theme.mono(11)).foregroundStyle(Theme.textSecondary)
                    Label("~\(track.totalMinutes) min total", systemImage: "clock.fill").font(Theme.mono(11)).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
            }
        }
        .cipherCard()
    }

    private func moduleSection(_ module: Module, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 11) {
                Image(systemName: module.systemImage).font(.system(size: 18, weight: .semibold)).foregroundStyle(accent)
                    .frame(width: 26)
                VStack(alignment: .leading, spacing: 2) {
                    Text(module.title).font(Theme.rounded(18, .bold)).foregroundStyle(Theme.textPrimary)
                    Text(module.summary).font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            ProgressView(value: progress.completion(of: module))
                .tint(accent)
                .scaleEffect(x: 1, y: 0.7, anchor: .center)

            ForEach(module.lessons) { lesson in
                NavigationLink(value: CipherRoute.lesson(lesson.id)) {
                    LessonRow(lesson: lesson, completed: progress.isComplete(lesson.id), accent: accent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Theme.surface.opacity(0.5), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Theme.stroke, lineWidth: 1))
    }
}
