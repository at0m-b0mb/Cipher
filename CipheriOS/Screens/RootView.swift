import SwiftUI

/// Type-safe navigation targets shared by every stack.
enum CipherRoute: Hashable {
    case track(String)
    case lesson(String)
}

/// A NavigationStack pre-wired with the app's route destinations, so each tab
/// resolves `.track` / `.lesson` links the same way.
struct NavStack<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        NavigationStack {
            content
                .navigationDestination(for: CipherRoute.self) { route in
                    switch route {
                    case .track(let id):  TrackDetailView(trackID: id)
                    case .lesson(let id): LessonView(lessonID: id)
                    }
                }
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var progress: ProgressStore
    @State private var tab = Int(ProcessInfo.processInfo.environment["CIPHER_TAB"] ?? "") ?? 0
    // Demo-only deep link (set via CIPHER_LESSON env) for screenshots/previews.
    @State private var demoLesson = ProcessInfo.processInfo.environment["CIPHER_LESSON"] ?? ""

    var body: some View {
        TabView(selection: $tab) {
            NavStack { DashboardView(goToLearn: { tab = 1 }) }
                .tag(0)
                .tabItem { Label("Home", systemImage: "house.fill") }

            NavStack { TracksView() }
                .tag(1)
                .tabItem { Label("Learn", systemImage: "books.vertical.fill") }

            NavStack { AnimationGalleryView() }
                .tag(2)
                .tabItem { Label("Animations", systemImage: "play.square.stack.fill") }

            NavStack { ProfileView() }
                .tag(3)
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
        }
        .tint(Theme.teal)
        .fullScreenCover(isPresented: Binding(get: { !demoLesson.isEmpty },
                                              set: { if !$0 { demoLesson = "" } })) {
            NavigationStack {
                LessonView(lessonID: demoLesson)
                    .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Close") { demoLesson = "" } } }
            }
        }
    }
}
