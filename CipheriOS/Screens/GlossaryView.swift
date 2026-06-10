import SwiftUI

struct GlossaryView: View {
    @State private var query = ""
    @State private var filter: TrackKind? = nil

    private var cards: [Flashcard] {
        Flashcards.deck.filter { c in
            (filter == nil || c.category == filter) &&
            (query.isEmpty
             || c.term.localizedCaseInsensitiveContains(query)
             || c.definition.localizedCaseInsensitiveContains(query))
        }
    }

    var body: some View {
        ZStack {
            CircuitBackground(tint: Theme.teal)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            filterChip(nil, "All", Theme.textSecondary)
                            filterChip(.fundamentals, "Fundamentals", Theme.teal)
                            filterChip(.redTeam, "Red Team", Theme.red)
                            filterChip(.blueTeam, "Blue Team", Theme.blue)
                        }
                    }
                    Text("\(cards.count) terms").font(Theme.mono(10)).foregroundStyle(Theme.textDim)
                    ForEach(cards) { card in
                        FlashcardCardView(card: card)
                    }
                    if cards.isEmpty {
                        Text("No matches for “\(query)”.").font(.system(size: 14)).foregroundStyle(Theme.textDim)
                            .frame(maxWidth: .infinity).padding(.top, 40)
                    }
                }
                .padding(18)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Glossary")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search terms")
    }

    private func filterChip(_ kind: TrackKind?, _ label: String, _ color: Color) -> some View {
        let selected = filter == kind
        return Button {
            withAnimation { filter = kind }
        } label: {
            Text(label)
                .font(Theme.mono(11, .bold))
                .foregroundStyle(selected ? .black : color)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(selected ? color : color.opacity(0.14), in: Capsule())
                .overlay(Capsule().strokeBorder(color.opacity(0.4), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
