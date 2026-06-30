import SwiftUI

// MARK: - Expansion wave 5 explainers
//
// Eight new visualizations: multi-factor auth, VMs vs containers, forward/reverse
// proxies, the WebSocket upgrade, CORS misconfiguration, public cloud-storage
// exposure, a SOAR auto-response playbook, and secrets management. They reuse the
// shared `LoopingTimeline`, `netNode`, `TokenChip`, `SequenceStage`, `lerp` and
// `ease` helpers, plus the three file-private helpers below.

// MARK: - File-private drawing helpers

private func wire5(_ a: CGPoint, _ b: CGPoint, _ color: Color = Theme.stroke) -> some View {
    Path { p in p.move(to: a); p.addLine(to: b) }
        .stroke(color, style: StrokeStyle(lineWidth: 1.2, dash: [3, 4]))
}

@ViewBuilder
private func chip5(_ a: CGPoint, _ b: CGPoint, _ p: Double, _ s: Double, _ e: Double,
                   _ label: String, _ c: Color, system: String = "arrow.right") -> some View {
    if p >= s && p <= e {
        let t = ease(CGFloat((p - s) / max(0.0001, e - s)))
        TokenChip(text: label, color: c, system: system)
            .position(lerp(a, b, t))
    }
}

private func panel5<C: View>(_ title: String, _ system: String, _ color: Color,
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

// MARK: 1 — Multi-factor authentication

/// A password alone is one factor — something you know. MFA adds a second from a
/// different category (something you have / are), so a phished password isn't
/// enough. We verify factor one, then factor two, then grant access.
struct MFAFactorsView: View {
    var body: some View {
        LoopingTimeline(period: 8) { p in
            let step = min(3, Int(p * 4))   // 0 idle · 1 password · 2 OTP · 3 granted
            VStack(spacing: 9) {
                Text("MULTI-FACTOR AUTHENTICATION")
                    .font(Theme.mono(9, .bold)).foregroundStyle(Theme.teal)

                panel5("FACTOR 1 — something you KNOW", "key.fill", Theme.blue, lit: step >= 1) {
                    HStack {
                        Text("password ••••••••").font(Theme.mono(9, .bold)).foregroundStyle(Theme.textSecondary)
                        Spacer()
                        if step >= 1 { Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.green) }
                    }
                }

                panel5("FACTOR 2 — something you HAVE", "iphone", Theme.amber, lit: step >= 2) {
                    HStack {
                        Text(step >= 2 ? "code  738 291" : "code  ------")
                            .font(Theme.mono(10, .bold))
                            .foregroundStyle(step >= 2 ? Theme.amber : Theme.textDim)
                        Spacer()
                        if step >= 2 { Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.green) }
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: step >= 3 ? "lock.open.fill" : "lock.fill")
                    Text(step >= 3 ? "access granted — both factors verified" : "verifying factors…")
                }
                .font(Theme.mono(9.5, .bold))
                .foregroundStyle(step >= 3 ? Theme.green : Theme.textSecondary)

                Text("an attacker who phished only the password is stopped cold at factor 2")
                    .font(Theme.mono(7.5)).foregroundStyle(Theme.textDim)
                    .multilineTextAlignment(.center).frame(width: 295)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 4)
            .animation(.easeInOut(duration: 0.3), value: step)
        }
    }
}

// MARK: 2 — VMs vs containers

/// A virtual machine ships a whole guest OS on top of a hypervisor — strong
/// isolation, but heavy. A container shares the host's kernel through a runtime
/// — light and instant, but a thinner boundary. Same goal, different trade-off.
struct VMvsContainerView: View {
    var body: some View {
        LoopingTimeline(period: 6) { p in
            let alt = Int(p * 2) % 2
            VStack(spacing: 10) {
                HStack(alignment: .bottom, spacing: 18) {
                    VStack(spacing: 4) {
                        Text("VIRTUAL MACHINES").font(Theme.mono(8, .bold)).foregroundStyle(Theme.blue)
                        HStack(spacing: 6) { vmCol(); vmCol() }
                        layer("Hypervisor", Theme.blue)
                        layer("Host hardware", Theme.textDim)
                    }
                    VStack(spacing: 4) {
                        Text("CONTAINERS").font(Theme.mono(8, .bold)).foregroundStyle(Theme.green)
                        HStack(spacing: 4) { box("App", Theme.teal); box("App", Theme.teal); box("App", Theme.teal) }
                        layer("Container engine", Theme.green)
                        layer("Shared host kernel", Theme.amber)
                        layer("Host hardware", Theme.textDim)
                    }
                }
                Text(alt == 0 ? "VMs: a full guest OS each — strong isolation, gigabytes, slow boot"
                              : "Containers: share the host kernel — megabytes, instant, thinner boundary")
                    .font(Theme.mono(8, .bold))
                    .foregroundStyle(alt == 0 ? Theme.blue : Theme.green)
                    .multilineTextAlignment(.center).frame(width: 300)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 4)
            .animation(.easeInOut(duration: 0.3), value: alt)
        }
    }

