import SwiftUI

// MARK: - Networking-track explainers
//
// Twelve beginner-friendly visualizations for the "Networking" track. Where the
// concept is a message passing between hosts (DNS, DHCP, the internet path) we
// reuse the shared `FlowStage` engine; the rest are bespoke stages that still
// build on `LoopingTimeline`, `TokenChip`, `lerp` and `ease` from AnimationKit.

// MARK: Shared helpers

/// A compact node box (smaller than `HostNode`) for the denser networking maps.
/// Supports a multi-line title via embedded `\n`.
func netNode(_ system: String, _ title: String, _ color: Color, _ active: Bool) -> some View {
    VStack(spacing: 3) {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color.opacity(active ? 0.20 : 0.06))
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(color.opacity(active ? 0.9 : 0.3), lineWidth: 1.2)
            Image(systemName: system)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(active ? color : Theme.textDim)
        }
        .frame(width: 46, height: 38)
        .shadow(color: active ? color.opacity(0.5) : .clear, radius: 6)
        Text(title)
            .font(Theme.mono(8, .bold))
            .foregroundStyle(active ? Theme.textPrimary : Theme.textDim)
            .multilineTextAlignment(.center)
            .lineLimit(2)
    }
    .frame(width: 74)
}

/// Position of a point travelling along a polyline `pts` at normalised `t` 0…1,
/// eased within each segment. Used by the gateway, NAT and VPN stages.
func pointOnPath(_ pts: [CGPoint], _ t: CGFloat) -> CGPoint {
    guard pts.count > 1 else { return pts.first ?? .zero }
    let clamped = min(max(t, 0), 0.9999)
    let segs = pts.count - 1
    let scaled = clamped * CGFloat(segs)
    let i = Int(scaled)
    return lerp(pts[i], pts[i + 1], ease(scaled - CGFloat(i)))
}

// MARK: 1 — A network of networks

struct InternetMapView: View {
    var body: some View {
        FlowStage(
            nodes: [
                FlowNode(id: "dev", pos: CGPoint(x: 0.14, y: 0.28), title: "Your laptop", subtitle: "home LAN",
                         system: "laptopcomputer", color: Theme.violet, startActive: true),
                FlowNode(id: "home", pos: CGPoint(x: 0.14, y: 0.80), title: "Home router", subtitle: "Wi-Fi",
                         system: "wifi.router", color: Theme.teal),
                FlowNode(id: "isp", pos: CGPoint(x: 0.40, y: 0.80), title: "ISP", subtitle: "provider",
                         system: "antenna.radiowaves.left.and.right", color: Theme.amber),
                FlowNode(id: "net", pos: CGPoint(x: 0.64, y: 0.28), title: "Internet", subtitle: "backbone",
                         system: "globe", color: Theme.blue, startActive: true),
                FlowNode(id: "srv", pos: CGPoint(x: 0.88, y: 0.28), title: "Web server", subtitle: "shop.com",
                         system: "server.rack", color: Theme.green)
            ],
            messages: [
                FlowMessage(from: "dev", to: "home", label: "data", color: Theme.violet, start: 0.00, end: 0.22),
                FlowMessage(from: "home", to: "isp", label: "data", color: Theme.teal, start: 0.24, end: 0.46),
                FlowMessage(from: "isp", to: "net", label: "data", color: Theme.amber, start: 0.48, end: 0.70),
                FlowMessage(from: "net", to: "srv", label: "data", color: Theme.blue, start: 0.72, end: 0.96, system: "arrow.right")
            ],
            period: 7,
            footnote: "The internet is a network OF networks — your data crosses several to reach a server."
        )
    }
}

// MARK: 2 — IP & MAC addresses

struct IPAddressingView: View {
    private let octets = ["192", "168", "1", "42"]
    private let bin    = ["11000000", "10101000", "00000001", "00101010"]

