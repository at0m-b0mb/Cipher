import SwiftUI

// MARK: - Expansion wave 9 explainers
//
// Six foundational visualizations that deepen the "ground floor" of the course
// — the literacy every red/blue operator needs before anything else clicks:
//   • numberBases     — one value dressed as decimal, binary and hex
//   • endianness      — how those bytes actually sit in memory
//   • charEncoding    — character → Unicode code point → UTF-8 bytes
//   • filePermissions — reading -rwxr-xr-- as the octal 754
//   • booleanLogic    — the AND/OR/XOR/NOT gates under every mask and cipher
//   • saltHashing     — why a per-user salt makes identical passwords differ
//
// All are Fundamentals (default-teal accent), built on the shared
// `LoopingTimeline` engine so they inherit play/pause, scrub and speed for free.

// MARK: - File-private helpers

/// A labelled value pill (DEC 77, etc.).
private func valuePill9(_ label: String, _ value: String, _ color: Color, on: Bool) -> some View {
    HStack(spacing: 6) {
        Text(label)
            .font(Theme.mono(8.5, .bold))
            .foregroundStyle(Theme.textDim)
            .frame(width: 30, alignment: .leading)
        Text(value)
            .font(Theme.mono(15, .bold))
            .foregroundStyle(on ? color : Theme.textDim)
            .padding(.horizontal, 10).padding(.vertical, 3)
            .background(color.opacity(on ? 0.16 : 0.05), in: RoundedRectangle(cornerRadius: 6))
    }
}

/// A 4-bit nibble → single hex digit tile.
private func nibble9(_ binary: String, _ hex: String, on: Bool) -> some View {
    VStack(spacing: 2) {
        Text(binary)
            .font(Theme.mono(8))
            .foregroundStyle(on ? Theme.textSecondary : Theme.textDim)
        Text(hex)
            .font(Theme.mono(13, .bold))
            .foregroundStyle(on ? Theme.amber : Theme.textDim)
            .frame(width: 36, height: 22)
            .background(on ? Theme.amber.opacity(0.16) : Theme.surfaceHi, in: RoundedRectangle(cornerRadius: 5))
            .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Theme.amber.opacity(on ? 0.6 : 0.2), lineWidth: 1))
    }
}

/// A single input-bit square (used by the boolean-logic gates).
private func bitCell9(_ label: String, _ v: Int) -> some View {
    VStack(spacing: 4) {
        Text(label).font(Theme.mono(9, .bold)).foregroundStyle(Theme.textDim)
        Text("\(v)")
            .font(Theme.mono(20, .bold))
            .foregroundStyle(v == 1 ? .black : Theme.textDim)
            .frame(width: 40, height: 40)
            .background(v == 1 ? Theme.teal : Theme.surfaceHi, in: RoundedRectangle(cornerRadius: 8))
    }
}

/// A gate-result tile (AND / OR / XOR / NOT).
private func gate9(_ name: String, _ v: Int, _ color: Color) -> some View {
    VStack(spacing: 4) {
        Text(name).font(Theme.mono(8, .bold)).foregroundStyle(color)
        Text("\(v)")
            .font(Theme.mono(15, .bold))
            .foregroundStyle(v == 1 ? .black : Theme.textDim)
            .frame(width: 40, height: 30)
            .background(v == 1 ? color : Theme.surfaceHi, in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(color.opacity(0.5), lineWidth: 1))
    }
}

/// A user → hash row for the salting animation.
private func userRow9(_ user: String, _ pass: String, _ salt: String, _ hash: String, _ salted: Bool) -> some View {
    HStack(spacing: 6) {
        Image(systemName: "person.fill").font(.system(size: 11)).foregroundStyle(Theme.textSecondary).frame(width: 15)
        Text(user).font(Theme.mono(9, .bold)).foregroundStyle(Theme.textPrimary).frame(width: 34, alignment: .leading)
        Text(pass).font(Theme.mono(8.5)).foregroundStyle(Theme.textDim).frame(width: 50, alignment: .leading)
        Text(salt.isEmpty ? " " : salt)
            .font(Theme.mono(8.5, .bold)).foregroundStyle(Theme.violet).frame(width: 32)
        Image(systemName: "arrow.right").font(.system(size: 8)).foregroundStyle(Theme.textDim)
        Text(hash)
            .font(Theme.mono(9, .bold)).foregroundStyle(.black)
            .padding(.horizontal, 6).padding(.vertical, 3)
            .background(salted ? Theme.green : Theme.red, in: RoundedRectangle(cornerRadius: 5))
    }
}