    @ViewBuilder private func vmCol() -> some View {
        VStack(spacing: 3) { box("App", Theme.teal); box("Guest OS", Theme.violet) }
    }
    @ViewBuilder private func box(_ t: String, _ c: Color) -> some View {
        Text(t).font(Theme.mono(7.5, .bold)).foregroundStyle(c)
            .frame(width: 46, height: 22)
            .background(c.opacity(0.15), in: RoundedRectangle(cornerRadius: 5))
            .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(c.opacity(0.6), lineWidth: 1))
    }
    @ViewBuilder private func layer(_ t: String, _ c: Color) -> some View {
        Text(t).font(Theme.mono(7.5, .bold)).foregroundStyle(c)
            .frame(width: 152, height: 20)
            .background(c.opacity(0.12), in: RoundedRectangle(cornerRadius: 5))
            .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(c.opacity(0.5), lineWidth: 1))
    }
}

// MARK: 3 — Forward vs reverse proxy

/// A forward proxy sits in front of the clients (filtering and anonymising what
/// goes out); a reverse proxy sits in front of the servers (terminating TLS,
/// caching and load-balancing what comes in). Same box, opposite direction.
struct ProxyFlowView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let a = CGPoint(x: w * 0.15, y: h * 0.30)
            let mid = CGPoint(x: w * 0.5, y: h * 0.30)
            let b = CGPoint(x: w * 0.85, y: h * 0.30)
            LoopingTimeline(period: 8) { p in
                let reverse = p > 0.5
                let lp = reverse ? (p - 0.5) / 0.5 : p / 0.5
                ZStack {
                    wire5(a, mid)
                    if !reverse {
                        wire5(mid, b)
                        netNode("person.2.fill", "internal\nclients", Theme.teal, true).position(a)
                        netNode("arrow.triangle.branch", "forward\nproxy", Theme.violet, true).position(mid)
                        netNode("globe", "internet", Theme.blue, true).position(b)
                        chip5(a, mid, lp, 0.05, 0.45, "request", Theme.teal)
                        chip5(mid, b, lp, 0.48, 0.92, "on client's behalf", Theme.violet)
                    } else {
                        netNode("globe", "internet\nclients", Theme.blue, true).position(a)
                        netNode("shield.lefthalf.filled", "reverse\nproxy", Theme.violet, true).position(mid)
                        ForEach(0..<3, id: \.self) { i in
                            let sy = h * (0.14 + 0.32 * Double(i))
                            let sp = CGPoint(x: w * 0.86, y: sy)
                            wire5(mid, sp)
                            netNode("server.rack", "app \(i + 1)", Theme.blue, true).position(sp)
                            if i == Int(lp * 3) % 3 { chip5(mid, sp, lp, 0.48, 0.92, "route", Theme.violet) }
                        }
                        chip5(a, mid, lp, 0.05, 0.45, "request", Theme.blue)
                    }
                    Text(reverse ? "REVERSE PROXY — fronts the servers: TLS, caching, load-balancing; hides the backend"
                                 : "FORWARD PROXY — fronts the clients: filters, logs and anonymises outbound traffic")
                        .font(Theme.mono(8, .bold)).foregroundStyle(Theme.violet)
                        .multilineTextAlignment(.center).frame(width: w * 0.95)
                        .position(x: w * 0.5, y: h * 0.90)
                }
                .animation(.easeInOut(duration: 0.3), value: reverse)
            }
        }
    }
}

// MARK: 4 — WebSocket upgrade

