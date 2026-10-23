import SwiftUI

@main
struct AthkarApp: App {
    @StateObject private var store = ProgressStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .environment(\.layoutDirection, .rightToLeft)
                .preferredColorScheme(.dark)
                .tint(Theme.dawn)
        }
    }
}

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("الرئيسية", systemImage: "house.fill")
            }

            NavigationStack {
                AdhkarIndexView()
            }
            .tabItem {
                Label("الأذكار", systemImage: "text.book.closed.fill")
            }

            NavigationStack {
                TasbihView()
            }
            .tabItem {
                Label("المسبحة", systemImage: "hand.tap.fill")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("الإعدادات", systemImage: "slider.horizontal.3")
            }
        }
    }
}
