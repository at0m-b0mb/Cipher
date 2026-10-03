import SwiftUI

/// The Practice tab: the two things you *do* rather than read — hands-on labs and
/// the animation gallery. Segmented rather than two tabs, so the tab bar stays at
/// five items (a sixth would collapse into an iOS "More" tab).
struct PracticeView: View {
    private enum Mode: String, CaseIterable {
        case labs = "Labs"
        case animations = "Animations"
    }

    @State private var mode: Mode = .labs

    var body: some View {
        ZStack {
            CircuitBackground(tint: mode == .labs ? Theme.green : Theme.violet)
            VStack(spacing: 0) {
                Picker("", selection: $mode) {
                    ForEach(Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 12)

                switch mode {
                case .labs:       LabsView().padding(.horizontal, 18)
                case .animations: AnimationGalleryView(embedded: true)
                }
            }
        }
        .navigationTitle("")
        .toolbar(.hidden, for: .navigationBar)
    }
}
