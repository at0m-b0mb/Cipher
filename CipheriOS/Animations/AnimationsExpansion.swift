import SwiftUI

// MARK: - Expansion explainers
//
// Six visualizations for the curriculum expansion: OS process memory and PKI
// certificate chains (Fundamentals), staged payloads and Windows token theft
// (Red Team), and IDS detection plus a secure-SDLC pipeline (Blue Team). They
// reuse FlowStage / SequenceStage where the shape fits and the shared
// `netNode` / `lerp` / `ease` helpers otherwise.

// MARK: 1 — Processes & memory layout (Fundamentals)

struct ProcessMemoryView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let boxX = w * 0.30
            let boxW = w * 0.42
            let top = h * 0.08, bot = h * 0.80
            let H = bot - top
            LoopingTimeline(period: 6) { p in
                let pushing = p < 0.5
                let stackN = pushing ? min(4, 1 + Int(p / 0.5 * 4)) : 4
                let heapN = pushing ? 1 : min(4, 1 + Int((p - 0.5) / 0.5 * 4))
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Theme.stroke, lineWidth: 1)
                        .frame(width: boxW, height: H)
                        .position(x: boxX, y: (top + bot) / 2)

                    region("Data / BSS", Theme.teal, y: top + H * 0.84, boxX: boxX, boxW: boxW)
                    region("Text (code)", Theme.blue, y: top + H * 0.96, boxX: boxX, boxW: boxW)

                    ForEach(0..<stackN, id: \.self) { i in
                        memBlock("frame \(stackN - i)", Theme.red, boxX: boxX, boxW: boxW, y: top + 12 + CGFloat(i) * 20)
                    }
                    ForEach(0..<heapN, id: \.self) { i in
                        memBlock("malloc", Theme.amber, boxX: boxX, boxW: boxW, y: top + H * 0.64 - CGFloat(i) * 20)
                    }

                    Text("high addresses").font(Theme.mono(6.5)).foregroundStyle(Theme.textDim)
                        .position(x: boxX, y: top - 6)
                    Text("low addresses").font(Theme.mono(6.5)).foregroundStyle(Theme.textDim)
                        .position(x: boxX, y: bot + 6)

                    VStack(alignment: .leading, spacing: 9) {
                        labelRow("Stack ↓", Theme.red, "locals & return addresses; grows DOWN each call")
                        labelRow("Heap ↑", Theme.amber, "malloc/new; grows UP as you allocate")
                        labelRow("Data", Theme.teal, "globals & static variables")
                        labelRow("Text", Theme.blue, "the program's machine code (read-only)")
                    }
                    .frame(width: w * 0.4)
                    .position(x: w * 0.78, y: h * 0.42)

                    Text(pushing ? "call() → push a stack frame" : "malloc() → grow the heap")
                        .font(Theme.mono(9, .bold))
                        .foregroundStyle(pushing ? Theme.red : Theme.amber)
                        .position(x: w * 0.5, y: h * 0.95)
                }
                .animation(.easeInOut(duration: 0.3), value: pushing)
            }
        }
    }

    private func memBlock(_ label: String, _ color: Color, boxX: CGFloat, boxW: CGFloat, y: CGFloat) -> some View {
        Text(label)
            .font(Theme.mono(8, .bold)).foregroundStyle(.black)
            .frame(width: boxW - 12, height: 16)
            .background(color, in: RoundedRectangle(cornerRadius: 4))
            .position(x: boxX, y: y)
    }

    private func region(_ label: String, _ color: Color, y: CGFloat, boxX: CGFloat, boxW: CGFloat) -> some View {
        Text(label)
            .font(Theme.mono(8, .bold)).foregroundStyle(.black)
            .frame(width: boxW - 12, height: 18)
            .background(color.opacity(0.85), in: RoundedRectangle(cornerRadius: 4))
            .position(x: boxX, y: y)
    }

    private func labelRow(_ t: String, _ c: Color, _ d: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(t).font(Theme.mono(9, .bold)).foregroundStyle(c).frame(width: 48, alignment: .leading)
            Text(d).font(Theme.mono(7.5)).foregroundStyle(Theme.textDim)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: 2 — Certificate chain / PKI (Fundamentals)

struct CertChainView: View {
    var body: some View {
        LoopingTimeline(period: 5) { p in
            let step = min(3, Int(p * 4))
            VStack(spacing: 7) {
                certCard("Root CA", "self-signed · in the trust store", Theme.violet, lit: step >= 0)
                arrow(lit: step >= 1)
                certCard("Intermediate CA", "signed by the Root", Theme.blue, lit: step >= 1)
                arrow(lit: step >= 2)
                certCard("shop.com", "leaf · the server's cert", Theme.teal, lit: step >= 2)
                HStack(spacing: 6) {
                    Image(systemName: step >= 3 ? "lock.fill" : "lock.open")
                    Text(step >= 3 ? "Chain links to a trusted Root → padlock turns green"
                                   : "browser walks leaf → root, checking each signature…")
                }
                .font(Theme.mono(8.5, .bold))
                .foregroundStyle(step >= 3 ? Theme.green : Theme.textDim)
                .multilineTextAlignment(.center)
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 4)
            .animation(.easeInOut(duration: 0.3), value: step)
        }
    }

    private func certCard(_ title: String, _ sub: String, _ color: Color, lit: Bool) -> some View {
        HStack(spacing: 9) {
            Image(systemName: "rosette")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(lit ? color : Theme.textDim)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(Theme.mono(11, .bold)).foregroundStyle(lit ? Theme.textPrimary : Theme.textDim)
                Text(sub).font(Theme.mono(8)).foregroundStyle(Theme.textDim)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .frame(width: 220)
        .background(color.opacity(lit ? 0.16 : 0.05), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(color.opacity(lit ? 0.9 : 0.25), lineWidth: 1.2))
        .shadow(color: lit ? color.opacity(0.4) : .clear, radius: 6)
    }

    private func arrow(lit: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.down").font(.system(size: 10, weight: .black))
            Text("signs").font(Theme.mono(7.5, .bold))
        }
        .foregroundStyle(lit ? Theme.amber : Theme.textDim)
    }
}

// MARK: 3 — Staged payload → Meterpreter (Red Team)

struct PayloadStagingView: View {
    var body: some View {
        FlowStage(
            nodes: [
                FlowNode(id: "atk", pos: CGPoint(x: 0.16, y: 0.5), title: "Attacker", subtitle: "msfconsole",
                         system: "terminal", color: Theme.red, startActive: true),
                FlowNode(id: "vic", pos: CGPoint(x: 0.84, y: 0.5), title: "Target", subtitle: "vuln service",
                         system: "server.rack", color: Theme.amber, startActive: true)
            ],
            messages: [
                FlowMessage(from: "atk", to: "vic", label: "exploit + stager", color: Theme.red, start: 0.02, end: 0.28),
                FlowMessage(from: "vic", to: "atk", label: "stager calls home", color: Theme.amber, start: 0.31, end: 0.52),
                FlowMessage(from: "atk", to: "vic", label: "stage: meterpreter", color: Theme.red, start: 0.55, end: 0.77),
                FlowMessage(from: "vic", to: "atk", label: "session 1 opened", color: Theme.green, start: 0.80, end: 0.99, system: "checkmark")
            ],
            period: 6,
            footnote: "A tiny stager lands first, calls home, and pulls down the full Meterpreter payload — then a session opens."
        )
    }
}

// MARK: 4 — Windows token theft (Red Team)

struct TokenTheftView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let me = CGPoint(x: w * 0.22, y: h * 0.40)
            let svc = CGPoint(x: w * 0.78, y: h * 0.40)
            LoopingTimeline(period: 5) { p in
                let stolen = p > 0.55
                let t = ease(CGFloat(min(max((p - 0.2) / 0.4, 0), 1)))
                let pos = lerp(svc, me, t)
                ZStack {
                    Path { pa in pa.move(to: me); pa.addLine(to: svc) }
                        .stroke(Theme.stroke, style: StrokeStyle(lineWidth: 1.5, dash: [4, 5]))

                    netNode(stolen ? "crown.fill" : "person.fill",
                            stolen ? "you\nSYSTEM" : "you\nuser",
                            stolen ? Theme.green : Theme.amber, true).position(me)
                    netNode("gearshape.2.fill", "service\nSYSTEM", Theme.blue, !stolen).position(svc)

                    if p > 0.2 && p < 0.62 {
                        TokenChip(text: "TOKEN: SYSTEM", color: Theme.red, system: "key.fill").position(pos)
                    }

                    Text("SeImpersonatePrivilege → duplicate a SYSTEM token → run as SYSTEM")
                        .font(Theme.mono(8)).foregroundStyle(Theme.textDim)
                        .multilineTextAlignment(.center).frame(width: w * 0.9)
                        .position(x: w * 0.5, y: h * 0.78)

                    Text(stolen ? "now running as NT AUTHORITY\\SYSTEM ✓"
                                : "coercing a privileged service to hand over its token…")
                        .font(Theme.mono(8.5, .bold))
                        .foregroundStyle(stolen ? Theme.green : Theme.amber)
                        .multilineTextAlignment(.center).frame(width: w * 0.9)
                        .position(x: w * 0.5, y: h * 0.92)
                }
                .animation(.easeInOut(duration: 0.3), value: stolen)
            }
        }
    }
}

