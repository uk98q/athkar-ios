import SwiftUI

@main
struct AthkarApp: App {
    @StateObject private var store = ProgressStore()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView()
            }
            .environmentObject(store)
            .environment(\.layoutDirection, .rightToLeft)
            .preferredColorScheme(.dark)
            .tint(Theme.morningAccent)
        }
    }
}
