import SwiftUI

// MARK: - OSI / TCP-IP encapsulation

struct OSIModelView: View {
    private let layers: [(name: String, tag: String, color: Color)] = [
        ("Application", "DATA", Theme.green),
        ("Transport", "TCP", Theme.teal),
        ("Network", "IP", Theme.blue),
        ("Data Link", "ETH", Theme.violet)
    ]
    // Outer → inner segments of the on-the-wire frame.
    private let segments: [(String, Color)] = [
        ("ETH", Theme.violet), ("IP", Theme.blue), ("TCP", Theme.teal), ("DATA", Theme.green)
    ]

    var body: some View {
        LoopingTimeline(period: 9 * 0.9) { p in
            let step = min(8, Int(p * 9))
            let encapsulating = step <= 4
            let revealed = max(0, encapsulating ? step : 8 - step)
            VStack(spacing: 18) {
                Text(encapsulating ? "ENCAPSULATING  ↓  sender adds headers" : "DECAPSULATING  ↑  receiver strips headers")
                    .font(Theme.mono(10, .bold))
                    .foregroundStyle(encapsulating ? Theme.red : Theme.blue)

                HStack(spacing: 4) {
                    if revealed == 0 {
                        Text("·").font(Theme.mono(12)).foregroundStyle(Theme.textDim)
                    }
                    ForEach(Array(segments.suffix(revealed).enumerated()), id: \.offset) { _, seg in
                        Text(seg.0)
                            .font(Theme.mono(10, .bold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 9).padding(.vertical, 9)
                            .background(seg.1, in: RoundedRectangle(cornerRadius: 6))
                    }
                }
                .frame(height: 38)
                .animation(.easeInOut(duration: 0.4), value: revealed)

                HStack(spacing: 8) {
                    ForEach(layers.indices, id: \.self) { i in
                        let active = (revealed - 1) == i
                        VStack(spacing: 3) {
                            Text(layers[i].tag)
                                .font(Theme.mono(9, .bold))
                                .foregroundStyle(active ? .black : Theme.textDim)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(active ? layers[i].color : Theme.surfaceHi, in: Capsule())
                            Text(layers[i].name).font(Theme.mono(7)).foregroundStyle(Theme.textDim)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.45), value: step)
        }
    }
}

// MARK: - TCP 3-way handshake

struct TCPHandshakeView: View {
    var body: some View {
        FlowStage(
            nodes: [
                FlowNode(id: "c", pos: CGPoint(x: 0.16, y: 0.5), title: "Client", subtitle: "you",
                         system: "laptopcomputer", color: Theme.teal, startActive: true),
                FlowNode(id: "s", pos: CGPoint(x: 0.84, y: 0.5), title: "Server", subtitle: ":443",
                         system: "server.rack", color: Theme.blue, startActive: true)
            ],
            messages: [
                FlowMessage(from: "c", to: "s", label: "SYN", color: Theme.teal, start: 0.05, end: 0.32, system: "arrow.right"),
                FlowMessage(from: "s", to: "c", label: "SYN-ACK", color: Theme.blue, start: 0.37, end: 0.63),
                FlowMessage(from: "c", to: "s", label: "ACK", color: Theme.green, start: 0.68, end: 0.92, system: "checkmark")
            ],
            period: 5,
            footnote: "SYN → SYN-ACK → ACK  ·  then the connection is ESTABLISHED"
        )
    }
}

// MARK: - Anatomy of a packet

struct PacketTravelView: View {
    private let frames: [(name: String, color: Color, fields: [String])] = [
        ("Ethernet", Theme.violet, ["src MAC  00:1a:2b:…", "dst MAC  fe:80:c4:…"]),
        ("IP", Theme.blue, ["src IP  10.10.10.8", "dst IP  93.184.x.x", "TTL  64"]),
        ("TCP", Theme.teal, ["src port  51544", "dst port  80", "flags  PSH, ACK"]),
        ("Payload", Theme.green, ["GET /login HTTP/1.1", "Host: shop.example.com", "Cookie: session=8f3b…"])
    ]

    var body: some View {
        LoopingTimeline(period: 4 * 1.25) { p in
            let active = min(3, Int(p * 4))
            HStack(spacing: 16) {
                ZStack {
                    ForEach(frames.indices, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(frames[i].color.opacity(active == i ? 1 : 0.4),
                                          lineWidth: active == i ? 2 : 1)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(active == i ? frames[i].color.opacity(0.12) : .clear))
                            .padding(CGFloat(i) * 15)
                            .shadow(color: active == i ? frames[i].color.opacity(0.6) : .clear, radius: 8)
                    }
                    Text(frames[active].name)
                        .font(Theme.mono(10, .bold))
                        .foregroundStyle(frames[active].color)
                }
                .frame(width: 150, height: 150)

                VStack(alignment: .leading, spacing: 6) {
                    Text(frames[active].name.uppercased() + " HEADER")
                        .font(Theme.mono(9, .bold))
                        .foregroundStyle(frames[active].color)
                    ForEach(frames[active].fields, id: \.self) { f in
                        Text(f).font(Theme.mono(10)).foregroundStyle(Theme.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .animation(.easeInOut(duration: 0.4), value: active)
        }
    }
}

// MARK: - Symmetric encryption

struct SymmetricEncryptionView: View {
    private let plain = "TRANSFER $5000"
    private let cipher = "9F2A·C4·17·EB"

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            LoopingTimeline(period: 6) { p in
                let isCipher = p > 0.30 && p < 0.70
                let t = ease(CGFloat(min(max((p - 0.10) / 0.80, 0), 1)))
                ZStack {
                    HostNode(title: "Sender", subtitle: "AES key", system: "person.fill", color: Theme.teal)
                        .position(x: w * 0.13, y: h * 0.52)
                    HostNode(title: "Receiver", subtitle: "same key", system: "person.fill", color: Theme.blue)
                        .position(x: w * 0.87, y: h * 0.52)

                    VStack(spacing: 1) {
                        Image(systemName: "key.fill").foregroundStyle(Theme.amber).font(.system(size: 13))
                        Text("ONE SHARED KEY").font(Theme.mono(8, .bold)).foregroundStyle(Theme.amber)
                    }
                    .position(x: w * 0.5, y: h * 0.16)

                    TokenChip(text: isCipher ? cipher : plain,
                              color: isCipher ? Theme.amber : Theme.green,
                              system: isCipher ? "lock.fill" : "lock.open.fill")
                        .position(x: w * (0.16 + 0.68 * t), y: h * 0.52)

                    Text(isCipher ? "ciphertext — unreadable on the wire"
                                  : (p <= 0.30 ? "plaintext" : "decrypted ✓"))
                        .font(Theme.mono(9, .bold))
                        .foregroundStyle(isCipher ? Theme.amber : Theme.green)
                        .position(x: w * 0.5, y: h * 0.86)
                }
            }
        }
    }
}

// MARK: - Public-key exchange

struct PublicKeyExchangeView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            LoopingTimeline(period: 6) { p in
                let t = ease(CGFloat(min(max((p - 0.15) / 0.6, 0), 1)))
                let delivered = p > 0.80
                ZStack {
                    HostNode(title: "Alice", subtitle: "encrypts", system: "person.fill", color: Theme.teal)
                        .position(x: w * 0.13, y: h * 0.30)
                    HostNode(title: "Bob", subtitle: "decrypts", system: "person.fill", color: Theme.blue)
                        .position(x: w * 0.87, y: h * 0.30)
                    HostNode(title: "Eve", subtitle: "eavesdropper", system: "eye.slash.fill", color: Theme.red, active: false)
                        .position(x: w * 0.5, y: h * 0.84)

                    Text("Bob's PUBLIC key").font(Theme.mono(8, .bold)).foregroundStyle(Theme.teal)
                        .position(x: w * 0.22, y: h * 0.56)
                    Text("Bob's PRIVATE key").font(Theme.mono(8, .bold)).foregroundStyle(Theme.blue)
                        .position(x: w * 0.80, y: h * 0.56)

                    TokenChip(text: "9F2A·C4·EB", color: Theme.amber, system: "envelope.badge.fill")
                        .position(x: w * (0.16 + 0.68 * t), y: h * 0.30)
                    if delivered {
                        Image(systemName: "lock.open.fill").foregroundStyle(Theme.green).font(.system(size: 13))
                            .position(x: w * 0.78, y: h * 0.46)
                    }
                    Text("✕ sees ciphertext only").font(Theme.mono(8.5, .bold)).foregroundStyle(Theme.red)
                        .position(x: w * 0.5, y: h * 0.66)
                }
            }
        }
    }
}

// MARK: - Hashing (avalanche + one-way)

struct HashingView: View {
    private let rows: [(input: String, digest: String, color: Color)] = [
        ("\"password\"", "5e88 4898 da28…", Theme.green),
        ("\"Password\"", "e7cf 3ef4 f17c…", Theme.teal),
        ("\"passw0rd\"", "8f0e 2c1a 77be…", Theme.amber)
    ]