// MARK: 5 — IDS signature & anomaly detection (Blue Team)

struct IDSDetectionView: View {
    private let packets: [(label: String, malicious: Bool)] = [
        (":443 GET /home", false), (":443 POST /login", false),
        ("GET /../../etc/passwd", true), (":80 GET /image.png", false)
    ]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let sensorX = w * 0.5
            let rowY = h * 0.32
            LoopingTimeline(period: Double(packets.count) * 1.3) { p in
                let i = min(packets.count - 1, Int(p * Double(packets.count)))
                let local = CGFloat(p * Double(packets.count) - Double(i))
                let pk = packets[i]
                let alerted = pk.malicious && local > 0.5
                let x = w * (0.08 + 0.84 * ease(local))
                ZStack {
                    Path { pa in pa.move(to: CGPoint(x: w * 0.06, y: rowY)); pa.addLine(to: CGPoint(x: w * 0.94, y: rowY)) }
                        .stroke(Theme.stroke, style: StrokeStyle(lineWidth: 1.2, dash: [3, 4]))

                    netNode("antenna.radiowaves.left.and.right", "IDS\nsensor", Theme.blue, true)
                        .position(x: sensorX, y: rowY)

                    TokenChip(text: pk.label,
                              color: pk.malicious ? (local > 0.5 ? Theme.red : Theme.amber) : Theme.green,
                              system: alerted ? "exclamationmark.triangle.fill" : "arrow.right")
                        .position(x: x, y: rowY)

                    if alerted {
                        HStack(spacing: 5) {
                            Image(systemName: "bell.badge.fill")
                            Text("ALERT · SID 2010935 · path traversal")
                        }
                        .font(Theme.mono(8.5, .bold)).foregroundStyle(.black)
                        .padding(.horizontal, 9).padding(.vertical, 5)
                        .background(Theme.red, in: Capsule())
                        .position(x: w * 0.5, y: h * 0.60)
                    }

                    Text("An IDS watches a copy of traffic and ALERTS on a match; an IPS sits inline and BLOCKS it.")
                        .font(Theme.mono(8)).foregroundStyle(Theme.textDim)
                        .multilineTextAlignment(.center).frame(width: w * 0.92)
                        .position(x: w * 0.5, y: h * 0.85)
                }
                .animation(.easeInOut(duration: 0.2), value: alerted)
            }
        }
    }
}

// MARK: 6 — Secure SDLC pipeline (Blue Team)

struct SecureSdlcView: View {
    var body: some View {
        SequenceStage(
            steps: [
                SequenceStep(system: "keyboard", title: "Code", detail: "developer commits a change", color: Theme.blue),
                SequenceStep(system: "doc.text.magnifyingglass", title: "SAST", detail: "static scan reads the source", color: Theme.blue),
                SequenceStep(system: "shippingbox", title: "Dependency scan", detail: "SCA flags a vulnerable library", color: Theme.amber),
                SequenceStep(system: "hammer", title: "Build", detail: "compile & sign the artifact", color: Theme.blue),
                SequenceStep(system: "globe.badge.chevron.backward", title: "DAST", detail: "dynamic test of the running app", color: Theme.blue),
                SequenceStep(system: "checkmark.shield", title: "Deploy", detail: "ships only if every gate passed", color: Theme.green)
            ],
            breakAt: 2,
            breakLabel: "Vulnerable dependency caught — pipeline fails the build"
        )
    }
}
