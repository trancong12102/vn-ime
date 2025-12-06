import AppKit
import Carbon
import Foundation

/// Protocol for keyboard event handling
public protocol KeyboardEventHandling: AnyObject, Sendable {
    /// Start capturing keyboard events
    /// - Throws: Error if unable to create event tap (usually permissions)
    func start() throws

    /// Stop capturing keyboard events
    func stop()

    /// Whether the handler is currently active
    var isActive: Bool { get }

    /// Whether Vietnamese mode is enabled
    var isVietnameseMode: Bool { get set }

    /// Reset the typing session (e.g., on mouse click)
    func resetSession()
}

/// Error types for keyboard event handling
public enum KeyboardEventError: Error, LocalizedError {
    case accessibilityNotEnabled
    case failedToCreateEventTap
    case failedToCreateRunLoopSource
    case failedToCreateEventSource

    public var errorDescription: String? {
        switch self {
        case .accessibilityNotEnabled:
            return "Accessibility permissions not enabled. Please enable in System Settings > Privacy & Security > Accessibility"
        case .failedToCreateEventTap:
            return "Failed to create keyboard event tap"
        case .failedToCreateRunLoopSource:
            return "Failed to create run loop source for event tap"
        case .failedToCreateEventSource:
            return "Failed to create private event source"
        }
    }
}

/// Handles keyboard events using CGEventTap
public final class KeyboardEventHandler: KeyboardEventHandling, @unchecked Sendable {
    // MARK: - Properties

    fileprivate var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let engine: any VietnameseEngine

    /// Private event source for identifying own events (prevents infinite loops)
    /// This is shared with TextInjector to ensure all injected events are properly filtered
    public private(set) var eventSource: CGEventSource?

    /// The current event tap proxy (stored for text injection in callback)
    fileprivate var currentProxy: CGEventTapProxy?

    /// Pre-created backspace key events for performance
    private var backspaceKeyDown: CGEvent?
    private var backspaceKeyUp: CGEvent?

    /// Last modifier flags for detecting changes
    fileprivate var lastFlags: CGEventFlags = []

    /// Whether Vietnamese mode is active
    public var isVietnameseMode: Bool = true

    /// Temporary engine disable (toggled via Command key release)
    fileprivate var tempOffEngine: Bool = false

    /// Temporary spell-check disable (toggled via Control key release)
    fileprivate var tempOffSpellCheck: Bool = false

    /// Track if hotkey was just used (to avoid temp off toggle right after hotkey)
    fileprivate var hasJustUsedHotkey: Bool = false

    /// Text injector for sending characters to applications
    fileprivate var textInjector: TextInjecting?

    /// Application detector for quirks handling
    fileprivate var applicationDetector: ApplicationDetecting?

    /// Hotkey detector for language switching
    fileprivate var hotkeyDetector: HotkeyDetecting?

    /// Input source detector for other language bypass
    fileprivate var inputSourceDetector: InputSourceDetecting?

    /// Keyboard layout converter for non-QWERTY layouts
    fileprivate var layoutConverter: KeyboardLayoutConverting?

    /// Configuration options
    public var enableLayoutCompat: Bool = false
    public var bypassOtherLanguage: Bool = true
    public var enableBeepOnSwitch: Bool = true

    public private(set) var isActive: Bool = false

    // MARK: - Initialization

    public init(engine: any VietnameseEngine) {
        self.engine = engine
    }

    deinit {
        stop()
    }

    // MARK: - Setup

    /// Configure dependencies after initialization
    public func configure(
        textInjector: TextInjecting,
        applicationDetector: ApplicationDetecting,
        hotkeyDetector: HotkeyDetecting,
        inputSourceDetector: InputSourceDetecting,
        layoutConverter: KeyboardLayoutConverting
    ) {
        self.textInjector = textInjector
        self.applicationDetector = applicationDetector
        self.hotkeyDetector = hotkeyDetector
        self.inputSourceDetector = inputSourceDetector
        self.layoutConverter = layoutConverter
    }

    // MARK: - Lifecycle

