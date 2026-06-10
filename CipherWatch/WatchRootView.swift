import SwiftUI

/// Apple Watch home: a quick menu into the daily drill, term of the day, and
/// progress. Designed for glanceable, on-the-go review that complements the
/// full course on iPhone.
struct WatchRootView: View {
    @EnvironmentObject private var progress: ProgressStore

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill").foregroundStyle(Theme.amber)
                        Text("\(progress.streak)").font(Theme.rounded(20, .bold)).foregroundStyle(Theme.textPrimary)
                        Text("day streak").font(Theme.mono(11)).foregroundStyle(Theme.textSecondary)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                NavigationLink { DailyDrillView() } label: {
                    menuRow("Daily Drill", "bolt.fill", Theme.red, "\(Flashcards.dailyDrill().count) cards")
                }
                NavigationLink { TermOfDayView() } label: {
                    menuRow("Term of the Day", "character.book.closed.fill", Theme.teal, Flashcards.termOfTheDay().term)
                }
                NavigationLink { WatchProgressView() } label: {
                    menuRow("Progress", "chart.bar.fill", Theme.blue, progress.rank.title)
                }
            }
            .navigationTitle("Cipher")
        }
    }

    private func menuRow(_ title: String, _ glyph: String, _ color: Color, _ subtitle: String) -> some View {
        HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous).fill(color.opacity(0.18)).frame(width: 34, height: 34)
                Image(systemName: glyph).font(.system(size: 15, weight: .bold)).foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.textPrimary)
                Text(subtitle).font(Theme.mono(9)).foregroundStyle(Theme.textDim).lineLimit(1)
            }
        }
        .padding(.vertical, 3)
    }
}