// MARK: 1 — Number systems (decimal · binary · hex)

/// One value (77) shown three ways. Reveal the binary place values that sum to
/// it, then group the bits into nibbles to read off the hex — the mental model
/// behind every hash dump, byte and colour code.
struct NumberBasesView: View {
    private let places = [128, 64, 32, 16, 8, 4, 2, 1]
    private let bits   = [0, 1, 0, 0, 1, 1, 0, 1]   // 77 = 64+8+4+1

    var body: some View {
        LoopingTimeline(period: 8) { p in
            let step = min(3, Int(p * 4))
            VStack(spacing: 12) {
                Text("ONE VALUE, THREE COSTUMES")
                    .font(Theme.mono(9, .bold)).foregroundStyle(Theme.teal)

                valuePill9("DEC", "77", Theme.amber, on: true)

                // Binary with place values
                VStack(spacing: 3) {
                    HStack(spacing: 4) {
                        Text("BIN").font(Theme.mono(8.5, .bold))
                            .foregroundStyle(Theme.textDim).frame(width: 26, alignment: .leading)
                        ForEach(0..<8, id: \.self) { i in
                            let set = bits[i] == 1
                            VStack(spacing: 2) {
                                Text("\(places[i])")
                                    .font(Theme.mono(6.5))
                                    .foregroundStyle(step >= 1 && set ? Theme.teal : Theme.textDim)
                                Text("\(bits[i])")
                                    .font(Theme.mono(11, .bold))
                                    .foregroundStyle(step >= 1 && set ? .black : Theme.textDim)
                                    .frame(width: 20, height: 20)
                                    .background((step >= 1 && set) ? Theme.teal : Theme.surfaceHi,
                                                in: RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }
                    Text("64 + 8 + 4 + 1  =  77")
                        .font(Theme.mono(8.5, .bold))
                        .foregroundStyle(Theme.teal)
                        .opacity(step >= 1 ? 1 : 0)
                }

                // Hex from nibbles
                HStack(spacing: 6) {
                    Text("HEX").font(Theme.mono(8.5, .bold))
                        .foregroundStyle(Theme.textDim).frame(width: 26, alignment: .leading)
                    nibble9("0100", "4", on: step >= 2)
                    nibble9("1101", "D", on: step >= 2)
                    Text("→ 0x4D")
                        .font(Theme.mono(11, .bold)).foregroundStyle(Theme.amber)
                        .opacity(step >= 2 ? 1 : 0)
                }

                Text("each nibble (4 bits) is exactly one hex digit — so one byte is two hex chars")
                    .font(Theme.mono(7)).foregroundStyle(Theme.textDim)
                    .multilineTextAlignment(.center).frame(width: 288)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.35), value: step)
        }
    }
}

// MARK: 2 — Endianness

/// The same 32-bit value stored two ways. Big-endian writes the most-significant
/// byte to the lowest address; little-endian (x86/ARM) reverses it — the reason
/// a hex dump of an integer often looks "backwards".
struct EndiannessView: View {
    private let bytes = ["1A", "2B", "3C", "4D"]   // 0x1A2B3C4D, index 0 = MSB

    var body: some View {
        LoopingTimeline(period: 7) { p in
            let little = p >= 0.5
            let order = little ? [3, 2, 1, 0] : [0, 1, 2, 3]
            let accent = little ? Theme.violet : Theme.amber
            VStack(spacing: 12) {
                Text("HOW BYTES SIT IN MEMORY")
                    .font(Theme.mono(9, .bold)).foregroundStyle(Theme.teal)

                Text("0x1A2B3C4D")
                    .font(Theme.mono(16, .bold)).foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 12).padding(.vertical, 4)
                    .background(Theme.teal.opacity(0.14), in: RoundedRectangle(cornerRadius: 6))

                Text(little ? "LITTLE-ENDIAN" : "BIG-ENDIAN")
                    .font(Theme.mono(11, .bold)).foregroundStyle(accent)

                HStack(spacing: 7) {
                    ForEach(0..<4, id: \.self) { addr in
                        VStack(spacing: 3) {
                            Text("+\(addr)").font(Theme.mono(7.5)).foregroundStyle(Theme.textDim)
                            Text(bytes[order[addr]])
                                .font(Theme.mono(13, .bold)).foregroundStyle(.black)
                                .frame(width: 42, height: 34)
                                .background(accent, in: RoundedRectangle(cornerRadius: 6))
                                .shadow(color: accent.opacity(0.55), radius: 5)
                        }
                    }
                }
                Text("← low address        high address →")
                    .font(Theme.mono(6.5)).foregroundStyle(Theme.textDim)

                Text(little
                     ? "x86 & ARM store the least-significant byte first"
                     : "network byte order (and many CPUs) stores the most-significant byte first")
                    .font(Theme.mono(7)).foregroundStyle(Theme.textDim)
                    .multilineTextAlignment(.center).frame(width: 282)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.4), value: little)
        }
    }
}

