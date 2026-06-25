import SwiftUI

// MARK: - Expansion wave 2 explainers
//
// Six visualizations filling gaps learners kept asking about: UI-redress
// clickjacking, web cache poisoning, a Bluetooth/BLE replay, RFID/NFC card
// cloning, DDoS reflection/amplification, and LSB steganography. They reuse the
// shared `LoopingTimeline`, `netNode`, `TokenChip`, `lerp` and `ease` helpers,
// plus the three small file-private helpers below.

// MARK: - File-private drawing helpers

/// A faint dashed connector between two points.
private func dashWire(_ a: CGPoint, _ b: CGPoint) -> some View {
    Path { p in p.move(to: a); p.addLine(to: b) }
        .stroke(Theme.stroke, style: StrokeStyle(lineWidth: 1.2, dash: [3, 4]))
}

/// A travelling token that only appears while the loop is inside `[s, e]`,
/// easing from `a` to `b`. The building block for every node-to-node message.
@ViewBuilder
private func flowChip(_ a: CGPoint, _ b: CGPoint, _ p: Double, _ s: Double, _ e: Double,
                      _ label: String, _ c: Color, system: String = "arrow.right") -> some View {
    if p >= s && p <= e {
        let t = ease(CGFloat((p - s) / max(0.0001, e - s)))
        TokenChip(text: label, color: c, system: system)
            .position(lerp(a, b, t))
    }
}

/// A titled, lit/dim panel — the staged-reveal card used by the binary/RFID views.
private func infoPanel<C: View>(_ title: String, _ system: String, _ color: Color,
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

// MARK: 1 — Clickjacking (UI redress)

/// The victim sees a friendly "CLAIM NOW" button; an invisible cross-origin
/// iframe of a real bank "Transfer" button is layered exactly on top. We fade
/// that hidden frame in so you can see the trap, then land the click on it.
struct ClickjackingView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let btn = CGPoint(x: w * 0.5, y: h * 0.55)
            LoopingTimeline(period: 6) { p in
                let reveal = ease(CGFloat(min(max((p - 0.30) / 0.30, 0), 1)))   // hidden-frame opacity
                let cursor = lerp(CGPoint(x: w * 0.20, y: h * 0.16), btn, ease(CGFloat(min(p / 0.62, 1))))
                let clicked = p > 0.66
                ZStack {
                    Text("🎁  You've won a FREE gift card!")
                        .font(Theme.mono(9.5, .bold)).foregroundStyle(Theme.textSecondary)
                        .position(x: w * 0.5, y: h * 0.27)

                    // What the victim THINKS they are clicking.
                    Text("CLAIM NOW")
                        .font(Theme.mono(11, .bold)).foregroundStyle(.black)
                        .frame(width: 152, height: 38)
                        .background(Theme.green, in: RoundedRectangle(cornerRadius: 9))
                        .position(btn)

                    // The invisible iframe of the REAL action, layered exactly on top.
                    Text(clicked ? "⚠︎ CONFIRM £5,000 TRANSFER" : "Confirm £5,000 transfer")
                        .font(Theme.mono(9.5, .bold)).foregroundStyle(.black)
                        .frame(width: 196, height: 44)
                        .background(Theme.red, in: RoundedRectangle(cornerRadius: 9))
                        .opacity(Double(reveal) * (clicked ? 0.96 : 0.5))
                        .position(btn)

                    if reveal > 0.05 {
                        Text("↑ a hidden bank frame sits under your cursor")
                            .font(Theme.mono(7.5)).foregroundStyle(Theme.red.opacity(Double(reveal)))
                            .position(x: w * 0.5, y: h * 0.74)
                    }

                    Image(systemName: "cursorarrow.click.2")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                        .shadow(color: .black.opacity(0.6), radius: 3)
                        .position(cursor)

                    if clicked {
                        Text("your click hit the invisible frame → £5,000 sent")
                            .font(Theme.mono(8, .bold)).foregroundStyle(Theme.red)
                            .multilineTextAlignment(.center).frame(width: w * 0.92)
                            .position(x: w * 0.5, y: h * 0.92)
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: clicked)
            }
        }
    }
}

