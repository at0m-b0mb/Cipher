import SwiftUI

// MARK: - Kerberos delegation abuse (S4U)

struct DelegationView: View {
    var body: some View {
        FlowStage(
            nodes: [
                FlowNode(id: "svc", pos: CGPoint(x: 0.16, y: 0.5), title: "Svc account", subtitle: "has delegation",
                         system: "gearshape.2.fill", color: Theme.red, startActive: true),
                FlowNode(id: "kdc", pos: CGPoint(x: 0.5, y: 0.18), title: "KDC", subtitle: "domain controller",
                         system: "lock.shield.fill", color: Theme.blue, startActive: true),
                FlowNode(id: "tgt", pos: CGPoint(x: 0.84, y: 0.5), title: "CIFS/FS01", subtitle: "target service",
                         system: "externaldrive.fill", color: Theme.violet, startActive: true)
            ],
            messages: [
                FlowMessage(from: "svc", to: "kdc", label: "S4U2Self (as Admin)", color: Theme.teal, start: 0.05, end: 0.26),
                FlowMessage(from: "kdc", to: "svc", label: "fwd'able TGS · Admin", color: Theme.blue, start: 0.30, end: 0.50, system: "ticket.fill"),
                FlowMessage(from: "svc", to: "kdc", label: "S4U2Proxy → CIFS", color: Theme.amber, start: 0.54, end: 0.72),
                FlowMessage(from: "svc", to: "tgt", label: "access as Admin", color: Theme.red, start: 0.76, end: 0.94, system: "crown.fill")
            ],
            period: 8,
            footnote: "constrained delegation: impersonate any user to the allowed service (S4U2Self → S4U2Proxy)"
        )
    }
}

// MARK: - Forest trust abuse (SID history)

/// A child-domain admin forges an inter-realm ticket carrying the Enterprise
/// Admins SID, crossing the trust to take over the forest root.
struct ForestTrustView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let cy = h * 0.42
            LoopingTimeline(period: 6.5) { p in
                let step = min(3, Int(p * 4))
                let crossing = step >= 2
                ZStack {
                    // trust line
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.30, y: cy))
                        path.addLine(to: CGPoint(x: w * 0.70, y: cy))
                    }
                    .stroke(Theme.stroke, style: StrokeStyle(lineWidth: 1.5, dash: [4, 5]))
                    Text("TRUST").font(Theme.mono(7.5, .bold)).foregroundStyle(Theme.textDim)
                        .padding(.horizontal, 4).background(Theme.background)
                        .position(x: w * 0.5, y: cy - 12)

                    domainNode("child.corp", step >= 0 ? "Domain Admin" : "", "person.3.fill",
                               Theme.red, on: true).position(x: w * 0.20, y: cy)
                    domainNode("corp.local", step >= 3 ? "forest OWNED" : "forest root", "building.columns.fill",
                               step >= 3 ? Theme.red : Theme.blue, on: step >= 3).position(x: w * 0.80, y: cy)

                    // forged ticket travelling across the trust
                    if crossing {
                        let t = ease(CGFloat(min(1, (p - 0.5) / 0.35)))
                        TokenChip(text: "+ Enterprise Admins SID", color: Theme.amber, system: "ticket.fill")
                            .position(x: w * (0.20 + 0.60 * t), y: cy)
                    }

                    Text(step >= 1 ? "forge inter-realm TGT · inject SID history" : "")
                        .font(Theme.mono(8, .bold)).foregroundStyle(Theme.amber)
                        .position(x: w * 0.5, y: h * 0.82)
                    if step >= 3 {
                        Text("child compromise → whole forest")
                            .font(Theme.mono(8.5, .bold)).foregroundStyle(Theme.red)
                            .position(x: w * 0.5, y: h * 0.93)
                    }
                }
                .animation(.easeInOut(duration: 0.4), value: step)
            }
        }
    }
    private func domainNode(_ t: String, _ s: String, _ icon: String, _ c: Color, on: Bool) -> some View {
        VStack(spacing: 3) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(c.opacity(on ? 0.22 : 0.10)).frame(width: 56, height: 48)
                RoundedRectangle(cornerRadius: 12).strokeBorder(c.opacity(on ? 1 : 0.6), lineWidth: 1.3).frame(width: 56, height: 48)
                Image(systemName: icon).font(.system(size: 20, weight: .semibold)).foregroundStyle(c)
            }
            .shadow(color: on ? c.opacity(0.6) : .clear, radius: 8)
            Text(t).font(Theme.mono(9, .bold)).foregroundStyle(Theme.textPrimary)
            Text(s).font(Theme.mono(8)).foregroundStyle(on ? c : Theme.textDim)
        }
        .frame(width: 96)
    }
}

