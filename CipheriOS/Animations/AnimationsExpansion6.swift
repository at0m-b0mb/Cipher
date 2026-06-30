import SwiftUI

// MARK: - Expansion wave 6 explainers
//
// Eight new visualizations: the compile-to-CPU pipeline, weak-vs-strong
// randomness, VLAN tagging, BadUSB keystroke injection, DLL search-order
// hijacking, the NIST CSF function wheel, a risk matrix, and YARA rule matching.
// They reuse the shared `LoopingTimeline`, `netNode`, `TokenChip`, `CycleStage`,
// `lerp` and `ease` helpers, plus the three file-private helpers below.

// MARK: - File-private drawing helpers

private func wire6(_ a: CGPoint, _ b: CGPoint, _ color: Color = Theme.stroke) -> some View {
    Path { p in p.move(to: a); p.addLine(to: b) }
        .stroke(color, style: StrokeStyle(lineWidth: 1.2, dash: [3, 4]))
}

@ViewBuilder
private func chip6(_ a: CGPoint, _ b: CGPoint, _ p: Double, _ s: Double, _ e: Double,
                   _ label: String, _ c: Color, system: String = "arrow.right") -> some View {
    if p >= s && p <= e {
        let t = ease(CGFloat((p - s) / max(0.0001, e - s)))
        TokenChip(text: label, color: c, system: system)
            .position(lerp(a, b, t))
    }
}

private func panel6<C: View>(_ title: String, _ system: String, _ color: Color,
                             lit: Bool, @ViewBuilder content: () -> C) -> some View {
    VStack(alignment: .leading, spacing: 5) {
        HStack(spacing: 5) {
            Image(systemName: system).font(.system(size: 10, weight: .bold))
            Text(title).font(Theme.mono(8, .bold))
        }
        .foregroundStyle(lit ? color : Theme.textDim)
        content()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(10)
    .background(color.opacity(lit ? 0.10 : 0.03), in: RoundedRectangle(cornerRadius: 10))
    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(color.opacity(lit ? 0.6 : 0.2), lineWidth: 1))
    .opacity(lit ? 1 : 0.55)
}

// MARK: 1 — Source to CPU

/// The journey of code: human-readable source is translated by a compiler into
/// the CPU's binary machine instructions, which the processor then runs one at a
/// time in a fetch-decode-execute loop.
struct CompilePipelineView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let y = h * 0.34
            let src = CGPoint(x: w * 0.13, y: y)
            let comp = CGPoint(x: w * 0.38, y: y)
            let code = CGPoint(x: w * 0.63, y: y)
            let cpu = CGPoint(x: w * 0.87, y: y)
            LoopingTimeline(period: 8) { p in
                let step = min(3, Int(p * 4))
                ZStack {
                    wire6(src, comp); wire6(comp, code); wire6(code, cpu)
                    netNode("doc.text.fill", "main.c\nsource", Theme.teal, step >= 0).position(src)
                    netNode("gearshape.2.fill", "compiler", Theme.violet, step >= 1).position(comp)
                    netNode("number", "machine\ncode", Theme.amber, step >= 2).position(code)
                    netNode("cpu", "CPU\nexecutes", Theme.green, step >= 3).position(cpu)

                    chip6(src, comp, p, 0.05, 0.25, "int x = 2+2;", Theme.teal)
                    chip6(comp, code, p, 0.30, 0.50, "translate", Theme.violet)
                    chip6(code, cpu, p, 0.55, 0.75, "10110100", Theme.amber)

                    if step >= 3 {
                        Text("fetch → decode → execute → repeat")
                            .font(Theme.mono(8, .bold)).foregroundStyle(Theme.green)
                            .position(x: w * 0.5, y: h * 0.60)
                    }
                    Text(step >= 3 ? "the source you write becomes machine code the CPU runs one instruction at a time"
                                   : "a compiler translates human-readable source into the CPU's binary instructions…")
                        .font(Theme.mono(8, .bold))
                        .foregroundStyle(step >= 3 ? Theme.green : Theme.textSecondary)
                        .multilineTextAlignment(.center).frame(width: w * 0.94)
                        .position(x: w * 0.5, y: h * 0.90)
                }
                .animation(.easeInOut(duration: 0.3), value: step)
            }
        }
    }
}