    var body: some View {
        LoopingTimeline(period: 3 * 1.1) { p in
            let active = min(2, Int(p * 3))
            GeometryReader { geo in
                let w = geo.size.width, h = geo.size.height
                ZStack {
                    VStack(spacing: 2) {
                        Image(systemName: "number.square.fill").font(.system(size: 16, weight: .bold))
                        Text("SHA-256").font(Theme.mono(9, .bold))
                    }
                    .foregroundStyle(Theme.violet)
                    .frame(width: 86, height: 56)
                    .background(Theme.violet.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.violet.opacity(0.6), lineWidth: 1.2))
                    .position(x: w * 0.5, y: h * 0.42)

                    Text(rows[active].input).font(Theme.mono(12, .bold)).foregroundStyle(rows[active].color)
                        .position(x: w * 0.16, y: h * 0.42)
                    Image(systemName: "arrow.right").foregroundStyle(Theme.textDim).position(x: w * 0.33, y: h * 0.42)
                    Image(systemName: "arrow.right").foregroundStyle(Theme.textDim).position(x: w * 0.67, y: h * 0.42)
                    Text(rows[active].digest).font(Theme.mono(11, .bold)).foregroundStyle(rows[active].color)
                        .position(x: w * 0.84, y: h * 0.42)

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left")
                        Text("one-way — can't be reversed")
                    }
                    .font(Theme.mono(9, .bold)).foregroundStyle(Theme.red)
                    .overlay(Rectangle().fill(Theme.red).frame(height: 1.4))
                    .position(x: w * 0.5, y: h * 0.74)

                    Text("flip one character → a totally different digest (avalanche)")
                        .font(Theme.mono(8)).foregroundStyle(Theme.textDim)
                        .position(x: w * 0.5, y: h * 0.92)
                }
                .animation(.easeInOut(duration: 0.4), value: active)
            }
        }
    }
}
