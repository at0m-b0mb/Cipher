import SwiftUI

// MARK: - Expansion wave 4 explainers
//
// Nine new visualizations: XOR/bitwise, a SQL SELECT scan, regex matching, BGP
// route selection, email delivery (SMTP/MX/IMAP), the QUIC vs TCP+TLS round-trip
// comparison, AD CS ESC1 abuse, SSRF, and ransomware encryption + backup
// recovery. They reuse the shared `LoopingTimeline`, `netNode`, `TokenChip`,
// `lerp` and `ease` helpers, plus the three file-private helpers below.

// MARK: - File-private drawing helpers

private func wire4(_ a: CGPoint, _ b: CGPoint, _ color: Color = Theme.stroke) -> some View {
    Path { p in p.move(to: a); p.addLine(to: b) }
        .stroke(color, style: StrokeStyle(lineWidth: 1.2, dash: [3, 4]))
}

@ViewBuilder
private func chip4(_ a: CGPoint, _ b: CGPoint, _ p: Double, _ s: Double, _ e: Double,
                   _ label: String, _ c: Color, system: String = "arrow.right") -> some View {
    if p >= s && p <= e {
        let t = ease(CGFloat((p - s) / max(0.0001, e - s)))
        TokenChip(text: label, color: c, system: system)
            .position(lerp(a, b, t))
    }
}

