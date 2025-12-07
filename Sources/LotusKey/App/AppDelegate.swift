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
        languageModeItem = NSMenuItem(title: "Vietnamese", action: #selector(toggleLanguageMode), keyEquivalent: "")
        languageModeItem?.target = self
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
        // Open Settings window using the standard macOS action for Settings scene
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
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
