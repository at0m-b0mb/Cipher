import SwiftUI

/// A short, seeded flashcard drill for the wrist. Reveal each card, mark it
/// known or for review, and finishing keeps your streak alive.
struct DailyDrillView: View {
    @EnvironmentObject private var progress: ProgressStore
    @State private var deck = Flashcards.dailyDrill()
    @State private var index = 0
    @State private var revealed = false
    @State private var known = 0
    @State private var finished = false

    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            if finished { summary } else { card }
        }
        .navigationTitle("Drill")
    }

    private var card: some View {
        let c = deck[index]
        return ScrollView {
            VStack(spacing: 10) {
                HStack {
                    Text("\(index + 1)/\(deck.count)").font(Theme.mono(10, .bold)).foregroundStyle(Theme.textDim)
                    Spacer()
                    Text(c.category.title).font(Theme.mono(9, .bold)).foregroundStyle(c.category.accent)
                }
                Text(c.term)
                    .font(Theme.rounded(19, .bold)).foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center).frame(maxWidth: .infinity)

                if revealed {
                    Text(c.definition)
                        .font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                    HStack(spacing: 8) {
                        Button { advance(got: false) } label: {
                            Label("Review", systemImage: "arrow.uturn.left").font(.system(size: 12, weight: .bold))
                        }.tint(Theme.amber)
                        Button { advance(got: true) } label: {
                            Label("Got it", systemImage: "checkmark").font(.system(size: 12, weight: .bold))
                        }.tint(Theme.green)
                    }
                    .padding(.top, 2)
                } else {
                    Button { withAnimation { revealed = true } } label: {
                        Text("Reveal").font(.system(size: 14, weight: .bold)).frame(maxWidth: .infinity)
                    }.tint(c.category.accent)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private var summary: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill").font(.system(size: 34)).foregroundStyle(Theme.green)
            Text("\(known)/\(deck.count)").font(Theme.rounded(30, .bold)).foregroundStyle(Theme.textPrimary)
            Text("cards known today").font(Theme.mono(10)).foregroundStyle(Theme.textSecondary)
            HStack(spacing: 6) {
                Image(systemName: "flame.fill").foregroundStyle(Theme.amber)
                Text("\(progress.streak)-day streak").font(Theme.mono(11, .bold)).foregroundStyle(Theme.textPrimary)
            }
            Button { restart() } label: { Text("Again").frame(maxWidth: .infinity) }.tint(Theme.teal)
        }
        .padding()
    }

    private func advance(got: Bool) {
        if got { known += 1 }
        if index + 1 >= deck.count {
            progress.markDailyActivity()
            withAnimation { finished = true }
        } else {
            withAnimation { index += 1; revealed = false }
        }
    }

    private func restart() {
        deck = Flashcards.dailyDrill()
        index = 0; revealed = false; known = 0; finished = false
    }
}