// MARK: 2 — Randomness & entropy

/// Security leans on unpredictability. A seeded PRNG is deterministic — predict
/// the seed and you predict every output. A CSPRNG is fed by hardware entropy
/// (timing, input jitter) so its output can't be foreseen. Keys need the latter.
struct EntropyRngView: View {
    private let weak = ["4", "1", "5", "9", "2", "6", "5", "3"]

    var body: some View {
        LoopingTimeline(period: 8) { p in
            let n = min(8, Int(p * 9))
            let predicted = p > 0.85
            VStack(spacing: 11) {
                Text("RANDOMNESS THAT MATTERS")
                    .font(Theme.mono(9, .bold)).foregroundStyle(Theme.teal)

                panel6("WEAK PRNG — seeded, deterministic", "dice.fill", Theme.red, lit: true) {
                    HStack(spacing: 3) {
                        ForEach(0..<8, id: \.self) { i in
                            Text(i < n ? weak[i] : "·")
                                .font(Theme.mono(11, .bold))
                                .foregroundStyle(i < n ? Theme.amber : Theme.textDim).frame(width: 15)
                        }
                        Text(predicted ? "→ next predicted!" : "")
                            .font(Theme.mono(7.5, .bold)).foregroundStyle(Theme.red)
                    }
                }

                panel6("CSPRNG — fed by OS entropy", "lock.shield.fill", Theme.green, lit: true) {
                    HStack(spacing: 8) {
                        Image(systemName: "cursorarrow.motionlines").foregroundStyle(Theme.textDim)
                        Image(systemName: "keyboard").foregroundStyle(Theme.textDim)
                        Image(systemName: "timer").foregroundStyle(Theme.textDim)
                        Text("→ unpredictable").font(Theme.mono(8, .bold)).foregroundStyle(Theme.green)
                    }
                    .font(.system(size: 11, weight: .bold))
                }

                Text("keys, tokens and nonces MUST come from a CSPRNG — a predictable RNG breaks the crypto built on it")
                    .font(Theme.mono(7.5)).foregroundStyle(Theme.textDim)
                    .multilineTextAlignment(.center).frame(width: 296)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 4)
            .animation(.easeInOut(duration: 0.25), value: n)
        }
    }
}

// MARK: 3 — VLAN tagging

/// One physical switch can host several isolated networks. As a frame enters, the
/// switch tags it with its VLAN id (802.1Q); the switch then only forwards it to
/// ports in the same VLAN — so VLAN 10 can't reach VLAN 20 even on one switch.
struct VlanTaggingView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let sw = CGPoint(x: w * 0.5, y: h * 0.42)
            let a = CGPoint(x: w * 0.16, y: h * 0.20)
            let b = CGPoint(x: w * 0.84, y: h * 0.20)
            let c = CGPoint(x: w * 0.16, y: h * 0.64)
            let d = CGPoint(x: w * 0.84, y: h * 0.64)
            LoopingTimeline(period: 7) { p in
                let blocked = p > 0.55
                ZStack {
                    wire6(a, sw); wire6(b, sw); wire6(c, sw); wire6(d, sw)
                    netNode("desktopcomputer", "PC-A\nVLAN 10", Theme.red, true).position(a)
                    netNode("desktopcomputer", "PC-B\nVLAN 10", Theme.red, true).position(b)
                    netNode("desktopcomputer", "PC-C\nVLAN 20", Theme.blue, true).position(c)
                    netNode("desktopcomputer", "PC-D\nVLAN 20", Theme.blue, true).position(d)
                    netNode("rectangle.connected.to.line.below", "switch", Theme.violet, true).position(sw)

                    chip6(a, sw, p, 0.05, 0.25, "tag VLAN 10", Theme.red)
                    chip6(sw, b, p, 0.28, 0.48, "VLAN 10", Theme.red)
                    if blocked { chip6(sw, d, p, 0.58, 0.74, "VLAN 20 blocked", Theme.amber, system: "xmark.octagon.fill") }

                    Text(blocked ? "the switch keeps VLANs apart — VLAN 10 can't reach VLAN 20, even on the same switch"
                                 : "each frame is tagged (802.1Q) with its VLAN as it enters the switch…")
                        .font(Theme.mono(8, .bold))
                        .foregroundStyle(blocked ? Theme.amber : Theme.violet)
                        .multilineTextAlignment(.center).frame(width: w * 0.94)
                        .position(x: w * 0.5, y: h * 0.92)
                }
                .animation(.easeInOut(duration: 0.3), value: blocked)
            }
        }
    }
}