private func panel4<C: View>(_ title: String, _ system: String, _ color: Color,
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

// MARK: 1 — XOR cipher / bitwise

/// XOR is the bitwise workhorse of cryptography: combine plaintext with a key
/// bit by bit, and XOR-ing with the same key again returns the original. We
/// compute the cipher byte one column at a time, then run it backwards.
struct XORCipherView: View {
    private let plain = [0, 1, 0, 0, 1, 0, 0, 0]   // 'H' = 0x48
    private let key   = [0, 0, 1, 0, 1, 1, 0, 1]
    private var cipher: [Int] { zip(plain, key).map { $0 ^ $1 } }

    var body: some View {
        LoopingTimeline(period: 8) { p in
            let phase = p < 0.55 ? 0 : 1
            let local = phase == 0 ? p / 0.55 : (p - 0.55) / 0.45
            let idx = min(8, Int(local * 9))
            VStack(spacing: 9) {
                Text(phase == 0 ? "ENCRYPT — plaintext ⊕ key" : "DECRYPT — ciphertext ⊕ key")
                    .font(Theme.mono(9, .bold)).foregroundStyle(phase == 0 ? Theme.teal : Theme.green)
                row("P", phase == 0 ? plain : cipher, Theme.textSecondary, revealed: 8)
                row("K", key, Theme.amber, revealed: 8)
                Rectangle().fill(Theme.stroke).frame(width: 250, height: 1)
                row("=", phase == 0 ? cipher : plain, Theme.green, revealed: idx, highlight: idx < 8 ? idx : -1)
                Text(phase == 0 ? "0⊕0=0   1⊕1=0   0⊕1=1   1⊕0=1"
                                : "the SAME key reverses it → 01001000 = ‘H’")
                    .font(Theme.mono(8)).foregroundStyle(Theme.textDim)
                    .multilineTextAlignment(.center).frame(width: 290)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 4)
            .animation(.easeInOut(duration: 0.18), value: idx)
        }
    }

    @ViewBuilder private func row(_ label: String, _ bits: [Int], _ color: Color,
                                  revealed: Int, highlight: Int = -1) -> some View {
        HStack(spacing: 4) {
            Text(label).font(Theme.mono(11, .bold)).foregroundStyle(color).frame(width: 16)
            ForEach(0..<8, id: \.self) { i in
                Text(i < revealed ? "\(bits[i])" : "·")
                    .font(Theme.mono(13, .bold))
                    .foregroundStyle(i < revealed ? color : Theme.textDim)
                    .frame(width: 24, height: 24)
                    .background(i == highlight ? color.opacity(0.20) : Color.clear,
                                in: RoundedRectangle(cornerRadius: 5))
            }
        }
    }
}

// MARK: 2 — SQL SELECT scan

/// A query reads as data: SELECT picks columns, WHERE filters rows. A scan head
/// walks the table; rows that satisfy the predicate light up, the rest dim out.
struct SQLQueryView: View {
    private let rows: [(String, Int)] = [("alice", 34), ("bob", 27), ("carol", 41), ("dave", 19), ("erin", 38)]

    var body: some View {
        LoopingTimeline(period: 7) { p in
            let scan = min(rows.count, Int(p * Double(rows.count + 1)))
            VStack(spacing: 8) {
                Text("SELECT name FROM users WHERE age > 30")
                    .font(Theme.mono(9.5, .bold)).foregroundStyle(Theme.teal)
                HStack {
                    Text("name").frame(width: 100, alignment: .leading)
                    Text("age").frame(width: 60, alignment: .leading)
                    Spacer()
                }
                .font(Theme.mono(8, .bold)).foregroundStyle(Theme.textDim).frame(width: 236)
                ForEach(0..<rows.count, id: \.self) { i in
                    let scanned = i < scan
                    let match = scanned && rows[i].1 > 30
                    HStack {
                        Text(rows[i].0).frame(width: 100, alignment: .leading)
                        Text("\(rows[i].1)").frame(width: 60, alignment: .leading)
                        Spacer()
                        if scanned {
                            Image(systemName: match ? "checkmark.circle.fill" : "xmark")
                                .font(.system(size: 9, weight: .bold))
                        }
                    }
                    .font(Theme.mono(9.5, .bold))
                    .foregroundStyle(match ? Theme.green : (scanned ? Theme.textDim : Theme.textSecondary))
                    .frame(width: 220)
                    .padding(.vertical, 5).padding(.horizontal, 8)
                    .background(match ? Theme.green.opacity(0.12)
                                : (i == scan ? Theme.amber.opacity(0.10) : Color.clear),
                                in: RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(i == scan ? Theme.amber.opacity(0.6) : Color.clear, lineWidth: 1))
                }
                Text(scan >= rows.count ? "3 rows matched the WHERE clause" : "scanning rows…")
                    .font(Theme.mono(8, .bold))
                    .foregroundStyle(scan >= rows.count ? Theme.green : Theme.textDim)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 4)
            .animation(.easeInOut(duration: 0.2), value: scan)
        }
    }
}

// MARK: 3 — Regex matching

/// A regular expression is a pattern that finds structure in text. A scan head
/// sweeps the input; when the character classes, quantifiers and literals line
/// up, the matching span is captured.
struct RegexMatchView: View {
    private let text = Array("contact bob@acme.com today")
    private let matchStart = 8
    private let matchEnd = 20   // "bob@acme.com"

    var body: some View {
        LoopingTimeline(period: 7) { p in
            let scan = Int(p * Double(text.count + 4))
            let matched = scan >= matchEnd
            VStack(spacing: 11) {
                Text("PATTERN").font(Theme.mono(7.5, .bold)).foregroundStyle(Theme.textDim)
                Text("[a-z]+@[a-z]+\\.[a-z]+")
                    .font(Theme.mono(13, .bold)).foregroundStyle(Theme.teal)
                Text("INPUT").font(Theme.mono(7.5, .bold)).foregroundStyle(Theme.textDim)
                HStack(spacing: 0) {
                    ForEach(0..<text.count, id: \.self) { i in
                        let inMatch = i >= matchStart && i < matchEnd
                        let lit = i < scan && inMatch
                        Text(String(text[i]))
                            .font(Theme.mono(11, .bold))
                            .foregroundStyle(lit ? .black : (i < scan ? Theme.textSecondary : Theme.textDim))
                            .frame(width: 11, height: 22)
                            .background(lit ? Theme.green : (i == scan ? Theme.amber.opacity(0.5) : Color.clear))
                    }
                }
                Text(matched ? "match: bob@acme.com  ✓" : "scanning for the pattern…")
                    .font(Theme.mono(9, .bold)).foregroundStyle(matched ? Theme.green : Theme.amber)
                Text("classes [a-z], the + quantifier, literal @ and \\. — regex is how you find structure in text")
                    .font(Theme.mono(7)).foregroundStyle(Theme.textDim)
                    .multilineTextAlignment(.center).frame(width: 295)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.14), value: scan)
        }
    }
}

// MARK: 4 — BGP route selection