// MARK: 2 — Web cache poisoning

/// An unkeyed header (Host / X-Forwarded-Host) is reflected into a cacheable
/// response. One attacker request poisons the shared cache entry, and every
/// later visitor is served the attacker's payload.
struct CachePoisoningView: View {
    private let victims = 3
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let atk = CGPoint(x: w * 0.16, y: h * 0.26)
            let cache = CGPoint(x: w * 0.5, y: h * 0.26)
            let origin = CGPoint(x: w * 0.84, y: h * 0.26)
            LoopingTimeline(period: 7) { p in
                let poisoned = p > 0.52
                ZStack {
                    dashWire(atk, cache); dashWire(cache, origin)

                    netNode("person.fill", "attacker", Theme.red, true).position(atk)
                    netNode("externaldrive.fill", poisoned ? "CDN cache\nPOISONED" : "CDN cache",
                            poisoned ? Theme.red : Theme.violet, true).position(cache)
                    netNode("server.rack", "origin", Theme.blue, true).position(origin)

                    flowChip(atk, cache, p, 0.02, 0.22, "X-Forwarded-Host: evil", Theme.amber)
                    flowChip(cache, origin, p, 0.24, 0.40, "cache miss → forward", Theme.violet)
                    flowChip(origin, cache, p, 0.40, 0.52, "200 OK + //evil.js", Theme.red, system: "arrow.left")

                    ForEach(0..<victims, id: \.self) { i in
                        let vp = CGPoint(x: w * (0.30 + 0.20 * Double(i)), y: h * 0.70)
                        let served = poisoned && p > 0.60 + Double(i) * 0.09
                        netNode("person.crop.circle", "visitor \(i + 1)",
                                served ? Theme.red : Theme.textDim, served).position(vp)
                        if poisoned {
                            flowChip(cache, vp, p, 0.60 + Double(i) * 0.09, 0.74 + Double(i) * 0.09,
                                     "evil.js", Theme.red, system: "arrow.down")
                        }
                    }

                    Text(poisoned ? "one poisoned cache entry is served to EVERY visitor"
                                  : "an unkeyed header is reflected — and the response is cacheable…")
                        .font(Theme.mono(8, .bold))
                        .foregroundStyle(poisoned ? Theme.red : Theme.amber)
                        .multilineTextAlignment(.center).frame(width: w * 0.94)
                        .position(x: w * 0.5, y: h * 0.94)
                }
                .animation(.easeInOut(duration: 0.3), value: poisoned)
            }
        }
    }
}

// MARK: 3 — Bluetooth / BLE replay

