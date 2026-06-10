import SwiftUI

struct TermOfDayView: View {
    @State private var revealed = false
    private let card = Flashcards.termOfTheDay()

    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 10) {
                    Text(card.category.title.uppercased())
                        .font(Theme.mono(9, .bold)).tracking(1).foregroundStyle(card.category.accent)
                    Text(card.term)
                        .font(Theme.rounded(20, .bold)).foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.center)
                    if revealed {
                        Text(card.definition)
                            .font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }
                    Button { withAnimation { revealed.toggle() } } label: {
                        Text(revealed ? "Hide" : "Reveal").frame(maxWidth: .infinity)
                    }
                    .tint(card.category.accent)
                    .padding(.top, 2)
                }
                .padding(.horizontal, 4)
            }
        }
        .navigationTitle("Today")
    }
}