    var body: some View {
        LoopingTimeline(period: 5) { p in
            let step = min(4, Int(p * 5))
            let macPhase = step == 4
            VStack(spacing: 12) {
                Text("IPv4 ADDRESS · four octets · 32 bits")
                    .font(Theme.mono(9.5, .bold))
                    .foregroundStyle(macPhase ? Theme.textDim : Theme.violet)

                HStack(spacing: 4) {
                    ForEach(0..<4, id: \.self) { i in
                        let on = !macPhase && step == i
                        VStack(spacing: 4) {
                            Text(octets[i])
                                .font(Theme.mono(17, .bold))
                                .foregroundStyle(on ? .black : (macPhase ? Theme.textDim : Theme.textPrimary))
                                .frame(width: 50, height: 32)
                                .background(on ? Theme.violet : Theme.surfaceHi,
                                            in: RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Theme.violet.opacity(on ? 1 : 0.3), lineWidth: 1))
                            Text(bin[i])
                                .font(Theme.mono(7.5, .bold))
                                .foregroundStyle(on ? Theme.violet : Theme.textDim)
                        }
                        if i < 3 {
                            Text(".").font(Theme.mono(17, .bold)).foregroundStyle(Theme.textDim).offset(y: -9)
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.35), value: step)

                Text("192.168.x.x is a PRIVATE range — reused inside every home & office, not routable on the public internet.")
                    .font(Theme.mono(8))
                    .foregroundStyle(Theme.textDim)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 280)

                HStack(spacing: 7) {
                    Image(systemName: "cpu").font(.system(size: 12))
                    Text("MAC  a4:83:e7:2b:14:9f").font(Theme.mono(11, .bold))
                }
                .foregroundStyle(macPhase ? Theme.amber : Theme.textDim)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background((macPhase ? Theme.amber : Theme.textDim).opacity(0.12), in: Capsule())

                Text(macPhase ? "48-bit hardware address — burned into the network card, unique per device"
                              : "the IP can change network to network; the MAC names the physical card")
                    .font(Theme.mono(7.5))
                    .foregroundStyle(Theme.textDim)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 4)
            .animation(.easeInOut(duration: 0.35), value: macPhase)
        }
    }
}

// MARK: 3 — Subnet mask & CIDR

struct SubnetMaskView: View {
    private let prefixes = [24, 25, 26, 28]

    var body: some View {
        LoopingTimeline(period: Double(prefixes.count) * 1.5) { p in
            let idx = min(prefixes.count - 1, Int(p * Double(prefixes.count)))
            let prefix = prefixes[idx]
            let hosts = max(0, (1 << (32 - prefix)) - 2)
            VStack(spacing: 12) {
                Text("IP  192.168.1.42")
                    .font(Theme.mono(12, .bold)).foregroundStyle(Theme.textPrimary)

                HStack(spacing: 5) {
                    ForEach(0..<4, id: \.self) { oct in
                        HStack(spacing: 1.5) {
                            ForEach(0..<8, id: \.self) { b in
                                let isNet = (oct * 8 + b) < prefix
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(isNet ? Theme.violet : Theme.green)
                                    .frame(width: 7, height: 18)
                                    .opacity(isNet ? 0.95 : 0.85)
                            }
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.4), value: prefix)

                HStack(spacing: 18) {
                    legend(Theme.violet, "network part")
                    legend(Theme.green, "host part")
                }

                Text("/\(prefix)   mask \(maskString(prefix))")
                    .font(Theme.mono(11, .bold)).foregroundStyle(Theme.violet)
                Text("\(hosts) usable host addresses")
                    .font(Theme.mono(11, .bold)).foregroundStyle(Theme.green)
                    .contentTransition(.numericText())
                Text("more network bits ⇢ more subnets, fewer hosts in each")
                    .font(Theme.mono(7.5)).foregroundStyle(Theme.textDim)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.4), value: prefix)
        }
    }

    private func legend(_ c: Color, _ t: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2).fill(c).frame(width: 10, height: 10)
            Text(t).font(Theme.mono(8.5, .bold)).foregroundStyle(Theme.textSecondary)
        }
    }

    private func maskString(_ prefix: Int) -> String {
        var bits: UInt32 = 0
        for i in 0..<prefix { bits |= (UInt32(1) << (31 - i)) }
        let o = [(bits >> 24) & 0xFF, (bits >> 16) & 0xFF, (bits >> 8) & 0xFF, bits & 0xFF]
        return o.map { String($0) }.joined(separator: ".")
    }
}

