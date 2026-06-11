import SwiftUI

// Local staged-reveal scaffold (file-private; mirrors the one in AnimationsWeb).
private struct Staged<Content: View>: View {
    let steps: Int
    var stepSeconds: Double = 1.15
    @ViewBuilder var content: (Int) -> Content
    var body: some View {
        LoopingTimeline(period: Double(steps + 1) * stepSeconds) { p in
            let step = min(steps, Int(p * Double(steps + 1)))
            content(step)
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(.easeInOut(duration: 0.4), value: step)
        }
    }
}

private struct Field<Content: View>: View {
    let caption: String
    var tint: Color = Theme.stroke
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(caption).font(Theme.mono(8, .bold)).tracking(0.6).foregroundStyle(Theme.textDim)
            content()
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surfaceHi, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(tint, lineWidth: 1))
        }
    }
}

// MARK: - Cross-Site Request Forgery

struct CSRFView: View {
    var body: some View {
        FlowStage(
            nodes: [
                FlowNode(id: "vic", pos: CGPoint(x: 0.16, y: 0.32), title: "Victim", subtitle: "logged in to bank",
                         system: "person.crop.circle.fill", color: Theme.teal, startActive: true),
                FlowNode(id: "bank", pos: CGPoint(x: 0.84, y: 0.32), title: "Bank", subtitle: "trusts the cookie",
                         system: "building.columns.fill", color: Theme.blue, startActive: true),
                FlowNode(id: "evil", pos: CGPoint(x: 0.5, y: 0.84), title: "Evil site", subtitle: "attacker page",
                         system: "exclamationmark.triangle.fill", color: Theme.red, startActive: true)
            ],
            messages: [
                FlowMessage(from: "vic", to: "evil", label: "visit /promo", color: Theme.teal, start: 0.04, end: 0.22),
                FlowMessage(from: "evil", to: "vic", label: "hidden auto-form", color: Theme.red, start: 0.26, end: 0.44, system: "doc.badge.gearshape"),
                FlowMessage(from: "vic", to: "bank", label: "POST /transfer + cookie", color: Theme.red, start: 0.50, end: 0.72, system: "lock.fill"),
                FlowMessage(from: "bank", to: "vic", label: "200 · funds moved", color: Theme.amber, start: 0.76, end: 0.92)
            ],
            period: 7,
            footnote: "the browser attaches the bank cookie automatically — so the forged request looks genuine"
        )
    }
}

// MARK: - JWT token attacks

struct JWTAttackView: View {
    var body: some View {
        Staged(steps: 3) { step in
            VStack(alignment: .leading, spacing: 12) {
                Text("JSON WEB TOKEN").font(Theme.mono(8, .bold)).foregroundStyle(Theme.textDim)
                // three segments
                HStack(spacing: 4) {
                    seg(step >= 1 ? "alg:none" : "alg:HS256", Theme.violet, changed: step >= 1)
                    Text(".").foregroundStyle(Theme.textDim)
                    seg(step >= 1 ? "role:ADMIN" : "role:user", Theme.amber, changed: step >= 1)
                    Text(".").foregroundStyle(Theme.textDim)
                    seg(step >= 2 ? "(stripped)" : "9f3a8c…", Theme.green, changed: step >= 2)
                }
                .font(Theme.mono(9, .bold))

                if step >= 1 {
                    Label("tamper the payload, set alg to none", systemImage: "pencil.and.scribble")
                        .font(Theme.mono(8.5, .bold)).foregroundStyle(Theme.amber)
                }
                if step >= 2 {
                    Label("drop the signature — server never verifies it", systemImage: "signature")
                        .font(Theme.mono(8.5, .bold)).foregroundStyle(Theme.red)
                }

                HStack(spacing: 8) {
                    Image(systemName: step >= 3 ? "lock.open.fill" : "lock.fill")
                        .font(.system(size: 20)).foregroundStyle(step >= 3 ? Theme.red : Theme.blue)
                    Text(step >= 3 ? "ACCEPTED — authenticated as admin" : "server validates token…")
                        .font(Theme.mono(10, .bold))
                        .foregroundStyle(step >= 3 ? Theme.red : Theme.textSecondary)
                }
                .padding(.top, 2)
                Spacer(minLength: 0)
            }
        }
    }
    private func seg(_ t: String, _ c: Color, changed: Bool) -> some View {
        Text(t)
            .foregroundStyle(changed ? c : Theme.textSecondary)
            .padding(.horizontal, 7).padding(.vertical, 5)
            .background((changed ? c : Theme.textDim).opacity(0.15), in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder((changed ? c : Theme.stroke).opacity(0.7), lineWidth: 1))
    }
}

