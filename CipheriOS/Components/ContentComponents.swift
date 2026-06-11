import SwiftUI
import UIKit

// MARK: - Callout

struct CalloutView: View {
    let kind: CalloutKind
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: kind.systemImage)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(kind.tint)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 5) {
                Text(kind.title.uppercased())
                    .font(Theme.mono(10, .bold)).tracking(1.2)
                    .foregroundStyle(kind.tint)
                Text(text.inlineMarkdown)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textPrimary)
                    .tint(kind.tint)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(kind.tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(kind.tint.opacity(0.4), lineWidth: 1))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2).fill(kind.tint).frame(width: 3).padding(.vertical, 10)
        }
    }
}

// MARK: - Code block

struct CodeBlockView: View {
    let language: String
    let code: String
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(language.uppercased())
                    .font(Theme.mono(10, .bold)).tracking(1).foregroundStyle(Theme.violet)
                Spacer()
                Button {
                    UIPasteboard.general.string = code
                    withAnimation { copied = true }
                    Task { try? await Task.sleep(for: .seconds(1.4)); withAnimation { copied = false } }
                } label: {
                    Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(Theme.mono(10, .medium))
                        .foregroundStyle(copied ? Theme.green : Theme.textDim)
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(Color.white.opacity(0.04))
            .overlay(Rectangle().fill(Theme.stroke).frame(height: 1), alignment: .bottom)

            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(Theme.mono(12))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(14)
            }
        }
        .background(Color.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.stroke, lineWidth: 1))
    }
}

// MARK: - Definition

struct DefinitionCard: View {
    let term: String
    let meaning: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 7) {
                Image(systemName: "character.book.closed.fill").font(.system(size: 13)).foregroundStyle(Theme.teal)
                Text(term).font(Theme.rounded(15, .bold)).foregroundStyle(Theme.textPrimary)
            }
            Text(meaning.inlineMarkdown)
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
                .tint(Theme.teal)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cipherCard()
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2).fill(Theme.teal).frame(width: 3).padding(.vertical, 12)
        }
    }
}

// MARK: - Key points (staggered reveal)

struct KeyPointsList: View {
    let points: [String]
    var accent: Color = Theme.teal
    @State private var shown = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            ForEach(points.indices, id: \.self) { i in
                HStack(alignment: .top, spacing: 11) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(accent)
                        .padding(.top, 3)
                    Text(points[i].inlineMarkdown)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textPrimary)
                        .tint(accent)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .opacity(i < shown ? 1 : 0)
                .offset(x: i < shown ? 0 : -10)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            for i in points.indices {
                withAnimation(.easeOut(duration: 0.35).delay(Double(i) * 0.08)) { shown = i + 1 }
            }
        }
    }
}

// MARK: - Interactive question (shared by checkpoints and quizzes)

struct QuestionCard: View {
    let question: QuizQuestion
    var accent: Color = Theme.teal
    var onAnswered: ((Bool) -> Void)? = nil

    @State private var selected: Int? = nil
    @State private var shakes: CGFloat = 0
    @State private var popped = false

    private var answered: Bool { selected != nil }
    private var isCorrect: Bool { selected == question.correctIndex }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question.prompt.inlineMarkdown)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(question.options.indices, id: \.self) { i in
                optionButton(i)
            }

            if answered {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: isCorrect ? "checkmark.seal.fill" : "xmark.seal.fill")
                        .foregroundStyle(isCorrect ? Theme.green : Theme.red)
                    Text(question.explanation.inlineMarkdown)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 2)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func optionButton(_ i: Int) -> some View {
        let isAnswer = i == question.correctIndex
        let isPicked = i == selected
        let bg: Color = {
            guard answered else { return Theme.surfaceHi }
            if isAnswer { return Theme.green.opacity(0.18) }
            if isPicked { return Theme.red.opacity(0.18) }
            return Theme.surfaceHi
        }()
        let edge: Color = {
            guard answered else { return Theme.stroke }
            if isAnswer { return Theme.green }
            if isPicked { return Theme.red }
            return Theme.stroke
        }()

        return Button {
            guard !answered else { return }
            let correct = i == question.correctIndex
            UINotificationFeedbackGenerator().notificationOccurred(correct ? .success : .error)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selected = i }
            if correct {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.5)) { popped = true }
                Task {
                    try? await Task.sleep(for: .milliseconds(220))
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { popped = false }
                }
            } else {
                withAnimation(.linear(duration: 0.45)) { shakes += 1 }
            }
            onAnswered?(correct)
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle().strokeBorder(edge, lineWidth: 1.5).frame(width: 22, height: 22)
                    if answered && isAnswer { Image(systemName: "checkmark").font(.system(size: 11, weight: .black)).foregroundStyle(Theme.green) }
                    else if answered && isPicked { Image(systemName: "xmark").font(.system(size: 11, weight: .black)).foregroundStyle(Theme.red) }
                    else { Text(String(UnicodeScalar(65 + i)!)).font(Theme.mono(11, .bold)).foregroundStyle(Theme.textSecondary) }
                }
                Text(question.options[i].inlineMarkdown)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(bg, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(edge, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(answered)
        .scaleEffect(isPicked && isAnswer && popped ? 1.03 : 1)
        .modifier(ShakeEffect(travel: isPicked && !isAnswer ? 7 : 0, animatableData: shakes))
    }
}

// MARK: - Inline checkpoint wrapper

struct InlineCheckpoint: View {
    let question: QuizQuestion
    var accent: Color = Theme.teal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("KNOWLEDGE CHECK", systemImage: "checkmark.circle")
                .font(Theme.mono(10, .bold)).tracking(1.2)
                .foregroundStyle(accent)
            QuestionCard(question: question, accent: accent)
        }
        .padding(16)
        .background(accent.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(accent.opacity(0.3), lineWidth: 1))
    }
}