// MARK: 4 — DNS lookup

struct DNSResolutionView: View {
    var body: some View {
        FlowStage(
            nodes: [
                FlowNode(id: "you", pos: CGPoint(x: 0.13, y: 0.5), title: "You", subtitle: "browser",
                         system: "laptopcomputer", color: Theme.violet, startActive: true),
                FlowNode(id: "res", pos: CGPoint(x: 0.40, y: 0.5), title: "Resolver", subtitle: "8.8.8.8",
                         system: "magnifyingglass", color: Theme.teal, startActive: true),
                FlowNode(id: "root", pos: CGPoint(x: 0.70, y: 0.16), title: "Root", subtitle: "“.”",
                         system: "circle.hexagongrid.fill", color: Theme.blue),
                FlowNode(id: "tld", pos: CGPoint(x: 0.87, y: 0.5), title: "TLD", subtitle: ".com",
                         system: "globe", color: Theme.amber),
                FlowNode(id: "auth", pos: CGPoint(x: 0.70, y: 0.84), title: "Authority", subtitle: "shop.com",
                         system: "server.rack", color: Theme.green)
            ],
            messages: [
                FlowMessage(from: "you", to: "res", label: "shop.com?", color: Theme.violet, start: 0.00, end: 0.12),
                FlowMessage(from: "res", to: "root", label: "shop.com?", color: Theme.teal, start: 0.13, end: 0.25),
                FlowMessage(from: "root", to: "res", label: "ask .com", color: Theme.blue, start: 0.26, end: 0.38),
                FlowMessage(from: "res", to: "tld", label: "shop.com?", color: Theme.teal, start: 0.39, end: 0.51),
                FlowMessage(from: "tld", to: "res", label: "ask host", color: Theme.amber, start: 0.52, end: 0.63),
                FlowMessage(from: "res", to: "auth", label: "shop.com?", color: Theme.teal, start: 0.64, end: 0.75),
                FlowMessage(from: "auth", to: "res", label: "93.184.x.x", color: Theme.green, start: 0.76, end: 0.87),
                FlowMessage(from: "res", to: "you", label: "93.184.x.x", color: Theme.green, start: 0.88, end: 1.0, system: "checkmark")
            ],
            period: 9,
            footnote: "The resolver walks root → TLD → authority, then caches the answer so next time is instant."
        )
    }
}

// MARK: 5 — Switch, router & the default gateway

struct DefaultGatewayView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let you  = CGPoint(x: w * 0.50, y: h * 0.82)
            let sw   = CGPoint(x: w * 0.50, y: h * 0.48)
            let peer = CGPoint(x: w * 0.17, y: h * 0.18)
            let gw   = CGPoint(x: w * 0.83, y: h * 0.48)
            let cloud = CGPoint(x: w * 0.83, y: h * 0.16)
            LoopingTimeline(period: 8) { p in
                let local = p < 0.5
                let t = CGFloat(local ? p / 0.5 : (p - 0.5) / 0.5)
                let path = local ? [you, sw, peer] : [you, sw, gw, cloud]
                let pos = pointOnPath(path, t)
                ZStack {
                    wire(you, sw); wire(sw, peer); wire(sw, gw); wire(gw, cloud)

                    netNode("laptopcomputer", "You\n.1.42", Theme.violet, true).position(you)
                    netNode("rectangle.split.3x1", "Switch", Theme.teal, true).position(sw)
                    netNode("desktopcomputer", "Peer\n.1.7", Theme.green, local).position(peer)
                    netNode("wifi.router", "Gateway\n.1.1", Theme.amber, !local).position(gw)
                    netNode("globe", "Internet", Theme.blue, !local).position(cloud)

                    TokenChip(text: local ? "to .1.7" : "to 93.184.x.x",
                              color: local ? Theme.green : Theme.amber, system: "arrow.right")
                        .position(pos)

                    Text(local ? "Same subnet → the switch delivers it directly"
                               : "Different network → hand it to the DEFAULT GATEWAY (your router)")
                        .font(Theme.mono(9, .bold))
                        .foregroundStyle(local ? Theme.green : Theme.amber)
                        .multilineTextAlignment(.center)
                        .frame(width: w * 0.92)
                        .position(x: w * 0.5, y: h * 0.97)
                }
                .animation(.easeInOut(duration: 0.3), value: local)
            }
        }
    }

    private func wire(_ a: CGPoint, _ b: CGPoint) -> some View {
        Path { p in p.move(to: a); p.addLine(to: b) }
            .stroke(Theme.stroke, style: StrokeStyle(lineWidth: 1.5, dash: [4, 5]))
    }
}

