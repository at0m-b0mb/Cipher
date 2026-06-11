import SwiftUI

private struct Staged<Content: View>: View {
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

// MARK: - SEH overflow

/// Structured Exception Handler overwrite: the overflow clobbers the nSEH /
/// handler pair, then a thrown exception runs the attacker's pop-pop-ret gadget,
/// which lands back on nSEH's short jump into the shellcode.
struct SEHOverflowView: View {
    private let cells: [(label: String, base: Color)] = [
        ("buffer[128]", Theme.teal),
        ("nSEH", Theme.blue),
        ("SE Handler", Theme.amber),
        ("outer frame", Theme.violet)
    ]
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let n = cells.count
            let cellH = (h - 40) / CGFloat(n)
            LoopingTimeline(period: 7) { p in
                let fill = ease(CGFloat(min(max((p - 0.1) / 0.55, 0), 1))) * CGFloat(n)
                let sehHit = fill > 2.4
                ZStack {
                    ForEach(cells.indices, id: \.self) { i in
                        let y = h - 24 - (CGFloat(i) + 0.5) * cellH
                        let overflowed = fill > CGFloat(i) + 0.4
                        let text: String = {
                            if i == 1 && sehHit { return "EB 06  (jmp +6)" }
                            if i == 2 && sehHit { return "pop;pop;ret" }
                            if i == 0 && overflowed { return "AAAA…" }
                            if i == 3 { return cells[i].label }
                            return overflowed ? "AAAA…" : cells[i].label
                        }()
                        let color = ((i == 1 || i == 2) && sehHit) ? Theme.red : cells[i].base
                        cell(text: text, color: color, overflowed: overflowed && i < 3, cellH: cellH, width: w)
                            .position(x: w * 0.42, y: y)
                    }
                    if sehHit {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("exception →").font(Theme.mono(7.5, .bold)).foregroundStyle(Theme.red)
                            Text("pop;pop;ret").font(Theme.mono(7.5, .bold)).foregroundStyle(Theme.red)
                            Text("→ nSEH jmp").font(Theme.mono(7.5, .bold)).foregroundStyle(Theme.amber)
                            Text("→ shellcode").font(Theme.mono(7.5, .bold)).foregroundStyle(Theme.green)
                        }
                        .position(x: w * 0.85, y: h * 0.45)
                    }
                    Text("overflow clobbers the SEH chain → exception hijacks execution")
                        .font(Theme.mono(7.5)).foregroundStyle(Theme.textDim)
                        .position(x: w * 0.5, y: h - 8)
                }
            }
        }
    }
    private func cell(text: String, color: Color, overflowed: Bool, cellH: CGFloat, width: CGFloat) -> some View {
        Text(text)
            .font(Theme.mono(9.5, .bold))
            .foregroundStyle(overflowed ? .black : Theme.textPrimary)
            .frame(width: width * 0.6, height: cellH - 6)
            .background((overflowed ? color : Theme.surfaceHi), in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(color.opacity(0.7), lineWidth: 1))
            .shadow(color: overflowed ? color.opacity(0.5) : .clear, radius: 5)
    }
}

// MARK: - Format string

struct FormatStringView: View {
    var body: some View {
        Staged(steps: 3) { step in
            VStack(alignment: .leading, spacing: 11) {
                fieldBox("VULNERABLE CALL", tint: Theme.amber.opacity(0.6)) {
                    (Text("printf(").foregroundColor(Theme.textSecondary)
                     + Text("user_input").foregroundColor(Theme.red)
                     + Text(")  ").foregroundColor(Theme.textSecondary)
                     + Text("// not printf(\"%s\", …)").foregroundColor(Theme.textDim))
                        .font(Theme.mono(9.5, .bold))
                        .fixedSize(horizontal: false, vertical: true)
                }
                fieldBox("INPUT", tint: step >= 2 ? Theme.red.opacity(0.6) : Theme.stroke) {
                    Text(step >= 2 ? "AAAA%n" : "%x %x %x %x")
                        .font(Theme.mono(10, .bold)).foregroundStyle(step >= 2 ? Theme.red : Theme.amber)
                }
                fieldBox(step >= 2 ? "EFFECT" : "OUTPUT", tint: step >= 1 ? Theme.red.opacity(0.5) : Theme.stroke) {
                    Group {
                        if step >= 2 {
                            Text("writes a value to address 0x41414141")
                                .foregroundStyle(Theme.red)
                        } else if step >= 1 {
                            Text("7ffd0a18 41414141 0804a0c0 …")
                                .foregroundStyle(Theme.green)
                        } else {
                            Text("(reads its own stack as arguments)")
                                .foregroundStyle(Theme.textDim)
                        }
                    }
                    .font(Theme.mono(9, .bold)).fixedSize(horizontal: false, vertical: true)
                }
                if step >= 1 && step < 2 {
                    Text("%x leaks the stack → memory disclosure")
                        .font(Theme.mono(8.5, .bold)).foregroundStyle(Theme.amber)
                }
                if step >= 3 {
                    Text("%n gives an arbitrary write → overwrite a GOT entry → control flow")
                        .font(Theme.mono(8.5, .bold)).foregroundStyle(Theme.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
    }
    private func fieldBox<C: View>(_ caption: String, tint: Color, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(caption).font(Theme.mono(8, .bold)).tracking(0.6).foregroundStyle(Theme.textDim)
            content()
                .padding(8).frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surfaceHi, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(tint, lineWidth: 1))
        }
    }
}

// MARK: - Heap exploitation (use-after-free)

struct HeapExploitView: View {
    var body: some View {
        Staged(steps: 3) { step in
            VStack(alignment: .leading, spacing: 12) {
                Text("HEAP").font(Theme.mono(8, .bold)).foregroundStyle(Theme.textDim)
                HStack(spacing: 8) {
                    chunk(title: "Object A",
                          line: step >= 2 ? "fn → system()" : "fn → render()",
                          c: step == 0 ? Theme.blue : step == 1 ? Theme.textDim : Theme.red,
                          ghost: step == 1)
                    chunk(title: "Object B", line: "data", c: Theme.violet, ghost: false)
                }
                // dangling pointer
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.forward").foregroundStyle(step >= 1 ? Theme.red : Theme.textDim)
                    Text(step == 0 ? "ptr → A (valid)"
                       : step == 1 ? "free(A) — ptr now dangles"
                       : "ptr still used → points at attacker data")
                        .font(Theme.mono(9, .bold))
                        .foregroundStyle(step == 0 ? Theme.textSecondary : step == 1 ? Theme.amber : Theme.red)
                }

                if step >= 2 {
                    Text("malloc(sizeof A) reclaims the freed slot with attacker bytes")
                        .font(Theme.mono(8.5, .bold)).foregroundStyle(Theme.amber)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if step >= 3 {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill").foregroundStyle(Theme.red)
                        Text("A->fn() called → use-after-free → attacker code runs")
                            .font(Theme.mono(9, .bold)).foregroundStyle(Theme.red)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }
    private func chunk(title: String, line: String, c: Color, ghost: Bool) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(Theme.mono(9, .bold)).foregroundStyle(ghost ? Theme.textDim : Theme.textPrimary)
            Text(line).font(Theme.mono(8.5)).foregroundStyle(c)
        }
        .padding(9)
        .frame(width: 120, alignment: .leading)
        .background((ghost ? Theme.surfaceHi.opacity(0.4) : c.opacity(0.12)), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8)
            .strokeBorder(ghost ? Theme.stroke : c.opacity(0.7), style: StrokeStyle(lineWidth: 1, dash: ghost ? [3, 3] : [])))
    }
}
