import SwiftUI

// MARK: - Math helpers

@inline(__always) func lerp(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
    CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
}

/// Smoothstep easing — eases in and out, nicer than linear for travelling tokens.
@inline(__always) func ease(_ t: CGFloat) -> CGFloat {
    let x = min(max(t, 0), 1)
    return x * x * (3 - 2 * x)
}

// MARK: - Looping timeline

/// Drives a child with a normalised progress value `0..<1` that loops every
/// `period` seconds. Pure function of progress → the animation is deterministic
/// and restarts cleanly when the parent assigns a new `.id`.
struct LoopingTimeline<Content: View>: View {
    let period: Double
    @ViewBuilder var content: (Double) -> Content
    @State private var start = Date()

    var body: some View {
        TimelineView(.animation) { ctx in
            let elapsed = ctx.date.timeIntervalSince(start)
            let p = period > 0 ? (elapsed.truncatingRemainder(dividingBy: period)) / period : 0
            content(p)
        }
    }
}

// MARK: - Explainer chrome

/// The card every animation lives in: a titled header with a replay button, a
/// dark "stage" with a faint grid and accent glow, then the caption. Replaying
/// re-seeds the inner view's state via `.id`.
struct AnimatedExplainer<Content: View>: View {
    let id: AnimationID
    let caption: String
    var accent: Color = Theme.teal
    var height: CGFloat = 250
    @ViewBuilder var content: () -> Content
    @State private var token = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                LiveDot(color: accent)
                Text(id.label)
                    .font(Theme.mono(12, .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button {
                    withAnimation { token += 1 }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(accent)
                        .padding(7)
                        .background(accent.opacity(0.14), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Replay animation")
            }

            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.black.opacity(0.35))
                GridPattern(spacing: 24).stroke(Theme.stroke.opacity(0.5), lineWidth: 0.5)
                RadialGradient(colors: [accent.opacity(0.16), .clear], center: .center, startRadius: 2, endRadius: 220)
                content()
                    .id(token)
                    .padding(14)
            }
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(accent.opacity(0.35), lineWidth: 1))

            Text(caption)
                .font(.system(size: 12.5))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Small pulsing "live" indicator.
struct LiveDot: View {
    let color: Color
    var body: some View {
        TimelineView(.animation) { ctx in
            let p = (sin(ctx.date.timeIntervalSinceReferenceDate * 3) + 1) / 2
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
                .shadow(color: color, radius: 4 + 3 * p)
                .opacity(0.6 + 0.4 * p)
        }
    }
}

// MARK: - Building-block nodes

/// A labelled host / actor box used across flow animations.
struct HostNode: View {
    let title: String
    var subtitle: String = ""
    let system: String
    let color: Color
    var active: Bool = true

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color.opacity(active ? 0.20 : 0.06))
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(color.opacity(active ? 0.9 : 0.3), lineWidth: 1.2)
                Image(systemName: system)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(active ? color : Theme.textDim)
            }
            .frame(width: 52, height: 46)
            .shadow(color: active ? color.opacity(0.5) : .clear, radius: 8)
            Text(title).font(Theme.mono(9.5, .bold)).foregroundStyle(active ? Theme.textPrimary : Theme.textDim)
            if !subtitle.isEmpty {
                Text(subtitle).font(Theme.mono(8)).foregroundStyle(Theme.textDim)
            }
        }
        .frame(width: 86)
    }
}

/// A travelling packet / ticket / message token.
struct TokenChip: View {
    let text: String
    let color: Color
    var system: String? = nil
    var body: some View {
        HStack(spacing: 3) {
            if let system { Image(systemName: system).font(.system(size: 8, weight: .black)) }
            Text(text).font(Theme.mono(9, .bold))
        }
        .foregroundStyle(.black)
        .padding(.horizontal, 7).padding(.vertical, 4)
        .background(color, in: Capsule())
        .shadow(color: color.opacity(0.7), radius: 6)
        .fixedSize()
    }
}

// MARK: - Flow stage (node-to-node messaging engine)

struct FlowNode: Identifiable {
    let id: String
    let pos: CGPoint          // normalised 0..1 within the stage
    let title: String
    var subtitle: String = ""
    let system: String
    let color: Color
    var startActive: Bool = false
}

struct FlowMessage: Identifiable {
    let id = UUID()
    let from: String
    let to: String
    let label: String
    let color: Color
    let start: Double         // 0..1 within the loop
    let end: Double
    var system: String? = nil
}

