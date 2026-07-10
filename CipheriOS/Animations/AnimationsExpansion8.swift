import SwiftUI

// MARK: - Expansion wave 8 explainers
//
// Two visualizations pairing with the new hands-on lessons: the social-engineering
// attack cycle (the human is the vulnerability) and log analysis (spotting the
// malicious needle in a haystack of normal events).

private func wire8(_ a: CGPoint, _ b: CGPoint, _ color: Color = Theme.stroke) -> some View {
    Path { p in p.move(to: a); p.addLine(to: b) }
        .stroke(color, style: StrokeStyle(lineWidth: 1.2, dash: [3, 4]))
}

@ViewBuilder
private func chip8(_ a: CGPoint, _ b: CGPoint, _ p: Double, _ s: Double, _ e: Double,
                   _ label: String, _ c: Color, system: String = "arrow.right") -> some View {
    if p >= s && p <= e {
        let t = ease(CGFloat((p - s) / max(0.0001, e - s)))
        TokenChip(text: label, color: c, system: system)
            .position(lerp(a, b, t))
    }
}

// MARK: 1 — Social engineering

/// No exploit required — the attacker researches the target, invents a believable
/// pretext, uses authority and urgency to earn trust, and the human hands over
/// what no firewall would. The most reliable attack there is.
struct SocialEngineeringView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let atk = CGPoint(x: w * 0.16, y: h * 0.30)
            let tgt = CGPoint(x: w * 0.84, y: h * 0.30)
            LoopingTimeline(period: 8) { p in
                let step = min(3, Int(p * 4))   // 0 recon · 1 pretext · 2 trust · 3 extract
                let owned = step >= 3
                ZStack {
                    wire8(atk, tgt)
                    netNode("person.fill.viewfinder", "attacker", Theme.red, true).position(atk)
                    netNode(owned ? "lock.open.fill" : "person.fill",
                            owned ? "target\n(fooled)" : "target",
                            owned ? Theme.red : Theme.blue, true).position(tgt)

                    Text("OSINT: name · role · vendor")
                        .font(Theme.mono(7.5, .bold))
                        .foregroundStyle(step >= 0 ? Theme.amber : Theme.textDim)
                        .position(x: w * 0.16, y: h * 0.56)

                    chip8(atk, tgt, p, 0.28, 0.48, "\"IT support — urgent\"", Theme.amber)
                    chip8(tgt, atk, p, 0.52, 0.66, "…okay, I trust you", Theme.blue, system: "arrow.left")
                    chip8(tgt, atk, p, 0.72, 0.92, "password + MFA code", Theme.red, system: "arrow.left")

                    Text(label(step))
                        .font(Theme.mono(8, .bold))
                        .foregroundStyle(owned ? Theme.red : Theme.textSecondary)
                        .multilineTextAlignment(.center).frame(width: w * 0.94)
                        .position(x: w * 0.5, y: h * 0.90)
                }
                .animation(.easeInOut(duration: 0.3), value: step)
            }
        }
    }

    private func label(_ s: Int) -> String {
        switch s {
        case 0:  return "1 · reconnaissance — learn just enough to sound legitimate"
        case 1:  return "2 · pretext — a believable story, wrapped in urgency"
        case 2:  return "3 · trust — authority + urgency lower the target's guard"
        default: return "4 · extract — the human hands over what no exploit could reach"
        }
    }
}

// MARK: 2 — Log analysis

/// Detection is finding the one line that matters in a flood of normal events.
/// Failed logins scroll past as noise — until 412 failures followed by a success
/// from the same foreign IP resolve into a brute-force compromise, and the SIEM
/// fires.
struct LogAnalysisView: View {
    private let logs: [(String, Bool)] = [
        ("10:02  auth ok    alice  10.0.0.5", false),
        ("10:03  GET /home  200", false),
        ("10:03  auth ok    bob    10.0.0.9", false),
        ("10:04  auth FAIL  admin  45.13.x  (x412)", true),
        ("10:05  GET /js    200", false),
        ("10:05  auth ok    admin  45.13.x", true)
    ]

    var body: some View {
        LoopingTimeline(period: 8) { p in
            let shown = min(logs.count, Int(p * Double(logs.count + 1)))
            let alerted = p > 0.85
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Image(systemName: "doc.text.magnifyingglass")
                    Text("SIEM  ·  auth.log")
                }
                .font(Theme.mono(9, .bold)).foregroundStyle(Theme.blue).frame(maxWidth: .infinity)

                ForEach(0..<logs.count, id: \.self) { i in
                    let vis = i < shown
                    let bad = logs[i].1
                    HStack(spacing: 6) {
                        Image(systemName: bad ? "exclamationmark.triangle.fill" : "circle.fill")
                            .font(.system(size: bad ? 8 : 4))
                            .foregroundStyle(bad ? Theme.red : Theme.textDim)
                        Text(logs[i].0)
                            .font(Theme.mono(9, bad ? .bold : .regular))
                            .foregroundStyle(bad ? Theme.red : Theme.textSecondary)
                        Spacer(minLength: 0)
                    }
                    .opacity(vis ? 1 : 0.2)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(vis && bad ? Theme.red.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 5))
                    .frame(width: 288)
                }

                if alerted {
                    HStack(spacing: 6) {
                        Image(systemName: "bell.badge.fill")
                        Text("ALERT: 412 failures then success from 45.13.x → brute-force compromise")
                    }
                    .font(Theme.mono(7.5, .bold)).foregroundStyle(Theme.red)
                    .multilineTextAlignment(.center).frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 4)
            .animation(.easeInOut(duration: 0.2), value: shown)
        }
    }
}
