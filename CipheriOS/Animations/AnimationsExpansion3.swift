import SwiftUI

// MARK: - Expansion wave 3 explainers
//
// Seven new visualizations rounding out gaps in the curriculum: the TLS 1.3
// handshake, IPv6 addressing, load balancing / CDN edge distribution, password
// spraying, NoSQL injection, the purple-team feedback loop, and STRIDE threat
// modeling. They reuse the shared `LoopingTimeline`, `netNode`, `TokenChip`,
// `lerp` and `ease` helpers, plus the three small file-private helpers below.

// MARK: - File-private drawing helpers

/// A faint dashed connector between two points.
private func wire3(_ a: CGPoint, _ b: CGPoint, _ color: Color = Theme.stroke) -> some View {
    Path { p in p.move(to: a); p.addLine(to: b) }
        .stroke(color, style: StrokeStyle(lineWidth: 1.2, dash: [3, 4]))
}

/// A travelling token that only appears while the loop is inside `[s, e]`,
/// easing from `a` to `b`.
@ViewBuilder
private func chip3(_ a: CGPoint, _ b: CGPoint, _ p: Double, _ s: Double, _ e: Double,
                   _ label: String, _ c: Color, system: String = "arrow.right") -> some View {
    if p >= s && p <= e {
        let t = ease(CGFloat((p - s) / max(0.0001, e - s)))
        TokenChip(text: label, color: c, system: system)
            .position(lerp(a, b, t))
    }
}

/// A titled, lit/dim panel — the staged-reveal card used by the NoSQL view.
private func panel3<C: View>(_ title: String, _ system: String, _ color: Color,
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

// MARK: 1 — TLS 1.3 handshake

/// ClientHello and ServerHello each carry a key share, so one round trip is
/// enough to agree a shared secret (ECDHE). Everything after the handshake —
/// the certificate, the Finished messages and all application data — is
/// encrypted. TLS 1.3 reduced this to a single round trip (1-RTT).
struct TLSHandshakeView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let c = CGPoint(x: w * 0.17, y: h * 0.30)
            let s = CGPoint(x: w * 0.83, y: h * 0.30)
            LoopingTimeline(period: 8) { p in
                let keyed = p > 0.50
                let secure = p > 0.62
                ZStack {
                    wire3(c, s)
                    netNode("laptopcomputer", "client", Theme.teal, true).position(c)
                    netNode(secure ? "lock.fill" : "server.rack",
                            secure ? "server\nsecure" : "server",
                            secure ? Theme.green : Theme.blue, true).position(s)

                    chip3(c, s, p, 0.02, 0.18, "ClientHello +keyshare", Theme.teal)
                    chip3(s, c, p, 0.20, 0.36, "ServerHello +keyshare", Theme.blue, system: "arrow.left")
                    chip3(s, c, p, 0.36, 0.50, "{Certificate}", Theme.amber, system: "arrow.left")
                    chip3(s, c, p, 0.50, 0.60, "{Finished}", Theme.blue, system: "arrow.left")
                    chip3(c, s, p, 0.60, 0.72, "{Finished}", Theme.teal)
                    if secure { chip3(c, s, p, 0.80, 0.96, "GET / (encrypted)", Theme.green) }

                    VStack(spacing: 2) {
                        Image(systemName: "key.horizontal.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(keyed ? Theme.green : Theme.textDim)
                        Text(keyed ? "shared key derived\n(ECDHE)" : "no shared key yet")
                            .font(Theme.mono(7.5, .bold))
                            .foregroundStyle(keyed ? Theme.green : Theme.textDim)
                            .multilineTextAlignment(.center)
                    }
                    .position(x: w * 0.5, y: h * 0.60)

                    Text(secure ? "both sides now share a key — the cert and all data after this are encrypted"
                                : "each Hello carries a key share, so TLS 1.3 agrees a secret in just one round trip")
                        .font(Theme.mono(8, .bold))
                        .foregroundStyle(secure ? Theme.green : Theme.textSecondary)
                        .multilineTextAlignment(.center).frame(width: w * 0.94)
                        .position(x: w * 0.5, y: h * 0.92)
                }
                .animation(.easeInOut(duration: 0.3), value: secure)
            }
        }
    }
}

