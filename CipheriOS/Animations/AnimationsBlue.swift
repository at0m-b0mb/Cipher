import SwiftUI

// MARK: - Defense in depth

struct DefenseInDepthView: View {
    private let rings: [(label: String, scale: CGFloat, color: Color)] = [
        ("Perimeter", 1.00, Theme.violet),
        ("Network", 0.80, Theme.blue),
        ("Endpoint", 0.60, Theme.teal),
        ("Identity", 0.42, Theme.amber),
        ("Data", 0.24, Theme.green)
    ]
    private let blockAt = 2   // caught at the Endpoint layer

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let c = CGPoint(x: w * 0.5, y: h * 0.5)
            let maxR = min(w, h) * 0.44
            LoopingTimeline(period: 6) { p in
                let travel = ease(CGFloat(min(p / 0.6, 1)))
                let startR = maxR * 1.18
                let endR = maxR * rings[blockAt].scale
                let tokenR = startR + (endR - startR) * travel
                let blocked = p > 0.64
                let angle = -Double.pi / 4
                let tokenPos = CGPoint(x: c.x + CGFloat(cos(angle)) * tokenR,
                                       y: c.y + CGFloat(sin(angle)) * tokenR)
                ZStack {
                    ForEach(rings.indices, id: \.self) { i in
                        let r = maxR * rings[i].scale
                        let reached = tokenR <= r * 1.03
                        let isBlock = i == blockAt && blocked
                        Circle()
                            .strokeBorder(rings[i].color.opacity(reached ? 1 : 0.4), lineWidth: isBlock ? 3 : 1.5)
                            .frame(width: r * 2, height: r * 2)
                            .position(c)
                            .shadow(color: isBlock ? Theme.red.opacity(0.7) : .clear, radius: 8)
                        Text(rings[i].label)
                            .font(Theme.mono(8, .bold))
                            .foregroundStyle(rings[i].color)
                            .position(x: c.x, y: c.y - r + 9)
                    }
                    Image(systemName: "doc.fill").foregroundStyle(Theme.green).font(.system(size: 13)).position(c)

                    Image(systemName: blocked ? "xmark.octagon.fill" : "figure.walk")
                        .foregroundStyle(blocked ? Theme.red : Theme.amber)
                        .font(.system(size: 16, weight: .bold))
                        .position(tokenPos)
                        .shadow(color: (blocked ? Theme.red : Theme.amber).opacity(0.7), radius: 6)

                    if blocked {
                        Text("DETECTED & CONTAINED")
                            .font(Theme.mono(9, .bold)).foregroundStyle(Theme.red)
                            .position(x: c.x, y: h * 0.95)
                    }
                }
            }
        }
    }
}

// MARK: - SIEM detection pipeline

struct SiemPipelineView: View {
    var body: some View {
        FlowStage(
            nodes: [
                FlowNode(id: "ep", pos: CGPoint(x: 0.13, y: 0.22), title: "Endpoint", subtitle: "Sysmon",
                         system: "laptopcomputer", color: Theme.teal, startActive: true),
                FlowNode(id: "fw", pos: CGPoint(x: 0.13, y: 0.5), title: "Firewall", subtitle: "",
                         system: "shield.fill", color: Theme.teal, startActive: true),
                FlowNode(id: "dns", pos: CGPoint(x: 0.13, y: 0.78), title: "DNS", subtitle: "",
                         system: "globe", color: Theme.teal, startActive: true),
                FlowNode(id: "siem", pos: CGPoint(x: 0.52, y: 0.5), title: "SIEM", subtitle: "normalize + rules",
                         system: "square.stack.3d.up.fill", color: Theme.blue, startActive: true),
                FlowNode(id: "an", pos: CGPoint(x: 0.88, y: 0.5), title: "Analyst", subtitle: "triage",
                         system: "person.fill", color: Theme.blue, startActive: true)
            ],
            messages: [
                FlowMessage(from: "ep", to: "siem", label: "log", color: Theme.teal, start: 0.04, end: 0.28),
                FlowMessage(from: "fw", to: "siem", label: "log", color: Theme.teal, start: 0.12, end: 0.34),
                FlowMessage(from: "dns", to: "siem", label: "log", color: Theme.teal, start: 0.20, end: 0.42),
                FlowMessage(from: "siem", to: "an", label: "⚠ ALERT", color: Theme.red, start: 0.58, end: 0.88, system: "exclamationmark.triangle.fill")
            ],
            period: 6,
            footnote: "telemetry normalized → a detection rule matches → prioritized alert to an analyst"
        )
    }
}

// MARK: - Incident response lifecycle

struct IncidentResponseView: View {
    var body: some View {
        CycleStage(nodes: [
            CycleNode(system: "shippingbox.fill", title: "Prepare", color: Theme.blue),
            CycleNode(system: "magnifyingglass", title: "Identify", color: Theme.blue),
            CycleNode(system: "hand.raised.fill", title: "Contain", color: Theme.amber),
            CycleNode(system: "trash.fill", title: "Eradicate", color: Theme.red),
            CycleNode(system: "arrow.clockwise", title: "Recover", color: Theme.green),
            CycleNode(system: "book.fill", title: "Lessons", color: Theme.violet)
        ], centerTitle: "IR\nlifecycle", centerSystem: "cross.case.fill", accent: Theme.blue)
    }
}

// MARK: - Threat hunting loop

struct ThreatHuntingView: View {
    var body: some View {
        CycleStage(nodes: [
            CycleNode(system: "lightbulb.fill", title: "Hypothesize", color: Theme.blue),
            CycleNode(system: "terminal.fill", title: "Query data", color: Theme.teal),
            CycleNode(system: "magnifyingglass", title: "Investigate", color: Theme.amber),
            CycleNode(system: "bell.badge.fill", title: "Automate detection", color: Theme.green)
        ], centerTitle: "hunt\nloop", centerSystem: "binoculars.fill", accent: Theme.blue)
    }
}

// MARK: - MITRE ATT&CK path

struct MITREAttackView: View {
    private let columns: [(tactic: String, techniques: [String], path: Int)] = [
        ("Initial\nAccess", ["Phishing", "Valid Accts", "Exploit"], 0),
        ("Execution", ["PowerShell", "WMI", "Sched. Task"], 0),
        ("Cred\nAccess", ["Kerberoast", "LSASS dump", "Brute force"], 0),
        ("Lateral\nMove", ["Pass-the-Hash", "RDP", "PsExec"], 0),
        ("Impact", ["Ransomware", "Exfil", "Wipe"], 0)
    ]

    var body: some View {
        PhaseAnimator(Array(0...columns.count)) { active in
            HStack(alignment: .top, spacing: 4) {
                ForEach(columns.indices, id: \.self) { ci in
                    VStack(spacing: 5) {
                        Text(columns[ci].tactic)
                            .font(Theme.mono(8, .bold)).foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center).frame(height: 24)
                        ForEach(columns[ci].techniques.indices, id: \.self) { ti in
                            let onPath = ti == columns[ci].path && ci < active
                            Text(columns[ci].techniques[ti])
                                .font(Theme.mono(7.5, .bold))
                                .foregroundStyle(onPath ? .black : Theme.textDim)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, minHeight: 30)
                                .padding(.horizontal, 2)
                                .background((onPath ? Theme.red : Theme.surfaceHi), in: RoundedRectangle(cornerRadius: 6))
                                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder((onPath ? Theme.red : Theme.stroke), lineWidth: 1))
                                .shadow(color: onPath ? Theme.red.opacity(0.6) : .clear, radius: 5)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        } animation: { _ in .easeInOut(duration: 0.45).delay(0.55) }
    }
}