    public func start() throws {
        // Check accessibility permissions
        let trusted = AXIsProcessTrusted()
        guard trusted else {
            throw KeyboardEventError.accessibilityNotEnabled
        }

        // Create private event source for own-event identification
        guard let source = CGEventSource(stateID: .privateState) else {
            throw KeyboardEventError.failedToCreateEventSource
        }
        eventSource = source

        // Pre-create backspace events for performance
        backspaceKeyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x33, keyDown: true)
        backspaceKeyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x33, keyDown: false)

        // Create event tap with expanded event mask
        let eventMask: CGEventMask =
            (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)
            | (1 << CGEventType.leftMouseDown.rawValue)
            | (1 << CGEventType.rightMouseDown.rawValue)
            | (1 << CGEventType.leftMouseDragged.rawValue)
            | (1 << CGEventType.rightMouseDragged.rawValue)

        guard
            let tap = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: eventMask,
                callback: keyboardCallback,
                userInfo: Unmanaged.passUnretained(self).toOpaque()
            )
        else {
            throw KeyboardEventError.failedToCreateEventTap
        }

        eventTap = tap

        // Create run loop source
        guard let runLoopSrc = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            throw KeyboardEventError.failedToCreateRunLoopSource
        }

        runLoopSource = runLoopSrc

        // Add to run loop
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSrc, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        isActive = true
    }

    public func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }

        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }

        runLoopSource = nil
        eventTap = nil
        eventSource = nil
        backspaceKeyDown = nil
        backspaceKeyUp = nil
        isActive = false
    }

    public func resetSession() {
        engine.reset()
        tempOffEngine = false
        tempOffSpellCheck = false
    }

    // MARK: - Event Filtering

    /// Check if event is from our own injection (prevents infinite loops)
    fileprivate func isOwnEvent(_ event: CGEvent) -> Bool {
        guard let source = eventSource else { return false }
        let eventSourceID = event.getIntegerValueField(.eventSourceStateID)
        let mySourceID = source.sourceStateID
        return eventSourceID == Int64(mySourceID.rawValue)
    }

    // MARK: - Event Handling

    fileprivate func handleMouseEvent() {
        // Mouse event means user clicked - reset typing session
        resetSession()
    }

    fileprivate func handleFlagsChanged(_ event: CGEvent) -> CGEvent? {
        let flags = event.flags

        // OpenKey pattern: Only process on modifier RELEASE (lastFlags > flags)
        // When pressing modifiers, just accumulate flags
        if lastFlags.rawValue == 0 || lastFlags.rawValue < flags.rawValue {
            // Modifier pressed - accumulate flags
            lastFlags = flags
            return event
        }

        // Modifier released (lastFlags > flags) - check for hotkeys and temp toggles
        if lastFlags.rawValue > flags.rawValue {
            // Check hotkey on flags changed (for modifier-only hotkeys)
            if let detector = hotkeyDetector,
                currentProxy != nil,
                detector.checkFlagsChanged(event: event, lastFlags: lastFlags)
            {
                lastFlags = []
                hasJustUsedHotkey = true
                toggleVietnameseMode()
                return nil  // Consume event
            }

            // Check for temporary spell-check toggle via Control key release
            // Only toggle if no hotkey was just used
            if !hasJustUsedHotkey && lastFlags.contains(.maskControl) {
                tempOffSpellCheck.toggle()
            }

            // Check for temporary engine toggle via Command key release
            // Only toggle if no hotkey was just used
            if !hasJustUsedHotkey && lastFlags.contains(.maskCommand) {
                tempOffEngine.toggle()
            }

            // Reset flags after processing release
            lastFlags = []
            hasJustUsedHotkey = false
        }

        return event
    }

    fileprivate func handleKeyDown(_ event: CGEvent, proxy: CGEventTapProxy) -> CGEvent? {
        // Check if other language input source is active
        if bypassOtherLanguage,
            let detector = inputSourceDetector,
            !detector.isEnglishInputSource()
        {
            return event
        }

        // Check for language switch hotkey
        if let detector = hotkeyDetector,
            detector.checkHotkey(event: event, type: .switchLanguage)
        {
            lastFlags = []
            hasJustUsedHotkey = true
            toggleVietnameseMode()
            return nil  // Consume the hotkey event
        }

        // Reset hasJustUsedHotkey if this is a normal key press
        hasJustUsedHotkey = lastFlags.rawValue != 0

        // Check for other control keys (Cmd, Ctrl, Option pressed)
        if hasOtherControlKey(event.flags) {
            return event
        }

        // Check temporary disable
        if tempOffEngine {
            return event
        }

        // Check Vietnamese mode
        if !isVietnameseMode {
            return event
        }

        // Convert key code for layout compatibility (if enabled)
        var keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        if enableLayoutCompat, let converter = layoutConverter {
            keyCode = converter.convertToLayoutIndependentKeyCode(event: event, fallback: keyCode)
        }

        // Get character from event
        let character = extractCharacter(from: event)

        // Get caps status (reserved for future use)
        _ = getCapsStatus(event.flags)

        // Process through engine
        let result = engine.processKey(keyCode: keyCode, character: character, modifiers: event.flags.rawValue)

        switch result {
        case .passThrough:
            return event
        case .suppress:
            return nil
        case .replace(let backspaceCount, let replacement):
            // Use text injector if available, otherwise fallback to basic injection
            if let injector = textInjector {
                if backspaceCount > 0 {
                    injector.injectBackspaces(count: backspaceCount, proxy: proxy)
                }
                if !replacement.isEmpty {
                    injector.injectString(replacement, proxy: proxy)
                }
            } else {
                // Fallback to basic injection
                sendBackspaces(count: backspaceCount, proxy: proxy)
                sendString(replacement, proxy: proxy)
            }
            return nil
        }
    }

    // MARK: - Helper Methods

    private func extractCharacter(from event: CGEvent) -> Character? {
        var actualStringLength = 0
        var unicodeString = [UniChar](repeating: 0, count: 4)
        event.keyboardGetUnicodeString(
            maxStringLength: 4,
            actualStringLength: &actualStringLength,
            unicodeString: &unicodeString
        )

        guard actualStringLength > 0 else { return nil }
        return Character(UnicodeScalar(unicodeString[0])!)
    }

    private func getCapsStatus(_ flags: CGEventFlags) -> Int {
        if flags.contains(.maskShift) {
            return 1  // Shift key
        } else if flags.contains(.maskAlphaShift) {
            return 2  // Caps Lock
        }
        return 0
    }

    private func hasOtherControlKey(_ flags: CGEventFlags) -> Bool {
        // Check for any modifier except Shift (matches OpenKey's OTHER_CONTROL_KEY macro)
        // Includes: Command, Control, Option/Alt, Fn (SecondaryFn), NumPad, Help
        return flags.contains(.maskCommand)
            || flags.contains(.maskControl)
            || flags.contains(.maskAlternate)
            || flags.contains(.maskSecondaryFn)
            || flags.contains(.maskNumericPad)
            || flags.contains(.maskHelp)
    }

    private func toggleVietnameseMode() {
        isVietnameseMode.toggle()
        if enableBeepOnSwitch {
            NSSound.beep()
        }
        // Reset engine when switching modes
        engine.reset()
    }

    // MARK: - Basic Text Injection (Fallback)

    private func sendBackspaces(count: Int, proxy: CGEventTapProxy) {
        guard eventSource != nil,
            let keyDown = backspaceKeyDown,
            let keyUp = backspaceKeyUp
        else { return }

        for _ in 0..<count {
            keyDown.tapPostEvent(proxy)
            keyUp.tapPostEvent(proxy)
        }
    }

    private func sendString(_ string: String, proxy: CGEventTapProxy) {
        guard let source = eventSource else { return }

        for char in string {
            guard !char.unicodeScalars.isEmpty else { continue }

            var chars = [UniChar](repeating: 0, count: 2)
            let charCount = char.utf16.count
            for (i, unit) in char.utf16.enumerated() {
                chars[i] = unit
            }

            guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
                let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
            else { continue }

            keyDown.keyboardSetUnicodeString(stringLength: charCount, unicodeString: &chars)
            keyUp.keyboardSetUnicodeString(stringLength: charCount, unicodeString: &chars)

            keyDown.tapPostEvent(proxy)
            keyUp.tapPostEvent(proxy)
        }
    }
}