/// HTTP is request/response — the client always asks first. A WebSocket starts
/// as an HTTP request that asks to UPGRADE; after a 101 the same connection
/// becomes a persistent, two-way channel where either side can push anytime.
struct WebSocketUpgradeView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let c = CGPoint(x: w * 0.18, y: h * 0.34)
            let s = CGPoint(x: w * 0.82, y: h * 0.34)
            LoopingTimeline(period: 7) { p in
                let open = p > 0.42
                ZStack {
                    wire5(c, s, open ? Theme.green.opacity(0.6) : Theme.stroke)
                    netNode("laptopcomputer", "browser", Theme.teal, true).position(c)
                    netNode(open ? "bolt.horizontal.fill" : "server.rack",
                            open ? "server\n(live)" : "server",
                            open ? Theme.green : Theme.blue, true).position(s)

                    chip5(c, s, p, 0.04, 0.20, "GET  Upgrade: websocket", Theme.teal)
                    chip5(s, c, p, 0.22, 0.40, "101 Switching Protocols", Theme.amber, system: "arrow.left")
                    if open {
                        chip5(c, s, p, 0.46, 0.62, "msg", Theme.green)
                        chip5(s, c, p, 0.64, 0.80, "push", Theme.green, system: "arrow.left")
                        chip5(c, s, p, 0.82, 0.98, "msg", Theme.green)
                    }

                    Text(open ? "one persistent connection — server and client push messages anytime, no polling"
                              : "an ordinary HTTP request asks to UPGRADE the connection…")
                        .font(Theme.mono(8, .bold))
                        .foregroundStyle(open ? Theme.green : Theme.textSecondary)
                        .multilineTextAlignment(.center).frame(width: w * 0.95)
                        .position(x: w * 0.5, y: h * 0.88)
                }
                .animation(.easeInOut(duration: 0.3), value: open)
            }
        }
    }
}

// MARK: 5 — CORS misconfiguration

/// The Same-Origin Policy stops evil.com's script reading the bank's responses.
/// CORS can safely relax that — but a server that reflects the attacker's Origin
/// AND allows credentials hands evil.com read access to the victim's data.
struct CORSMisconfigView: View {
    var body: some View {
        LoopingTimeline(period: 8) { p in
            let leaked = p > 0.55
            VStack(spacing: 9) {
                Text("CORS MISCONFIGURATION")
                    .font(Theme.mono(9, .bold)).foregroundStyle(Theme.red)

                panel5("evil.com script (in the victim's browser)", "curlybraces", Theme.amber, lit: true) {
                    Text("fetch('https://bank/api/me',\n  { credentials: 'include' })")
                        .font(Theme.mono(9, .bold)).foregroundStyle(Theme.textSecondary)
                }

                Image(systemName: "arrow.down").font(.system(size: 10, weight: .bold)).foregroundStyle(Theme.textDim)

                panel5("bank API response headers", "server.rack", leaked ? Theme.red : Theme.violet, lit: true) {
                    Text("Access-Control-Allow-Origin: https://evil.com\nAccess-Control-Allow-Credentials: true")
                        .font(Theme.mono(7.5, .bold))
                        .foregroundStyle(leaked ? Theme.red : Theme.textDim)
                }

                HStack(spacing: 6) {
                    Image(systemName: leaked ? "lock.open.fill" : "lock.fill")
                    Text(leaked ? "browser lets evil.com READ the response → account data stolen" : "checking the Origin…")
                }
                .font(Theme.mono(9, .bold))
                .foregroundStyle(leaked ? Theme.red : Theme.textSecondary)

                Text("the server reflected an untrusted Origin and allowed credentials — never echo arbitrary origins")
                    .font(Theme.mono(7)).foregroundStyle(Theme.textDim)
                    .multilineTextAlignment(.center).frame(width: 296)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 4)
            .animation(.easeInOut(duration: 0.3), value: leaked)
        }
    }
}

// MARK: 6 — Public cloud-storage exposure

