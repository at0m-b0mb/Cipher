import SwiftUI

// MARK: - Cyber Kill Chain

struct CyberKillChainView: View {
    var body: some View {
        SequenceStage(steps: [
            SequenceStep(system: "binoculars.fill", title: "1 · Reconnaissance", detail: "research the target", color: Theme.red),
            SequenceStep(system: "hammer.fill", title: "2 · Weaponization", detail: "exploit + payload", color: Theme.red),
            SequenceStep(system: "paperplane.fill", title: "3 · Delivery", detail: "phishing email / USB", color: Theme.amber),
            SequenceStep(system: "bolt.fill", title: "4 · Exploitation", detail: "the payload executes", color: Theme.amber),
            SequenceStep(system: "externaldrive.fill.badge.plus", title: "5 · Installation", detail: "persistence / backdoor", color: Theme.magenta),
            SequenceStep(system: "antenna.radiowaves.left.and.right", title: "6 · Command & Control", detail: "implant phones home", color: Theme.magenta),
            SequenceStep(system: "target", title: "7 · Actions on Objectives", detail: "steal · encrypt · pivot", color: Theme.red)
        ], breakAt: 5, breakLabel: "block the C2 domain → the attack fails")
    }
}

// MARK: - Port scan

struct PortScanView: View {
    private let ports: [(port: Int, service: String, state: String, color: Color)] = [
        (22, "ssh", "open", Theme.green),
        (80, "http", "open", Theme.green),
        (443, "https", "closed", Theme.red),
        (3389, "rdp", "filtered", Theme.amber),
        (8080, "http-alt", "open", Theme.green)
    ]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let n = ports.count
            let top: CGFloat = 24, rowH = (h - 36) / CGFloat(n)
            LoopingTimeline(period: 7) { p in
                let idx = min(n - 1, Int(p * Double(n)))
                let local = p * Double(n) - Double(idx)
                ZStack {
                    HostNode(title: "nmap", subtitle: "scanner", system: "antenna.radiowaves.left.and.right", color: Theme.red)
                        .position(x: w * 0.13, y: h * 0.5)

                    ForEach(ports.indices, id: \.self) { i in
                        let y = top + (CGFloat(i) + 0.5) * rowH
                        let resolved = p > (Double(i) + 0.55) / Double(n)
                        portRow(ports[i], resolved: resolved)
                            .position(x: w * 0.66, y: y)
                    }

                    if local < 0.6 {
                        let y = top + (CGFloat(idx) + 0.5) * rowH
                        TokenChip(text: "SYN", color: Theme.teal, system: "arrow.right")
                            .position(x: lerp(CGPoint(x: w * 0.22, y: h * 0.5),
                                              CGPoint(x: w * 0.5, y: y),
                                              ease(CGFloat(local / 0.6))).x,
                                      y: lerp(CGPoint(x: w * 0.22, y: h * 0.5),
                                              CGPoint(x: w * 0.5, y: y),
                                              ease(CGFloat(local / 0.6))).y)
                    }
                }
            }
        }
    }

    private func portRow(_ p: (port: Int, service: String, state: String, color: Color), resolved: Bool) -> some View {
        HStack(spacing: 8) {
            Text("\(p.port)/tcp").font(Theme.mono(10, .bold)).foregroundStyle(Theme.textSecondary).frame(width: 56, alignment: .leading)
            Text(resolved ? p.state : "·····")
                .font(Theme.mono(10, .bold))
                .foregroundStyle(resolved ? p.color : Theme.textDim)
                .frame(width: 60, alignment: .leading)
            Text(p.service).font(Theme.mono(9)).foregroundStyle(Theme.textDim)
        }
        .padding(.horizontal, 8).padding(.vertical, 5)
        .background((resolved ? p.color.opacity(0.12) : Theme.surfaceHi), in: RoundedRectangle(cornerRadius: 7))
        .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder((resolved ? p.color.opacity(0.6) : Theme.stroke), lineWidth: 1))
    }
}