// MARK: 6 — Routing & traceroute

struct RoutingHopsView: View {
    private let hops: [(ip: String, ms: String)] = [
        ("10.0.0.1", "1"), ("72.14.5.9", "8"), ("108.170.238.1", "14"), ("93.184.216.34", "21")
    ]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let n = hops.count
            let rowY = h * 0.24
            let youP = CGPoint(x: w * 0.06, y: rowY)
            let xs: [CGFloat] = (0..<n).map { w * (0.22 + 0.72 * CGFloat($0) / CGFloat(max(1, n - 1))) }
            LoopingTimeline(period: Double(n) + 1.2) { p in
                let prog = p * Double(n) + 0.0001
                let active = min(n, Int(prog))
                let segT = CGFloat(prog - Double(active))
                let fromPt = active == 0 ? youP : CGPoint(x: xs[active - 1], y: rowY)
                let toPt = CGPoint(x: xs[min(active, n - 1)], y: rowY)
                let pos = lerp(fromPt, toPt, ease(min(segT, 1)))
                ZStack {
                    Path { pa in pa.move(to: youP); pa.addLine(to: CGPoint(x: xs[n - 1], y: rowY)) }
                        .stroke(Theme.stroke, style: StrokeStyle(lineWidth: 1.5, dash: [4, 5]))

                    netNode("laptopcomputer", "you", Theme.violet, true).position(youP)
                    ForEach(0..<n, id: \.self) { i in
                        netNode(i == n - 1 ? "server.rack" : "point.3.connected.trianglepath.dotted",
                                i == n - 1 ? "dest" : "R\(i + 1)",
                                i == n - 1 ? Theme.green : Theme.amber, i < active)
                            .position(x: xs[i], y: rowY)
                    }

                    TokenChip(text: "TTL \(max(1, 64 - active))", color: Theme.violet, system: "arrow.right")
                        .position(pos)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("$ traceroute shop.com")
                            .font(Theme.mono(8.5, .bold)).foregroundStyle(Theme.teal)
                        ForEach(0..<n, id: \.self) { i in
                            if i < active {
                                Text("\(i + 1)  \(hops[i].ip)  \(hops[i].ms) ms")
                                    .font(Theme.mono(8.5))
                                    .foregroundStyle(i == n - 1 ? Theme.green : Theme.textSecondary)
                            }
                        }
                    }
                    .frame(width: w * 0.82, alignment: .leading)
                    .position(x: w * 0.5, y: h * 0.7)
                }
                .animation(.easeInOut(duration: 0.25), value: active)
            }
        }
    }
}

// MARK: 7 — NAT translation

