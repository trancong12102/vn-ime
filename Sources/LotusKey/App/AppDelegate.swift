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

    /// Settings store
    private let settings = SettingsStore()

    /// Current language mode menu item
    private var languageModeItem: NSMenuItem?

    // MARK: - App Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        applyLifecycleSettings()
        setupMenuBar()
        setupEventHandler()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup resources
        eventHandler?.stop()
        applicationDetector?.stopMonitoring()
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
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        updateMenuBarIcon(isVietnameseMode: true)

        let menu = NSMenu()

        // Language mode toggle
        languageModeItem = NSMenuItem(title: "Vietnamese", action: #selector(toggleLanguageMode), keyEquivalent: "")
        languageModeItem?.state = .on
        menu.addItem(languageModeItem!)

        menu.addItem(NSMenuItem.separator())

        // Settings
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))

        menu.addItem(NSMenuItem.separator())

        // Quit
        menu.addItem(
            NSMenuItem(title: "Quit LotusKey", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    private func updateMenuBarIcon(isVietnameseMode: Bool) {
        if let button = statusItem?.button {
            button.image = Self.createMenuBarIcon(isVietnameseMode: isVietnameseMode)
        }
    }

    /// Creates a menu bar icon matching macOS native input source style
    /// - Vietnamese mode: "VI" filled (like macOS active input source)
    /// - English mode: "EN" not filled (outline only)
    private static func createMenuBarIcon(isVietnameseMode: Bool) -> NSImage {
        // Match macOS input source icon: wider rounded rectangle
        let size = NSSize(width: 22, height: 16)

        // Use NSImage with drawing handler for proper scaling on Retina
        let image = NSImage(size: size, flipped: false) { rect in
            if isVietnameseMode {
                Self.drawFilledIcon(text: "VI", in: rect)
            } else {
                Self.drawOutlineIcon(text: "EN", in: rect)
            }
            return true
        }

        image.isTemplate = true
        return image
    }

    /// Draws filled icon like macOS native input source (active state)
    /// Uses knockout effect: text is cut out from the filled rectangle
    private static func drawFilledIcon(text: String, in rect: NSRect) {
        let cornerRadius: CGFloat = 3.5

        // Draw filled rounded rectangle background (full rect, no inset)
        let bgPath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
        NSColor.black.setFill()
        bgPath.fill()

        // Knockout text: use destinationOut compositing to cut text from background
        let font = NSFont.systemFont(ofSize: 11, weight: .semibold)
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

    /// Draws outline icon (inactive state) - text only, no background
    private static func drawOutlineIcon(text: String, in rect: NSRect) {
        let font = NSFont.systemFont(ofSize: 13, weight: .medium)
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
        languageModeItem?.title = isVietnameseMode ? "Vietnamese" : "English"
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

        // Subscribe to application changes to update quirks
        appDetector.applicationChanged
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateAppQuirks()
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
        default:
            break
        }
    }

    private func updateAppQuirks() {
        guard let appDetector = applicationDetector, let injector = textInjector else { return }
        injector.setAppQuirk(appDetector.currentAppQuirk)
    }

    // MARK: - Actions

    @objc private func toggleLanguageMode() {
        guard let handler = eventHandler else { return }
        handler.isVietnameseMode.toggle()
        updateLanguageModeMenuItem(isVietnameseMode: handler.isVietnameseMode)
    }

    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        if let settingsItem = NSApp.mainMenu?.item(withTitle: "LotusKey")?.submenu?.item(withTitle: "Settings…") {
            NSApp.sendAction(settingsItem.action!, to: settingsItem.target, from: nil)
        }
    }

    // MARK: - Helpers

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "LotusKey Error"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
