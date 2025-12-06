import AppKit
import Carbon
import Foundation

/// Protocol for keyboard layout conversion
public protocol KeyboardLayoutConverting: AnyObject, Sendable {
    /// Convert an event's key code to a layout-independent key code
    /// - Parameters:
    ///   - event: The keyboard event
    ///   - fallback: Fallback key code if conversion fails
    /// - Returns: The layout-independent key code
    func convertToLayoutIndependentKeyCode(event: CGEvent, fallback: UInt16) -> UInt16

    /// Get the character for a key code ignoring modifiers
    /// - Parameter event: The keyboard event
    /// - Returns: The character, or nil if unavailable
    func getCharacterIgnoringModifiers(event: CGEvent) -> Character?
}

/// Converts keyboard events for non-QWERTY layout compatibility
public final class KeyboardLayoutConverter: KeyboardLayoutConverting, @unchecked Sendable {
    // MARK: - QWERTY Key Code Mapping

    /// Character to QWERTY key code mapping
    private static let charToKeyCode: [Character: UInt16] = [
        // Letters - row by row from QWERTY layout
        "a": 0x00, "s": 0x01, "d": 0x02, "f": 0x03, "h": 0x04, "g": 0x05, "z": 0x06, "x": 0x07,
        "c": 0x08, "v": 0x09, "b": 0x0B, "q": 0x0C, "w": 0x0D, "e": 0x0E, "r": 0x0F, "y": 0x10,
        "t": 0x11, "1": 0x12, "2": 0x13, "3": 0x14, "4": 0x15, "6": 0x16, "5": 0x17, "=": 0x18,
        "9": 0x19, "7": 0x1A, "-": 0x1B, "8": 0x1C, "0": 0x1D, "]": 0x1E, "o": 0x1F, "u": 0x20,
        "[": 0x21, "i": 0x22, "p": 0x23, "l": 0x25, "j": 0x26, "'": 0x27, "k": 0x28, ";": 0x29,
        "\\": 0x2A, ",": 0x2B, "/": 0x2C, "n": 0x2D, "m": 0x2E, ".": 0x2F, "`": 0x32,

        // Uppercase letters map to same key codes
        "A": 0x00, "S": 0x01, "D": 0x02, "F": 0x03, "H": 0x04, "G": 0x05, "Z": 0x06, "X": 0x07,
        "C": 0x08, "V": 0x09, "B": 0x0B, "Q": 0x0C, "W": 0x0D, "E": 0x0E, "R": 0x0F, "Y": 0x10,
        "T": 0x11, "O": 0x1F, "U": 0x20, "I": 0x22, "P": 0x23, "L": 0x25, "J": 0x26, "K": 0x28,
        "N": 0x2D, "M": 0x2E,

        // Shifted symbols
        "!": 0x12, "@": 0x13, "#": 0x14, "$": 0x15, "^": 0x16, "%": 0x17, "+": 0x18,
        "(": 0x19, "&": 0x1A, "_": 0x1B, "*": 0x1C, ")": 0x1D, "}": 0x1E, "{": 0x21,
        "\"": 0x27, ":": 0x29, "|": 0x2A, "<": 0x2B, "?": 0x2C, ">": 0x2F, "~": 0x32,
    ]

    // MARK: - Initialization

    public init() {}

    // MARK: - Conversion

    public func convertToLayoutIndependentKeyCode(event: CGEvent, fallback: UInt16) -> UInt16 {
        // Try to get the character from NSEvent
        guard let char = getCharacterIgnoringModifiers(event: event) else {
            return fallback
        }

        // Look up the QWERTY key code for this character
        if let keyCode = Self.charToKeyCode[char] {
            return keyCode
        }

        // Fall back to the original key code
        return fallback
    }

    public func getCharacterIgnoringModifiers(event: CGEvent) -> Character? {
        // Convert CGEvent to NSEvent to access charactersIgnoringModifiers
        guard let nsEvent = NSEvent(cgEvent: event) else {
            return nil
        }

        guard let chars = nsEvent.charactersIgnoringModifiers, !chars.isEmpty else {
            return nil
        }

        return chars.first
    }
}