struct NATTranslationView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let dev = CGPoint(x: w * 0.14, y: h * 0.30)
            let nat = CGPoint(x: w * 0.50, y: h * 0.30)
            let server = CGPoint(x: w * 0.86, y: h * 0.30)
            LoopingTimeline(period: 7) { p in
                let outbound = p < 0.5
                let t = CGFloat(outbound ? p / 0.5 : 1 - (p - 0.5) / 0.5)   // 0→1 both directions
                let onPrivate = t < 0.5
                let pos = lerp(dev, server, ease(t))
                ZStack {
                    Path { pa in pa.move(to: dev); pa.addLine(to: server) }
                        .stroke(Theme.stroke, style: StrokeStyle(lineWidth: 1.5, dash: [4, 5]))

                    netNode("desktopcomputer", "Private\n.1.10", Theme.green, true).position(dev)
                    netNode("wifi.router", "NAT\nrouter", Theme.violet, true).position(nat)
                    netNode("server.rack", "Server", Theme.blue, true).position(server)

                    TokenChip(text: onPrivate ? "192.168.1.10:5001" : "203.0.113.5:40001",
                              color: onPrivate ? Theme.green : Theme.blue,
                              system: outbound ? "arrow.right" : "arrow.left")
                        .position(pos)

                    VStack(spacing: 4) {
                        Text("NAT TRANSLATION TABLE")
                            .font(Theme.mono(8, .bold)).foregroundStyle(Theme.violet)
                        HStack(spacing: 6) {
                            Text("192.168.1.10:5001").font(Theme.mono(8.5, .bold)).foregroundStyle(Theme.green)
                            Image(systemName: "arrow.left.arrow.right").font(.system(size: 8)).foregroundStyle(Theme.textDim)
                            Text("203.0.113.5:40001").font(Theme.mono(8.5, .bold)).foregroundStyle(Theme.blue)
                        }
                        .padding(.horizontal, 8).padding(.vertical, 5)
                        .background(Theme.surfaceHi, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .position(x: w * 0.5, y: h * 0.68)

                    Text("Many private devices share ONE public IP — the router rewrites address & port both ways.")
                        .font(Theme.mono(8)).foregroundStyle(Theme.textDim)
                        .multilineTextAlignment(.center).frame(width: w * 0.92)
                        .position(x: w * 0.5, y: h * 0.92)
                }
                .animation(.easeInOut(duration: 0.2), value: onPrivate)
            }
        }
    }
}

// MARK: 8 — DHCP lease (DORA)

struct DHCPLeaseView: View {
    var body: some View {
        FlowStage(
            nodes: [
                FlowNode(id: "c", pos: CGPoint(x: 0.18, y: 0.5), title: "New device", subtitle: "no IP yet",
                         system: "ipad", color: Theme.violet, startActive: true),
                FlowNode(id: "s", pos: CGPoint(x: 0.82, y: 0.5), title: "DHCP server", subtitle: "the router",
                         system: "wifi.router", color: Theme.teal, startActive: true)
            ],
            messages: [
                FlowMessage(from: "c", to: "s", label: "DISCOVER", color: Theme.violet, start: 0.02, end: 0.24, system: "dot.radiowaves.left.and.right"),
                FlowMessage(from: "s", to: "c", label: "OFFER .1.50", color: Theme.teal, start: 0.27, end: 0.49),
                FlowMessage(from: "c", to: "s", label: "REQUEST .1.50", color: Theme.violet, start: 0.52, end: 0.74),
                FlowMessage(from: "s", to: "c", label: "ACK ✓", color: Theme.green, start: 0.77, end: 0.99, system: "checkmark")
            ],
            period: 6,
            footnote: "DORA — Discover · Offer · Request · Ack. The lease also hands you the gateway & DNS servers."
        )
    }
}

// MARK: 9 — TCP vs UDP

