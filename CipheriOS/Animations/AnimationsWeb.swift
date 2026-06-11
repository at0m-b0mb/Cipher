import SwiftUI

// MARK: - Shared staged-reveal scaffold
//
// Most web-attack explainers walk through a few discrete states (craft → server
// reacts → impact). This little helper drives a stepped reveal off the looping
// timeline so each view just describes its steps, matching the feel of the SQLi
// and XSS animations.

private struct StagedReveal<Content: View>: View {
    let steps: Int
    var stepSeconds: Double = 1.15
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

/// A small labelled field/box used throughout the web animations.
private struct FieldBox<Content: View>: View {
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

// MARK: - An HTTP request (fundamentals)

struct HTTPRequestView: View {
    var body: some View {
        FlowStage(
            nodes: [
                FlowNode(id: "br", pos: CGPoint(x: 0.16, y: 0.5), title: "Browser", subtitle: "the client",
                         system: "globe", color: Theme.teal, startActive: true),
                FlowNode(id: "sv", pos: CGPoint(x: 0.84, y: 0.5), title: "Server", subtitle: "web app",
                         system: "server.rack", color: Theme.blue, startActive: true)
            ],
            messages: [
                FlowMessage(from: "br", to: "sv", label: "GET /login", color: Theme.teal, start: 0.04, end: 0.24, system: "arrow.right"),
                FlowMessage(from: "sv", to: "br", label: "200 · Set-Cookie", color: Theme.amber, start: 0.28, end: 0.48, system: "checkmark.seal.fill"),
                FlowMessage(from: "br", to: "sv", label: "GET /account · Cookie", color: Theme.teal, start: 0.55, end: 0.75, system: "lock.fill"),
                FlowMessage(from: "sv", to: "br", label: "200 · your data", color: Theme.green, start: 0.79, end: 0.96)
            ],
            period: 7,
            footnote: "HTTP is stateless — the cookie is how the server remembers who you are"
        )
    }
}

// MARK: - Broken access control / IDOR

struct AccessControlView: View {
    private let rows = ["acct #",  "name", "balance"]
    var body: some View {
        StagedReveal(steps: 3) { step in
            VStack(alignment: .leading, spacing: 12) {
                Text("Logged in as **alice** (acct 1042)")
                    .font(Theme.mono(10)).foregroundStyle(Theme.textSecondary)

                FieldBox(caption: "REQUEST URL", tint: step >= 1 ? Theme.red.opacity(0.6) : Theme.stroke) {
                    (Text("GET /invoice?id=")
                        .foregroundColor(Theme.textSecondary)
                     + Text(step >= 1 ? "1043" : "1042")
                        .foregroundColor(step >= 1 ? Theme.red : Theme.green))
                        .font(Theme.mono(11, .bold))
                }

                if step >= 1 {
                    Label("changed the id — no ownership check on the server",
                          systemImage: "pencil.and.scribble")
                        .font(Theme.mono(8.5, .bold)).foregroundStyle(Theme.amber)
                }

                HStack(spacing: 10) {
                    Image(systemName: "cylinder.fill").font(.system(size: 22))
                        .foregroundStyle(step >= 2 ? Theme.red : Theme.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(step >= 2 ? "Invoice 1043 — Bob Reyes" : "Invoice 1042 — Alice Stone")
                            .font(Theme.mono(10, .bold))
                            .foregroundStyle(step >= 2 ? Theme.red : Theme.textPrimary)
                        Text(step >= 2 ? "$ 9,800 · SSN ****  ← another user!" : "$ 240 · your own record")
                            .font(Theme.mono(9))
                            .foregroundStyle(step >= 2 ? Theme.amber : Theme.textDim)
                    }
                }
                .opacity(step >= 1 ? 1 : 0.3)

                if step >= 3 {
                    Text("IDOR ✓  iterate ids → harvest every account")
                        .font(Theme.mono(9, .bold)).foregroundStyle(Theme.red)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - Path traversal & file inclusion

struct FileInclusionView: View {
    var body: some View {
        StagedReveal(steps: 3) { step in
            VStack(alignment: .leading, spacing: 11) {
                FieldBox(caption: "VULNERABLE PARAMETER",
                         tint: step >= 1 ? Theme.red.opacity(0.6) : Theme.stroke) {
                    (Text("?page=")
                        .foregroundColor(Theme.textSecondary)
                     + Text(step >= 1 ? "../../../../etc/passwd" : "home.php")
                        .foregroundColor(step >= 1 ? Theme.red : Theme.green))
                        .font(Theme.mono(11, .bold))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Image(systemName: "arrow.down")
                    .foregroundStyle(step >= 2 ? Theme.red : Theme.textDim)
                    .frame(maxWidth: .infinity)

                FieldBox(caption: step >= 1 ? "SERVER INCLUDES THE FILE IT'S GIVEN" : "SERVER RENDERS THE PAGE",
                         tint: step >= 2 ? Theme.red.opacity(0.6) : Theme.stroke) {
                    if step >= 2 {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("root:x:0:0:root:/root:/bin/bash").foregroundStyle(Theme.green)
                            Text("www-data:x:33:33:/var/www:/usr/sbin/nologin").foregroundStyle(Theme.green)
                        }
                        .font(Theme.mono(8.5))
                    } else {
                        Text(step >= 1 ? "reading path…" : "<h1>Welcome home</h1>")
                            .font(Theme.mono(9)).foregroundStyle(Theme.textDim)
                    }
                }

                if step >= 3 {
                    Text("escalate: php://filter leaks source · log poisoning → RCE")
                        .font(Theme.mono(8.5, .bold)).foregroundStyle(Theme.amber)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - Server-side template injection

struct TemplateInjectionView: View {
    var body: some View {
        StagedReveal(steps: 3) { step in
            VStack(alignment: .leading, spacing: 12) {
                FieldBox(caption: "USER INPUT (probe)",
                         tint: step >= 1 ? Theme.amber.opacity(0.6) : Theme.stroke) {
                    (Text("name=")
                        .foregroundColor(Theme.textSecondary)
                     + Text(step >= 2 ? "{{ cycler.__init__.__globals__.os.popen('id').read() }}"
                                       : "{{ 7*7 }}")
                        .foregroundColor(step >= 2 ? Theme.red : Theme.amber))
                        .font(Theme.mono(10, .bold))
                        .fixedSize(horizontal: false, vertical: true)
                }

                FieldBox(caption: "RENDERED RESPONSE",
                         tint: step >= 2 ? Theme.red.opacity(0.6) : Theme.stroke) {
                    Group {
                        if step >= 2 {
                            Text("Hello uid=33(www-data) gid=33(www-data)")
                                .foregroundStyle(Theme.red)
                        } else if step >= 1 {
                            (Text("Hello ").foregroundColor(Theme.textPrimary)
                             + Text("49").foregroundColor(Theme.green))
                        } else {
                            Text("Hello {{ name }}").foregroundStyle(Theme.textDim)
                        }
                    }
                    .font(Theme.mono(10, .bold))
                    .fixedSize(horizontal: false, vertical: true)
                }

                if step >= 1 && step < 2 {
                    Text("math evaluated → it's a live template engine (Jinja2)")
                        .font(Theme.mono(8.5, .bold)).foregroundStyle(Theme.amber)
                }
                if step >= 3 {
                    Text("SSTI → remote code execution on the server")
                        .font(Theme.mono(9, .bold)).foregroundStyle(Theme.red)
                }
                Spacer(minLength: 0)
            }
        }
    }
}
