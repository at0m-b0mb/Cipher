import SwiftUI
import UIKit

@main
struct CipherApp: App {
    @StateObject private var progress = ProgressStore()

    init() { Self.configureAppearance() }

    var body: some Scene {
        WindowGroup {
            Group {
                if progress.hasAcceptedEthics {
                    RootView()
                } else {
                    EthicsGateView()
                }
            }
            .environmentObject(progress)
            .preferredColorScheme(.dark)
            .tint(Theme.teal)
        }
    }

    /// Make the navigation and tab bars match the dark console aesthetic.
    private static func configureAppearance() {
        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()
        nav.titleTextAttributes = [.foregroundColor: UIColor(Theme.textPrimary)]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor(Theme.textPrimary)]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().tintColor = UIColor(Theme.teal)

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = UIColor(Theme.surface)
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
    }
}