// MARK: - Tunneling & pivoting

struct TunnelingView: View {
    var body: some View {
        FlowStage(
            nodes: [
                FlowNode(id: "atk", pos: CGPoint(x: 0.12, y: 0.5), title: "Attacker", subtitle: "outside",
                         system: "desktopcomputer", color: Theme.red, startActive: true),
                FlowNode(id: "piv", pos: CGPoint(x: 0.45, y: 0.5), title: "Pivot", subtitle: "DMZ host",
                         system: "arrow.triangle.2.circlepath", color: Theme.amber, startActive: true),
                FlowNode(id: "db", pos: CGPoint(x: 0.83, y: 0.28), title: "DB01", subtitle: "hidden subnet",
                         system: "cylinder.fill", color: Theme.violet, startActive: true),
                FlowNode(id: "dc", pos: CGPoint(x: 0.83, y: 0.74), title: "DC01", subtitle: "hidden subnet",
                         system: "lock.shield.fill", color: Theme.red, startActive: true)
            ],
            messages: [
                FlowMessage(from: "atk", to: "piv", label: "SSH -D 1080", color: Theme.teal, start: 0.05, end: 0.24, system: "arrow.left.arrow.right"),
                FlowMessage(from: "piv", to: "db", label: "proxychains → :3306", color: Theme.amber, start: 0.30, end: 0.52),
                FlowMessage(from: "piv", to: "dc", label: "proxychains → :445", color: Theme.amber, start: 0.58, end: 0.80)
            ],
            period: 7,
            footnote: "route your tools through the pivot to reach the otherwise-unreachable 10.10.20.0/24"
        )
    }
}

// MARK: - AppLocker / application-whitelisting bypass

struct AppLockerBypassView: View {
    var body: some View {
        LoopingTimeline(period: 6) { p in
            let step = min(2, Int(p * 3))
            let bypassed = step >= 1
            VStack(alignment: .leading, spacing: 12) {
                Text("POLICY: allow only C:\\Program Files\\*  ·  C:\\Windows\\*")
                    .font(Theme.mono(8, .bold)).foregroundStyle(Theme.textDim)

                // first attempt — blocked
                HStack(spacing: 9) {
                    Image(systemName: step == 0 ? "xmark.octagon.fill" : "doc.fill")
                        .font(.system(size: 18)).foregroundStyle(step == 0 ? Theme.green : Theme.textDim)
                    Text("C:\\Users\\bob\\evil.exe")
                        .font(Theme.mono(9.5, .bold)).foregroundStyle(step == 0 ? Theme.textPrimary : Theme.textDim)
                    Text(step == 0 ? "BLOCKED" : "")
                        .font(Theme.mono(9, .bold)).foregroundStyle(Theme.green)
                }
                .opacity(step == 0 ? 1 : 0.4)

                if step >= 1 {
                    Image(systemName: "arrow.down").foregroundStyle(Theme.red).frame(maxWidth: .infinity)
                    HStack(spacing: 9) {
                        Image(systemName: step >= 2 ? "lock.open.fill" : "wrench.adjustable.fill")
                            .font(.system(size: 18)).foregroundStyle(step >= 2 ? Theme.red : Theme.amber)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("InstallUtil.exe  /U  evil.dll")
                                .font(Theme.mono(9.5, .bold)).foregroundStyle(Theme.red)
                            Text("a signed Microsoft binary in C:\\Windows — trusted by policy")
                                .font(Theme.mono(8)).foregroundStyle(Theme.textDim)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(9)
                    .background(Theme.red.opacity(0.10), in: RoundedRectangle(cornerRadius: 9))
                    .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(Theme.red.opacity(0.5), lineWidth: 1))
                }

                if step >= 2 {
                    Text("ALLOWED — code runs via a whitelisted LOLBin")
                        .font(Theme.mono(9, .bold)).foregroundStyle(Theme.red)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(.easeInOut(duration: 0.4), value: step)
        }
    }
}