/// A phone unlocks a smart lock with a plaintext BLE command; an attacker's
/// sniffer captures the packet and replays it verbatim — no key, no pairing.
struct BleAttackView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let phone = CGPoint(x: w * 0.18, y: h * 0.28)
            let lock = CGPoint(x: w * 0.82, y: h * 0.28)
            let attacker = CGPoint(x: w * 0.5, y: h * 0.68)
            LoopingTimeline(period: 7) { p in
                let step = min(3, Int(p * 4))               // 0 advertise · 1 unlock · 2 sniff · 3 replay
                let legitOpen = p > 0.40 && p < 0.52
                let attackOpen = p > 0.88
                let open = legitOpen || attackOpen
                ZStack {
                    dashWire(phone, lock); dashWire(phone, attacker); dashWire(lock, attacker)

                    netNode("iphone", "phone\n(central)", Theme.blue, true).position(phone)
                    netNode(open ? "lock.open.fill" : "lock.fill",
                            open ? "smart lock\nOPEN" : "smart lock",
                            open ? Theme.green : Theme.violet, true).position(lock)
                    netNode("antenna.radiowaves.left.and.right", "attacker\nsniffer",
                            Theme.red, step >= 2).position(attacker)

                    flowChip(lock, phone, p, 0.03, 0.18, "ADV ✓", Theme.amber, system: "dot.radiowaves.left.and.right")
                    flowChip(phone, lock, p, 0.22, 0.40, "0x01 UNLOCK", Theme.blue)
                    flowChip(phone, attacker, p, 0.24, 0.44, "captured", Theme.red, system: "eye.fill")
                    flowChip(attacker, lock, p, 0.66, 0.90, "REPLAY 0x01", Theme.red)

                    Text(step >= 3 ? "the captured command replays verbatim — the lock opens for the attacker"
                         : step >= 2 ? "the sniffer captures the BLE packet off the air"
                         : step >= 1 ? "the phone sends the unlock command — unencrypted"
                                     : "the lock advertises openly, no pairing required")
                        .font(Theme.mono(8, .bold))
                        .foregroundStyle(step >= 3 ? Theme.red : step >= 1 ? Theme.amber : Theme.textDim)
                        .multilineTextAlignment(.center).frame(width: w * 0.92)
                        .position(x: w * 0.5, y: h * 0.94)
                }
                .animation(.easeInOut(duration: 0.3), value: open)
            }
        }
    }
}

// MARK: 4 — RFID / NFC card cloning

/// A covert reader lifts a badge's UID, writes it to a blank card, and the
/// clone opens the door — the classic low-frequency access-card attack.
struct RfidCloneView: View {
    var body: some View {
        LoopingTimeline(period: 6) { p in
            let step = min(3, Int(p * 4))   // 0 read · 1 captured · 2 written · 3 access
            VStack(spacing: 7) {
                infoPanel("1 · READ", "wave.3.right", Theme.violet, lit: step >= 0) {
                    Text(step >= 1 ? "UID  04 A3 19 5C  ✓ captured"
                                   : "covert reader brushed past the victim's badge…")
                        .font(Theme.mono(9, .bold))
                        .foregroundStyle(step >= 1 ? Theme.green : Theme.textSecondary)
                }
                Image(systemName: "arrow.down").font(.system(size: 10, weight: .bold)).foregroundStyle(Theme.textDim)
                infoPanel("2 · WRITE", "square.and.arrow.down.fill", Theme.teal, lit: step >= 2) {
                    Text(step >= 2 ? "UID flashed to a blank T5577 card → clone ready"
                                   : "waiting for the cloner…")
                        .font(Theme.mono(9, .bold))
                        .foregroundStyle(step >= 2 ? Theme.green : Theme.textDim)
                }
                HStack(spacing: 6) {
                    Image(systemName: step >= 3 ? "lock.open.fill" : "lock.fill")
                    Text(step >= 3 ? "clone tapped on the door reader → ACCESS GRANTED"
                                   : "present the clone to the door reader")
                }
                .font(Theme.mono(9.5, .bold))
                .foregroundStyle(step >= 3 ? Theme.green : Theme.red)
                .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 4)
            .animation(.easeInOut(duration: 0.3), value: step)
        }
    }
}

// MARK: 5 — DDoS reflection / amplification