// MARK: 3 — Character encoding (ASCII / Unicode / UTF-8)

/// Characters aren't bytes — they're code points that get *encoded* into bytes.
/// Reveal three characters that take 1, 2 and 3 UTF-8 bytes so the "why is my
/// emoji four bytes?" mystery disappears.
struct CharEncodingView: View {
    private let rows: [(String, String, Int, String)] = [
        ("A", "U+0041", 1, "41"),
        ("é", "U+00E9", 2, "C3 A9"),
        ("→", "U+2192", 3, "E2 86 92")
    ]

    var body: some View {
        LoopingTimeline(period: 7.5) { p in
            let active = min(rows.count - 1, Int(p * Double(rows.count)))
            VStack(spacing: 9) {
                Text("CHARACTER → CODE POINT → UTF-8 BYTES")
                    .font(Theme.mono(8.5, .bold)).foregroundStyle(Theme.teal)
                    .frame(maxWidth: .infinity)

                ForEach(0..<rows.count, id: \.self) { i in
                    let on = i <= active
                    HStack(spacing: 8) {
                        Text(rows[i].0)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(on ? Theme.textPrimary : Theme.textDim)
                            .frame(width: 30)
                        Text(rows[i].1)
                            .font(Theme.mono(10, .bold))
                            .foregroundStyle(on ? Theme.amber : Theme.textDim)
                            .frame(width: 66, alignment: .leading)
                        HStack(spacing: 4) {
                            ForEach(Array(rows[i].3.split(separator: " ").enumerated()), id: \.offset) { _, b in
                                Text(String(b))
                                    .font(Theme.mono(9.5, .bold)).foregroundStyle(.black)
                                    .padding(.horizontal, 5).padding(.vertical, 2)
                                    .background(on ? Theme.teal : Theme.surfaceHi, in: RoundedRectangle(cornerRadius: 4))
                            }
                        }
                        Spacer(minLength: 0)
                        Text("\(rows[i].2)B")
                            .font(Theme.mono(8, .bold))
                            .foregroundStyle(on ? Theme.violet : Theme.textDim)
                    }
                    .opacity(on ? 1 : 0.4)
                }

                Text("ASCII covers U+0000–007F in one byte; UTF-8 extends to all of Unicode in 1–4 bytes")
                    .font(Theme.mono(7)).foregroundStyle(Theme.textDim)
                    .multilineTextAlignment(.center).frame(width: 290)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.35), value: active)
        }
    }
}

// MARK: 4 — Linux file permissions

/// Turn the `-rwxr-xr--` string every Linux box shows into the octal `754` a
/// developer types into `chmod`. Light owner, then group, then other, summing
/// r=4 w=2 x=1 for each triple.
struct FilePermissionsView: View {
    private let groups: [(String, [Bool], Int)] = [
        ("owner", [true, true, true],  7),
        ("group", [true, false, true], 5),
        ("other", [true, false, false], 4)
    ]
    private let letters = ["r", "w", "x"]

