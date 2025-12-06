import Carbon
import Foundation

/// Protocol for hotkey detection
public protocol HotkeyDetecting: AnyObject, Sendable {
    /// Check if a keyboard event matches a registered hotkey
    /// - Parameters:
    ///   - event: The keyboard event to check
    ///   - type: The type of hotkey to check for
    /// - Returns: true if the event matches the hotkey
    func checkHotkey(event: CGEvent, type: HotkeyType) -> Bool

    /// Check if a flags changed event triggers a modifier-only hotkey
    /// - Parameters:
    ///   - event: The flags changed event
    ///   - lastFlags: The previous modifier flags
    /// - Returns: true if a modifier hotkey was triggered
    func checkFlagsChanged(event: CGEvent, lastFlags: CGEventFlags) -> Bool

    /// Set the hotkey configuration
    /// - Parameters:
    ///   - hotkey: The hotkey configuration
    ///   - type: The type of hotkey
    func setHotkey(_ hotkey: Hotkey, for type: HotkeyType)

    /// Get the current hotkey configuration
    /// - Parameter type: The type of hotkey
    /// - Returns: The hotkey configuration
    func getHotkey(for type: HotkeyType) -> Hotkey
}

/// Types of hotkeys supported
public enum HotkeyType: Sendable {
    /// Toggle between Vietnamese and English mode
    case switchLanguage
    /// Convert clipboard content
    case convertClipboard
    /// Open settings
    case openSettings
}

/// Hotkey configuration
public struct Hotkey: Sendable, Equatable {
    /// The key code (0-255)
    public let keyCode: UInt16
    /// Whether Control modifier is required
    public let control: Bool
    /// Whether Option/Alt modifier is required
    public let option: Bool
    /// Whether Command modifier is required
    public let command: Bool
    /// Whether Shift modifier is required
    public let shift: Bool
    /// Whether to play beep sound when triggered
    public let enableBeep: Bool

    /// Create a hotkey from individual components
    public init(
        keyCode: UInt16,
        control: Bool = false,
        option: Bool = false,
        command: Bool = false,
        shift: Bool = false,
        enableBeep: Bool = true
    ) {
        self.keyCode = keyCode
        self.control = control
        self.option = option
        self.command = command
        self.shift = shift
        self.enableBeep = enableBeep
    }

    /// Create a hotkey from OpenKey-compatible bitfield format
    /// Format: Bits 0-7: Key code, Bit 8: Control, Bit 9: Option, Bit 10: Command, Bit 11: Shift, Bit 15: Beep
    public init(bitfield: UInt32) {
        self.keyCode = UInt16(bitfield & 0xFF)
        self.control = (bitfield & 0x100) != 0
        self.option = (bitfield & 0x200) != 0
        self.command = (bitfield & 0x400) != 0
        self.shift = (bitfield & 0x800) != 0
        self.enableBeep = (bitfield & 0x8000) != 0
    }

    /// Convert to OpenKey-compatible bitfield format
    public var toBitfield: UInt32 {
        var result: UInt32 = UInt32(keyCode)
        if control { result |= 0x100 }
        if option { result |= 0x200 }
        if command { result |= 0x400 }
        if shift { result |= 0x800 }
        if enableBeep { result |= 0x8000 }
        return result
    }

    /// Check if this hotkey matches the given event
    public func matches(event: CGEvent) -> Bool {
        let eventKeyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags

        guard eventKeyCode == keyCode else { return false }

        // Check modifiers
        let hasControl = flags.contains(.maskControl)
        let hasOption = flags.contains(.maskAlternate)
        let hasCommand = flags.contains(.maskCommand)
        let hasShift = flags.contains(.maskShift)

        return control == hasControl
            && option == hasOption
            && command == hasCommand
            && shift == hasShift
    }

    /// Default language switch hotkey: Ctrl+Space
    public static let defaultSwitchLanguage = Hotkey(
        keyCode: 0x31,  // Space key
        control: true,
        enableBeep: true
    )

    /// Alternative language switch hotkey: Option+Z (OpenKey default)
    public static let openKeyDefault = Hotkey(bitfield: 0x7A000206)
}

/// Detects hotkey combinations
public final class HotkeyDetector: HotkeyDetecting, @unchecked Sendable {
    // MARK: - Properties

    private let lock = NSLock()
    private var hotkeys: [HotkeyType: Hotkey] = [
        .switchLanguage: .defaultSwitchLanguage
    ]

    // MARK: - Initialization

    public init() {}

    // MARK: - Configuration

    public func setHotkey(_ hotkey: Hotkey, for type: HotkeyType) {
        lock.lock()
        defer { lock.unlock() }
        hotkeys[type] = hotkey
    }

    public func getHotkey(for type: HotkeyType) -> Hotkey {
        lock.lock()
        defer { lock.unlock() }
        return hotkeys[type] ?? .defaultSwitchLanguage
    }

    // MARK: - Detection

    public func checkHotkey(event: CGEvent, type: HotkeyType) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard let hotkey = hotkeys[type] else { return false }
        return hotkey.matches(event: event)
    }

    public func checkFlagsChanged(event: CGEvent, lastFlags: CGEventFlags) -> Bool {
        // Check for modifier-only hotkeys (e.g., modifier release triggers action)
        // OpenKey pattern: hotkey is checked when lastFlags > currentFlags (release)
        // The actual check is done in KeyboardEventHandler.handleFlagsChanged
        // This method is reserved for future modifier-only hotkey support
        // (e.g., double-tap Control, Caps Lock toggle)
        _ = event.flags  // Suppress unused warning, reserved for future use

        return false
    }
}

// MARK: - CGEventFlags Extension

extension CGEventFlags {
    /// Check if Control modifier is pressed
    public var hasControl: Bool { contains(.maskControl) }

    /// Check if Option/Alt modifier is pressed
    public var hasOption: Bool { contains(.maskAlternate) }

    /// Check if Command modifier is pressed
    public var hasCommand: Bool { contains(.maskCommand) }

    /// Check if Shift modifier is pressed
    public var hasShift: Bool { contains(.maskShift) }

    /// Check if Caps Lock is active
    public var hasCapsLock: Bool { contains(.maskAlphaShift) }

    /// Check if Fn (Secondary Function) modifier is pressed
    public var hasSecondaryFn: Bool { contains(.maskSecondaryFn) }

    /// Check if NumPad key is pressed
    public var hasNumericPad: Bool { contains(.maskNumericPad) }

    /// Check if Help key is pressed
    public var hasHelp: Bool { contains(.maskHelp) }

    /// Check if any control key (except Shift) is pressed
    /// Matches OpenKey's OTHER_CONTROL_KEY macro
    public var hasOtherControlKey: Bool {
        hasControl || hasOption || hasCommand || hasSecondaryFn || hasNumericPad || hasHelp
    }
}
