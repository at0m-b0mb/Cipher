import SwiftUI

/// Renders one `LessonBlock`. The lesson player just maps over a lesson's blocks
/// with this view, so the entire content layer is data-driven.
struct LessonBlockView: View {
    let block: LessonBlock
    let accent: Color

    var body: some View {
        switch block {
        case .heading(let text):
            Text(text)
                .font(Theme.rounded(20, .bold))
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 6)

        case .paragraph(let text):
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

        case .keyPoints(let points):
            KeyPointsList(points: points, accent: accent)

        case .callout(let kind, let text):
            CalloutView(kind: kind, text: text)

        case .definition(let term, let meaning):
            DefinitionCard(term: term, meaning: meaning)

        case .terminal(let prompt, let command, let output):
            TerminalView(prompt: prompt, command: command, output: output)

        case .code(let language, let code):
            CodeBlockView(language: language, code: code)

        case .animation(let id, let caption):
            AnimationView(id: id, caption: caption)

        case .checkpoint(let question):
            InlineCheckpoint(question: question, accent: accent)
        }
    }
}