// MARK: - Phishing → initial access

struct PhishingFlowView: View {
    var body: some View {
        FlowStage(
            nodes: [
                FlowNode(id: "atk", pos: CGPoint(x: 0.15, y: 0.5), title: "Attacker", subtitle: "C2 server",
                         system: "desktopcomputer", color: Theme.red, startActive: true),
                FlowNode(id: "usr", pos: CGPoint(x: 0.85, y: 0.5), title: "Employee", subtitle: "the target",
                         system: "person.crop.circle.fill", color: Theme.teal, startActive: true)
            ],
            messages: [
                FlowMessage(from: "atk", to: "usr", label: "Phishing email", color: Theme.amber, start: 0.05, end: 0.35, system: "envelope.fill"),
                FlowMessage(from: "usr", to: "atk", label: "Reverse shell", color: Theme.red, start: 0.58, end: 0.92, system: "terminal.fill")
            ],
            period: 6,
            footnote: "email → victim clicks → payload runs → attacker gets a shell"
        )
    }
}

// MARK: - SQL injection

struct SQLInjectionView: View {
    private let rows = ["admin   ·  ********", "alice   ·  ********", "bob     ·  ********"]

    var body: some View {
        LoopingTimeline(period: 4 * 1.2) { p in
            let step = min(3, Int(p * 4))
            VStack(alignment: .leading, spacing: 14) {
                // Input field
                VStack(alignment: .leading, spacing: 3) {
                    Text("LOGIN INPUT").font(Theme.mono(8, .bold)).foregroundStyle(Theme.textDim)
                    HStack {
                        Text("username:").font(Theme.mono(11)).foregroundStyle(Theme.textSecondary)
                        Text(step >= 1 ? "admin' OR '1'='1" : "")
                            .font(Theme.mono(11, .bold)).foregroundStyle(Theme.red)
                        Spacer()
                    }
                    .padding(8)
                    .background(Theme.surfaceHi, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.stroke, lineWidth: 1))
                }
                .opacity(step >= 1 ? 1 : 0.25)

                // Assembled query
                VStack(alignment: .leading, spacing: 3) {
                    Text("QUERY EXECUTED").font(Theme.mono(8, .bold)).foregroundStyle(Theme.textDim)
                    if step >= 2 {
                        (Text("SELECT * FROM users WHERE name='admin")
                         + Text("' OR '1'='1").foregroundColor(Theme.red)
                         + Text("'"))
                            .font(Theme.mono(10.5))
                            .foregroundStyle(Theme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text(" ").font(Theme.mono(10.5))
                    }
                }
                .opacity(step >= 2 ? 1 : 0.25)

                // Result
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "cylinder.fill").font(.system(size: 24)).foregroundStyle(Theme.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(step >= 3 ? "ALL ROWS RETURNED — auth bypassed" : "")
                            .font(Theme.mono(9, .bold)).foregroundStyle(Theme.red)
                        if step >= 3 {
                            ForEach(rows, id: \.self) { r in
                                Text(r).font(Theme.mono(9)).foregroundStyle(Theme.green)
                            }
                        }
                    }
                }
                .opacity(step >= 3 ? 1 : 0.25)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(.easeInOut(duration: 0.4), value: step)
        }
    }
}

// MARK: - Reflected XSS

