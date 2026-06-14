import SwiftUI

// MARK: - Local staged-reveal scaffold
//
// The new "modern stack" explainers (encoding, cloud, containers, API, OAuth,
// threat-intel, zero-trust) each walk through a few discrete states. This mirrors
// the StagedReveal used by the web animations so the whole library keeps one feel,
// but is kept private to this file to avoid any cross-file coupling.

private struct ModReveal<Content: View>: View {
    let steps: Int
    var stepSeconds: Double = 1.2
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

/// A labelled box used throughout the modern-stack animations.
private struct ModField<Content: View>: View {
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

// MARK: - Encoding layers (fundamentals)

/// Shows one short message re-dressed through encoding layers — text → hex →
/// Base64 → URL — to drive home that encoding is reversible *representation*,
/// not encryption. Each row lights up in turn.
struct EncodingLayersView: View {
    private struct Row: Identifiable {
        let id = UUID()
        let label: String
        let value: String
        let tint: Color
        let note: String
    }
    private let rows: [Row] = [
        Row(label: "TEXT (ASCII)",       value: "Hi!",                          tint: Theme.teal,  note: "three characters a human reads"),
        Row(label: "BYTES (HEX)",        value: "48 69 21",                     tint: Theme.blue,  note: "what the machine actually stores"),
        Row(label: "BASE64",             value: "SGkh",                         tint: Theme.violet, note: "binary-safe text for transport"),
        Row(label: "URL / PERCENT",      value: "Hi%21",                        tint: Theme.amber, note: "safe to drop into a URL")
    ]

