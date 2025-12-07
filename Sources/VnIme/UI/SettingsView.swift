import SwiftUI

/// Modern Settings view for VnIme - macOS 2025 design patterns
/// Two tabs: General (all settings) and About (app info)
struct SettingsView: View {
    // Input method settings
    @AppStorage(SettingsKey.inputMethod.rawValue) private var inputMethod = "Telex"
    @AppStorage(SettingsKey.quickTelexEnabled.rawValue) private var quickTelexEnabled = true
    @AppStorage(SettingsKey.autoCapitalize.rawValue) private var autoCapitalize = true

    // Spelling settings
    @AppStorage(SettingsKey.spellCheckEnabled.rawValue) private var spellCheckEnabled = true
    @AppStorage(SettingsKey.restoreIfWrongSpelling.rawValue) private var restoreIfWrongSpelling = true

    // Features
    @AppStorage(SettingsKey.smartSwitchEnabled.rawValue) private var smartSwitchEnabled = true

    // Startup settings
    @AppStorage(SettingsKey.launchAtLogin.rawValue) private var launchAtLogin = false
    @AppStorage(SettingsKey.showDockIcon.rawValue) private var showDockIcon = false

    // Advanced settings
    @AppStorage(SettingsKey.fixBrowserAutocomplete.rawValue) private var fixBrowserAutocomplete = true
    @AppStorage(SettingsKey.fixChromiumBrowser.rawValue) private var fixChromiumBrowser = true
    @AppStorage(SettingsKey.sendKeyStepByStep.rawValue) private var sendKeyStepByStep = false

    private let inputMethods = ["Telex", "Simple Telex"]

    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 420, height: 420)
    }

    // MARK: - General Tab

    private var generalTab: some View {
        Form {
            Section {
                Picker("Input Method", selection: $inputMethod) {
                    ForEach(inputMethods, id: \.self) { method in
                        Text(method).tag(method)
                    }
                }

                Toggle(isOn: $quickTelexEnabled) {
                    HelpLabel(
                        "Quick Telex",
                        help: "cc → ch, gg → gi\nkk → kh, ngg → ngh\nqq → qu"
                    )
                }

                Toggle("Auto-capitalize", isOn: $autoCapitalize)
            } header: {
                Label("Input", systemImage: "keyboard")
            }

            Section {
                Toggle("Spell Checking", isOn: $spellCheckEnabled)

                Toggle(isOn: $restoreIfWrongSpelling) {
                    HelpLabel(
                        "Restore Invalid Words",
                        help: "Reverts text if spelling is invalid.\nHold ⌃ Control to bypass."
                    )
                }
                .disabled(!spellCheckEnabled)
            } header: {
                Label("Spelling", systemImage: "textformat.abc")
            }

            Section {
                Toggle(isOn: $smartSwitchEnabled) {
                    HelpLabel(
                        "Smart Language Switch",
                        help: "Remembers Vietnamese or English preference for each application."
                    )
                }

                Toggle("Launch at Login", isOn: $launchAtLogin)

                Toggle("Show in Dock", isOn: $showDockIcon)
            } header: {
                Label("Behavior", systemImage: "arrow.triangle.2.circlepath")
            }

            Section {
                Toggle(isOn: $fixBrowserAutocomplete) {
                    HelpLabel(
                        "Fix Browser Autocomplete",
                        help: "Fixes input issues in browser address bars and search fields."
                    )
                }

                Toggle(isOn: $fixChromiumBrowser) {
                    HelpLabel(
                        "Fix Chromium Browsers",
                        help: "Chrome, Edge, Arc, Brave, and other Chromium-based browsers."
                    )
                }
                .disabled(!fixBrowserAutocomplete)

                Toggle(isOn: $sendKeyStepByStep) {
                    HelpLabel(
                        "Step-by-Step Mode",
                        help: "Sends keys one at a time.\nSlower but more compatible."
                    )
                }
            } header: {
                Label("Compatibility", systemImage: "puzzlepiece.extension")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - About Tab

    private var aboutTab: some View {
        VStack(spacing: 20) {
            Spacer()

            // App icon and name
            VStack(spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 80, height: 80)

                Text("VnIme")
                    .font(.title.bold())

                Text("Version \(appVersion)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Description
            Text("Vietnamese Input Method for macOS")
                .font(.callout)
                .foregroundStyle(.secondary)

            Spacer()

            // Links
            HStack(spacing: 16) {
                if let url = URL(string: "https://github.com/trancong12102/vn-ime") {
                    Link(destination: url) {
                        Label("GitHub", systemImage: "link")
                    }
                    .buttonStyle(.link)
                }
            }

            // Copyright
            Text("© 2025 Cong Tran")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Text("Licensed under GPL-3.0")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}

// MARK: - Help Label Component

/// A label with an inline help button that shows a popover on click
private struct HelpLabel: View {
    let title: String
    let help: String

    @State private var showingHelp = false

    init(_ title: String, help: String) {
        self.title = title
        self.help = help
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(title)

            Image(systemName: "questionmark.circle")
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .onTapGesture {
                    showingHelp.toggle()
                }
                .popover(isPresented: $showingHelp, arrowEdge: .trailing) {
                    Text(help)
                        .font(.callout)
                        .padding(12)
                        .frame(maxWidth: 240)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .help(help.replacingOccurrences(of: "\n", with: " "))
        }
    }
}

#Preview {
    SettingsView()
}
