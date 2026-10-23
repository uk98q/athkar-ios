import SwiftUI

@main
struct MuslimApp: App {
    @StateObject private var store = ProgressStore()
    @StateObject private var location = LocationService()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(store)
                .environmentObject(location)
                .environment(\.layoutDirection, .rightToLeft)
                .preferredColorScheme(.dark)
                .tint(Theme.dawn)
        }
    }
}