/// Configurable engine: place nodes, describe messages travelling between them
/// over a looping timeline. Powers the handshake, Kerberos, phishing, lateral
/// movement, C2 and SIEM animations from pure data.
struct FlowStage: View {
    let nodes: [FlowNode]
    let messages: [FlowMessage]
    var period: Double = 6
    var footnote: String? = nil

    private func node(_ id: String) -> FlowNode { nodes.first { $0.id == id } ?? nodes[0] }
    private func center(_ n: FlowNode, _ w: CGFloat, _ h: CGFloat) -> CGPoint {
        CGPoint(x: n.pos.x * w, y: n.pos.y * h)
    }
    private func isHot(_ id: String, _ p: Double) -> Bool {
        if node(id).startActive { return true }
        return messages.contains { ($0.from == id && p >= $0.start) || ($0.to == id && p >= $0.end) }
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height - (footnote == nil ? 0 : 22)

            ZStack {
                // Static wires between message endpoints.
                Path { path in
                    var seen = Set<String>()
                    for m in messages {
                        let key = [m.from, m.to].sorted().joined()
                        guard !seen.contains(key) else { continue }
                        seen.insert(key)
                        path.move(to: center(node(m.from), w, h))
                        path.addLine(to: center(node(m.to), w, h))
                    }
                }
                .stroke(Theme.stroke, style: StrokeStyle(lineWidth: 1.5, dash: [4, 5]))

                LoopingTimeline(period: period) { p in
                    ZStack {
                        ForEach(nodes) { n in
                            HostNode(title: n.title, subtitle: n.subtitle, system: n.system,
                                     color: n.color, active: isHot(n.id, p))
                                .position(center(n, w, h))
                        }
                        ForEach(messages) { m in
                            if p >= m.start && p <= m.end {
                                let t = ease(CGFloat((p - m.start) / max(0.0001, m.end - m.start)))
                                TokenChip(text: m.label, color: m.color, system: m.system)
                                    .position(lerp(center(node(m.from), w, h), center(node(m.to), w, h), t))
                                    .transition(.opacity)
                            }
                        }
                    }
                }
            }
            .frame(width: w, height: h)

            if let footnote {
                Text(footnote)
                    .font(Theme.mono(9.5))
                    .foregroundStyle(Theme.textDim)
                    .frame(width: w, height: 22)
                    .position(x: w / 2, y: h + 11)
            }
        }
    }
}

// MARK: - Sequence stage (staged reveal engine)

struct SequenceStep: Identifiable {
    let id = UUID()
    let system: String
    let title: String
    let detail: String
    var color: Color = Theme.red
}

/// A vertical chain of steps that light up one after another, with a glowing
/// token advancing the connector. Powers the Cyber Kill Chain.
struct SequenceStage: View {
    let steps: [SequenceStep]
    var breakAt: Int? = nil
    var breakLabel: String = "Defender breaks the chain"