// MARK: 2 — IPv6 address anatomy

/// A 128-bit IPv6 address splits into a 48-bit global routing prefix (your
/// ISP), a 16-bit subnet id (yours to carve up), and a 64-bit interface id
/// (the host, often auto-built from the MAC via SLAAC). We light each field in
/// turn and size a bar to its share of the bits.
struct IPv6AddressView: View {
    private let hextets = ["2001", "0db8", "85a3", "1f00", "0000", "8a2e", "0370", "7334"]
    private struct Seg { let name: String; let bits: String; let color: Color; let detail: String }
    private let segs = [
        Seg(name: "Global Routing Prefix", bits: "48 bits", color: Theme.violet,
            detail: "handed to you by your ISP — locates your whole site on the internet"),
        Seg(name: "Subnet ID", bits: "16 bits", color: Theme.amber,
            detail: "yours to assign — up to 65,536 subnets inside that one prefix"),
        Seg(name: "Interface ID", bits: "64 bits", color: Theme.teal,
            detail: "names the host — often auto-built from the MAC (SLAAC / EUI-64)")
    ]

    var body: some View {
        LoopingTimeline(period: 9) { p in
            let step = min(2, Int(p * 3))
            VStack(spacing: 12) {
                Text("ONE IPv6 ADDRESS = 128 BITS")
                    .font(Theme.mono(9, .bold)).foregroundStyle(Theme.violet)

                HStack(spacing: 2) {
                    ForEach(0..<8, id: \.self) { i in
                        let g = i < 3 ? 0 : (i < 4 ? 1 : 2)
                        let on = g == step
                        Text(hextets[i])
                            .font(Theme.mono(12, .bold))
                            .foregroundStyle(on ? segs[g].color : Theme.textDim)
                            .scaleEffect(on ? 1.14 : 1)
                        if i < 7 { Text(":").font(Theme.mono(10)).foregroundStyle(Theme.textDim) }
                    }
                }

                HStack(spacing: 3) {
                    bar(segs[0], units: 3, on: step == 0)
                    bar(segs[1], units: 1, on: step == 1)
                    bar(segs[2], units: 4, on: step == 2)
                }

                VStack(spacing: 3) {
                    Text("\(segs[step].name)  ·  \(segs[step].bits)")
                        .font(Theme.mono(9.5, .bold)).foregroundStyle(segs[step].color)
                    Text(segs[step].detail)
                        .font(Theme.mono(8)).foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center).frame(width: 280)
                }

                Text("no more NAT — there are enough addresses for every device on earth, many times over")
                    .font(Theme.mono(7.5)).foregroundStyle(Theme.textDim)
                    .multilineTextAlignment(.center).frame(width: 290)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 4)
            .animation(.easeInOut(duration: 0.35), value: step)
        }
    }

    @ViewBuilder private func bar(_ s: Seg, units: CGFloat, on: Bool) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(s.color.opacity(on ? 0.9 : 0.28))
            .frame(width: units * 28, height: 16)
            .overlay(Text(s.bits).font(Theme.mono(6.5, .bold))
                .foregroundStyle(on ? .black : Theme.textDim))
    }
}

// MARK: 3 — Load balancer / CDN edge

