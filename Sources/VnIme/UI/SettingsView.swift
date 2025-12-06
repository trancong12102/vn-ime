import SwiftUI

/// Main settings view for VnIme
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            InputMethodSettingsView()
                .tabItem {
                    Label("Input Method", systemImage: "keyboard")
                }

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 500, height: 400)
    }
}

/// General settings tab
struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showDockIcon") private var showDockIcon = false
    @AppStorage("spellCheckEnabled") private var spellCheckEnabled = true
    @AppStorage("smartSwitchEnabled") private var smartSwitchEnabled = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox("Startup") {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Launch at login", isOn: $launchAtLogin)
                    Toggle("Show Dock icon", isOn: $showDockIcon)
                }
                .padding(.vertical, 4)
            }

            GroupBox("Features") {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Enable spell checking", isOn: $spellCheckEnabled)
                    Toggle("Smart language switch per app", isOn: $smartSwitchEnabled)
                }
                .padding(.vertical, 4)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Input method settings tab
struct InputMethodSettingsView: View {
    @AppStorage("inputMethod") private var inputMethod = "Telex"
    @AppStorage("quickTelexEnabled") private var quickTelexEnabled = true
    @AppStorage("autoCapitalize") private var autoCapitalize = true

    private let inputMethods = ["Telex", "Simple Telex"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox("Input Method") {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Method", selection: $inputMethod) {
                        ForEach(inputMethods, id: \.self) { method in
                            Text(method).tag(method)
                        }
                    }

                    Toggle("Quick Telex (cc=ch, gg=gi...)", isOn: $quickTelexEnabled)
                    Toggle("Auto-capitalize first letter", isOn: $autoCapitalize)
                }
                .padding(.vertical, 4)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// About tab
struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "keyboard")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundStyle(.tint)

            Text("VnIme")
                .font(.title)
                .fontWeight(.bold)

            Text("Version 1.0.0")
                .foregroundStyle(.secondary)

            Text("Vietnamese Input Method for macOS")
                .font(.subheadline)

            Divider()
                .frame(width: 200)

            Link("GitHub Repository", destination: URL(string: "https://github.com/trancong12102/vn-ime")!)

            Text("GPL-3.0 License")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    SettingsView()
}