struct TCPvsUDPView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            LoopingTimeline(period: 5) { p in
                ZStack {
                    laneLabel("TCP", "reliable · ordered · acknowledged", Theme.teal, y: h * 0.10, w: w)
                    tcpLane(p: p, w: w, y: h * 0.34)
                    Rectangle().fill(Theme.stroke).frame(width: w * 0.9, height: 1)
                        .position(x: w * 0.5, y: h * 0.52)
                    laneLabel("UDP", "fast · best-effort · no guarantees", Theme.amber, y: h * 0.60, w: w)
                    udpLane(p: p, w: w, y: h * 0.84)
                }
            }
        }
    }

    private func laneLabel(_ name: String, _ sub: String, _ color: Color, y: CGFloat, w: CGFloat) -> some View {
        HStack(spacing: 6) {
            Text(name).font(Theme.mono(11, .bold)).foregroundStyle(.black)
                .padding(.horizontal, 7).padding(.vertical, 2)
                .background(color, in: Capsule())
            Text(sub).font(Theme.mono(8.5, .bold)).foregroundStyle(color)
        }
        .position(x: w * 0.5, y: y)
    }

    private func tcpLane(p: Double, w: CGFloat, y: CGFloat) -> some View {
        let sending = p < 0.5
        let segP = CGFloat(sending ? p / 0.5 : (p - 0.5) / 0.5)
        let x = sending ? w * (0.14 + 0.72 * ease(segP)) : w * (0.86 - 0.72 * ease(segP))
        return ZStack {
            Path { pa in pa.move(to: CGPoint(x: w * 0.12, y: y)); pa.addLine(to: CGPoint(x: w * 0.88, y: y)) }
                .stroke(Theme.stroke, style: StrokeStyle(lineWidth: 1.2, dash: [3, 4]))
            TokenChip(text: sending ? "SEQ 1" : "ACK 1",
                      color: sending ? Theme.teal : Theme.green,
                      system: sending ? "arrow.right" : "checkmark")
                .position(x: x, y: y)
        }
    }

    private func udpLane(p: Double, w: CGFloat, y: CGFloat) -> some View {
        let lostLocal = (p - 0.16) / 0.5
        let markerVisible = lostLocal > 0.45 && lostLocal < 0.85
        return ZStack {
            Path { pa in pa.move(to: CGPoint(x: w * 0.12, y: y)); pa.addLine(to: CGPoint(x: w * 0.88, y: y)) }
                .stroke(Theme.stroke, style: StrokeStyle(lineWidth: 1.2, dash: [3, 4]))
            ForEach(0..<3, id: \.self) { i in
                let local = CGFloat((p - Double(i) * 0.16) / 0.5)
                let lost = (i == 1)
                let x = w * (0.14 + 0.72 * ease(min(max(local, 0), 1)))
                if local >= 0 && local <= 1 {
                    TokenChip(text: "\(i + 1)", color: lost ? Theme.red : Theme.amber)
                        .position(x: x, y: y)
                        .opacity(lost && local > 0.5 ? 0 : 1)
                }
            }
            if markerVisible {
                Image(systemName: "xmark").font(.system(size: 10, weight: .black)).foregroundStyle(Theme.red)
                    .position(x: w * 0.5, y: y - 15)
            }
        }
    }
}

// MARK: 10 — Joining a Wi-Fi network

struct WiFiConnectView: View {
    private let steps = ["Scanning for networks…", "Authenticating (WPA2)…", "Associated ✓", "Surfing the web"]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let ap = CGPoint(x: w * 0.5, y: h * 0.34)
            LoopingTimeline(period: Double(steps.count) * 1.3) { p in
                let step = min(steps.count - 1, Int(p * Double(steps.count)))
                let pulse = CGFloat((sin(p * .pi * 8) + 1) / 2)
                ZStack {
                    ForEach(0..<3, id: \.self) { r in
                        Circle()
                            .strokeBorder(Theme.violet.opacity(0.45 - Double(r) * 0.12), lineWidth: 2)
                            .frame(width: CGFloat(46 + r * 26) + pulse * 8,
                                   height: CGFloat(46 + r * 26) + pulse * 8)
                            .position(ap)
                    }
                    netNode("wifi.router", "Access Point\n\"CoffeeWiFi\"", Theme.violet, true).position(ap)
                    netNode("iphone", "your phone", step >= 2 ? Theme.green : Theme.amber, true)
                        .position(x: w * 0.5, y: h * 0.74)
                    if step >= 2 {
                        Image(systemName: "checkmark.shield.fill").foregroundStyle(Theme.green).font(.system(size: 15))
                            .position(x: w * 0.63, y: h * 0.54)
                    }
                    Text(steps[step]).font(Theme.mono(10, .bold))
                        .foregroundStyle(step >= 2 ? Theme.green : Theme.amber)
                        .position(x: w * 0.5, y: h * 0.93)
                }
                .animation(.easeInOut(duration: 0.3), value: step)
            }
        }
    }
}

// MARK: 11 — VPN tunnel

