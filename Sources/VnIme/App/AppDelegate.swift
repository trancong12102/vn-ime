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
        setupMenuBar()
        setupEventHandler()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup resources
        eventHandler?.stop()
        applicationDetector?.stopMonitoring()
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
            NSMenuItem(title: "Quit VnIme", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    private func updateMenuBarIcon(isVietnameseMode: Bool) {
        if let button = statusItem?.button {
            // Use "V" for Vietnamese mode, "E" for English mode
            let symbolName = isVietnameseMode ? "v.circle.fill" : "e.circle"
            button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "VnIme")
        }
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
            showError("Failed to start VnIme: \(error.localizedDescription)")
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

        print("VnIme event handler started successfully")
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
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Helpers

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "VnIme Error"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