// MARK: - CGEventTap Callback

private func keyboardCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon = refcon else {
        return Unmanaged.passRetained(event)
    }

    let handler = Unmanaged<KeyboardEventHandler>.fromOpaque(refcon).takeUnretainedValue()

    // Store proxy for use in event handling
    handler.currentProxy = proxy

    // Handle tap being disabled by system
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let tap = handler.eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        return Unmanaged.passRetained(event)
    }

    // Check if this is our own event (prevents infinite loops)
    if handler.isOwnEvent(event) {
        return Unmanaged.passRetained(event)
    }

    // Handle mouse events - reset session
    switch type {
    case .leftMouseDown, .rightMouseDown, .leftMouseDragged, .rightMouseDragged:
        handler.handleMouseEvent()
        return Unmanaged.passRetained(event)
    default:
        break
    }

    // Handle flags changed (modifier keys)
    if type == .flagsChanged {
        if let result = handler.handleFlagsChanged(event) {
            return Unmanaged.passRetained(result)
        }
        return nil
    }

    // Only process keyDown events for Vietnamese input
    guard type == .keyDown else {
        return Unmanaged.passRetained(event)
    }

    if let result = handler.handleKeyDown(event, proxy: proxy) {
        return Unmanaged.passRetained(result)
    }

    return nil
}
