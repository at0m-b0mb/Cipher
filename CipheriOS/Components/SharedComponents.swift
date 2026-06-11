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

// MARK: - Shake effect

/// Horizontal shake driven by an incrementing counter — animate the counter
/// change and the view rattles. Used for wrong quiz answers.
struct ShakeEffect: GeometryEffect {
    var travel: CGFloat = 7
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(
            translationX: travel * sin(animatableData * .pi * shakesPerUnit * 2), y: 0))
    }
}

// MARK: - Decode text

/// Title text that "decrypts" into place: glyphs churn like a cracking tool,
/// then resolve left to right into the real string. The final string renders
/// invisibly underneath so the layout never jumps.
struct DecodeText: View {
    let text: String
    var font: Font = Theme.rounded(27, .bold)
    var color: Color = Theme.textPrimary

    @State private var revealed = 0
    @State private var churn = 0

    private static let glyphs = Array("█▓▒░<>/\\|10#$%&@?")

    var body: some View {
        Text(text)
            .font(font)
            .opacity(0)
            .overlay(alignment: .topLeading) {
                Text(display)
                    .font(font)
                    .foregroundStyle(color)
            }
            .fixedSize(horizontal: false, vertical: true)
            .task { await run() }
            .accessibilityLabel(text)
    }

    private var display: String {
        let chars = Array(text)
        guard revealed < chars.count else { return text }
        let head = String(chars.prefix(revealed))
        let tail = chars.suffix(from: revealed).map { c -> Character in
            c == " " ? " " : (Self.glyphs.randomElement() ?? c)
        }
        return head + String(tail)
    }

    private func run() async {
        let count = text.count
        guard count > 0 else { return }
        // ~0.7s total regardless of title length.
        let perChar = max(12, 700 / count)
        for i in 0...count {
            guard !Task.isCancelled else { return }
            revealed = i
            churn += 1
            try? await Task.sleep(for: .milliseconds(perChar))
        }
    }
}

// MARK: - Confetti

/// A one-shot confetti burst rendered in a Canvas. Every particle's path is a
/// pure function of time and its seed, so the whole burst costs one draw pass
/// per frame and stops ticking when it finishes.
struct ConfettiBurst: View {
    var colors: [Color] = [Theme.teal, Theme.green, Theme.amber, Theme.red,
                           Theme.blue, Theme.violet, Theme.magenta]
    var count: Int = 80
    var duration: Double = 3.0

    @State private var start = Date()
    @State private var finished = false

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: finished)) { ctx in
            Canvas { context, size in
                let t = ctx.date.timeIntervalSince(start)
                guard t < duration else { return }
                for i in 0..<count {
                    let r1 = rand(i, 1), r2 = rand(i, 2), r3 = rand(i, 3), r4 = rand(i, 4)
                    let delay = r4 * 0.25
                    let life = max(0, t - delay)
                    guard life > 0 else { continue }

                    let x0 = size.width * (0.15 + 0.7 * r1)
                    let vx = (r2 - 0.5) * 160
                    let vy = -(220 + 240 * r3)
                    let x = x0 + vx * life
                    let y = size.height * 0.55 + vy * life + 420 * life * life

                    let fade = min(1, max(0, (duration - delay - life) / 0.6))
                    let spin = Angle.radians(life * (2 + 8 * r2) * (r1 > 0.5 ? 1 : -1))
                    let w = 5 + 5 * r3, h = 8 + 4 * r2

                    var piece = context
                    piece.translateBy(x: x, y: y)
                    piece.rotate(by: spin)
                    piece.opacity = fade
                    piece.fill(
                        Path(roundedRect: CGRect(x: -w / 2, y: -h / 2, width: w, height: h), cornerRadius: 1.5),
                        with: .color(colors[i % colors.count]))
                }
            }
        }
        .allowsHitTesting(false)
        .task {
            try? await Task.sleep(for: .seconds(duration))
            finished = true
        }
    }

    /// Cheap deterministic pseudo-random in 0..<1 from a particle index.
    private func rand(_ i: Int, _ salt: Int) -> Double {
        let x = sin(Double(i) * 12.9898 + Double(salt) * 78.233) * 43758.5453
        return x - x.rounded(.down)
    }
}
