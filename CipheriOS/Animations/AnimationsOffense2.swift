import SwiftUI

// MARK: - AMSI bypass (evasion)

/// The Antimalware Scan Interface gate: a payload is blocked, the attacker
/// patches the scan function in memory, and the same payload then sails through.
struct AMSIBypassView: View {
    var body: some View {
        LoopingTimeline(period: 6) { p in
            let step = min(2, Int(p * 3))
            let bypassed = step >= 1
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "terminal.fill").foregroundStyle(Theme.violet)
                    Text("powershell  IEX(payload)")
                        .font(Theme.mono(10, .bold)).foregroundStyle(Theme.textPrimary)
                }

                // AMSI gate
                HStack(spacing: 10) {
                    Image(systemName: bypassed ? "shield.slash.fill" : "shield.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(bypassed ? Theme.red : Theme.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AMSI · AmsiScanBuffer()")
                            .font(Theme.mono(10, .bold)).foregroundStyle(Theme.textSecondary)
                        Text(bypassed ? "patched in memory → AMSI_RESULT_CLEAN"
                                      : "scanning script content…")
                            .font(Theme.mono(8.5)).foregroundStyle(bypassed ? Theme.red : Theme.textDim)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background((bypassed ? Theme.red : Theme.blue).opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder((bypassed ? Theme.red : Theme.blue).opacity(0.5), lineWidth: 1))

                if step == 1 {
                    Text("[Ref].Assembly…GetField('amsiInitFailed') = $true")
                        .font(Theme.mono(8.5, .bold)).foregroundStyle(Theme.amber)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // verdict
                HStack(spacing: 8) {
                    Image(systemName: step == 0 ? "xmark.octagon.fill"
                                    : step == 2 ? "checkmark.seal.fill" : "wrench.adjustable.fill")
                        .foregroundStyle(step == 0 ? Theme.green : step == 2 ? Theme.red : Theme.amber)
                    Text(step == 0 ? "BLOCKED — malware detected"
                       : step == 2 ? "ALLOWED — implant runs in memory"
                       : "patching the scanner…")
                        .font(Theme.mono(10, .bold))
                        .foregroundStyle(step == 0 ? Theme.green : step == 2 ? Theme.red : Theme.amber)
                }
                .opacity(step == 1 ? 0.4 : 1)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(.easeInOut(duration: 0.4), value: step)
        }
    }
}

// MARK: - Process injection (evasion)

struct ProcessInjectionView: View {
    var body: some View {
        FlowStage(
            nodes: [
                FlowNode(id: "mal", pos: CGPoint(x: 0.14, y: 0.5), title: "loader.exe", subtitle: "malicious",
                         system: "ant.fill", color: Theme.red, startActive: true),
                FlowNode(id: "exp", pos: CGPoint(x: 0.5, y: 0.5), title: "explorer.exe", subtitle: "trusted",
                         system: "macwindow", color: Theme.teal, startActive: true),
                FlowNode(id: "c2", pos: CGPoint(x: 0.86, y: 0.5), title: "C2", subtitle: "operator",
                         system: "server.rack", color: Theme.red, startActive: true)
            ],
            messages: [
                FlowMessage(from: "mal", to: "exp", label: "VirtualAllocEx", color: Theme.amber, start: 0.05, end: 0.24),
                FlowMessage(from: "mal", to: "exp", label: "WriteProcessMemory", color: Theme.amber, start: 0.28, end: 0.46, system: "memorychip"),
                FlowMessage(from: "mal", to: "exp", label: "CreateRemoteThread", color: Theme.red, start: 0.50, end: 0.66, system: "play.fill"),
                FlowMessage(from: "exp", to: "c2", label: "beacon (as explorer)", color: Theme.green, start: 0.72, end: 0.95, system: "dot.radiowaves.up.forward")
            ],
            period: 7,
            footnote: "shellcode runs inside a trusted process — telemetry shows explorer.exe, not loader.exe"
        )
    }
}

// MARK: - WPA2 handshake capture (wireless)

struct WiFiHandshakeView: View {
    var body: some View {
        FlowStage(
            nodes: [
                FlowNode(id: "cli", pos: CGPoint(x: 0.16, y: 0.32), title: "Client", subtitle: "laptop",
                         system: "laptopcomputer", color: Theme.teal, startActive: true),
                FlowNode(id: "ap", pos: CGPoint(x: 0.84, y: 0.32), title: "AP", subtitle: "WPA2",
                         system: "wifi", color: Theme.blue, startActive: true),
                FlowNode(id: "atk", pos: CGPoint(x: 0.5, y: 0.84), title: "Attacker", subtitle: "monitor mode",
                         system: "antenna.radiowaves.left.and.right", color: Theme.red, startActive: true)
            ],
            messages: [
                FlowMessage(from: "atk", to: "cli", label: "deauth", color: Theme.red, start: 0.04, end: 0.18, system: "bolt.horizontal.fill"),
                FlowMessage(from: "ap", to: "cli", label: "ANonce", color: Theme.blue, start: 0.24, end: 0.40),
                FlowMessage(from: "cli", to: "ap", label: "SNonce + MIC", color: Theme.teal, start: 0.44, end: 0.60),
                FlowMessage(from: "cli", to: "atk", label: "handshake sniffed", color: Theme.amber, start: 0.64, end: 0.84, system: "doc.viewfinder")
            ],
            period: 7,
            footnote: "force a reconnect, capture the 4-way handshake → crack the PSK offline (hashcat -m 22000)"
        )
    }
}