    var body: some View {
        PhaseAnimator(Array(0...steps.count)) { active in
            VStack(spacing: 0) {
                ForEach(steps.indices, id: \.self) { i in
                    HStack(spacing: 12) {
                        ZStack {
                            if i < steps.count - 1 {
                                Rectangle()
                                    .fill(i < active ? steps[i].color : Theme.stroke)
                                    .frame(width: 2, height: 26)
                                    .offset(y: 22)
                            }
                            Circle()
                                .fill(i < active ? steps[i].color : Theme.surfaceHi)
                                .frame(width: 26, height: 26)
                                .overlay(Circle().strokeBorder(steps[i].color.opacity(i < active ? 1 : 0.3), lineWidth: 1.5))
                                .shadow(color: i == active - 1 ? steps[i].color.opacity(0.8) : .clear, radius: 8)
                            Image(systemName: steps[i].system)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(i < active ? .black : Theme.textDim)
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text(steps[i].title)
                                .font(Theme.mono(11, .bold))
                                .foregroundStyle(i < active ? Theme.textPrimary : Theme.textDim)
                            Text(steps[i].detail)
                                .font(Theme.mono(8.5))
                                .foregroundStyle(Theme.textDim)
                            if breakAt == i && i < active {
                                Text("✂︎ " + breakLabel)
                                    .font(Theme.mono(8.5, .bold))
                                    .foregroundStyle(Theme.blue)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 30)
                }
            }
        } animation: { _ in .easeInOut(duration: 0.45).delay(0.45) }
    }
}

// MARK: - Cycle stage (looping ring of phases)

struct CycleNode: Identifiable {
    let id = UUID()
    let system: String
    let title: String
    var color: Color = Theme.blue
}

/// Phases arranged around a ring with a rotating highlight. Powers the Incident
/// Response lifecycle and the Threat Hunting loop.
struct CycleStage: View {
    let nodes: [CycleNode]
    let centerTitle: String
    let centerSystem: String
    var accent: Color = Theme.blue

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let radius = min(w, h) / 2 - 36
            let c = CGPoint(x: w / 2, y: h / 2)
            PhaseAnimator(Array(0..<nodes.count)) { active in
                ZStack {
                    Circle()
                        .strokeBorder(Theme.stroke, style: StrokeStyle(lineWidth: 1.5, dash: [3, 6]))
                        .frame(width: radius * 2, height: radius * 2)
                        .position(c)

                    VStack(spacing: 3) {
                        Image(systemName: centerSystem).font(.system(size: 17, weight: .bold)).foregroundStyle(accent)
                        Text(centerTitle).font(Theme.mono(9, .bold)).foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(width: 96)
                    .position(c)

                    ForEach(nodes.indices, id: \.self) { i in
                        let angle = (Double(i) / Double(nodes.count)) * 2 * .pi - .pi / 2
                        let pt = CGPoint(x: c.x + cos(angle) * radius, y: c.y + sin(angle) * radius)
                        let on = i == active
                        VStack(spacing: 2) {
                            ZStack {
                                Circle().fill(on ? nodes[i].color : Theme.surfaceHi)
                                    .frame(width: 34, height: 34)
                                    .overlay(Circle().strokeBorder(nodes[i].color.opacity(on ? 1 : 0.35), lineWidth: 1.5))
                                    .shadow(color: on ? nodes[i].color.opacity(0.8) : .clear, radius: 9)
                                Image(systemName: nodes[i].system)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(on ? .black : Theme.textDim)
                            }
                            Text(nodes[i].title)
                                .font(Theme.mono(8, .bold))
                                .foregroundStyle(on ? Theme.textPrimary : Theme.textDim)
                                .multilineTextAlignment(.center)
                                .frame(width: 74)
                        }
                        .position(pt)
                    }
                }
            } animation: { _ in .easeInOut(duration: 0.5).delay(0.55) }
        }
    }
}

// MARK: - Ladder stage (privilege climb)

struct LadderRung: Identifiable {
    let id = UUID()
    let level: String         // e.g. "root"  /  uid label
    let via: String           // technique used to reach it
    let system: String
    var color: Color = Theme.red
}

/// A token climbing rungs from low privilege to high, each rung annotated with
/// the technique used. Powers Privilege Escalation.
struct LadderStage: View {
    let rungs: [LadderRung]   // ordered bottom (index 0) → top

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let n = rungs.count
            let stepH = h / CGFloat(n)
            PhaseAnimator(Array(0..<n)) { active in
                ZStack {
                    ForEach(rungs.indices, id: \.self) { i in
                        let reached = (n - 1 - i) <= active   // index 0 is bottom; active counts from bottom
                        let y = h - (CGFloat(i) + 0.5) * stepH
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 9)
                                    .fill(reached ? rungs[i].color.opacity(0.22) : Theme.surfaceHi)
                                    .frame(width: 40, height: 30)
                                    .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(rungs[i].color.opacity(reached ? 1 : 0.3), lineWidth: 1.2))
                                Image(systemName: rungs[i].system)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(reached ? rungs[i].color : Theme.textDim)
                            }
                            VStack(alignment: .leading, spacing: 0) {
                                Text(rungs[i].level).font(Theme.mono(11, .bold))
                                    .foregroundStyle(reached ? Theme.textPrimary : Theme.textDim)
                                Text(rungs[i].via).font(Theme.mono(8.5))
                                    .foregroundStyle(reached ? rungs[i].color : Theme.textDim)
                            }
                            Spacer(minLength: 0)
                        }
                        .position(x: w / 2, y: y)
                        .frame(width: w)
                    }
                    // Climbing token
                    let ty = h - (CGFloat(active) + 0.5) * stepH
                    Image(systemName: "figure.climbing")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.amber)
                        .shadow(color: Theme.amber, radius: 8)
                        .position(x: w - 24, y: ty)
                }
            } animation: { _ in .easeInOut(duration: 0.5).delay(0.5) }
        }
    }
}