/// The internet is a mesh of Autonomous Systems. Each AS announces which
/// prefixes it can reach; BGP propagates those announcements and every router
/// picks the best (usually shortest) AS-path to a destination.
struct BGPRoutingView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let you = CGPoint(x: w * 0.14, y: h * 0.46)
            let as1 = CGPoint(x: w * 0.40, y: h * 0.22)
            let as2 = CGPoint(x: w * 0.40, y: h * 0.70)
            let as3 = CGPoint(x: w * 0.65, y: h * 0.46)
            let dst = CGPoint(x: w * 0.89, y: h * 0.46)
            LoopingTimeline(period: 8) { p in
                let announced = p > 0.45
                ZStack {
                    wire4(you, as1); wire4(you, as2); wire4(as1, as3)
                    wire4(as2, as3); wire4(as3, dst); wire4(as1, as2)
                    netNode("network", "AS65000\nyou", Theme.teal, true).position(you)
                    netNode("globe", "AS100", Theme.violet, true).position(as1)
                    netNode("globe", "AS200", Theme.violet, true).position(as2)
                    netNode("globe", "AS300", Theme.violet, true).position(as3)
                    netNode("server.rack", "AS400\n203.0.113/24", Theme.blue, true).position(dst)

                    chip4(dst, as3, p, 0.05, 0.20, "I reach /24", Theme.amber, system: "megaphone.fill")
                    chip4(as3, as1, p, 0.20, 0.34, "via AS400", Theme.amber)
                    chip4(as3, as2, p, 0.20, 0.34, "via AS400", Theme.amber)

                    if announced {
                        chip4(you, as1, p, 0.50, 0.64, "packet", Theme.green)
                        chip4(as1, as3, p, 0.64, 0.80, "packet", Theme.green)
                        chip4(as3, dst, p, 0.80, 0.96, "packet", Theme.green)
                    }

                    Text(announced ? "BGP chose the shortest AS-path: you → AS100 → AS300 → AS400"
                                   : "each AS announces which prefixes it can reach, and through whom…")
                        .font(Theme.mono(8, .bold))
                        .foregroundStyle(announced ? Theme.green : Theme.amber)
                        .multilineTextAlignment(.center).frame(width: w * 0.94)
                        .position(x: w * 0.5, y: h * 0.95)
                }
                .animation(.easeInOut(duration: 0.3), value: announced)
            }
        }
    }
}

// MARK: 5 — Email delivery

/// Sending mail is several protocols in a trench coat: SMTP submits it, a DNS
/// MX lookup finds the recipient's server, SMTP again delivers it, and the
/// recipient's client pulls it down with IMAP (or POP).
struct EmailFlowView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let alice = CGPoint(x: w * 0.12, y: h * 0.30)
            let out   = CGPoint(x: w * 0.38, y: h * 0.30)
            let dns   = CGPoint(x: w * 0.38, y: h * 0.72)
            let inn   = CGPoint(x: w * 0.66, y: h * 0.30)
            let bob   = CGPoint(x: w * 0.90, y: h * 0.30)
            LoopingTimeline(period: 9) { p in
                ZStack {
                    wire4(alice, out); wire4(out, dns); wire4(out, inn); wire4(inn, bob)
                    netNode("person.fill", "Alice", Theme.teal, true).position(alice)
                    netNode("paperplane.fill", "her SMTP\nserver", Theme.violet, true).position(out)
                    netNode("magnifyingglass", "DNS\nMX lookup", Theme.amber, true).position(dns)
                    netNode("tray.full.fill", "bob.com\nmail server", Theme.violet, true).position(inn)
                    netNode("person.crop.circle", "Bob", Theme.blue, true).position(bob)

                    chip4(alice, out, p, 0.04, 0.20, "SMTP submit", Theme.teal)
                    chip4(out, dns, p, 0.22, 0.36, "MX for bob.com?", Theme.amber)
                    chip4(dns, out, p, 0.36, 0.48, "mail.bob.com", Theme.amber, system: "arrow.up")
                    chip4(out, inn, p, 0.50, 0.68, "SMTP deliver", Theme.violet)
                    chip4(bob, inn, p, 0.72, 0.84, "IMAP fetch?", Theme.blue, system: "arrow.left")
                    chip4(inn, bob, p, 0.84, 0.98, "your mail", Theme.green)

                    Text("submit by SMTP · find the server by MX · deliver by SMTP · read by IMAP/POP")
                        .font(Theme.mono(7.5, .bold)).foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center).frame(width: w * 0.96)
                        .position(x: w * 0.5, y: h * 0.94)
                }
            }
        }
    }
}

// MARK: 6 — QUIC vs TCP+TLS