// MARK: 4 — BadUSB keystroke injection

/// A malicious USB device declares itself a keyboard — the one peripheral every
/// OS trusts without a prompt — then "types" a payload at machine speed the
/// moment it's plugged in. No software exploit, just abused trust in HID.
struct BadUsbInjectView: View {
    var body: some View {
        LoopingTimeline(period: 8) { p in
            let step = min(3, Int(p * 4))
            VStack(spacing: 9) {
                HStack(spacing: 8) {
                    Image(systemName: "externaldrive.fill").foregroundStyle(Theme.amber)
                    Image(systemName: "arrow.right").foregroundStyle(Theme.textDim)
                    Image(systemName: "laptopcomputer").foregroundStyle(Theme.blue)
                }
                .font(.system(size: 18, weight: .bold))

                panel6("THE OS SEES", "keyboard.fill", step >= 1 ? Theme.amber : Theme.textDim, lit: step >= 1) {
                    Text(step >= 1 ? "new device: USB HID Keyboard — trusted, no prompt" : "enumerating…")
                        .font(Theme.mono(8.5, .bold)).foregroundStyle(step >= 1 ? Theme.amber : Theme.textDim)
                }

                panel6("INJECTED KEYSTROKES (~1000 wpm)", "terminal.fill", step >= 2 ? Theme.red : Theme.textDim, lit: step >= 2) {
                    Text(step >= 2 ? "Win+R → powershell → IEX(New-Object Net.WebClient)…" : "—")
                        .font(Theme.mono(7.5, .bold)).foregroundStyle(step >= 2 ? Theme.green : Theme.textDim)
                }

                HStack(spacing: 6) {
                    Image(systemName: step >= 3 ? "bolt.fill" : "hourglass")
                    Text(step >= 3 ? "payload runs as the logged-in user — in under 2 seconds" : "typing…")
                }
                .font(Theme.mono(9, .bold))
                .foregroundStyle(step >= 3 ? Theme.red : Theme.textSecondary)

                Text("a BadUSB pretends to be a keyboard — the one device every machine trusts unconditionally")
                    .font(Theme.mono(7)).foregroundStyle(Theme.textDim)
                    .multilineTextAlignment(.center).frame(width: 296)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 4)
            .animation(.easeInOut(duration: 0.3), value: step)
        }
    }
}

// MARK: 5 — DLL search-order hijacking

/// When a program loads a library by name, Windows searches a fixed list of
/// directories — and checks the application's own folder first. Drop a malicious
/// DLL of the right name there and it loads instead of the real one.
struct DllHijackView: View {
    private let order = ["1 · application directory", "2 · system32", "3 · windows", "4 · PATH dirs"]

