import SwiftUI

// MARK: - Active Directory forest (fundamentals)

/// A small hierarchy that reveals domain → OUs → the domain controller, making
/// the point that every secret in the domain ultimately lives on the DC.
struct ADForestView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            LoopingTimeline(period: 6) { p in
                let step = min(3, Int(p * 4))
                ZStack {
                    // connecting lines
                    Path { path in
                        let top = CGPoint(x: w * 0.5, y: h * 0.20)
                        for x in [0.22, 0.5, 0.78] {
                            path.move(to: top)
                            path.addLine(to: CGPoint(x: w * x, y: h * 0.56))
                        }
                        path.move(to: CGPoint(x: w * 0.78, y: h * 0.62))
                        path.addLine(to: CGPoint(x: w * 0.78, y: h * 0.86))
                    }
                    .stroke(Theme.stroke, style: StrokeStyle(lineWidth: 1.3, dash: [3, 4]))

                    node("corp.local", "domain root", "lock.shield.fill", Theme.blue, on: true)
                        .position(x: w * 0.5, y: h * 0.20)

                    node("Workstations", "OU", "desktopcomputer", Theme.teal, on: step >= 1)
                        .position(x: w * 0.22, y: h * 0.56)
                    node("Servers", "OU", "server.rack", Theme.teal, on: step >= 1)
                        .position(x: w * 0.5, y: h * 0.56)
                    node("Domain\nControllers", "OU", "building.columns.fill", Theme.violet, on: step >= 2)
                        .position(x: w * 0.78, y: h * 0.56)

                    node("DC01 · NTDS.dit", "every hash", "key.fill", Theme.red, on: step >= 3)
                        .position(x: w * 0.78, y: h * 0.86)

                    if step >= 3 {
                        Text("own the DC → own the domain")
                            .font(Theme.mono(8.5, .bold)).foregroundStyle(Theme.red)
                            .position(x: w * 0.3, y: h * 0.86)
                    }
                }
                .animation(.easeInOut(duration: 0.45), value: step)
            }
        }
    }

    private func node(_ title: String, _ sub: String, _ icon: String, _ color: Color, on: Bool) -> some View {
        VStack(spacing: 3) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(color.opacity(on ? 0.20 : 0.05))
                RoundedRectangle(cornerRadius: 10).strokeBorder(color.opacity(on ? 0.9 : 0.3), lineWidth: 1.2)
                Image(systemName: icon).font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(on ? color : Theme.textDim)
            }
            .frame(width: 46, height: 38)
            .shadow(color: on ? color.opacity(0.5) : .clear, radius: 7)
            Text(title).font(Theme.mono(8.5, .bold)).multilineTextAlignment(.center)
                .foregroundStyle(on ? Theme.textPrimary : Theme.textDim)
            Text(sub).font(Theme.mono(7)).foregroundStyle(Theme.textDim)
        }
        .frame(width: 88)
    }
}

// MARK: - DCSync → Golden Ticket

struct DCSyncView: View {
    var body: some View {
        FlowStage(
            nodes: [
                FlowNode(id: "atk", pos: CGPoint(x: 0.16, y: 0.5), title: "Attacker", subtitle: "has DA rights",
                         system: "desktopcomputer", color: Theme.red, startActive: true),
                FlowNode(id: "dc", pos: CGPoint(x: 0.84, y: 0.28), title: "DC", subtitle: "replication API",
                         system: "lock.shield.fill", color: Theme.blue, startActive: true),
                FlowNode(id: "tkt", pos: CGPoint(x: 0.84, y: 0.80), title: "Golden Ticket", subtitle: "any user, forever",
                         system: "ticket.fill", color: Theme.violet)
            ],
            messages: [
                FlowMessage(from: "atk", to: "dc", label: "DRSUAPI: replicate", color: Theme.teal, start: 0.05, end: 0.28),
                FlowMessage(from: "dc", to: "atk", label: "krbtgt NTLM hash", color: Theme.red, start: 0.33, end: 0.58, system: "key.fill"),
                FlowMessage(from: "atk", to: "tkt", label: "forge TGT", color: Theme.red, start: 0.63, end: 0.90, system: "crown.fill")
            ],
            period: 7,
            footnote: "DCSync pulls the krbtgt hash → forge a ticket valid as anyone, indefinitely"
        )
    }
}

// MARK: - BloodHound attack path

/// A directed graph of AD objects with one shortest path to Domain Admin
/// lighting up edge by edge — the way BloodHound surfaces privilege chains.
struct AttackPathView: View {
    private struct Edge { let from: Int; let to: Int; let label: String }
    private let pts: [CGPoint] = [
        CGPoint(x: 0.12, y: 0.30),   // 0 you
        CGPoint(x: 0.40, y: 0.74),   // 1 group
        CGPoint(x: 0.66, y: 0.30),   // 2 computer
        CGPoint(x: 0.90, y: 0.72)    // 3 DA
    ]
    private let labels: [(t: String, s: String, icon: String, c: Color)] = [
        ("j.doe", "you", "person.fill", Theme.teal),
        ("IT Support", "group", "person.3.fill", Theme.amber),
        ("FILE01", "AdminTo", "desktopcomputer", Theme.amber),
        ("Domain Admins", "owned", "crown.fill", Theme.red)
    ]
    private let edges = [
        Edge(from: 0, to: 1, label: "MemberOf"),
        Edge(from: 1, to: 2, label: "AdminTo"),
        Edge(from: 2, to: 3, label: "HasSession")
    ]