// MARK: - ARP poisoning / MITM (wireless & network)

struct ARPPoisoningView: View {
    var body: some View {
        FlowStage(
            nodes: [
                FlowNode(id: "vic", pos: CGPoint(x: 0.14, y: 0.34), title: "Victim", subtitle: "10.0.0.5",
                         system: "laptopcomputer", color: Theme.teal, startActive: true),
                FlowNode(id: "gw", pos: CGPoint(x: 0.86, y: 0.34), title: "Gateway", subtitle: "10.0.0.1",
                         system: "network", color: Theme.blue, startActive: true),
                FlowNode(id: "atk", pos: CGPoint(x: 0.5, y: 0.84), title: "Attacker", subtitle: "in the middle",
                         system: "desktopcomputer", color: Theme.red, startActive: true)
            ],
            messages: [
                FlowMessage(from: "atk", to: "vic", label: "GW is-at atk-MAC", color: Theme.red, start: 0.04, end: 0.22, system: "arrow.triangle.swap"),
                FlowMessage(from: "atk", to: "gw", label: "victim is-at atk-MAC", color: Theme.red, start: 0.26, end: 0.44, system: "arrow.triangle.swap"),
                FlowMessage(from: "vic", to: "atk", label: "traffic", color: Theme.amber, start: 0.52, end: 0.68),
                FlowMessage(from: "atk", to: "gw", label: "relayed", color: Theme.green, start: 0.72, end: 0.90)
            ],
            period: 7,
            footnote: "poison both ARP caches → every victim↔gateway packet now flows through you"
        )
    }
}

// MARK: - Return-Oriented Programming (exploit dev)

/// With DEP marking the stack non-executable, the attacker can't run injected
/// shellcode — so they chain existing code "gadgets", each ending in `ret`, to
/// call `system("/bin/sh")` entirely from code already in the binary.
struct ROPChainView: View {
    private let gadgets: [(addr: String, asm: String, note: String, c: Color)] = [
        ("0x401234", "pop rdi ; ret", "load argument", Theme.teal),
        ("0x4a3b00", "\"/bin/sh\"",    "→ rdi", Theme.amber),
        ("0x401890", "ret",            "stack align", Theme.violet),
        ("0x40a0c0", "system()",       "execute", Theme.red)
    ]
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let n = gadgets.count
            let top: CGFloat = 30
            let rowH = (h - top - 24) / CGFloat(n)
            LoopingTimeline(period: 6.5) { p in
                let active = min(n - 1, Int(p * Double(n + 1)))
                ZStack {
                    Text("DEP: stack is non-executable → reuse existing code")
                        .font(Theme.mono(8, .bold)).foregroundStyle(Theme.textDim)
                        .position(x: w * 0.5, y: 12)

                    ForEach(gadgets.indices, id: \.self) { i in
                        let on = i <= active
                        let y = top + (CGFloat(i) + 0.5) * rowH
                        HStack(spacing: 8) {
                            Text(gadgets[i].addr)
                                .font(Theme.mono(9)).foregroundStyle(Theme.textDim).frame(width: 58, alignment: .leading)
                            Text(gadgets[i].asm)
                                .font(Theme.mono(10, .bold))
                                .foregroundStyle(on ? .black : Theme.textDim)
                                .padding(.horizontal, 8).padding(.vertical, 5)
                                .frame(width: 118, alignment: .leading)
                                .background((on ? gadgets[i].c : Theme.surfaceHi), in: RoundedRectangle(cornerRadius: 6))
                                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(gadgets[i].c.opacity(0.7), lineWidth: 1))
                            Text(gadgets[i].note)
                                .font(Theme.mono(8)).foregroundStyle(on ? gadgets[i].c : Theme.textDim)
                        }
                        .position(x: w * 0.46, y: y)
                        .shadow(color: i == active ? gadgets[i].c.opacity(0.6) : .clear, radius: 7)

                        // "ret →" connector to the next gadget
                        if i < n - 1 && i < active {
                            Image(systemName: "arrow.turn.down.right")
                                .font(.system(size: 9, weight: .bold)).foregroundStyle(Theme.red)
                                .position(x: w * 0.92, y: y + rowH * 0.5)
                        }
                    }

                    if active >= n - 1 {
                        Text("system(\"/bin/sh\") → shell · no injected shellcode")
                            .font(Theme.mono(8.5, .bold)).foregroundStyle(Theme.red)
                            .position(x: w * 0.5, y: h - 10)
                    }
                }
                .animation(.easeInOut(duration: 0.35), value: active)
            }
        }
    }
}
