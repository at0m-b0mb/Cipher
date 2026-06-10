import SwiftUI

@main
struct CipherWatchApp: App {
    @StateObject private var progress = ProgressStore()

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environmentObject(progress)
                .tint(Theme.teal)
        }
    }
}