    var body: some View {
        ModReveal(steps: rows.count) { step in
            VStack(alignment: .leading, spacing: 9) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { idx, row in
                    let on = step > idx
                    HStack(spacing: 10) {
                        Text(row.label)
                            .font(Theme.mono(8, .bold))
                            .foregroundStyle(on ? row.tint : Theme.textDim)
                            .frame(width: 96, alignment: .leading)
                        Text(row.value)
                            .font(Theme.mono(13, .bold))
                            .foregroundStyle(on ? Theme.textPrimary : Theme.textDim.opacity(0.5))
                        Spacer(minLength: 0)
                        if on { Image(systemName: "arrow.down").font(.system(size: 9, weight: .black)).foregroundStyle(Theme.textDim) }
                    }
                    .padding(.vertical, 6).padding(.horizontal, 9)
                    .background((on ? row.tint.opacity(0.10) : Color.clear), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(row.tint.opacity(on ? 0.55 : 0.12), lineWidth: 1))
                }
                if step >= rows.count {
                    Text("Same bytes, four costumes — all reversible. Encoding ≠ encryption.")
                        .font(Theme.mono(8.5, .bold)).foregroundStyle(Theme.teal)
                } else if step >= 1 {
                    Text(rows[min(step - 1, rows.count - 1)].note)
                        .font(Theme.mono(8.5)).foregroundStyle(Theme.textDim)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - Cloud metadata SSRF (red)

/// An SSRF reaches the cloud metadata service and walks back temporary IAM
/// credentials — the classic "URL preview feature → cloud takeover" path.
struct CloudMetadataView: View {
    var body: some View {
        FlowStage(
            nodes: [
                FlowNode(id: "atk", pos: CGPoint(x: 0.14, y: 0.30), title: "Attacker", subtitle: "controls a URL",
                         system: "person.fill.viewfinder", color: Theme.red, startActive: true),
                FlowNode(id: "app", pos: CGPoint(x: 0.5, y: 0.74), title: "Web App", subtitle: "fetches URLs",
                         system: "server.rack", color: Theme.amber, startActive: true),
                FlowNode(id: "imds", pos: CGPoint(x: 0.86, y: 0.30), title: "169.254…", subtitle: "metadata",
                         system: "cloud.fill", color: Theme.blue, startActive: true)
            ],
            messages: [
                FlowMessage(from: "atk", to: "app", label: "url=169.254.169.254", color: Theme.red, start: 0.04, end: 0.26, system: "arrow.right"),
                FlowMessage(from: "app", to: "imds", label: "GET /iam/creds", color: Theme.amber, start: 0.30, end: 0.52, system: "arrow.up.right"),
                FlowMessage(from: "imds", to: "app", label: "AKIA… secret", color: Theme.blue, start: 0.56, end: 0.74, system: "key.fill"),
                FlowMessage(from: "app", to: "atk", label: "cloud keys", color: Theme.green, start: 0.78, end: 0.96, system: "checkmark.seal.fill")
            ],
            period: 7.5,
            footnote: "A 'preview this link' feature becomes stolen cloud credentials — IMDSv2 tokens stop it"
        )
    }
}

// MARK: - Container / Kubernetes escape (red)

/// A foothold inside a container finds a host door — a mounted Docker socket or
/// the --privileged flag — and pivots to root on the underlying node.
struct ContainerEscapeView: View {
    var body: some View {
        ModReveal(steps: 3) { step in
            VStack(alignment: .leading, spacing: 11) {
                ModField(caption: "INSIDE THE CONTAINER (low priv)",
                         tint: step >= 1 ? Theme.amber.opacity(0.6) : Theme.stroke) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("$ id  →  uid=1000(app)").font(Theme.mono(10)).foregroundStyle(Theme.textSecondary)
                        if step >= 1 {
                            (Text("$ ls /var/run/  →  ").foregroundColor(Theme.textSecondary)
                             + Text("docker.sock").foregroundColor(Theme.red))
                                .font(Theme.mono(10, .bold))
                        }
                    }
                }

                if step >= 1 {
                    Label("host door found — the Docker socket is mounted in",
                          systemImage: "exclamationmark.triangle.fill")
                        .font(Theme.mono(8.5, .bold)).foregroundStyle(Theme.amber)
                }

                HStack(spacing: 10) {
                    nodeBox("Container", "shippingbox.fill", step >= 2 ? Theme.red : Theme.amber)
                    Image(systemName: "arrow.right").font(.system(size: 13, weight: .black))
                        .foregroundStyle(step >= 2 ? Theme.red : Theme.textDim)
                    nodeBox("Host node", "externaldrive.fill", step >= 2 ? Theme.red : Theme.textDim)
                }
                .frame(maxWidth: .infinity)

                if step >= 2 {
                    ModField(caption: "ESCAPE: start a container mounting the host root",
                             tint: Theme.red.opacity(0.6)) {
                        Text("docker run -v /:/host --privileged … chroot /host")
                            .font(Theme.mono(9.5, .bold)).foregroundStyle(Theme.red)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                if step >= 3 {
                    Text("now root on the node → every other pod's secrets are yours")
                        .font(Theme.mono(9, .bold)).foregroundStyle(Theme.red)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func nodeBox(_ title: String, _ system: String, _ color: Color) -> some View {
        VStack(spacing: 3) {
            Image(systemName: system).font(.system(size: 18, weight: .semibold)).foregroundStyle(color)
            Text(title).font(Theme.mono(8.5, .bold)).foregroundStyle(color)
        }
        .frame(width: 92, height: 52)
        .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(color.opacity(0.6), lineWidth: 1))
    }
}

// MARK: - API / GraphQL BOLA (red)

/// GraphQL introspection reveals the schema; then a single id swap on an object
/// reference returns another tenant's record — Broken Object-Level Authorization.
struct ApiBolaView: View {
    var body: some View {
        ModReveal(steps: 3) { step in
            VStack(alignment: .leading, spacing: 11) {
                ModField(caption: "STEP 1 · ASK THE API TO DESCRIBE ITSELF",
                         tint: step >= 1 ? Theme.violet.opacity(0.6) : Theme.stroke) {
                    (Text("{ __schema { types { name } } }").foregroundColor(step >= 1 ? Theme.violet : Theme.textDim))
                        .font(Theme.mono(10, .bold))
                }
                if step >= 1 {
                    Text("introspection on → full map of queries & mutations leaks")
                        .font(Theme.mono(8.5, .bold)).foregroundStyle(Theme.amber)
                }

                ModField(caption: "STEP 2 · REQUEST AN OBJECT BY ID",
                         tint: step >= 2 ? Theme.red.opacity(0.6) : Theme.stroke) {
                    (Text("{ invoice(id: ")
                        .foregroundColor(Theme.textSecondary)
                     + Text(step >= 2 ? "2001" : "2000")
                        .foregroundColor(step >= 2 ? Theme.red : Theme.green)
                     + Text(") { total ssn } }")
                        .foregroundColor(Theme.textSecondary))
                        .font(Theme.mono(10, .bold))
                        .fixedSize(horizontal: false, vertical: true)
                }

                ModField(caption: "RESPONSE",
                         tint: step >= 2 ? Theme.red.opacity(0.6) : Theme.stroke) {
                    if step >= 2 {
                        Text("{ total: 9800, ssn: \"***1199\" }  ← not your tenant")
                            .font(Theme.mono(9.5, .bold)).foregroundStyle(Theme.red)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text(step >= 1 ? "{ total: 240, ssn: \"***0042\" }  your own" : "waiting…")
                            .font(Theme.mono(9.5)).foregroundStyle(Theme.textDim)
                    }
                }
                if step >= 3 {
                    Text("BOLA / IDOR — the server authenticates you but never checks ownership")
                        .font(Theme.mono(8.5, .bold)).foregroundStyle(Theme.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - OAuth token theft via open redirect (red)

/// The OAuth authorization-code dance, derailed: a tampered redirect_uri sends
/// the victim's authorization code to the attacker, who exchanges it for a token.
struct OAuthFlowView: View {
    var body: some View {
        FlowStage(
            nodes: [
                FlowNode(id: "user", pos: CGPoint(x: 0.14, y: 0.30), title: "Victim", subtitle: "clicks link",
                         system: "person.fill", color: Theme.teal, startActive: true),
                FlowNode(id: "idp", pos: CGPoint(x: 0.5, y: 0.30), title: "Auth Server", subtitle: "issues code",
                         system: "checkmark.shield.fill", color: Theme.blue, startActive: true),
                FlowNode(id: "atk", pos: CGPoint(x: 0.84, y: 0.72), title: "Attacker", subtitle: "evil redirect",
                         system: "person.fill.viewfinder", color: Theme.red, startActive: true)
            ],
            messages: [
                FlowMessage(from: "user", to: "idp", label: "login · redirect_uri=evil", color: Theme.red, start: 0.04, end: 0.28, system: "arrow.right"),
                FlowMessage(from: "idp", to: "atk", label: "?code=AUTH", color: Theme.amber, start: 0.32, end: 0.56, system: "arrow.down.right"),
                FlowMessage(from: "atk", to: "idp", label: "exchange code", color: Theme.red, start: 0.60, end: 0.80, system: "arrow.up.left"),
                FlowMessage(from: "idp", to: "atk", label: "access_token", color: Theme.green, start: 0.84, end: 0.97, system: "key.fill")
            ],
            period: 7.5,
            footnote: "An unvalidated redirect_uri leaks the auth code — exact-match redirect allowlists stop it"
        )
    }
}

// MARK: - Cyber threat intelligence cycle (blue)

/// The intelligence lifecycle as a rotating ring — direction → collection →
/// processing → analysis → dissemination → feedback, then around again.
struct ThreatIntelView: View {
    var body: some View {
        CycleStage(
            nodes: [
                CycleNode(system: "scope",                title: "Direction",     color: Theme.blue),
                CycleNode(system: "tray.and.arrow.down.fill", title: "Collection", color: Theme.teal),
                CycleNode(system: "gearshape.2.fill",     title: "Processing",    color: Theme.violet),
                CycleNode(system: "brain.head.profile",   title: "Analysis",      color: Theme.amber),
                CycleNode(system: "paperplane.fill",      title: "Dissem-\nination", color: Theme.green),
                CycleNode(system: "arrow.triangle.2.circlepath", title: "Feedback", color: Theme.magenta)
            ],
            centerTitle: "Intel\nCycle",
            centerSystem: "globe.americas.fill",
            accent: Theme.blue
        )
    }
}

// MARK: - Zero trust policy decision (blue)

/// Every request is evaluated, live, against identity, device posture and risk
/// before the policy engine grants the *least* access needed — "never trust,
/// always verify."
struct ZeroTrustView: View {
    private struct Check: Identifiable {
        let id = UUID()
        let label: String
        let system: String
        let verdict: String
    }
    private let checks: [Check] = [
        Check(label: "Identity (MFA / passkey)", system: "person.badge.key.fill",  verdict: "alice ✓"),
        Check(label: "Device posture",           system: "laptopcomputer",          verdict: "managed, patched ✓"),
        Check(label: "Context & risk score",     system: "location.viewfinder",     verdict: "known geo, low risk ✓")
    ]

    var body: some View {
        ModReveal(steps: checks.count + 1) { step in
            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 8) {
                    Image(systemName: "person.fill").foregroundStyle(Theme.teal)
                    Text("request → resource").font(Theme.mono(10, .bold)).foregroundStyle(Theme.textSecondary)
                    Spacer(minLength: 0)
                    Text("policy engine").font(Theme.mono(8.5, .bold)).foregroundStyle(Theme.blue)
                }

                ForEach(Array(checks.enumerated()), id: \.element.id) { idx, check in
                    let on = step > idx
                    HStack(spacing: 9) {
                        Image(systemName: on ? "checkmark.seal.fill" : check.system)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(on ? Theme.green : Theme.textDim)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(check.label).font(Theme.mono(9.5, .bold))
                                .foregroundStyle(on ? Theme.textPrimary : Theme.textDim)
                            if on {
                                Text(check.verdict).font(Theme.mono(8.5)).foregroundStyle(Theme.green)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 6).padding(.horizontal, 9)
                    .background((on ? Theme.green.opacity(0.08) : Color.clear), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.blue.opacity(on ? 0.4 : 0.12), lineWidth: 1))
                }

                if step > checks.count {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.open.fill").foregroundStyle(.black)
                        Text("ALLOW — least privilege, this session only")
                            .font(Theme.mono(9, .bold)).foregroundStyle(.black)
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