    var body: some View {
        LoopingTimeline(period: 8) { p in
            let hijacked = p > 0.5
            VStack(spacing: 9) {
                Text("DLL SEARCH-ORDER HIJACKING")
                    .font(Theme.mono(9, .bold)).foregroundStyle(Theme.red)

                panel6("app.exe needs helper.dll", "macwindow", Theme.blue, lit: true) {
                    Text("LoadLibrary(\"helper.dll\")  — no full path given")
                        .font(Theme.mono(8.5, .bold)).foregroundStyle(Theme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 5) {
                    ForEach(0..<order.count, id: \.self) { i in
                        let first = i == 0
                        HStack(spacing: 6) {
                            Image(systemName: first && hijacked ? "exclamationmark.triangle.fill" : "magnifyingglass")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(first && hijacked ? Theme.red : Theme.textDim)
                            Text(order[i]).font(Theme.mono(8.5, .bold))
                                .foregroundStyle(first && hijacked ? Theme.red : Theme.textDim)
                            if first && hijacked {
                                Text("← planted evil.dll (writable!)")
                                    .font(Theme.mono(7.5, .bold)).foregroundStyle(Theme.amber)
                            }
                        }
                    }
                }
                .frame(width: 282, alignment: .leading)

                Text(hijacked ? "the loader checks the app folder FIRST — the planted DLL loads, and runs as the app"
                              : "Windows searches a fixed list of directories for the DLL by name…")
                    .font(Theme.mono(7.5, .bold))
                    .foregroundStyle(hijacked ? Theme.red : Theme.textSecondary)
                    .multilineTextAlignment(.center).frame(width: 296)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 4)
            .animation(.easeInOut(duration: 0.3), value: hijacked)
        }
    }
}

// MARK: 6 — NIST CSF function wheel

/// The NIST Cybersecurity Framework organises a whole security programme into
/// five continuous functions. They aren't a one-time checklist — they cycle, each
/// informing the next. Reuses the shared rotating-ring engine.
struct NistCsfView: View {
    var body: some View {
        CycleStage(nodes: [
            CycleNode(system: "list.bullet.clipboard", title: "Identify", color: Theme.violet),
            CycleNode(system: "shield.lefthalf.filled", title: "Protect", color: Theme.blue),
            CycleNode(system: "antenna.radiowaves.left.and.right", title: "Detect", color: Theme.teal),
            CycleNode(system: "bolt.fill", title: "Respond", color: Theme.amber),
            CycleNode(system: "arrow.clockwise", title: "Recover", color: Theme.green)
        ], centerTitle: "NIST CSF", centerSystem: "checkmark.seal.fill", accent: Theme.blue)
    }
}

// MARK: 7 — Risk matrix

/// Risk = likelihood × impact. Plot each risk on the grid and the colour tells
/// you where to spend: the top-right (likely AND damaging) demands action first;
/// the bottom-left can often be accepted.
struct RiskMatrixView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let size: CGFloat = 50
            let ox = w * 0.5 - size * 1.5
            let oy = h * 0.16
            LoopingTimeline(period: 7) { p in
                let shown = min(4, Int(p * 5))
                let hot = p > 0.8
                let risks: [(Int, Int, String)] = [(2, 0, "R1"), (0, 2, "R2"), (1, 1, "R3"), (2, 1, "R4")]
                ZStack {
                    Text("RISK = LIKELIHOOD × IMPACT")
                        .font(Theme.mono(9, .bold)).foregroundStyle(Theme.blue)
                        .position(x: w * 0.5, y: h * 0.06)

                    ForEach(0..<3, id: \.self) { row in
                        ForEach(0..<3, id: \.self) { col in
                            let sev = (2 - row) + col
                            let c: Color = sev >= 3 ? Theme.red : (sev >= 2 ? Theme.amber : Theme.green)
                            Rectangle().fill(c.opacity(0.20))
                                .frame(width: size, height: size)
                                .overlay(Rectangle().strokeBorder(c.opacity(0.5), lineWidth: 1))
                                .position(x: ox + size * (CGFloat(col) + 0.5),
                                          y: oy + size * (CGFloat(row) + 0.5))
                        }
                    }

                    Text("impact →").font(Theme.mono(7, .bold)).foregroundStyle(Theme.textDim)
                        .position(x: ox + size * 1.5, y: oy + size * 3 + 12)
                    Text("likelihood →").font(Theme.mono(7, .bold)).foregroundStyle(Theme.textDim)
                        .rotationEffect(.degrees(-90)).position(x: ox - 18, y: oy + size * 1.5)

                    ForEach(0..<risks.count, id: \.self) { i in
                        if i < shown {
                            let item = risks[i]
                            let sev = (2 - item.1) + item.0
                            let high = sev >= 3
                            Circle().fill(high && hot ? Theme.red : Theme.textPrimary)
                                .frame(width: 18, height: 18)
                                .overlay(Text(item.2).font(Theme.mono(7, .black)).foregroundStyle(.black))
                                .shadow(color: high && hot ? Theme.red : .clear, radius: 6)
                                .position(x: ox + size * (CGFloat(item.0) + 0.5),
                                          y: oy + size * (CGFloat(item.1) + 0.5))
                        }
                    }

                    Text(hot ? "treat the top-right (high/high) first — mitigate, transfer, avoid or accept"
                             : "plot each risk by how likely it is and how bad it would be…")
                        .font(Theme.mono(7.5, .bold))
                        .foregroundStyle(hot ? Theme.red : Theme.textSecondary)
                        .multilineTextAlignment(.center).frame(width: w * 0.95)
                        .position(x: w * 0.5, y: h * 0.93)
                }
                .animation(.easeInOut(duration: 0.3), value: shown)
            }
        }
    }
}

