import SwiftUI

@main
struct PayflowiOSApp: App {
    @StateObject private var settingsStore = SalarySettingsStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(settingsStore)
        }
    }
}