struct XSSReflectedView: View {
    var body: some View {
        LoopingTimeline(period: 4 * 1.25) { p in
            let step = min(3, Int(p * 4))
            VStack(alignment: .leading, spacing: 12) {
                // URL
                VStack(alignment: .leading, spacing: 3) {
                    Text("CRAFTED URL").font(Theme.mono(8, .bold)).foregroundStyle(Theme.textDim)
                    (Text("/search?q=").foregroundColor(Theme.textSecondary)
                     + Text("<script>steal(cookie)</script>").foregroundColor(Theme.red))
                        .font(Theme.mono(10))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .opacity(step >= 1 ? 1 : 0.25)

                // Reflected page
                VStack(alignment: .leading, spacing: 3) {
                    Text("SERVER REFLECTS IT INTO THE PAGE").font(Theme.mono(8, .bold)).foregroundStyle(Theme.textDim)
                    (Text("Results for ").foregroundColor(Theme.textPrimary)
                     + Text("<script>steal(cookie)</script>").foregroundColor(Theme.red))
                        .font(Theme.mono(10))
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.surfaceHi, in: RoundedRectangle(cornerRadius: 8))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .opacity(step >= 2 ? 1 : 0.25)

                // Execution + theft
                HStack(spacing: 10) {
                    Image(systemName: "globe").font(.system(size: 20)).foregroundStyle(Theme.teal)
                    Image(systemName: "arrow.right").foregroundStyle(step >= 3 ? Theme.red : Theme.textDim)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(step >= 3 ? "script runs in victim's browser" : "")
                            .font(Theme.mono(9, .bold)).foregroundStyle(Theme.red)
                        Text(step >= 3 ? "document.cookie → attacker" : "")
                            .font(Theme.mono(9)).foregroundStyle(Theme.amber)
                    }
                    Spacer()
                    if step >= 3 {
                        HostNode(title: "Attacker", subtitle: "gets session", system: "desktopcomputer", color: Theme.red)
                    }
                }
                .opacity(step >= 3 ? 1 : 0.25)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(.easeInOut(duration: 0.4), value: step)
        }
    }
}

// MARK: - Privilege escalation ladder

struct PrivilegeEscalationView: View {
    var body: some View {
        LadderStage(rungs: [
            LadderRung(level: "uid=33 www-data", via: "initial web foothold", system: "person.fill", color: Theme.amber),
            LadderRung(level: "uid=1000 dev", via: "creds reused in .env", system: "person.2.fill", color: Theme.amber),
            LadderRung(level: "sudo / SUID", via: "sudo -l → GTFOBins", system: "wrench.and.screwdriver.fill", color: Theme.red),
            LadderRung(level: "uid=0  root", via: "full control of the host", system: "crown.fill", color: Theme.red)
        ])
    }
}

// MARK: - Offline password cracking

struct PasswordCrackingView: View {
    private let candidates = ["123456", "qwerty", "letmein", "password", "dragon",
                              "Summer2024!", "iloveyou", "admin123", "welcome", "monkey"]
    private let matchIndex = 5

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            LoopingTimeline(period: 9) { p in
                let f = p * Double(candidates.count + 2)
                let idx = min(candidates.count - 1, Int(f))
                let found = idx >= matchIndex
                let current = found ? candidates[matchIndex] : candidates[idx]
                ZStack {
                    Text("TARGET HASH")
                        .font(Theme.mono(8, .bold)).foregroundStyle(Theme.textDim)
                        .position(x: w * 0.5, y: h * 0.12)
                    Text("$6$xy…$Q9rT…")
                        .font(Theme.mono(11, .bold)).foregroundStyle(Theme.red)
                        .position(x: w * 0.5, y: h * 0.24)

                    // Hash function box
                    HStack(spacing: 10) {
                        Text("rockyou.txt").font(Theme.mono(9)).foregroundStyle(Theme.textDim)
                        Image(systemName: "arrow.right").foregroundStyle(Theme.textDim)
                        Text("sha512crypt").font(Theme.mono(9, .bold)).foregroundStyle(Theme.violet)
                            .padding(.horizontal, 8).padding(.vertical, 5)
                            .background(Theme.violet.opacity(0.14), in: Capsule())
                    }
                    .position(x: w * 0.5, y: h * 0.46)

                    // Current candidate
                    HStack(spacing: 8) {
                        Image(systemName: found ? "checkmark.seal.fill" : "xmark")
                            .foregroundStyle(found ? Theme.green : Theme.red)
                        Text(current)
                            .font(Theme.mono(14, .bold))
                            .foregroundStyle(found ? Theme.green : Theme.textPrimary)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background((found ? Theme.green : Theme.red).opacity(0.12), in: RoundedRectangle(cornerRadius: 9))
                    .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder((found ? Theme.green : Theme.red).opacity(0.6), lineWidth: 1))
                    .shadow(color: found ? Theme.green.opacity(0.6) : .clear, radius: 10)
                    .position(x: w * 0.5, y: h * 0.66)

                    Text(found ? "CRACKED ✓  ·  no rate limit, GPU speed" : "guessing offline…  1.2 GH/s")
                        .font(Theme.mono(9, .bold))
                        .foregroundStyle(found ? Theme.green : Theme.textDim)
                        .position(x: w * 0.5, y: h * 0.86)
                }
            }
        }
    }
}

