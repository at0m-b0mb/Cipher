import SwiftUI

// MARK: - Difficulty pips

/// Four-pip difficulty indicator, filled to the lesson's level and tinted.
struct DifficultyPips: View {
    let difficulty: Difficulty
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<4) { i in
                Capsule()
                    .fill(i < difficulty.pips ? difficulty.tint : Theme.stroke)
                    .frame(width: 14, height: 4)
            }
        }
        .accessibilityLabel("Difficulty: \(difficulty.label)")
    }
}

// MARK: - Progress ring

/// A circular completion ring with a centred label. Used on the dashboard,
/// track cards and profile.
struct ProgressRing: View {
    let progress: Double          // 0...1
    var color: Color = Theme.teal
    var lineWidth: CGFloat = 8
    var size: CGFloat = 64
    var label: String? = nil

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.stroke, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.0001, progress))
                .stroke(
                    AngularGradient(colors: [color.opacity(0.6), color], center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.5), radius: 6)
                .animation(.easeOut(duration: 0.8), value: progress)
            if let label {
                Text(label)
                    .font(Theme.rounded(size * 0.26, .bold))
                    .foregroundStyle(Theme.textPrimary)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var systemImage: String? = nil
    var accent: Color = Theme.textSecondary
    var body: some View {
        HStack(spacing: 8) {
            if let systemImage {
                Image(systemName: systemImage).foregroundStyle(accent)
            }
            Text(title.uppercased())
                .font(Theme.mono(12, .semibold))
                .tracking(1.5)
                .foregroundStyle(Theme.textSecondary)
            Rectangle().fill(Theme.stroke).frame(height: 1)
        }
    }
}

// MARK: - Small pill / chip

struct AccentChip: View {
    let text: String
    var systemImage: String? = nil
    var color: Color = Theme.teal
    var body: some View {
        HStack(spacing: 4) {
            if let systemImage { Image(systemName: systemImage).font(.system(size: 10, weight: .bold)) }
            Text(text).font(Theme.mono(11, .medium))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.14), in: Capsule())
        .overlay(Capsule().strokeBorder(color.opacity(0.35), lineWidth: 1))
    }
}

// MARK: - Stat badge

struct StatBadge: View {
    let value: String
    let caption: String
    var systemImage: String
    var color: Color
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage).font(.system(size: 18, weight: .semibold)).foregroundStyle(color)
            Text(value).font(Theme.rounded(20, .bold)).foregroundStyle(Theme.textPrimary)
            Text(caption).font(Theme.mono(10)).foregroundStyle(Theme.textDim)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .cipherCard()
    }
}

// MARK: - Animated circuit background

/// A cheap, always-on ambient backdrop: the dark gradient, a faint grid, and a
/// couple of slow-drifting accent glows. Sits behind the main screens to give
/// the "console" mood without taxing the GPU.
struct CircuitBackground: View {
    var tint: Color = Theme.teal
    var body: some View {
        ZStack {
            Theme.backgroundGradient
            GridPattern().stroke(Theme.stroke.opacity(0.5), lineWidth: 0.5)
            TimelineView(.animation(minimumInterval: 0.1)) { ctx in
                let t = ctx.date.timeIntervalSinceReferenceDate
                Canvas { context, size in
                    drawGlow(&context, size: size, t: t, color: tint, phase: 0)
                    drawGlow(&context, size: size, t: t, color: Theme.violet, phase: 2.2)
                }
            }
            .blur(radius: 60)
            .opacity(0.5)
        }
        .ignoresSafeArea()
    }

    private func drawGlow(_ context: inout GraphicsContext, size: CGSize, t: Double, color: Color, phase: Double) {
        let x = size.width * (0.5 + 0.35 * cos(t * 0.08 + phase))
        let y = size.height * (0.4 + 0.3 * sin(t * 0.06 + phase * 1.7))
        let r: CGFloat = 130
        let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
        context.fill(Circle().path(in: rect), with: .color(color.opacity(0.5)))
    }
}

/// A simple repeating grid used by the ambient background and animation stages.
struct GridPattern: Shape {
    var spacing: CGFloat = 28
    func path(in rect: CGRect) -> Path {
        var p = Path()
        var x: CGFloat = 0
        while x <= rect.width { p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: rect.height)); x += spacing }
        var y: CGFloat = 0
        while y <= rect.height { p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: rect.width, y: y)); y += spacing }
        return p
    }
}