/// A pool of identical backends sits behind one load balancer. Each incoming
/// request is sent to the next healthy node (round-robin); the node failing its
/// health check is skipped entirely — the foundation of scaling and uptime.
struct LoadBalancerView: View {
    private let total = 4
    private let down = 2
    private let healthy = [0, 1, 3]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let client = CGPoint(x: w * 0.12, y: h * 0.45)
            let lb = CGPoint(x: w * 0.42, y: h * 0.45)
            LoopingTimeline(period: 6) { p in
                let rounds = healthy.count
                let rlen = 1.0 / Double(rounds)
                let r = min(rounds - 1, Int(p / rlen))
                let base = Double(r) * rlen
                let local = (p - base) / rlen
                let target = healthy[r]
                let atServer = local > 0.45
                ZStack {
                    ForEach(0..<total, id: \.self) { i in
                        let sy = h * (0.13 + 0.66 * Double(i) / Double(total - 1))
                        let sp = CGPoint(x: w * 0.82, y: sy)
                        let isDown = i == down
                        let chosen = atServer && target == i
                        wire3(lb, sp)
                        netNode(isDown ? "xmark.octagon.fill" : "server.rack",
                                isDown ? "node \(i + 1)\ndown" : "node \(i + 1)",
                                isDown ? Theme.red : (chosen ? Theme.green : Theme.violet),
                                chosen || isDown).position(sp)
                        if target == i {
                            chip3(lb, sp, p, base + rlen * 0.45, base + rlen * 0.92,
                                  "serve", Theme.green, system: "shippingbox.fill")
                        }
                    }
                    wire3(client, lb)
                    netNode("person.2.fill", "clients", Theme.blue, true).position(client)
                    netNode("rectangle.split.3x1.fill", "load\nbalancer", Theme.violet, true).position(lb)
                    chip3(client, lb, p, base + rlen * 0.05, base + rlen * 0.42, "request", Theme.blue)

                    Text("the balancer spreads requests across healthy nodes — and skips the one failing its health check")
                        .font(Theme.mono(8, .bold)).foregroundStyle(Theme.violet)
                        .multilineTextAlignment(.center).frame(width: w * 0.94)
                        .position(x: w * 0.5, y: h * 0.95)
                }
                .animation(.easeInOut(duration: 0.25), value: atServer)
            }
        }
    }
}

// MARK: 4 — Password spraying

/// Brute force hammers one account and trips its lockout. Spraying inverts it:
/// try ONE common password against MANY accounts, one attempt each, so no single
/// account's failure counter trips — and one reused password is all it takes.
struct PasswordSprayView: View {
    private let users = ["alice", "bob", "carol", "dave", "erin", "frank", "gita", "hugo"]
    private let hit = 5   // frank reused the sprayed password

    var body: some View {
        LoopingTimeline(period: 8) { p in
            let tried = min(users.count, Int(p * Double(users.count + 1)))
            VStack(spacing: 11) {
                HStack(spacing: 5) {
                    Image(systemName: "key.fill").font(.system(size: 10, weight: .bold)).foregroundStyle(Theme.amber)
                    Text("spraying one password:").font(Theme.mono(9.5, .bold)).foregroundStyle(Theme.textSecondary)
                    Text("Spring2026!").font(Theme.mono(9.5, .bold)).foregroundStyle(Theme.amber)
                }

                let cols = Array(repeating: GridItem(.fixed(60), spacing: 8), count: 4)
                LazyVGrid(columns: cols, spacing: 8) {
                    ForEach(0..<users.count, id: \.self) { i in
                        let done = i < tried
                        let won = done && i == hit
                        VStack(spacing: 3) {
                            Image(systemName: won ? "lock.open.fill" : (done ? "xmark" : "person.fill"))
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(won ? .black : (done ? Theme.textDim : Theme.textSecondary))
                                .frame(width: 34, height: 28)
                                .background(won ? Theme.green : Theme.surfaceHi.opacity(0.7),
                                            in: RoundedRectangle(cornerRadius: 7))
                            Text(users[i]).font(Theme.mono(7.5, .bold))
                                .foregroundStyle(won ? Theme.green : (done ? Theme.textDim : Theme.textSecondary))
                        }
                    }
                }
                .frame(width: 284)

                Text(tried > hit ? "1 try per account → no lockout, and one user reused the password"
                                 : "one attempt each, then move on — the lockout counter never trips")
                    .font(Theme.mono(8, .bold))
                    .foregroundStyle(tried > hit ? Theme.green : Theme.textSecondary)
                    .multilineTextAlignment(.center).frame(width: 290)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 4)
            .animation(.easeInOut(duration: 0.25), value: tried)
        }
    }
}

// MARK: 5 — NoSQL injection