/// HTTP/2 rides TCP then TLS — each costs a round trip before any data. QUIC
/// (HTTP/3) folds transport and crypto into one handshake over UDP, so it
/// connects in a single round trip (zero on resume) and survives a network
/// change because the connection is named by an id, not an IP/port tuple.
struct QUICHandshakeView: View {
    var body: some View {
        LoopingTimeline(period: 7) { p in
            let step = min(3, Int(p * 4))
            VStack(spacing: 12) {
                Text("CONNECTION SETUP — ROUND TRIPS")
                    .font(Theme.mono(9, .bold)).foregroundStyle(Theme.violet)

                panel4("TCP + TLS 1.3  (HTTP/2)", "tortoise.fill", Theme.amber, lit: true) {
                    HStack(spacing: 6) {
                        rtt("TCP SYN", Theme.amber, step >= 0)
                        rtt("TLS hello", Theme.amber, step >= 1)
                        Text("= 2 RTT").font(Theme.mono(8.5, .bold)).foregroundStyle(Theme.amber)
                    }
                }

                panel4("QUIC  (HTTP/3, over UDP)", "hare.fill", Theme.green, lit: step >= 2) {
                    HStack(spacing: 6) {
                        rtt("crypto + data", Theme.green, step >= 2)
                        Text("= 1 RTT (0 on resume)")
                            .font(Theme.mono(8, .bold))
                            .foregroundStyle(step >= 2 ? Theme.green : Theme.textDim)
                    }
                }

                Text(step >= 3 ? "QUIC merges transport + crypto into one handshake — and a connection id lets it survive a Wi-Fi → cellular switch"
                               : "TCP and TLS each need their own round trip before any data…")
                    .font(Theme.mono(7.5, .bold))
                    .foregroundStyle(step >= 3 ? Theme.green : Theme.textDim)
                    .multilineTextAlignment(.center).frame(width: 296)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 4)
            .animation(.easeInOut(duration: 0.3), value: step)
        }
    }

    @ViewBuilder private func rtt(_ label: String, _ color: Color, _ lit: Bool) -> some View {
        Text(label)
            .font(Theme.mono(8, .bold)).foregroundStyle(lit ? .black : Theme.textDim)
            .padding(.horizontal, 7).padding(.vertical, 4)
            .background(lit ? color : Theme.surfaceHi, in: Capsule())
    }
}

// MARK: 7 — AD CS abuse (ESC1)

/// A misconfigured certificate template (ESC1) lets a low-privilege user request
/// a cert AND name the subject — so they enroll as "Administrator", then use that
/// certificate to authenticate (PKINIT) and receive a Domain Admin ticket.
struct ADCSEsc1View: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let user = CGPoint(x: w * 0.16, y: h * 0.28)
            let ca   = CGPoint(x: w * 0.5,  y: h * 0.28)
            let dc   = CGPoint(x: w * 0.84, y: h * 0.28)
            LoopingTimeline(period: 8) { p in
                let owned = p > 0.78
                ZStack {
                    wire4(user, ca); wire4(ca, dc); wire4(user, dc)
                    netNode("person.fill", owned ? "user →\nDOMAIN ADMIN" : "low-priv\nuser",
                            owned ? Theme.red : Theme.amber, true).position(user)
                    netNode("seal.fill", "AD CS\n(CA)", Theme.violet, true).position(ca)
                    netNode("building.columns.fill", "Domain\nController", Theme.blue, true).position(dc)

                    chip4(user, ca, p, 0.04, 0.24, "enroll: SAN=Administrator", Theme.amber)
                    chip4(ca, user, p, 0.30, 0.50, "cert issued", Theme.red, system: "arrow.left")
                    chip4(user, dc, p, 0.56, 0.76, "PKINIT auth as Administrator", Theme.red)

                    Text(owned ? "ESC1: the template allowed an enrollee-supplied subject → a TGT as Domain Admin"
                               : "the cert template allows enrollee-supplied subject + client authentication…")
                        .font(Theme.mono(7.5, .bold))
                        .foregroundStyle(owned ? Theme.red : Theme.amber)
                        .multilineTextAlignment(.center).frame(width: w * 0.95)
                        .position(x: w * 0.5, y: h * 0.88)
                }
                .animation(.easeInOut(duration: 0.3), value: owned)
            }
        }
    }
}

// MARK: 8 — Server-Side Request Forgery

