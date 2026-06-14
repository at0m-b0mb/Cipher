import SwiftUI

// MARK: - Local staged-reveal scaffold (wave 3)
//
// Same stepped-reveal feel as the other explainer files, kept file-private so
// each animation just describes its steps.

private struct M2Reveal<Content: View>: View {
    let steps: Int
    var stepSeconds: Double = 1.25
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

private struct M2Field<Content: View>: View {
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

// MARK: - Subdomain takeover (red)

/// A dangling DNS record points at a deprovisioned service; the attacker simply
/// claims that service and now serves content from the victim's subdomain.
struct SubdomainTakeoverView: View {
    var body: some View {
        M2Reveal(steps: 3) { step in
            VStack(alignment: .leading, spacing: 11) {
                M2Field(caption: "DNS RECORD (still published)") {
                    (Text("blog.acme.com  CNAME  ")
                        .foregroundColor(Theme.textSecondary)
                     + Text("acme.github.io")
                        .foregroundColor(step >= 2 ? Theme.red : Theme.teal))
                        .font(Theme.mono(10, .bold))
                        .fixedSize(horizontal: false, vertical: true)
                }

                M2Field(caption: "THE SERVICE IT POINTS TO",
                        tint: step >= 1 ? Theme.amber.opacity(0.6) : Theme.stroke) {
                    if step >= 1 {
                        Text("404 — There isn't a GitHub Pages site here.")
                            .font(Theme.mono(9.5, .bold)).foregroundStyle(Theme.amber)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("200 OK — Acme blog (live)")
                            .font(Theme.mono(9.5)).foregroundStyle(Theme.green)
                    }
                }

                if step >= 1 && step < 2 {
                    Label("dangling record — the resource was deleted but DNS still points to it",
                          systemImage: "exclamationmark.triangle.fill")
                        .font(Theme.mono(8.5, .bold)).foregroundStyle(Theme.amber)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if step >= 2 {
                    M2Field(caption: "ATTACKER CLAIMS THE NAME", tint: Theme.red.opacity(0.6)) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("$ register acme.github.io → mine ✓").foregroundStyle(Theme.red)
                            Text("blog.acme.com now serves ATTACKER content").foregroundStyle(Theme.red)
                        }
                        .font(Theme.mono(9, .bold))
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }
                if step >= 3 {
                    Text("phishing on a trusted domain · cookie theft · OAuth abuse")
                        .font(Theme.mono(8.5, .bold)).foregroundStyle(Theme.red)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - HTTP request smuggling (red)

/// Front-end and back-end disagree on where a request ends (CL vs TE), so a
/// smuggled prefix is glued onto the next visitor's request.
struct RequestSmugglingView: View {
    var body: some View {
        M2Reveal(steps: 3) { step in
            VStack(alignment: .leading, spacing: 10) {
                M2Field(caption: "ATTACKER REQUEST (two length headers disagree)",
                        tint: step >= 1 ? Theme.red.opacity(0.6) : Theme.stroke) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Content-Length: 6").foregroundStyle(Theme.amber)
                        Text("Transfer-Encoding: chunked").foregroundStyle(Theme.violet)
                        if step >= 1 {
                            Text("…0\\r\\n\\r\\nGET /admin …").foregroundStyle(Theme.red)
                        }
                    }
                    .font(Theme.mono(9, .bold))
                    .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 8) {
                    proxyBox("Front-end", "uses Content-Length", Theme.amber, step >= 1)
                    Image(systemName: "arrow.right").font(.system(size: 12, weight: .black)).foregroundStyle(Theme.textDim)
                    proxyBox("Back-end", "uses Transfer-Encoding", Theme.violet, step >= 2)
                }
                .frame(maxWidth: .infinity)

                if step >= 2 {
                    Text("they disagree → the leftover bytes start a NEW request on the back-end")
                        .font(Theme.mono(8.5, .bold)).foregroundStyle(Theme.amber)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if step >= 3 {
                    M2Field(caption: "NEXT VICTIM'S REQUEST IS POISONED", tint: Theme.red.opacity(0.6)) {
                        Text("GET /admin  +  victim's session  → attacker's prefix runs as them")
                            .font(Theme.mono(9, .bold)).foregroundStyle(Theme.red)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func proxyBox(_ t: String, _ s: String, _ c: Color, _ on: Bool) -> some View {
        VStack(spacing: 2) {
            Image(systemName: "server.rack").font(.system(size: 15, weight: .semibold)).foregroundStyle(on ? c : Theme.textDim)
            Text(t).font(Theme.mono(8.5, .bold)).foregroundStyle(on ? Theme.textPrimary : Theme.textDim)
            Text(s).font(Theme.mono(7)).foregroundStyle(on ? c : Theme.textDim)
        }
        .frame(width: 120, height: 56)
        .background((on ? c.opacity(0.10) : Color.clear), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(c.opacity(on ? 0.6 : 0.2), lineWidth: 1))
    }
}

// MARK: - Race condition / TOCTOU (red)

/// Many requests slip through the gap between "check" and "act", so a one-time
/// action fires several times — a gift card redeemed five times at once.
struct RaceConditionView: View {
    var body: some View {
        M2Reveal(steps: 3) { step in
            VStack(alignment: .leading, spacing: 12) {
                Text("$10 gift card · server: `if balance>=10 { redeem() }`")
                    .font(Theme.mono(9.5)).foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 7) {
                    ForEach(0..<5, id: \.self) { i in
                        VStack(spacing: 3) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(step >= 1 ? Theme.red : Theme.textDim)
                            Text("req\(i + 1)").font(Theme.mono(7, .bold)).foregroundStyle(Theme.textDim)
                            if step >= 2 {
                                Text("✓ pass").font(Theme.mono(7, .bold)).foregroundStyle(Theme.amber)
                            }
                        }
                        .opacity(step >= 1 ? 1 : 0.35)
                    }
                }
                .frame(maxWidth: .infinity)

                if step >= 1 {
                    Text(step >= 2 ? "all 5 read balance=10 BEFORE any deduct — the TOCTOU window"
                                   : "fire all 5 at once, in parallel")
                        .font(Theme.mono(8.5, .bold)).foregroundStyle(Theme.amber)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if step >= 3 {
                    M2Field(caption: "RESULT", tint: Theme.red.opacity(0.6)) {
                        Text("redeemed 5× → $50 of value from a $10 card")
                            .font(Theme.mono(9.5, .bold)).foregroundStyle(Theme.red)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - Insecure file upload → web shell (red)

/// A disguised script slips past an upload filter, lands in a web-served folder,
/// and runs when requested — a web shell.
struct FileUploadView: View {
    var body: some View {
        M2Reveal(steps: 3) { step in
            VStack(alignment: .leading, spacing: 11) {
                M2Field(caption: "UPLOAD (avatar form — expects an image)",
                        tint: step >= 1 ? Theme.red.opacity(0.6) : Theme.stroke) {
                    (Text("filename: ")
                        .foregroundColor(Theme.textSecondary)
                     + Text(step >= 1 ? "shell.php" : "cat.png")
                        .foregroundColor(step >= 1 ? Theme.red : Theme.green)
                     + Text("   Content-Type: image/png")
                        .foregroundColor(Theme.textDim))
                        .font(Theme.mono(9.5, .bold))
                        .fixedSize(horizontal: false, vertical: true)
                }

                if step >= 1 {
                    Text("filter checks the MIME header, not the real contents → bypassed")
                        .font(Theme.mono(8.5, .bold)).foregroundStyle(Theme.amber)
                        .fixedSize(horizontal: false, vertical: true)
                }

                M2Field(caption: "STORED IN A WEB-SERVED FOLDER",
                        tint: step >= 2 ? Theme.red.opacity(0.6) : Theme.stroke) {
                    (Text("GET /uploads/")
                        .foregroundColor(Theme.textSecondary)
                     + Text(step >= 1 ? "shell.php" : "cat.png")
                        .foregroundColor(step >= 2 ? Theme.red : Theme.textDim))
                        .font(Theme.mono(9.5, .bold))
                }

                if step >= 2 {
                    M2Field(caption: "SERVER EXECUTES IT", tint: Theme.red.opacity(0.6)) {
                        Text("uid=33(www-data)  — interactive web shell")
                            .font(Theme.mono(9.5, .bold)).foregroundStyle(Theme.red)
                    }
                }
                if step >= 3 {
                    Text("fixes: validate real type, strip exec, store outside webroot, random names")
                        .font(Theme.mono(8, .bold)).foregroundStyle(Theme.teal)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - Block cipher modes / the ECB pitfall (fundamentals)

/// The "ECB penguin": encrypting identical plaintext blocks under ECB yields
/// identical ciphertext blocks, so structure survives — while CBC/GCM scramble it.
struct BlockCipherModesView: View {
    // A 5×5 "C" (for Cipher) so the surviving pattern is obvious under ECB.
    private let pattern: [[Int]] = [
        [0,1,1,1,0],
        [1,0,0,0,0],
        [1,0,0,0,0],
        [1,0,0,0,0],
        [0,1,1,1,0]
    ]
    private let cbcPalette: [Color] = [Theme.teal, Theme.blue, Theme.violet, Theme.amber, Theme.red, Theme.green, Theme.magenta]

    private func cbcColor(_ r: Int, _ c: Int) -> Color {
        // Deterministic pseudo-random so CBC looks like stable noise.
        let h = (r &* 31 &+ c &* 17 &+ 7) &* 2654435761
        return cbcPalette[abs(h) % cbcPalette.count]
    }

    var body: some View {
        M2Reveal(steps: 3) { step in
            VStack(spacing: 10) {
                Text(step == 0 ? "PLAINTEXT (blocks of identical data)"
                     : step == 1 ? "ECB — identical blocks → identical ciphertext"
                     : "CBC / GCM — chaining randomises every block")
                    .font(Theme.mono(9, .bold))
                    .foregroundStyle(step == 1 ? Theme.red : step >= 2 ? Theme.green : Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { r in
                        HStack(spacing: 4) {
                            ForEach(0..<5, id: \.self) { c in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(cellColor(step, r, c))
                                    .frame(width: 26, height: 26)
                                    .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Color.black.opacity(0.25), lineWidth: 0.5))
                            }
                        }
                    }
                }

                if step >= 3 {
                    Text("ECB leaks structure — never use it. Prefer CBC, or AEAD like GCM.")
                        .font(Theme.mono(8, .bold)).foregroundStyle(Theme.teal)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func cellColor(_ step: Int, _ r: Int, _ c: Int) -> Color {
        let on = pattern[r][c] == 1
        switch step {
        case 0:  return on ? Theme.teal : Theme.surfaceHi
        case 1:  return on ? Theme.red  : Color(hex: "#1F2A40")   // identical mapping → pattern survives
        default: return cbcColor(r, c)                            // noise
        }
    }
}

// MARK: - Mobile app security (red)

/// The mobile attack surface: secrets sat in plaintext on the device, defeated
/// pinning, and the API behind the app laid bare to an intercepting proxy.
struct MobileSecurityView: View {
    var body: some View {
        M2Reveal(steps: 3) { step in
            VStack(alignment: .leading, spacing: 11) {
                HStack(spacing: 9) {
                    Image(systemName: "iphone").font(.system(size: 20, weight: .semibold)).foregroundStyle(Theme.teal)
                    Text("the app is just a client to an API").font(Theme.mono(9.5, .bold)).foregroundStyle(Theme.textSecondary)
                }

                M2Field(caption: "1 · LOCAL STORAGE ON A ROOTED DEVICE",
                        tint: step >= 1 ? Theme.red.opacity(0.6) : Theme.stroke) {
                    if step >= 1 {
                        Text("shared_prefs/auth.xml → token=eyJhbGci… (plaintext!)")
                            .font(Theme.mono(9, .bold)).foregroundStyle(Theme.red)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("scanning app sandbox…").font(Theme.mono(9)).foregroundStyle(Theme.textDim)
                    }
                }

                M2Field(caption: "2 · CERTIFICATE PINNING",
                        tint: step >= 2 ? Theme.red.opacity(0.6) : Theme.stroke) {
                    Text(step >= 2 ? "Frida hook → pinning bypassed → traffic readable in Burp"
                                   : "pinning blocks the proxy…")
                        .font(Theme.mono(9, step >= 2 ? .bold : .regular))
                        .foregroundStyle(step >= 2 ? Theme.red : Theme.textDim)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if step >= 3 {
                    Text("3 · now attack the API directly — IDOR/BOLA, weak auth, hardcoded keys")
                        .font(Theme.mono(8.5, .bold)).foregroundStyle(Theme.amber)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - Email authentication: SPF / DKIM / DMARC (blue)

/// A spoofed sender is checked against SPF, DKIM and DMARC — each fails, and the
/// DMARC policy rejects the message. A defensive win against phishing.
struct EmailAuthView: View {
    private struct Check: Identifiable {
        let id = UUID()
        let label: String
        let detail: String
    }
    private let checks: [Check] = [
        Check(label: "SPF",   detail: "sending IP not authorised for corp.com"),
        Check(label: "DKIM",  detail: "no valid signature for the domain"),
        Check(label: "DMARC", detail: "alignment fails → policy = reject")
    ]

    var body: some View {
        M2Reveal(steps: checks.count + 1) { step in
            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 8) {
                    Image(systemName: "envelope.fill").foregroundStyle(Theme.amber)
                    (Text("From: ").foregroundColor(Theme.textSecondary)
                     + Text("ceo@corp.com").foregroundColor(Theme.red))
                        .font(Theme.mono(10, .bold))
                    Spacer(minLength: 0)
                    Text("spoofed").font(Theme.mono(8, .bold)).foregroundStyle(Theme.red)
                }

                ForEach(Array(checks.enumerated()), id: \.element.id) { idx, check in
                    let on = step > idx
                    HStack(spacing: 9) {
                        Image(systemName: on ? "xmark.octagon.fill" : "questionmark.circle")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(on ? Theme.red : Theme.textDim)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(check.label).font(Theme.mono(9.5, .bold))
                                .foregroundStyle(on ? Theme.textPrimary : Theme.textDim)
                            if on {
                                Text(check.detail).font(Theme.mono(8)).foregroundStyle(Theme.red)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 5).padding(.horizontal, 9)
                    .background((on ? Theme.red.opacity(0.08) : Color.clear), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.stroke.opacity(on ? 0.8 : 0.3), lineWidth: 1))
                }

                if step > checks.count {
                    HStack(spacing: 8) {
                        Image(systemName: "trash.fill").foregroundStyle(.black)
                        Text("REJECTED — spoofed mail never reaches the inbox")
                            .font(Theme.mono(8.5, .bold)).foregroundStyle(.black)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 7).padding(.horizontal, 11)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.green, in: RoundedRectangle(cornerRadius: 9))
                }
                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - Deception: honeypots & canary tokens (blue)

/// A planted trap — a tempting file with an embedded canary — fires a silent,
/// high-confidence alert the moment an intruder touches it.
struct HoneyTokenView: View {
    var body: some View {
        FlowStage(
            nodes: [
                FlowNode(id: "atk", pos: CGPoint(x: 0.16, y: 0.30), title: "Intruder", subtitle: "inside the net",
                         system: "person.fill.viewfinder", color: Theme.red, startActive: true),
                FlowNode(id: "bait", pos: CGPoint(x: 0.5, y: 0.74), title: "Canary", subtitle: "passwords.xlsx",
                         system: "doc.text.fill", color: Theme.amber, startActive: true),
                FlowNode(id: "soc", pos: CGPoint(x: 0.84, y: 0.30), title: "SOC", subtitle: "alerted",
                         system: "bell.badge.fill", color: Theme.blue, startActive: true)
            ],
            messages: [
                FlowMessage(from: "atk", to: "bait", label: "opens the bait file", color: Theme.red, start: 0.05, end: 0.32, system: "hand.tap.fill"),
                FlowMessage(from: "bait", to: "soc", label: "silent beacon", color: Theme.amber, start: 0.38, end: 0.66, system: "antenna.radiowaves.left.and.right"),
                FlowMessage(from: "soc", to: "soc", label: "TRIPWIRE ALERT", color: Theme.blue, start: 0.72, end: 0.95, system: "exclamationmark.triangle.fill")
            ],
            period: 7,
            footnote: "Nobody legitimate touches a canary — so every hit is high-signal, near-zero false-positive"
        )
    }
}