// MARK: 8 — YARA rule matching

/// YARA describes malware as a set of strings/byte-patterns plus a condition.
/// A scanner checks each pattern against a file; when enough match the condition,
/// the file is flagged. It's the file-side counterpart to a SIEM's Sigma rule.
struct YaraMatchView: View {
    private let rows: [(String, String, Bool)] = [
        ("$a", "\"cmd.exe /c\"", true),
        ("$b", "{ 6A 40 68 00 30 }", true),
        ("$c", "\"evil.corp\"", false)
    ]

    var body: some View {
        LoopingTimeline(period: 8) { p in
            let scanned = min(3, Int(p * 4))
            let matched = p > 0.8
            VStack(alignment: .leading, spacing: 7) {
                Text("YARA RULE — pattern-match malware")
                    .font(Theme.mono(9, .bold)).foregroundStyle(Theme.blue)
                    .frame(maxWidth: .infinity)

                ForEach(0..<rows.count, id: \.self) { i in
                    let row = rows[i]
                    let done = i < scanned
                    HStack(spacing: 6) {
                        Text(row.0).font(Theme.mono(9, .bold)).foregroundStyle(Theme.violet).frame(width: 22, alignment: .leading)
                        Text("= " + row.1).font(Theme.mono(8.5, .bold)).foregroundStyle(Theme.textSecondary)
                        Spacer()
                        if done {
                            Image(systemName: row.2 ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 11)).foregroundStyle(row.2 ? Theme.green : Theme.textDim)
                        }
                    }
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(done && row.2 ? Theme.green.opacity(0.10) : Color.clear,
                                in: RoundedRectangle(cornerRadius: 6))
                    .frame(width: 286)
                }

                Text("condition:  2 of them")
                    .font(Theme.mono(8.5, .bold)).foregroundStyle(Theme.amber).frame(maxWidth: .infinity)

                HStack(spacing: 6) {
                    Image(systemName: matched ? "exclamationmark.shield.fill" : "shield")
                    Text(matched ? "2 of 3 matched → FLAGGED as malware" : "scanning the file…")
                }
                .font(Theme.mono(9, .bold))
                .foregroundStyle(matched ? Theme.red : Theme.textSecondary)
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 4)
            .animation(.easeInOut(duration: 0.25), value: scanned)
        }
    }
}