// MARK: - Kerberoasting

struct KerberoastingView: View {
    var body: some View {
        FlowStage(
            nodes: [
                FlowNode(id: "usr", pos: CGPoint(x: 0.15, y: 0.32), title: "Domain User", subtitle: "any account",
                         system: "person.fill", color: Theme.teal, startActive: true),
                FlowNode(id: "kdc", pos: CGPoint(x: 0.5, y: 0.18), title: "KDC", subtitle: "domain controller",
                         system: "lock.shield.fill", color: Theme.blue, startActive: true),
                FlowNode(id: "svc", pos: CGPoint(x: 0.85, y: 0.32), title: "Service", subtitle: "has an SPN",
                         system: "server.rack", color: Theme.violet, startActive: true),
                FlowNode(id: "crk", pos: CGPoint(x: 0.5, y: 0.82), title: "hashcat", subtitle: "offline",
                         system: "bolt.fill", color: Theme.red)
            ],
            messages: [
                FlowMessage(from: "usr", to: "kdc", label: "Request TGS (SPN)", color: Theme.teal, start: 0.05, end: 0.30),
                FlowMessage(from: "kdc", to: "usr", label: "TGS · enc w/ svc hash", color: Theme.blue, start: 0.35, end: 0.62, system: "ticket.fill"),
                FlowMessage(from: "usr", to: "crk", label: "crack → Summer2023!", color: Theme.red, start: 0.67, end: 0.92)
            ],
            period: 7,
            footnote: "any domain user can request the ticket → crack the service password offline"
        )
    }
}

// MARK: - Lateral movement

struct LateralMovementView: View {
    var body: some View {
        FlowStage(
            nodes: [
                FlowNode(id: "h0", pos: CGPoint(x: 0.12, y: 0.4), title: "Foothold", subtitle: "compromised",
                         system: "desktopcomputer", color: Theme.red, startActive: true),
                FlowNode(id: "h1", pos: CGPoint(x: 0.38, y: 0.4), title: "WS-01", subtitle: "", system: "desktopcomputer", color: Theme.red),
                FlowNode(id: "h2", pos: CGPoint(x: 0.64, y: 0.4), title: "SRV-02", subtitle: "", system: "server.rack", color: Theme.red),
                FlowNode(id: "dc", pos: CGPoint(x: 0.9, y: 0.4), title: "DC", subtitle: "domain admin", system: "lock.shield.fill", color: Theme.red)
            ],
            messages: [
                FlowMessage(from: "h0", to: "h1", label: "reused creds", color: Theme.amber, start: 0.05, end: 0.30),
                FlowMessage(from: "h1", to: "h2", label: "Pass-the-Hash", color: Theme.red, start: 0.35, end: 0.58, system: "number"),
                FlowMessage(from: "h2", to: "dc", label: "PtH → Pwn3d!", color: Theme.red, start: 0.63, end: 0.88, system: "crown.fill")
            ],
            period: 7,
            footnote: "reuse credentials to hop host → host until you own the Domain Controller"
        )
    }
}

