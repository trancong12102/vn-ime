import SwiftUI

@main
struct LotusKeyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Settings window (opened via menu)
        Settings {
            SettingsView()
        }
    }
}
