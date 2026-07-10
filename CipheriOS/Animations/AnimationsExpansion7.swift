import SwiftUI

// MARK: - Expansion wave 7 explainers
//
// Two foundational visualizations that pair with the new "Core Security
// Concepts" module and the beginner learning path: the CIA triad (the three
// properties all security protects) and the spectrum of threat actors.

// MARK: 1 — The CIA triad

/// Confidentiality, Integrity and Availability — the three properties every
/// security control ultimately serves. We light each in turn and name the attack
/// that breaks it and the control that protects it.
struct CiaTriadView: View {
    private let pillars: [(String, String, String, String, Color)] = [
        ("eye.slash.fill",        "Confidentiality", "broken by: theft, sniffing", "kept by: encryption, access control", Theme.blue),
        ("checkmark.shield.fill", "Integrity",       "broken by: tampering, MITM",  "kept by: hashing, signatures",       Theme.teal),
        ("bolt.heart.fill",       "Availability",    "broken by: DoS, ransomware",  "kept by: redundancy, backups",       Theme.amber)
    ]

    var body: some View {
        LoopingTimeline(period: 6) { p in
            let active = min(2, Int(p * 3))
            VStack(spacing: 12) {
                Text("THE CIA TRIAD").font(Theme.mono(9, .bold)).foregroundStyle(Theme.teal)

                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        let on = i == active
                        VStack(spacing: 6) {
                            Image(systemName: pillars[i].0)
                                .font(.system(size: 21, weight: .bold))
                                .foregroundStyle(on ? pillars[i].4 : Theme.textDim)
                            Text(pillars[i].1)
                                .font(Theme.mono(8.5, .bold))
                                .foregroundStyle(on ? Theme.textPrimary : Theme.textDim)
                                .multilineTextAlignment(.center)
                        }
                        .frame(width: 92, height: 80)
                        .background(on ? pillars[i].4.opacity(0.14) : Color.clear, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(pillars[i].4.opacity(on ? 0.8 : 0.25), lineWidth: 1.2))
                        .shadow(color: on ? pillars[i].4.opacity(0.5) : .clear, radius: 8)
                    }
                }

                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.octagon.fill").foregroundStyle(Theme.red)
                        Text(pillars[active].2).foregroundStyle(Theme.red)
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.green)
                        Text(pillars[active].3).foregroundStyle(Theme.green)
                    }
                }
                .font(Theme.mono(8.5, .bold))

                Text("every security control ultimately protects one of these three properties")
                    .font(Theme.mono(7.5)).foregroundStyle(Theme.textDim)
                    .multilineTextAlignment(.center).frame(width: 296)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 4)
            .animation(.easeInOut(duration: 0.35), value: active)
        }
    }
}

// MARK: 2 — Threat actors

/// Not all attackers are equal. The spectrum runs from script kiddies running
/// others' tools up to nation-state APTs with vast resources — each with a
/// different motive. Capability and resources climb as the list fills in.
struct ThreatActorsView: View {
    private let actors: [(String, String, String, Color, Int)] = [
        ("person.fill",            "Script Kiddie",      "runs others' tools, for kicks",          Theme.green,  1),
        ("megaphone.fill",         "Hacktivist",         "ideology — to send a message",            Theme.teal,   2),
        ("dollarsign.circle.fill", "Cybercriminal",      "money — ransomware, fraud, theft",        Theme.amber,  3),
        ("person.badge.key.fill",  "Insider",            "access plus a grievance or a payoff",     Theme.violet, 3),
        ("building.columns.fill",  "APT / Nation-State", "espionage & sabotage — vast resources",   Theme.red,    4)
    ]

    var body: some View {
        LoopingTimeline(period: 8) { p in
            let active = min(actors.count - 1, Int(p * Double(actors.count)))
            VStack(alignment: .leading, spacing: 7) {
                Text("WHO ATTACKS — AND WHY")
                    .font(Theme.mono(9, .bold)).foregroundStyle(Theme.teal)
                    .frame(maxWidth: .infinity)

                ForEach(0..<actors.count, id: \.self) { i in
                    let on = i <= active
                    HStack(spacing: 9) {
                        Image(systemName: actors[i].0)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(on ? actors[i].3 : Theme.textDim).frame(width: 22)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(actors[i].1).font(Theme.mono(9.5, .bold))
                                .foregroundStyle(on ? Theme.textPrimary : Theme.textDim)
                            Text(actors[i].2).font(Theme.mono(7.5))
                                .foregroundStyle(on ? actors[i].3 : Theme.textDim)
                        }
                        Spacer(minLength: 0)
                        HStack(spacing: 2) {
                            ForEach(0..<4, id: \.self) { b in
                                Capsule()
                                    .fill(b < actors[i].4 && on ? actors[i].3 : Theme.stroke)
                                    .frame(width: 6, height: 10)
                            }
                        }
                    }
                    .opacity(on ? 1 : 0.5)
                }

                Text("sophistication and resources climb from kiddies to nation-state APTs")
                    .font(Theme.mono(7)).foregroundStyle(Theme.textDim)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 4)
            .animation(.easeInOut(duration: 0.3), value: active)
        }
    }
}