struct VPNTunnelView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let you = CGPoint(x: w * 0.12, y: h * 0.32)
            let vpn = CGPoint(x: w * 0.62, y: h * 0.32)
            let net = CGPoint(x: w * 0.88, y: h * 0.32)
            LoopingTimeline(period: 6) { p in
                let pos = lerp(you, vpn, ease(min(CGFloat(p) / 0.75, 1)))
                ZStack {
                    Capsule()
                        .fill(Theme.green.opacity(0.10))
                        .frame(width: (vpn.x - you.x) + 36, height: 42)
                        .overlay(Capsule().strokeBorder(Theme.green.opacity(0.7), lineWidth: 1.5))
                        .position(x: (you.x + vpn.x) / 2, y: you.y)
                    Path { pa in pa.move(to: vpn); pa.addLine(to: net) }
                        .stroke(Theme.stroke, style: StrokeStyle(lineWidth: 1.5, dash: [4, 5]))

                    netNode("laptopcomputer", "You", Theme.violet, true).position(x: you.x + 6, y: you.y)
                    netNode("lock.shield", "VPN\nserver", Theme.green, true).position(vpn)
                    netNode("globe", "Internet", Theme.blue, true).position(net)
                    netNode("eye.slash.fill", "snooper", Theme.red, false).position(x: w * 0.36, y: h * 0.74)

                    TokenChip(text: "encrypted", color: Theme.green, system: "lock.fill")
                        .position(x: pos.x, y: you.y)

                    Text("Inside the tunnel everything is encrypted — a snooper on the public network sees only ciphertext.")
                        .font(Theme.mono(8)).foregroundStyle(Theme.textDim)
                        .multilineTextAlignment(.center).frame(width: w * 0.92)
                        .position(x: w * 0.5, y: h * 0.93)
                }
            }
        }
    }
}

// MARK: 12 — Firewall filtering

struct FirewallFilterView: View {
    private let rules: [(port: String, allow: Bool)] = [
        (":443 HTTPS", true), (":22 SSH", true), (":23 Telnet", false), (":3389 RDP", false)
    ]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let wallX = w * 0.52
            let rowY = h * 0.40
            LoopingTimeline(period: Double(rules.count) * 1.3) { p in
                let i = min(rules.count - 1, Int(p * Double(rules.count)))
                let local = CGFloat(p * Double(rules.count) - Double(i))
                let rule = rules[i]
                let blockedHere = !rule.allow && local > 0.5
                let x = rule.allow
                    ? w * (0.08 + 0.84 * ease(local))
                    : w * 0.08 + (wallX - w * 0.08) * ease(min(local / 0.5, 1))
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Theme.red.opacity(0.16))
                        .frame(width: 14, height: h * 0.6)
                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.red.opacity(0.7), lineWidth: 1.2))
                        .position(x: wallX, y: rowY)
                    Image(systemName: "flame.fill").foregroundStyle(Theme.red).font(.system(size: 11))
                        .position(x: wallX, y: h * 0.06)
                    Text("FIREWALL").font(Theme.mono(7, .bold)).foregroundStyle(Theme.red)
                        .position(x: wallX, y: h * 0.13)

                    TokenChip(text: rule.port, color: rule.allow ? Theme.green : Theme.red,
                              system: rule.allow ? "arrow.right" : "xmark")
                        .position(x: x, y: rowY)
                        .opacity(blockedHere ? max(0, Double(1 - (local - 0.5) / 0.5)) : 1)
                    if blockedHere {
                        Image(systemName: "xmark.octagon.fill").foregroundStyle(Theme.red).font(.system(size: 17))
                            .position(x: wallX - 16, y: rowY)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("RULESET").font(Theme.mono(7.5, .bold)).foregroundStyle(Theme.textDim)
                        ForEach(0..<rules.count, id: \.self) { r in
                            HStack(spacing: 4) {
                                Image(systemName: rules[r].allow ? "checkmark" : "xmark")
                                    .font(.system(size: 7, weight: .black))
                                    .foregroundStyle(rules[r].allow ? Theme.green : Theme.red)
                                Text(rules[r].port)
                                    .font(Theme.mono(7.5, r == i ? .bold : .regular))
                                    .foregroundStyle(r == i ? Theme.textPrimary : Theme.textDim)
                            }
                        }
                    }
                    .position(x: w * 0.18, y: h * 0.85)

                    Text(rule.allow ? "allowed ✓ — matches an accept rule"
                                    : "blocked ✕ — no rule permits it")
                        .font(Theme.mono(8.5, .bold))
                        .foregroundStyle(rule.allow ? Theme.green : Theme.red)
                        .frame(width: w * 0.5)
                        .position(x: w * 0.68, y: h * 0.85)
                }
                .animation(.easeInOut(duration: 0.2), value: i)
            }
        }
    }
}
