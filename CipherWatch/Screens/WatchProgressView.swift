import SwiftUI

struct WatchProgressView: View {
    @EnvironmentObject private var progress: ProgressStore

    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 12) {
                    ZStack {
                        Circle().fill(Theme.amber.opacity(0.16)).frame(width: 52, height: 52)
                        Image(systemName: progress.rank.glyph).font(.system(size: 20, weight: .bold)).foregroundStyle(Theme.amber)
                    }
                    Text(progress.rank.title).font(Theme.rounded(17, .bold)).foregroundStyle(Theme.textPrimary)
                    Text("\(progress.xp) XP").font(Theme.mono(10)).foregroundStyle(Theme.textSecondary)

                    stat("\(progress.streak)d", "Current streak", "flame.fill", Theme.amber)
                    stat("\(progress.longestStreak)d", "Longest streak", "trophy.fill", Theme.green)
                    stat("\(progress.completedLessons.count)", "Lessons on iPhone", "checkmark.seal.fill", Theme.teal)
                }
                .padding()
            }
        }
        .navigationTitle("Progress")
    }

    private func stat(_ value: String, _ caption: String, _ glyph: String, _ color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: glyph).foregroundStyle(color).font(.system(size: 14)).frame(width: 22)
            Text(value).font(Theme.rounded(15, .bold)).foregroundStyle(Theme.textPrimary)
            Spacer()
            Text(caption).font(Theme.mono(9)).foregroundStyle(Theme.textDim)
        }
        .padding(10)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