    private func pt(_ i: Int, _ w: CGFloat, _ h: CGFloat) -> CGPoint {
        CGPoint(x: pts[i].x * w, y: pts[i].y * h)
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            LoopingTimeline(period: 6) { p in
                let active = min(edges.count, Int(p * Double(edges.count + 1)))
                ZStack {
                    ForEach(edges.indices, id: \.self) { i in
                        let on = i < active
                        let a = pt(edges[i].from, w, h), b = pt(edges[i].to, w, h)
                        Path { path in path.move(to: a); path.addLine(to: b) }
                        .stroke(on ? Theme.red : Theme.stroke,
                                style: StrokeStyle(lineWidth: on ? 2 : 1.3, dash: on ? [] : [3, 4]))
                        Text(edges[i].label)
                            .font(Theme.mono(7.5, .bold))
                            .foregroundStyle(on ? Theme.red : Theme.textDim)
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .background(Theme.background, in: Capsule())
                            .position(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
                    }
                    ForEach(pts.indices, id: \.self) { i in
                        node(labels[i], on: i <= active).position(pt(i, w, h))
                    }
                    Text("shortest path to Domain Admin")
                        .font(Theme.mono(8)).foregroundStyle(Theme.textDim)
                        .position(x: w * 0.5, y: h * 0.97)
                }
                .animation(.easeInOut(duration: 0.4), value: active)
            }
        }
    }

    private func node(_ l: (t: String, s: String, icon: String, c: Color), on: Bool) -> some View {
        VStack(spacing: 2) {
            ZStack {
                Circle().fill(on ? l.c.opacity(0.22) : Theme.surfaceHi).frame(width: 34, height: 34)
                Circle().strokeBorder(l.c.opacity(on ? 1 : 0.35), lineWidth: 1.5).frame(width: 34, height: 34)
                Image(systemName: l.icon).font(.system(size: 13, weight: .bold))
                    .foregroundStyle(on ? l.c : Theme.textDim)
            }
            .shadow(color: on ? l.c.opacity(0.6) : .clear, radius: 7)
            Text(l.t).font(Theme.mono(8, .bold)).foregroundStyle(on ? Theme.textPrimary : Theme.textDim)
            Text(l.s).font(Theme.mono(7)).foregroundStyle(on ? l.c : Theme.textDim)
        }
        .frame(width: 78)
    }
}

// MARK: - Tiered administration (blue)

/// Three admin tiers stacked, with a stolen low-tier credential blocked from
/// climbing into Tier 0 — the structural defeat of lateral movement to DA.
struct ADTieringView: View {
    private let tiers: [(t: String, s: String, icon: String, c: Color)] = [
        ("TIER 0", "DCs · Domain Admins", "crown.fill", Theme.red),
        ("TIER 1", "servers · app admins", "server.rack", Theme.amber),
        ("TIER 2", "workstations · users", "desktopcomputer", Theme.teal)
    ]
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let rowH = h / 3
            LoopingTimeline(period: 5) { p in
                let climb = ease(CGFloat(min(max((p - 0.15) / 0.6, 0), 1)))   // 0..1
                let blocked = climb > 0.66
                ZStack {
                    ForEach(tiers.indices, id: \.self) { i in
                        let y = rowH * (CGFloat(i) + 0.5)
                        tierRow(tiers[i]).position(x: w * 0.42, y: y)
                    }
                    // climbing stolen credential, from tier 2 toward tier 0
                    let startY = rowH * 2.5, endY = rowH * 0.5
                    let y = startY + (endY - startY) * min(climb, 0.62)
                    Image(systemName: "key.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(blocked ? Theme.red : Theme.amber)
                        .shadow(color: (blocked ? Theme.red : Theme.amber).opacity(0.7), radius: 6)
                        .position(x: w * 0.84, y: y)
                    if blocked {
                        // barrier between tier 1 and tier 0
                        Rectangle().fill(Theme.red)
                            .frame(width: w * 0.5, height: 2)
                            .position(x: w * 0.5, y: rowH)
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.red)
                            .position(x: w * 0.84, y: rowH * 1.0)
                        Text("Tier 0 admins never log on lower → stolen creds can't climb")
                            .font(Theme.mono(7.5, .bold)).foregroundStyle(Theme.red)
                            .multilineTextAlignment(.center).frame(width: w * 0.7)
                            .position(x: w * 0.5, y: rowH * 0.16)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: blocked)
            }
        }
    }
    private func tierRow(_ t: (t: String, s: String, icon: String, c: Color)) -> some View {
        HStack(spacing: 9) {
            ZStack {
                RoundedRectangle(cornerRadius: 9).fill(t.c.opacity(0.18)).frame(width: 38, height: 32)
                RoundedRectangle(cornerRadius: 9).strokeBorder(t.c.opacity(0.8), lineWidth: 1.2).frame(width: 38, height: 32)
                Image(systemName: t.icon).font(.system(size: 14, weight: .bold)).foregroundStyle(t.c)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(t.t).font(Theme.mono(10, .bold)).foregroundStyle(t.c)
                Text(t.s).font(Theme.mono(8)).foregroundStyle(Theme.textDim)
            }
        }
        .frame(width: 200, alignment: .leading)
    }
}