/// Where SQL injection breaks out of a string, NoSQL injection abuses the fact
/// that the query is a structured object. Smuggling an operator like `$ne`
/// (not-equal) turns "password must equal X" into "password just has to exist"
/// — an authentication bypass with no password at all.
struct NoSQLInjectionView: View {
    var body: some View {
        LoopingTimeline(period: 8) { p in
            let injected = p > 0.5
            VStack(spacing: 9) {
                Text("MONGODB LOGIN QUERY")
                    .font(Theme.mono(9, .bold)).foregroundStyle(Theme.red)

                panel3(injected ? "ATTACKER SENDS" : "NORMAL LOGIN",
                       injected ? "exclamationmark.shield.fill" : "person.fill",
                       injected ? Theme.red : Theme.blue, lit: true) {
                    Text(injected ? "{ \"user\": \"admin\",\n  \"pass\": { \"$ne\": null } }"
                                  : "{ \"user\": \"admin\",\n  \"pass\": \"hunter2\" }")
                        .font(Theme.mono(9.5, .bold))
                        .foregroundStyle(injected ? Theme.amber : Theme.textSecondary)
                }

                Image(systemName: "arrow.down").font(.system(size: 10, weight: .bold)).foregroundStyle(Theme.textDim)

                panel3("SERVER EVALUATES", "server.rack", Theme.violet, lit: true) {
                    Text(injected ? "pass ≠ null is true for EVERY user\n→ the query matches admin"
                                  : "\"hunter2\" ≠ stored password\n→ no document matches")
                        .font(Theme.mono(8, .bold))
                        .foregroundStyle(injected ? Theme.red : Theme.textDim)
                }

                HStack(spacing: 6) {
                    Image(systemName: injected ? "lock.open.fill" : "lock.fill")
                    Text(injected ? "logged in as admin — no password needed" : "access denied")
                }
                .font(Theme.mono(9.5, .bold))
                .foregroundStyle(injected ? Theme.green : Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 4)
            .animation(.easeInOut(duration: 0.3), value: injected)
        }
    }
}

// MARK: 6 — The purple-team loop

/// Red emulates a known technique, blue checks whether it was detected, the gap
/// is found, a detection is built and tested — and measured coverage climbs.
/// Purple teaming is that closed feedback loop, not a separate team.
struct PurpleTeamView: View {
    private let steps: [(String, String, String, Color)] = [
        ("flame.fill",                  "Red emulates",     "runs ATT&CK T1003 — credential dump", Theme.red),
        ("magnifyingglass",             "Blue checks",      "did the SIEM alert on it?",           Theme.blue),
        ("exclamationmark.triangle.fill","Gap found",       "no detection fired",                  Theme.amber),
        ("checkmark.shield.fill",       "Detection built",  "new rule written + tested → covered", Theme.green)
    ]