/// The app is a confused deputy: it fetches any URL you hand it, from inside the
/// trusted network. Point it at the cloud metadata service or an internal admin
/// panel and it reaches past the firewall and reflects the secret back.
struct SSRFAttackView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let atk = CGPoint(x: w * 0.15, y: h * 0.30)
            let app = CGPoint(x: w * 0.50, y: h * 0.30)
            let svc = CGPoint(x: w * 0.85, y: h * 0.30)
            LoopingTimeline(period: 8) { p in
                let leaked = p > 0.74
                ZStack {
                    Path { pa in
                        let x = w * 0.68
                        pa.move(to: CGPoint(x: x, y: h * 0.04)); pa.addLine(to: CGPoint(x: x, y: h * 0.52))
                    }.stroke(Theme.amber.opacity(0.6), style: StrokeStyle(lineWidth: 1.4, dash: [4, 4]))
                    Text("firewall").font(Theme.mono(6.5, .bold)).foregroundStyle(Theme.amber.opacity(0.85))
                        .position(x: w * 0.68, y: h * 0.56)

                    wire4(atk, app); wire4(app, svc)
                    netNode("person.fill", "attacker", Theme.red, true).position(atk)
                    netNode("globe", "web app\n(trusted)", Theme.blue, true).position(app)
                    netNode(leaked ? "key.fill" : "lock.shield.fill",
                            leaked ? "metadata\n169.254.169.254" : "internal\nservice",
                            leaked ? Theme.red : Theme.violet, true).position(svc)

                    chip4(atk, app, p, 0.04, 0.26, "url=http://169.254…", Theme.amber)
                    chip4(app, svc, p, 0.30, 0.52, "GET (from trusted app)", Theme.violet)
                    chip4(svc, app, p, 0.54, 0.72, "IAM creds", Theme.red, system: "arrow.left")
                    chip4(app, atk, p, 0.74, 0.94, "reflected back", Theme.red, system: "arrow.left")

                    Text(leaked ? "the app fetched an internal URL and handed the secret back — no firewall hole needed"
                                : "the app fetches any URL you give it, from inside the trusted network…")
                        .font(Theme.mono(7.5, .bold))
                        .foregroundStyle(leaked ? Theme.red : Theme.textSecondary)
                        .multilineTextAlignment(.center).frame(width: w * 0.95)
                        .position(x: w * 0.5, y: h * 0.90)
                }
                .animation(.easeInOut(duration: 0.3), value: leaked)
            }
        }
    }
}

// MARK: 9 — Ransomware & recovery

/// First the files fall — encrypted one by one. Then the only thing that saves
/// you: restoring from a backup the malware couldn't reach. An offline,
/// immutable copy (the "1" in 3-2-1) turns a catastrophe into an afternoon.
struct RansomwareRecoveryView: View {
    private let cols = 5
    private let rowsN = 2

    var body: some View {
        LoopingTimeline(period: 9) { p in
            let n = cols * rowsN
            let phase = p < 0.5 ? 0 : 1
            let local = phase == 0 ? p / 0.5 : (p - 0.5) / 0.5
            let count = min(n, Int(local * Double(n + 1)))
            VStack(spacing: 11) {
                Text(phase == 0 ? "RANSOMWARE ENCRYPTS YOUR FILES" : "RESTORE FROM OFFLINE BACKUP")
                    .font(Theme.mono(9, .bold)).foregroundStyle(phase == 0 ? Theme.red : Theme.green)

                let grid = Array(repeating: GridItem(.fixed(40), spacing: 8), count: cols)
                LazyVGrid(columns: grid, spacing: 8) {
                    ForEach(0..<n, id: \.self) { i in
                        let locked = phase == 0 ? i < count : i >= count
                        let icon = locked ? "lock.fill" : (phase == 0 ? "doc.fill" : "checkmark")
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(width: 36, height: 30)
                            .background(locked ? Theme.red : Theme.green, in: RoundedRectangle(cornerRadius: 7))
                    }
                }
                .frame(width: 248)

                HStack(spacing: 6) {
                    Image(systemName: phase == 0 ? "exclamationmark.triangle.fill" : "externaldrive.fill.badge.checkmark")
                    Text(phase == 0 ? "no backup → pay the ransom or lose everything"
                                    : "3-2-1: an offline copy can't be encrypted")
                }
                .font(Theme.mono(8, .bold)).foregroundStyle(phase == 0 ? Theme.amber : Theme.green)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 4)
            .animation(.easeInOut(duration: 0.2), value: count)
        }
    }
}