// MARK: - Stack buffer overflow

struct BufferOverflowView: View {
    // Stack cells, bottom (buffer) → top (caller). Overflow climbs upward.
    private let cells: [(label: String, base: Color)] = [
        ("buffer[64]", Theme.teal),
        ("saved EBP", Theme.blue),
        ("RETURN ADDRESS", Theme.amber),
        ("caller frame", Theme.violet)
    ]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let n = cells.count
            let cellH = (h - 30) / CGFloat(n)
            LoopingTimeline(period: 7) { p in
                let fill = ease(CGFloat(min(max((p - 0.1) / 0.7, 0), 1)))   // 0..1 up the stack
                let filledCells = fill * CGFloat(n)
                let retOverwritten = filledCells > 2.2
                ZStack {
                    ForEach(cells.indices, id: \.self) { i in
                        // index 0 = bottom
                        let y = h - 18 - (CGFloat(i) + 0.5) * cellH
                        let overflowed = filledCells > CGFloat(i) + 0.4
                        let isRet = i == 2
                        cell(i, label: cells[i].label,
                             color: isRet && retOverwritten ? Theme.red : cells[i].base,
                             overflowed: overflowed,
                             text: isRet && retOverwritten ? "0x42424242 ➜ shellcode" : (overflowed ? "AAAAAAAA…" : cells[i].label),
                             cellH: cellH, width: w)
                            .position(x: w * 0.46, y: y)
                    }
                    // EIP hijack callout
                    if retOverwritten {
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.branch").foregroundStyle(Theme.red)
                            Text("EIP\nhijacked")
                                .font(Theme.mono(8, .bold)).foregroundStyle(Theme.red)
                                .multilineTextAlignment(.center)
                        }
                        .position(x: w * 0.88, y: h - 18 - 2.5 * cellH)
                    }
                    Text("input overruns the buffer → overwrites the return address")
                        .font(Theme.mono(8)).foregroundStyle(Theme.textDim)
                        .position(x: w * 0.5, y: h - 8)
                }
            }
        }
    }

    private func cell(_ i: Int, label: String, color: Color, overflowed: Bool, text: String, cellH: CGFloat, width: CGFloat) -> some View {
        Text(text)
            .font(Theme.mono(10, .bold))
            .foregroundStyle(overflowed ? .black : Theme.textPrimary)
            .frame(width: width * 0.7, height: cellH - 6)
            .background((overflowed ? color : Theme.surfaceHi), in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(color.opacity(0.7), lineWidth: 1))
            .shadow(color: overflowed ? color.opacity(0.5) : .clear, radius: 6)
    }
}

// MARK: - C2 beacon

struct C2BeaconView: View {
    var body: some View {
        FlowStage(
            nodes: [
                FlowNode(id: "imp", pos: CGPoint(x: 0.16, y: 0.5), title: "Implant", subtitle: "victim host",
                         system: "antenna.radiowaves.left.and.right", color: Theme.red, startActive: true),
                FlowNode(id: "c2", pos: CGPoint(x: 0.84, y: 0.5), title: "C2 server", subtitle: "operator",
                         system: "server.rack", color: Theme.red, startActive: true)
            ],
            messages: [
                FlowMessage(from: "imp", to: "c2", label: "beacon", color: Theme.amber, start: 0.04, end: 0.18, system: "dot.radiowaves.up.forward"),
                FlowMessage(from: "c2", to: "imp", label: "task", color: Theme.blue, start: 0.20, end: 0.32),
                FlowMessage(from: "imp", to: "c2", label: "beacon", color: Theme.amber, start: 0.50, end: 0.64, system: "dot.radiowaves.up.forward"),
                FlowMessage(from: "c2", to: "imp", label: "result", color: Theme.green, start: 0.66, end: 0.80)
            ],
            period: 6,
            footnote: "sleep ~60s ± jitter · encrypted HTTPS check-ins blend into normal web traffic"
        )
    }
}