    var body: some View {
        LoopingTimeline(period: 8) { p in
            let active = min(steps.count - 1, Int(p * Double(steps.count)))
            let coverage = 0.40 + 0.55 * Double(active) / Double(steps.count - 1)
            VStack(spacing: 10) {
                Text("THE PURPLE-TEAM LOOP")
                    .font(Theme.mono(9, .bold)).foregroundStyle(Theme.violet)

                ForEach(0..<steps.count, id: \.self) { i in
                    let on = i == active
                    let done = i < active
                    HStack(spacing: 9) {
                        ZStack {
                            Circle().fill(on || done ? steps[i].3 : Theme.surfaceHi)
                                .frame(width: 28, height: 28)
                                .overlay(Circle().strokeBorder(steps[i].3.opacity(on || done ? 1 : 0.3), lineWidth: 1.5))
                                .shadow(color: on ? steps[i].3.opacity(0.7) : .clear, radius: 7)
                            Image(systemName: steps[i].0).font(.system(size: 12, weight: .bold))
                                .foregroundStyle(on || done ? .black : Theme.textDim)
                        }
                        VStack(alignment: .leading, spacing: 0) {
                            Text(steps[i].1).font(Theme.mono(10.5, .bold))
                                .foregroundStyle(on ? Theme.textPrimary : (done ? Theme.textSecondary : Theme.textDim))
                            Text(steps[i].2).font(Theme.mono(8))
                                .foregroundStyle(on ? steps[i].3 : Theme.textDim)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                VStack(spacing: 3) {
                    HStack {
                        Text("detection coverage").font(Theme.mono(8, .bold)).foregroundStyle(Theme.textDim)
                        Spacer()
                        Text("\(Int(coverage * 100))%").font(Theme.mono(8, .bold)).foregroundStyle(Theme.green)
                    }
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Theme.surfaceHi).frame(height: 6)
                            Capsule().fill(Theme.green).frame(width: g.size.width * coverage, height: 6)
                                .shadow(color: Theme.green.opacity(0.5), radius: 3)
                        }
                    }.frame(height: 6)
                }
                .frame(width: 284)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 4)
            .animation(.easeInOut(duration: 0.4), value: active)
        }
    }
}

// MARK: 7 — STRIDE threat modeling

/// Threat modeling asks "what can go wrong?" of a design before it ships.
/// STRIDE is the prompt: for each element crossing a trust boundary, walk the
/// six threat categories. Here a simple data-flow diagram sits above the six
/// STRIDE threats, each lighting up with the security property it violates.
struct ThreatModelingView: View {
    private let stride: [(String, String, String, String, Color)] = [
        ("S", "Spoofing",          "impersonating another user or system", "Authentication",   Theme.red),
        ("T", "Tampering",         "altering data in transit or at rest",  "Integrity",        Theme.amber),
        ("R", "Repudiation",       "denying an action with no audit trail", "Non-repudiation",  Theme.violet),
        ("I", "Info Disclosure",   "leaking data to the unauthorized",      "Confidentiality",  Theme.blue),
        ("D", "Denial of Service", "exhausting a resource to deny others",  "Availability",     Theme.magenta),
        ("E", "Elevation of Priv.","gaining rights you were never granted", "Authorization",    Theme.green)
    ]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            LoopingTimeline(period: 9) { p in
                let active = min(stride.count - 1, Int(p * Double(stride.count)))
                let u = CGPoint(x: w * 0.16, y: h * 0.15)
                let app = CGPoint(x: w * 0.5, y: h * 0.15)
                let db = CGPoint(x: w * 0.84, y: h * 0.15)
                ZStack {
                    wire3(u, app); wire3(app, db)
                    netNode("person.fill", "user", Theme.blue, true).position(u)
                    netNode("globe", "web app", Theme.teal, true).position(app)
                    netNode("cylinder.fill", "database", Theme.violet, true).position(db)

                    Path { pa in
                        let x = w * 0.32
                        pa.move(to: CGPoint(x: x, y: h * 0.01)); pa.addLine(to: CGPoint(x: x, y: h * 0.28))
                    }.stroke(Theme.red.opacity(0.7), style: StrokeStyle(lineWidth: 1.4, dash: [4, 4]))
                    Text("trust boundary").font(Theme.mono(6.5, .bold)).foregroundStyle(Theme.red.opacity(0.85))
                        .position(x: w * 0.32, y: h * 0.32)

                    let cols = [GridItem(.fixed(138), spacing: 8), GridItem(.fixed(138), spacing: 8)]
                    LazyVGrid(columns: cols, spacing: 6) {
                        ForEach(0..<stride.count, id: \.self) { i in
                            let on = i == active
                            HStack(spacing: 6) {
                                Text(stride[i].0)
                                    .font(Theme.mono(12, .black))
                                    .foregroundStyle(on ? .black : stride[i].4)
                                    .frame(width: 22, height: 22)
                                    .background(on ? stride[i].4 : stride[i].4.opacity(0.15),
                                                in: RoundedRectangle(cornerRadius: 6))
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(stride[i].1).font(Theme.mono(8.5, .bold))
                                        .foregroundStyle(on ? Theme.textPrimary : Theme.textDim)
                                    Text(stride[i].3).font(Theme.mono(7))
                                        .foregroundStyle(on ? stride[i].4 : Theme.textDim)
                                }
                                Spacer(minLength: 0)
                            }
                            .opacity(on ? 1 : 0.5)
                        }
                    }
                    .frame(width: 288)
                    .position(x: w * 0.5, y: h * 0.60)

                    Text(stride[active].2)
                        .font(Theme.mono(8.5, .bold)).foregroundStyle(stride[active].4)
                        .multilineTextAlignment(.center).frame(width: w * 0.9)
                        .position(x: w * 0.5, y: h * 0.94)
                }
                .animation(.easeInOut(duration: 0.3), value: active)
            }
        }
    }
}