/// No exploit required: a bucket left world-readable answers an anonymous LIST
/// with every object name, then serves the files. Most cloud "breaches" are
/// exactly this — a misconfiguration, not a hack.
struct BucketExposureView: View {
    private let files = ["customers.csv", "backup.sql", "secrets.env", ".aws-creds"]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let atk = CGPoint(x: w * 0.18, y: h * 0.28)
            let bkt = CGPoint(x: w * 0.80, y: h * 0.28)
            LoopingTimeline(period: 8) { p in
                let listed = p > 0.30
                let grabbed = p > 0.62
                ZStack {
                    wire5(atk, bkt)
                    netNode("person.fill", "attacker\n(no creds)", Theme.red, true).position(atk)
                    netNode("externaldrive.fill", "bucket\nACL: PUBLIC", Theme.amber, true).position(bkt)

                    chip5(atk, bkt, p, 0.04, 0.28, "LIST (no auth)", Theme.amber)
                    chip5(bkt, atk, p, 0.32, 0.56, "\(files.count) objects", Theme.violet, system: "arrow.left")
                    chip5(atk, bkt, p, 0.58, 0.74, "GET secrets.env", Theme.red)
                    chip5(bkt, atk, p, 0.76, 0.96, "AWS keys", Theme.red, system: "arrow.left")

                    if listed {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(files, id: \.self) { f in
                                Text("• \(f)")
                                    .font(Theme.mono(8, .bold))
                                    .foregroundStyle(grabbed && f == "secrets.env" ? Theme.red : Theme.textDim)
                            }
                        }
                        .position(x: w * 0.5, y: h * 0.64)
                    }

                    Text(grabbed ? "a world-readable bucket needs no exploit — just the URL. Misconfig, not hack."
                                 : "anonymous LIST on a public bucket dumps every object name…")
                        .font(Theme.mono(8, .bold))
                        .foregroundStyle(grabbed ? Theme.red : Theme.amber)
                        .multilineTextAlignment(.center).frame(width: w * 0.95)
                        .position(x: w * 0.5, y: h * 0.92)
                }
                .animation(.easeInOut(duration: 0.3), value: grabbed)
            }
        }
    }
}

// MARK: 7 — SOAR auto-response playbook

/// Security Orchestration, Automation & Response turns an alert into action in
/// seconds: enrich it, decide on severity, contain automatically, and notify a
/// human — so analysts spend judgment, not keystrokes. Reuses the chain engine.
struct SOARPlaybookView: View {
    var body: some View {
        SequenceStage(steps: [
            SequenceStep(system: "bell.badge.fill",      title: "Alert fires", detail: "EDR: malware on HOST-42",            color: Theme.red),
            SequenceStep(system: "magnifyingglass",      title: "Enrich",      detail: "hash → known ransomware (intel)",    color: Theme.amber),
            SequenceStep(system: "brain.head.profile",   title: "Decide",      detail: "severity HIGH → auto-contain",       color: Theme.violet),
            SequenceStep(system: "network.slash",        title: "Contain",     detail: "isolate host + disable the user",    color: Theme.blue),
            SequenceStep(system: "checkmark.seal.fill",  title: "Notify",      detail: "ticket opened, analyst paged",       color: Theme.green)
        ])
    }
}

// MARK: 8 — Secrets management

/// A secret hardcoded in a repo lives in git history forever and never rotates.
/// A secrets manager issues short-lived, dynamic credentials at runtime that
/// auto-expire and are audited — so a leak is contained by the clock.
struct SecretsVaultView: View {
    var body: some View {
        LoopingTimeline(period: 8) { p in
            let vault = p > 0.5
            VStack(spacing: 10) {
                Text(vault ? "WITH A SECRETS MANAGER" : "THE ANTI-PATTERN")
                    .font(Theme.mono(9, .bold)).foregroundStyle(vault ? Theme.green : Theme.red)

                if !vault {
                    panel5("hardcoded in the git repo", "doc.text.fill", Theme.red, lit: true) {
                        Text("config.py:\n  API_KEY = \"AKIA…REAL…SECRET\"")
                            .font(Theme.mono(8.5, .bold)).foregroundStyle(Theme.amber)
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "eye.fill")
                        Text("in git history forever — every clone leaks it, and it's never rotated")
                    }
                    .font(Theme.mono(8, .bold)).foregroundStyle(Theme.red)
                    .multilineTextAlignment(.leading).frame(width: 296)
                } else {
                    panel5("app fetches the secret at runtime", "lock.rectangle.stack.fill", Theme.green, lit: true) {
                        Text("vault.read('db/creds')\n→ user: v-app-x9   ttl: 15m")
                            .font(Theme.mono(8.5, .bold)).foregroundStyle(Theme.teal)
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "clock.badge.checkmark.fill")
                        Text("short-lived & dynamic — auto-expires, rotated, audited, never in code")
                    }
                    .font(Theme.mono(8, .bold)).foregroundStyle(Theme.green)
                    .multilineTextAlignment(.leading).frame(width: 296)
                }

                Text("secrets belong in a vault (HashiCorp Vault, AWS Secrets Manager), not in source")
                    .font(Theme.mono(7)).foregroundStyle(Theme.textDim)
                    .multilineTextAlignment(.center).frame(width: 296)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 4)
            .animation(.easeInOut(duration: 0.3), value: vault)
        }
    }
}
