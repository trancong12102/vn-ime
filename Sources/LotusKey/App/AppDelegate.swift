import AppKit
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: - Properties

    private var statusItem: NSStatusItem?
    private var cancellables = Set<AnyCancellable>()

    /// The Vietnamese input engine
    private var engine: DefaultVietnameseEngine?

    /// The keyboard event handler
    private var eventHandler: KeyboardEventHandler?

    /// Text injector for sending characters to applications
    private var textInjector: TextInjector?

    /// Application detector for quirks handling
    private var applicationDetector: ApplicationDetector?

    /// Hotkey detector for language switching
    private var hotkeyDetector: HotkeyDetector?

    /// Input source detector for other language bypass
    private var inputSourceDetector: InputSourceDetector?

    /// Keyboard layout converter for non-QWERTY layouts
    private var layoutConverter: KeyboardLayoutConverter?

    /// Smart switch for per-application language memory
    private var smartSwitch: SmartSwitch?

    /// Track previous app for smart switch save on app change
    private var previousAppBundleId: String?

    /// Settings store
    private let settings = SettingsStore()

    /// Current language mode menu item
    private var languageModeItem: NSMenuItem?

    /// Input method menu items
    private var telexMenuItem: NSMenuItem?
    private var simpleTelexMenuItem: NSMenuItem?

    // MARK: - App Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        applyLifecycleSettings()
        setupMenuBar()
        setupEventHandler()
        setupSettingsWindowObserver()
    }

    /// Observe Settings window close to restore activation policy
    private func setupSettingsWindowObserver() {
        NotificationCenter.default.publisher(for: .settingsWindowClosed)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                // Restore accessory mode if user prefers hidden dock icon
                if !self.settings.showDockIcon {
                    AppLifecycleManager.shared.setDockIconVisible(false)
                }
            }
            .store(in: &cancellables)
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup resources
        eventHandler?.stop()
        applicationDetector?.stopMonitoring()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Menu bar app should continue running even when all windows are closed
        print("[LotusKey] applicationShouldTerminateAfterLastWindowClosed called - returning false")
        return false
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        print("[LotusKey] applicationShouldTerminate called")
        // Check if this is an unexpected termination
        if eventHandler == nil {
            print("[LotusKey] WARNING: Termination requested before event handler initialized")
        }
        return .terminateNow
    }

    // MARK: - Lifecycle Settings

    private func applyLifecycleSettings() {
        // Apply dock icon setting
        AppLifecycleManager.shared.setDockIconVisible(settings.showDockIcon)

        // Note: SMAppService.mainApp requires the app to be properly code-signed
        // and may crash in development builds. We skip the sync in debug builds.
        #if !DEBUG
        // Sync launch at login setting with actual system state
        // User might have changed it in System Settings directly
        let actuallyEnabled = AppLifecycleManager.shared.isLaunchAtLoginEnabled
        if settings.launchAtLogin != actuallyEnabled {
            // Update stored setting to match system state (without triggering another registration)
            let defaults = UserDefaults.standard
            defaults.set(actuallyEnabled, forKey: SettingsKey.launchAtLogin.rawValue)
        }

        // If launch at login requires approval, we could show a hint to the user
        // but for now we just log it
        if AppLifecycleManager.shared.launchAtLoginRequiresApproval {
            print("Launch at login requires approval in System Settings > Login Items")
        }
        #endif
    }

    // MARK: - Menu Bar Setup

    private func setupMenuBar() {
        // Use fixed width matching macOS native input source icons
        statusItem = NSStatusBar.system.statusItem(withLength: 28)

        updateMenuBarIcon(isVietnameseMode: true)

        let menu = NSMenu()

        // Language mode toggle
        languageModeItem = NSMenuItem(
            title: L("Enable Vietnamese Typing"),
            action: #selector(toggleLanguageMode),
            keyEquivalent: ""
        )
        languageModeItem?.target = self
        languageModeItem?.state = .on
        menu.addItem(languageModeItem!)

        menu.addItem(NSMenuItem.separator())

        // Input method selection
        telexMenuItem = NSMenuItem(
            title: L("Telex"),
            action: #selector(selectTelex),
            keyEquivalent: ""
        )
        telexMenuItem?.target = self
        menu.addItem(telexMenuItem!)

        simpleTelexMenuItem = NSMenuItem(
            title: L("Simple Telex"),
            action: #selector(selectSimpleTelex),
            keyEquivalent: ""
        )
        simpleTelexMenuItem?.target = self
        menu.addItem(simpleTelexMenuItem!)

        updateInputMethodMenuItems()

        menu.addItem(NSMenuItem.separator())

        // Settings
        let settingsItem = NSMenuItem(
            title: L("Settings..."),
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        menu.addItem(settingsItem)

        // About
        let aboutItem = NSMenuItem(
            title: L("About LotusKey"),
            action: #selector(openAbout),
            keyEquivalent: ""
        )
        aboutItem.image = NSImage(systemSymbolName: "info.circle", accessibilityDescription: nil)
        menu.addItem(aboutItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        menu.addItem(NSMenuItem(
            title: L("Quit LotusKey"),
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        statusItem?.menu = menu
    }

    private func updateMenuBarIcon(isVietnameseMode: Bool) {
        if let button = statusItem?.button {
            button.image = Self.createMenuBarIcon(isVietnameseMode: isVietnameseMode)
        }
    }

    // MARK: - Menu Bar Icon Constants

    /// Menu bar icon dimensions matching macOS native input source style
    private enum MenuBarIconStyle {
        /// Icon dimensions (matches macOS input source indicator)
        static let iconWidth: CGFloat = 22
        static let iconHeight: CGFloat = 16
        /// Corner radius for the rounded rectangle
        static let cornerRadius: CGFloat = 4.5
        /// Stroke width for outline mode
        static let strokeWidth: CGFloat = 1.25
        /// Font size for the language label
        static let fontSize: CGFloat = 11
        /// Font weight for the language label
        static let fontWeight: NSFont.Weight = .semibold
    }

    /// Creates a menu bar icon matching macOS native input source style
    /// - Vietnamese mode: "VI" filled (like macOS active input source)
    /// - English mode: "EN" not filled (outline only)
    private static func createMenuBarIcon(isVietnameseMode: Bool) -> NSImage {
        // Fixed icon size matching macOS native input source
        let iconSize = NSSize(width: MenuBarIconStyle.iconWidth, height: MenuBarIconStyle.iconHeight)
        // Canvas size: width matches icon, height is standard menu bar working area (22pt)
        let canvasSize = NSSize(width: iconSize.width, height: 22)

        let image = NSImage(size: canvasSize, flipped: false) { canvasRect in
            // Center the icon within the 22pt canvas (standard menu bar height)
            let iconRect = NSRect(
                x: (canvasRect.width - iconSize.width) / 2,
                y: (canvasRect.height - iconSize.height) / 2,
                width: iconSize.width,
                height: iconSize.height
            )

            if isVietnameseMode {
                Self.drawFilledIcon(text: "VI", in: iconRect)
            } else {
                Self.drawOutlineIcon(text: "EN", in: iconRect)
            }
            return true
        }

        image.isTemplate = true
        return image
    }

    /// Draws filled icon like macOS native input source (active state)
    /// Uses knockout effect: text is cut out from the filled rectangle
    private static func drawFilledIcon(text: String, in rect: NSRect) {
        // Draw filled rounded rectangle background
        let bgPath = NSBezierPath(
            roundedRect: rect,
            xRadius: MenuBarIconStyle.cornerRadius,
            yRadius: MenuBarIconStyle.cornerRadius
        )
        NSColor.black.setFill()
        bgPath.fill()

        // Knockout text: use destinationOut compositing to cut text from background
        let font = NSFont.systemFont(ofSize: MenuBarIconStyle.fontSize, weight: MenuBarIconStyle.fontWeight)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.black,
        ]

        let textSize = text.size(withAttributes: attributes)
        let textPoint = NSPoint(
            x: rect.midX - textSize.width / 2,
            y: rect.midY - textSize.height / 2
        )

        // Cut text shape out of the background
        NSGraphicsContext.current?.compositingOperation = .destinationOut
        text.draw(at: textPoint, withAttributes: attributes)
        NSGraphicsContext.current?.compositingOperation = .sourceOver
    }

    /// Draws outline icon (inactive state) - rounded rectangle outline with text inside
    private static func drawOutlineIcon(text: String, in rect: NSRect) {
        // Inset for stroke (half of stroke width on each side)
        let insetRect = rect.insetBy(
            dx: MenuBarIconStyle.strokeWidth / 2,
            dy: MenuBarIconStyle.strokeWidth / 2
        )

        // Draw rounded rectangle outline (stroke only, not filled)
        let outlinePath = NSBezierPath(
            roundedRect: insetRect,
            xRadius: MenuBarIconStyle.cornerRadius,
            yRadius: MenuBarIconStyle.cornerRadius
        )
        outlinePath.lineWidth = MenuBarIconStyle.strokeWidth
        NSColor.black.setStroke()
        outlinePath.stroke()

        // Draw text centered inside the outline
        let font = NSFont.systemFont(ofSize: MenuBarIconStyle.fontSize, weight: MenuBarIconStyle.fontWeight)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.black,
        ]

        let textSize = text.size(withAttributes: attributes)
        let textPoint = NSPoint(
            x: rect.midX - textSize.width / 2,
            y: rect.midY - textSize.height / 2
        )
        text.draw(at: textPoint, withAttributes: attributes)
    }

    private func updateLanguageModeMenuItem(isVietnameseMode: Bool) {
        languageModeItem?.state = isVietnameseMode ? .on : .off
        updateMenuBarIcon(isVietnameseMode: isVietnameseMode)
    }

    // MARK: - Event Handler Setup

    private func setupEventHandler() {
        // Check accessibility permission first
        if !AXIsProcessTrusted() {
            AccessibilityPermissionWindowController.shared.show { [weak self] in
                self?.initializeEventHandler()
            }
            return
        }

        initializeEventHandler()
    }

    private func initializeEventHandler() {
        // Create engine
        let engine = DefaultVietnameseEngine()
        self.engine = engine

        // Configure engine based on settings
        engine.spellCheckEnabled = settings.spellCheckEnabled
        engine.quickTelex.isEnabled = settings.quickTelexEnabled
        engine.restoreIfWrongSpelling = settings.restoreIfWrongSpelling

        // Set input method based on settings
        if settings.inputMethod == "Simple Telex" {
            engine.setInputMethod(SimpleTelexInputMethod())
        } else {
            engine.setInputMethod(TelexInputMethod())
        }

        // Create event handler
        let handler = KeyboardEventHandler(engine: engine)
        self.eventHandler = handler

        // Start handler first to create the event source
        do {
            try handler.start()
        } catch {
            print("Failed to start event handler: \(error.localizedDescription)")
            showError("Failed to start LotusKey: \(error.localizedDescription)")
            return
        }

        // Create TextInjector with shared event source (important for own-event filtering)
        guard let eventSource = handler.eventSource,
              let injector = TextInjector(eventSource: eventSource) else {
            print("Failed to create TextInjector with shared event source")
            handler.stop()
            return
        }
        self.textInjector = injector

        // Apply advanced settings to TextInjector
        injector.fixBrowserAutocomplete = settings.fixBrowserAutocomplete
        injector.fixChromiumBrowser = settings.fixChromiumBrowser
        injector.sendKeyStepByStep = settings.sendKeyStepByStep

        let appDetector = ApplicationDetector()
        self.applicationDetector = appDetector

        let hotkey = HotkeyDetector()
        self.hotkeyDetector = hotkey

        let inputSource = InputSourceDetector()
        self.inputSourceDetector = inputSource

        let layout = KeyboardLayoutConverter()
        self.layoutConverter = layout

        // Configure handler with dependencies
        handler.configure(
            textInjector: injector,
            applicationDetector: appDetector,
            hotkeyDetector: hotkey,
            inputSourceDetector: inputSource,
            layoutConverter: layout
        )

        // Start monitoring applications
        appDetector.startMonitoring()

        // Initialize SmartSwitch
        let smartSwitch = SmartSwitch()
        self.smartSwitch = smartSwitch

        // Capture initial app for smart switch (so first app switch saves correctly)
        previousAppBundleId = appDetector.currentBundleIdentifier

        // Subscribe to application changes for quirks and smart switch
        appDetector.applicationChanged
            .receive(on: DispatchQueue.main)
            .sink { [weak self] bundleId in
                self?.handleAppChange(newBundleId: bundleId)
            }
            .store(in: &cancellables)

        // Subscribe to language mode changes from keyboard handler (hotkey toggles)
        handler.languageModeChanged
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isVietnamese in
                self?.handleLanguageModeChange(isVietnamese)
            }
            .store(in: &cancellables)

        // Subscribe to settings changes
        settings.settingsChanged
            .receive(on: DispatchQueue.main)
            .sink { [weak self] key in
                self?.handleSettingsChange(key)
            }
            .store(in: &cancellables)

        print("LotusKey event handler started successfully")
    }

    // MARK: - Settings Handling

    private func handleSettingsChange(_ key: SettingsKey) {
        guard let engine = engine, eventHandler != nil else { return }

        switch key {
        case .inputMethod:
            if settings.inputMethod == "Simple Telex" {
                engine.setInputMethod(SimpleTelexInputMethod())
            } else {
                engine.setInputMethod(TelexInputMethod())
            }
        case .spellCheckEnabled:
            engine.spellCheckEnabled = settings.spellCheckEnabled
        case .quickTelexEnabled:
            engine.quickTelex.isEnabled = settings.quickTelexEnabled
        case .restoreIfWrongSpelling:
            engine.restoreIfWrongSpelling = settings.restoreIfWrongSpelling
        case .fixBrowserAutocomplete:
            textInjector?.fixBrowserAutocomplete = settings.fixBrowserAutocomplete
        case .fixChromiumBrowser:
            textInjector?.fixChromiumBrowser = settings.fixChromiumBrowser
        case .sendKeyStepByStep:
            textInjector?.sendKeyStepByStep = settings.sendKeyStepByStep
        case .smartSwitchEnabled:
            // When enabled, save current mode for current app
            if settings.smartSwitchEnabled,
               let handler = eventHandler,
               let smartSwitch = smartSwitch,
               let bundleId = applicationDetector?.currentBundleIdentifier {
                smartSwitch.setVietnameseEnabled(handler.isVietnameseMode, for: bundleId)
            }
        default:
            break
        }
    }

    private func updateAppQuirks() {
        guard let appDetector = applicationDetector, let injector = textInjector else { return }
        injector.setAppQuirk(appDetector.currentAppQuirk)
    }

    // MARK: - Smart Switch

    private func handleAppChange(newBundleId: String?) {
        // Always update app quirks
        updateAppQuirks()

        guard settings.smartSwitchEnabled,
              let handler = eventHandler,
              let smartSwitch = smartSwitch,
              let newBundleId = newBundleId else {
            previousAppBundleId = newBundleId
            return
        }

        // Save current language mode for previous app (if exists)
        if let prevId = previousAppBundleId {
            smartSwitch.setVietnameseEnabled(handler.isVietnameseMode, for: prevId)
        }

        // Restore or save for new app
        if smartSwitch.hasPreference(for: newBundleId) {
            // Restore saved preference (direct set, no publish)
            let savedMode = smartSwitch.shouldEnableVietnamese(for: newBundleId)
            if handler.isVietnameseMode != savedMode {
                handler.isVietnameseMode = savedMode
                engine?.reset()  // Reset engine when mode changes
            }
            updateLanguageModeMenuItem(isVietnameseMode: savedMode)
        } else {
            // First time seeing this app - save current mode
            smartSwitch.setVietnameseEnabled(handler.isVietnameseMode, for: newBundleId)
        }

        previousAppBundleId = newBundleId
    }

    private func handleLanguageModeChange(_ isVietnamese: Bool) {
        // Update menu bar
        updateLanguageModeMenuItem(isVietnameseMode: isVietnamese)

        // Save preference for current app if smart switch is enabled
        guard settings.smartSwitchEnabled,
              let smartSwitch = smartSwitch,
              let currentBundleId = applicationDetector?.currentBundleIdentifier else {
            return
        }

        smartSwitch.setVietnameseEnabled(isVietnamese, for: currentBundleId)
    }

    // MARK: - Actions

    @objc private func toggleLanguageMode() {
        guard let handler = eventHandler else { return }
        handler.toggleVietnameseMode()
        // Menu update will be triggered via languageModeChanged subscription
    }

    @objc private func openSettings() {
        // Post notification to trigger Settings opening via the hidden SwiftUI window.
        // This approach uses @Environment(\.openSettings) which is the official SwiftUI API
        // for opening Settings, ensuring native styling (tabs, liquid glass design).
        NotificationCenter.default.post(name: .openSettingsRequest, object: nil)
    }

    @objc private func openAbout() {
        let credits = NSAttributedString(
            string: """
            \(L("Vietnamese Input Method for macOS"))

            \(L("Developed by")) \(L("Author Name"))
            \(L("Licensed under GPL-3.0"))

            https://github.com/lotus-key/lotus-key
            """,
            attributes: [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: NSColor.secondaryLabelColor,
                .paragraphStyle: {
                    let style = NSMutableParagraphStyle()
                    style.alignment = .center
                    return style
                }(),
            ]
        )

        let options: [NSApplication.AboutPanelOptionKey: Any] = [
            .applicationName: "LotusKey",
            .applicationVersion: appVersion,
            .version: buildNumber,
            .credits: credits,
            .applicationIcon: NSApp.applicationIconImage as Any,
        ]

        NSApp.orderFrontStandardAboutPanel(options: options)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    @objc private func selectTelex() {
        settings.inputMethod = "Telex"
        updateInputMethodMenuItems()
    }

    @objc private func selectSimpleTelex() {
        settings.inputMethod = "Simple Telex"
        updateInputMethodMenuItems()
    }

    private func updateInputMethodMenuItems() {
        let isTelex = settings.inputMethod == "Telex"
        telexMenuItem?.state = isTelex ? .on : .off
        simpleTelexMenuItem?.state = isTelex ? .off : .on
    }

    // MARK: - Helpers

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = L("LotusKey Error")
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: L("OK"))
        alert.runModal()
    }
}
