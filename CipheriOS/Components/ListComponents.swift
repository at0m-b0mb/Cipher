import SwiftUI

/// Big tappable track summary used on the dashboard and the Learn tab.
struct TrackCard: View {
    let track: Track
    let completion: Double

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(track.accent.opacity(0.16))
                    .frame(width: 58, height: 58)
                Image(systemName: track.kind.glyph)
                    .font(.system(size: 23, weight: .bold))
                    .foregroundStyle(track.accent)
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(track.title).font(Theme.rounded(19, .bold)).foregroundStyle(Theme.textPrimary)
                Text(track.tagline)
                    .font(.system(size: 12.5)).foregroundStyle(Theme.textSecondary)
                    .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 12) {
                    Label("\(track.modules.count) modules", systemImage: "square.stack.3d.up")
                        .font(Theme.mono(9)).foregroundStyle(Theme.textDim)
                    Label("\(track.lessons.count) lessons", systemImage: "doc.text")
                        .font(Theme.mono(9)).foregroundStyle(Theme.textDim)
                }
            }
            Spacer(minLength: 4)
            ProgressRing(progress: completion, color: track.accent, lineWidth: 6, size: 50,
                         label: "\(Int(completion * 100))%")
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(track.accent.opacity(0.35), lineWidth: 1))
    }
}

/// A single lesson row with completion state and quick meta.
struct LessonRow: View {
    let lesson: Lesson
    let completed: Bool
    let accent: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().strokeBorder(completed ? Theme.green : accent.opacity(0.5), lineWidth: 1.5)
                    .frame(width: 26, height: 26)
                Image(systemName: completed ? "checkmark" : "play.fill")
                    .font(.system(size: completed ? 11 : 9, weight: .black))
                    .foregroundStyle(completed ? Theme.green : accent)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(lesson.title).font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    DifficultyPips(difficulty: lesson.difficulty)
                    Text("\(lesson.minutes) min").font(Theme.mono(9)).foregroundStyle(Theme.textDim)
                    if !lesson.animations.isEmpty {
                        Image(systemName: "play.circle.fill").font(.system(size: 10)).foregroundStyle(accent)
                    }
                }
            }
            Spacer(minLength: 4)
            Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.textDim)
        }
        .padding(.vertical, 11).padding(.horizontal, 14)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.stroke, lineWidth: 1))
    }
}

/// Flippable "term of the day" / glossary card.
struct FlashcardCardView: View {
    let card: Flashcard
    @State private var revealed = false

    var body: some View {
        Button { withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { revealed.toggle() } } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    AccentChip(text: card.category.title, color: card.category.accent)
                    Spacer()
                    Image(systemName: revealed ? "arrow.uturn.backward" : "hand.tap.fill")
                        .font(.system(size: 11)).foregroundStyle(Theme.textDim)
                }
                Text(card.term)
                    .font(Theme.rounded(18, .bold)).foregroundStyle(Theme.textPrimary)
                Text(revealed ? card.definition : "Tap to reveal the definition")
                    .font(.system(size: 13.5))
                    .foregroundStyle(revealed ? Theme.textSecondary : Theme.textDim)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(card.category.accent.opacity(0.35), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