// MARK: - Source-to-sink (white-box review)

/// Tracing untrusted input from where it enters (source) to where it does
/// damage (sink) — the core white-box (OSWE) reading skill.
struct SourceReviewView: View {
    private let stages: [(t: String, s: String, icon: String, c: Color)] = [
        ("SOURCE", "req.body.name  ← user input", "arrow.down.circle.fill", Theme.amber),
        ("FLOWS THROUGH", "buildQuery(name)  ← no validation", "arrow.triangle.branch", Theme.textSecondary),
        ("SINK", "db.exec(\"… \" + name)  ← SQL", "flame.fill", Theme.red)
    ]
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let n = stages.count
            let rowH = (h - 20) / CGFloat(n)
            LoopingTimeline(period: 5) { p in
                let active = min(n - 1, Int(p * Double(n + 1)))
                ZStack {
                    // connecting spine
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.18, y: rowH * 0.5))
                        path.addLine(to: CGPoint(x: w * 0.18, y: rowH * (CGFloat(n) - 0.5)))
                    }
                    .stroke(Theme.stroke, style: StrokeStyle(lineWidth: 2, dash: [3, 4]))

                    ForEach(stages.indices, id: \.self) { i in
                        let on = i <= active
                        let y = rowH * (CGFloat(i) + 0.5)
                        HStack(spacing: 10) {
                            ZStack {
                                Circle().fill(on ? stages[i].c.opacity(0.2) : Theme.surfaceHi).frame(width: 30, height: 30)
                                Circle().strokeBorder(stages[i].c.opacity(on ? 1 : 0.3), lineWidth: 1.4).frame(width: 30, height: 30)
                                Image(systemName: stages[i].icon).font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(on ? stages[i].c : Theme.textDim)
                            }
                            .shadow(color: on ? stages[i].c.opacity(0.5) : .clear, radius: 6)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(stages[i].t).font(Theme.mono(9, .bold)).foregroundStyle(on ? stages[i].c : Theme.textDim)
                                Text(stages[i].s).font(Theme.mono(8.5)).foregroundStyle(on ? Theme.textPrimary : Theme.textDim)
                            }
                            Spacer(minLength: 0)
                        }
                        .position(x: w * 0.5, y: y)
                        .frame(width: w * 0.92)
                    }
                    if active >= n - 1 {
                        Text("tainted input reaches a dangerous sink → injection")
                            .font(Theme.mono(8, .bold)).foregroundStyle(Theme.red)
                            .position(x: w * 0.5, y: h - 8)
                    }
                }
                .animation(.easeInOut(duration: 0.4), value: active)
            }
        }
    }
}

// MARK: - Client-side attack (malicious document)

struct ClientSideView: View {
    var body: some View {
        Staged(steps: 3) { step in
            VStack(alignment: .leading, spacing: 11) {
                // the document
                HStack(spacing: 10) {
                    Image(systemName: "doc.fill").font(.system(size: 22)).foregroundStyle(Theme.blue)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Invoice_Q2.docm").font(Theme.mono(10, .bold)).foregroundStyle(Theme.textPrimary)
                        Text("macro-enabled attachment").font(Theme.mono(8)).foregroundStyle(Theme.textDim)
                    }
                }

                if step >= 1 {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.shield.fill").foregroundStyle(Theme.amber)
                        Text("⚠ Enable Content").font(Theme.mono(9, .bold)).foregroundStyle(Theme.amber)
                        Text("← victim clicks").font(Theme.mono(8)).foregroundStyle(Theme.textDim)
                    }
                    .padding(7)
                    .background(Theme.amber.opacity(0.12), in: RoundedRectangle(cornerRadius: 7))
                }

                if step >= 2 {
                    Field(caption: "VBA MACRO RUNS", tint: Theme.red.opacity(0.6)) {
                        Text("Shell(\"powershell -enc SQBFAFgA…\")")
                            .font(Theme.mono(9, .bold)).foregroundStyle(Theme.red)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if step >= 3 {
                    HStack(spacing: 8) {
                        Image(systemName: "antenna.radiowaves.left.and.right").foregroundStyle(Theme.red)
                        Text("beacon → attacker C2").font(Theme.mono(9, .bold)).foregroundStyle(Theme.red)
                        Spacer()
                        HostNode(title: "Attacker", subtitle: "shell", system: "desktopcomputer", color: Theme.red)
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }
}
