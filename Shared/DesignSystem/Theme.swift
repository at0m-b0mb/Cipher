import SwiftUI

// MARK: - Hex colour helper

extension Color {
    /// Build a colour from a hex string like `"#1B2430"` or `"1B2430"`.
    init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        let r, g, b, a: Double
        switch s.count {
        case 8: // RRGGBBAA
            r = Double((v & 0xFF00_0000) >> 24) / 255
            g = Double((v & 0x00FF_0000) >> 16) / 255
            b = Double((v & 0x0000_FF00) >> 8) / 255
            a = Double(v & 0x0000_00FF) / 255
        default: // RRGGBB
            r = Double((v & 0xFF0000) >> 16) / 255
            g = Double((v & 0x00FF00) >> 8) / 255
            b = Double(v & 0x0000FF) / 255
            a = 1
        }
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - Palette & typography

/// Central design tokens. A dark, high-contrast "console" look: deep navy-black
/// surfaces, neon accents, and monospaced type for anything that represents code,
/// commands or data — the visual language professional security tooling lives in.
enum Theme {

    // Surfaces
    static let background = Color(hex: "#0A0E14")
    static let surface    = Color(hex: "#121826")
    static let surfaceHi  = Color(hex: "#1B2435")
    static let stroke     = Color(hex: "#27324A")

    // Text
    static let textPrimary   = Color(hex: "#EDF1F7")
    static let textSecondary = Color(hex: "#9AA7BD")
    static let textDim       = Color(hex: "#5C6B85")

    // Accents
    static let red     = Color(hex: "#FF4D6A")   // red team
    static let blue    = Color(hex: "#3DA0FF")   // blue team
    static let teal    = Color(hex: "#2BE6C0")   // fundamentals
    static let green   = Color(hex: "#3CE88B")   // "success / terminal"
    static let amber   = Color(hex: "#FFC24B")   // warnings
    static let magenta = Color(hex: "#FF6BD6")
    static let violet  = Color(hex: "#9B8CFF")

    // Gradients
    static let backgroundGradient = LinearGradient(
        colors: [Color(hex: "#0B1018"), Color(hex: "#070A10")],
        startPoint: .top, endPoint: .bottom)

    static func glow(_ color: Color) -> RadialGradient {
        RadialGradient(colors: [color.opacity(0.35), .clear],
                       center: .center, startRadius: 1, endRadius: 120)
    }

    static func accentGradient(_ color: Color) -> LinearGradient {
        LinearGradient(colors: [color, color.opacity(0.55)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // Type
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// MARK: - Reusable surface styling

extension View {
    /// Standard rounded card surface used across both apps.
    func cipherCard(padding: CGFloat = 16, stroke: Color = Theme.stroke) -> some View {
        self
            .padding(padding)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(stroke, lineWidth: 1)
            )
    }

    /// A subtle neon edge in the given accent — for selected / featured cards.
    func neonEdge(_ color: Color, radius: CGFloat = 18, lineWidth: CGFloat = 1.5) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(
                    LinearGradient(colors: [color.opacity(0.9), color.opacity(0.2)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: lineWidth)
        )
        .shadow(color: color.opacity(0.35), radius: 12, x: 0, y: 0)
    }
}