    var body: some View {
        LoopingTimeline(period: 6) { p in
            let active = min(groups.count - 1, Int(p * Double(groups.count)))
            VStack(spacing: 12) {
                Text("READING  -rwxr-xr--")
                    .font(Theme.mono(10, .bold)).foregroundStyle(Theme.teal)

                HStack(spacing: 14) {
                    ForEach(0..<groups.count, id: \.self) { g in
                        let on = g <= active
                        VStack(spacing: 5) {
                            Text(groups[g].0).font(Theme.mono(8, .bold))
                                .foregroundStyle(on ? Theme.textPrimary : Theme.textDim)
                            HStack(spacing: 3) {
                                ForEach(0..<3, id: \.self) { b in
                                    let bit = groups[g].1[b]
                                    Text(bit ? letters[b] : "-")
                                        .font(Theme.mono(11, .bold))
                                        .foregroundStyle(bit && on ? .black : Theme.textDim)
                                        .frame(width: 20, height: 22)
                                        .background(bit && on ? Theme.teal : Theme.surfaceHi,
                                                    in: RoundedRectangle(cornerRadius: 4))
                                }
                            }
                            Text("\(groups[g].2)")
                                .font(Theme.mono(16, .bold))
                                .foregroundStyle(on ? Theme.amber : Theme.textDim)
                        }
                    }
                }

                Text("chmod 754 file")
                    .font(Theme.mono(11, .bold)).foregroundStyle(Theme.green)
                    .opacity(active >= 2 ? 1 : 0)

                Text("each rwx triple is one octal digit: r=4, w=2, x=1 — add them up")
                    .font(Theme.mono(7)).foregroundStyle(Theme.textDim)
                    .multilineTextAlignment(.center).frame(width: 286)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.35), value: active)
        }
    }
}

// MARK: 5 — Boolean / bitwise logic gates

/// Cycle the four input combinations through AND, OR, XOR and NOT so the truth
/// tables become muscle memory — the operations behind masking flags, combining
/// keys and the XOR at the heart of stream ciphers.
struct BooleanLogicView: View {
    private let inputs: [(Int, Int)] = [(0, 0), (0, 1), (1, 0), (1, 1)]

    var body: some View {
        LoopingTimeline(period: 8) { p in
            let idx = min(3, Int(p * 4))
            let a = inputs[idx].0, b = inputs[idx].1
            VStack(spacing: 12) {
                Text("BITWISE LOGIC GATES")
                    .font(Theme.mono(9, .bold)).foregroundStyle(Theme.teal)

                HStack(spacing: 16) {
                    bitCell9("A", a)
                    bitCell9("B", b)
                }

                HStack(spacing: 9) {
                    gate9("AND", a & b, Theme.blue)
                    gate9("OR",  a | b, Theme.teal)
                    gate9("XOR", a ^ b, Theme.magenta)
                    gate9("¬A",  a == 0 ? 1 : 0, Theme.amber)
                }

                Text("AND = both · OR = either · XOR = differ · NOT = flip — the four ops under every mask & cipher")
                    .font(Theme.mono(7)).foregroundStyle(Theme.textDim)
                    .multilineTextAlignment(.center).frame(width: 292)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.3), value: idx)
        }
    }
}

// MARK: 6 — Salted hashing

/// Two users pick the same weak password. Toggle between unsalted (identical
/// hashes — crack one, crack both) and salted (a unique random salt per user, so
/// the digests diverge and precomputed rainbow tables are worthless).
struct SaltHashingView: View {
    var body: some View {
        LoopingTimeline(period: 7) { p in
            let salted = p >= 0.5
            VStack(spacing: 11) {
                Text(salted ? "WITH A PER-USER SALT" : "WITHOUT SALT")
                    .font(Theme.mono(10, .bold))
                    .foregroundStyle(salted ? Theme.green : Theme.red)

                userRow9("alice", "hunter2", salted ? "·f3a9" : "", salted ? "1a2f…9c" : "9b74…e1", salted)
                userRow9("bob",   "hunter2", salted ? "·7c1e" : "", salted ? "b833…40" : "9b74…e1", salted)

                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: salted ? "checkmark.seal.fill" : "xmark.octagon.fill")
                        .foregroundStyle(salted ? Theme.green : Theme.red)
                    Text(salted
                         ? "same password → different hashes: rainbow tables are useless"
                         : "same password → identical hash: crack one and you've cracked both")
                        .foregroundStyle(salted ? Theme.green : Theme.red)
                }
                .font(Theme.mono(8, .bold))
                .frame(width: 288)

                Text("a salt is unique random data mixed in before hashing — not a secret, just a de-duplicator")
                    .font(Theme.mono(7)).foregroundStyle(Theme.textDim)
                    .multilineTextAlignment(.center).frame(width: 288)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.4), value: salted)
        }
    }
}