/// A spoofed source address (the victim's) makes open resolvers fire huge
/// replies at the victim — a tiny query becomes a flood many times its size.
struct DdosAmplificationView: View {
    private let reflectors = 4
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let atk = CGPoint(x: w * 0.13, y: h * 0.48)
            let victim = CGPoint(x: w * 0.87, y: h * 0.48)
            LoopingTimeline(period: 5) { p in
                let flooding = p > 0.45
                ZStack {
                    netNode("person.fill", "attacker\nspoofs src=victim", Theme.red, true).position(atk)
                    netNode(flooding ? "xmark.octagon.fill" : "desktopcomputer",
                            flooding ? "victim\nFLOODED" : "victim",
                            flooding ? Theme.amber : Theme.blue, flooding).position(victim)

                    ForEach(0..<reflectors, id: \.self) { i in
                        let ry = h * (0.14 + 0.70 * Double(i) / Double(reflectors - 1))
                        let r = CGPoint(x: w * 0.5, y: ry)
                        dashWire(atk, r); dashWire(r, victim)
                        netNode("server.rack", "open\nresolver", Theme.violet, true).position(r)
                        flowChip(atk, r, p, 0.02 + Double(i) * 0.02, 0.30 + Double(i) * 0.02,
                                 "64 B query", Theme.teal)
                        flowChip(r, victim, p, 0.34 + Double(i) * 0.02, 0.74 + Double(i) * 0.03,
                                 "3,200 B reply", Theme.red)
                    }

                    Text("spoofed 64-byte query → 3,200-byte reply ≈ 50× amplification onto the victim")
                        .font(Theme.mono(8, .bold)).foregroundStyle(Theme.amber)
                        .multilineTextAlignment(.center).frame(width: w * 0.96)
                        .position(x: w * 0.5, y: h * 0.95)
                }
                .animation(.easeInOut(duration: 0.3), value: flooding)
            }
        }
    }
}

// MARK: 6 — LSB steganography

/// The hidden message lives in the least-significant bit of each pixel byte —
/// a change invisible to the eye. A reading head sweeps the cover image,
/// peels off the LSBs, and reassembles the secret byte 'H'.
struct SteganographyView: View {
    private let hidden = [0, 1, 0, 0, 1, 0, 0, 0]   // ASCII 'H' = 0x48
    private let bytes  = ["10110100", "01101101", "11000100", "10101000",
                          "01011001", "11100010", "10010100", "00110000"]
    private let swatches: [Color] = [Theme.red, Theme.amber, Theme.teal, Theme.blue,
                                     Theme.violet, Theme.green, Theme.magenta, Theme.blue]

    var body: some View {
        LoopingTimeline(period: 7) { p in
            let idx = min(8, Int(p * 9))            // pixels read so far
            let bits = hidden.prefix(idx).map(String.init).joined()
            VStack(spacing: 10) {
                Text("LSB STEGANOGRAPHY").font(Theme.mono(9, .bold)).foregroundStyle(Theme.teal)

                Text("COVER IMAGE — unchanged to the eye")
                    .font(Theme.mono(7.5)).foregroundStyle(Theme.textDim)

                HStack(spacing: 5) {
                    ForEach(0..<8, id: \.self) { i in
                        let reading = i == idx
                        let done = i < idx
                        VStack(spacing: 3) {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(swatches[i].opacity(0.85))
                                .frame(width: 22, height: 22)
                                .overlay(RoundedRectangle(cornerRadius: 5)
                                    .strokeBorder(reading ? Color.white : .clear, lineWidth: 1.5))
                                .shadow(color: reading ? .white.opacity(0.8) : .clear, radius: 5)
                            HStack(spacing: 0) {
                                Text(String(bytes[i].dropLast()))
                                    .foregroundStyle(Theme.textDim)
                                Text(String(bytes[i].last!))
                                    .foregroundStyle(done || reading ? Theme.green : Theme.amber)
                            }
                            .font(Theme.mono(6.5, .bold))
                        }
                    }
                }

                VStack(spacing: 3) {
                    Text("hidden bits:  \(bits.isEmpty ? "…" : bits)")
                        .font(Theme.mono(9, .bold)).foregroundStyle(Theme.textSecondary)
                    Text(idx >= 8 ? "decoded byte 0x48  →  “H”" : "reading the last bit of each pixel…")
                        .font(Theme.mono(9.5, .bold))
                        .foregroundStyle(idx >= 8 ? Theme.green : Theme.textDim)
                }

                Text("every 8 pixels hide one character — a whole file fits in an innocent image")
                    .font(Theme.mono(7)).foregroundStyle(Theme.textDim)
                    .multilineTextAlignment(.center).frame(width: 280)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.2), value: idx)
        }
    }
}
