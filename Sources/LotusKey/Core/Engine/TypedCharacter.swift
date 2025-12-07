import Foundation

/// A single character in the typing buffer with complete state metadata.
///
/// Stores both the base character and its Vietnamese processing state
/// (modifiers, tone marks, capitalization) in a format compatible with
/// the original OpenKey bit-packed layout.
public struct TypedCharacter: Sendable, Hashable {
    /// Base character code (bits 0-15) - ASCII value or keycode
    public var baseCode: UInt16

    /// Character state flags (bits 16-25)
    public var state: CharacterState

    // MARK: - Initialization

    /// Create from base code and state
    public init(baseCode: UInt16, state: CharacterState = []) {
        self.baseCode = baseCode
        self.state = state
    }

    /// Create from a Character with optional capitalization
    public init(character: Character, caps: Bool = false) {
        // Use lowercase ASCII value as base
        let lowercased = character.lowercased().first ?? character
        self.baseCode = UInt16(lowercased.asciiValue ?? 0)
        self.state = caps ? .caps : []
    }

    /// Create from a Character, auto-detecting capitalization
    public init(character: Character) {
        let isUpper = character.isUppercase
        let lowercased = character.lowercased().first ?? character
        self.baseCode = UInt16(lowercased.asciiValue ?? 0)
        self.state = isUpper ? .caps : []
    }

    /// Unpack from UInt32 (OpenKey compatibility)
    public init(rawValue: UInt32) {
        self.baseCode = UInt16(rawValue & 0xFFFF)
        self.state = CharacterState(rawValue: rawValue & 0xFFFF_0000)
    }

    // MARK: - Computed Properties

    /// Pack to UInt32 for OpenKey compatibility
    public var rawValue: UInt32 {
        UInt32(baseCode) | state.rawValue
    }

    /// The base ASCII character (lowercase)
    public var baseCharacter: Character? {
        guard baseCode > 0, baseCode < 128 else { return nil }
        guard let scalar = UnicodeScalar(baseCode) else { return nil }
        return Character(scalar)
    }

    /// Check if this is a vowel (a, e, i, o, u, y)
    public var isVowel: Bool {
        guard let char = baseCharacter else { return false }
        return VietnameseConstants.baseVowels.contains(char)
    }

    /// Check if this character has a modifier (â, ê, ô, ơ, ư, ă)
    public var isModifiedVowel: Bool {
        isVowel && state.hasModifier
    }

    /// Check if this character is uppercase
    public var isUppercase: Bool {
        state.contains(.caps)
    }
}

// MARK: - CustomStringConvertible

extension TypedCharacter: CustomStringConvertible {
    public var description: String {
        let charStr = baseCharacter.map { String($0) } ?? "?"
        return "TypedCharacter(\(charStr), \(state))"
    }
}

// MARK: - Vietnamese Constants

/// Constants for Vietnamese character processing
public enum VietnameseConstants {
    /// Base vowels in Vietnamese
    public static let baseVowels: Set<Character> = ["a", "e", "i", "o", "u", "y"]

    /// Consonants that can start a word (single letters)
    public static let consonants: Set<Character> = [
        "b", "c", "d", "g", "h", "k", "l", "m",
        "n", "p", "q", "r", "s", "t", "v", "x",
    ]

    /// Valid first consonant clusters in Vietnamese (23 patterns)
    /// "qu" and "gi" are special - they consume the following vowel-like letter
    public static let firstConsonantClusters: Set<String> = [
        "b", "c", "ch", "d", "g", "gh", "gi", "h", "k", "kh",
        "l", "m", "n", "ng", "ngh", "nh", "p", "ph", "qu", "r",
        "s", "t", "th", "tr", "v", "x",
    ]

    /// Valid ending consonants in Vietnamese (9 patterns)
    /// These affect tone mark validity
    public static let endConsonants: Set<String> = [
        "c", "ch", "m", "n", "ng", "nh", "p", "t"
    ]

    /// "Sharp" ending consonants - only sắc(´) and nặng(.) tones valid
    /// huyền(`), hỏi(?), ngã(~) are INVALID with these endings
    public static let sharpEndConsonants: Set<String> = [
        "c", "ch", "p", "t"
    ]

    /// Characters that break a word
    public static let wordBreakChars: Set<Character> = [
        " ", "\t", "\n", "\r",
        ".", ",", ";", ":", "!", "?",
        "(", ")", "[", "]", "{", "}",
        "'", "\"", "`",
        "/", "\\",
        "@", "#", "$", "%", "^", "&", "*",
        "+", "=", "-", "_",
        "<", ">",
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
    ]

    /// Check if a character is a word break
    public static func isWordBreak(_ char: Character) -> Bool {
        wordBreakChars.contains(char)
    }

    /// Check if a character is a vowel
    public static func isVowel(_ char: Character) -> Bool {
        baseVowels.contains(char.lowercased().first ?? char)
    }

    /// Check if a character is a consonant
    public static func isConsonant(_ char: Character) -> Bool {
        consonants.contains(char.lowercased().first ?? char)
    }

    /// Check if 'u' at given position is part of 'qu' consonant cluster
    /// In "qu" + vowel, the 'u' is part of the consonant, not a vowel
    public static func isUPartOfQu(buffer: [Character], uIndex: Int) -> Bool {
        guard uIndex > 0 else { return false }
        let prev = buffer[uIndex - 1].lowercased().first ?? buffer[uIndex - 1]
        guard prev == "q" else { return false }
        // 'u' after 'q' is part of consonant if followed by another vowel
        if uIndex + 1 < buffer.count {
            let next = buffer[uIndex + 1].lowercased().first ?? buffer[uIndex + 1]
            return baseVowels.contains(next)
        }
        // At end of buffer, treat as potential consonant cluster
        return true
    }

    /// Check if 'i' at given position is part of 'gi' consonant cluster
    /// In "gi" + vowel, the 'i' is part of the consonant, not a vowel
    public static func isIPartOfGi(buffer: [Character], iIndex: Int) -> Bool {
        guard iIndex > 0 else { return false }
        let prev = buffer[iIndex - 1].lowercased().first ?? buffer[iIndex - 1]
        guard prev == "g" else { return false }
        // 'i' after 'g' is part of consonant if followed by another vowel
        if iIndex + 1 < buffer.count {
            let next = buffer[iIndex + 1].lowercased().first ?? buffer[iIndex + 1]
            return baseVowels.contains(next)
        }
        return false
    }

    /// Validate if a tone mark is valid with given ending consonant
    /// - Returns: true if valid, false if invalid combination
    public static func isValidToneWithEnding(tone: CharacterState, ending: String) -> Bool {
        let isSharpEnding = sharpEndConsonants.contains(ending.lowercased())

        // Sắc and Nặng are ONLY valid with sharp endings (c, ch, p, t)
        if tone.contains(.acute) || tone.contains(.dotBelow) {
            // These tones can appear with any ending, but are most natural with sharp
            return true
        }

        // Huyền, Hỏi, Ngã are INVALID with sharp endings
        if tone.contains(.grave) || tone.contains(.hook) || tone.contains(.tilde) {
            return !isSharpEnding
        }

        return true
    }
}

// MARK: - Key Codes

public extension TypedCharacter {
    /// Virtual key code for backspace/delete
    static let backspaceKeyCode: UInt16 = 51
}

// MARK: - Break Key Codes

/// Key codes that break/reset the typing session.
///
/// These are navigation and control keys that should reset the engine buffer
/// without producing visible character output. Unlike word break *characters*
/// (space, punctuation), break *keycodes* are detected by their virtual key code.
///
/// Reference: OpenKey Engine.cpp lines 21-28 (_breakCode array)
public enum BreakKeyCodes {
    // MARK: - macOS Virtual Key Codes

    /// ESC key - cancels current input
    public static let escape: UInt16 = 53

    /// Tab key - navigation
    public static let tab: UInt16 = 48

    /// Return key (main keyboard)
    public static let returnKey: UInt16 = 36

    /// Enter key (numpad)
    public static let enter: UInt16 = 76

    /// Left arrow - cursor navigation
    public static let leftArrow: UInt16 = 123

    /// Right arrow - cursor navigation
    public static let rightArrow: UInt16 = 124

    /// Down arrow - cursor navigation
    public static let downArrow: UInt16 = 125

    /// Up arrow - cursor navigation
    public static let upArrow: UInt16 = 126

    // MARK: - Navigation Break Keys Set

    /// Set of navigation key codes that should break the typing session.
    /// These keys reset the buffer without appending any character.
    ///
    /// Matches OpenKey's _breakCode array (excluding punctuation keycodes,
    /// which are handled separately via character-based word break detection).
    public static let navigationBreaks: Set<UInt16> = [
        escape,      // ESC
        tab,         // Tab
        returnKey,   // Return
        enter,       // Enter (numpad)
        leftArrow,   // Left Arrow
        rightArrow,  // Right Arrow
        downArrow,   // Down Arrow
        upArrow,     // Up Arrow
    ]

    // MARK: - Detection

    /// Check if a key code is a break key code (navigation key that resets session).
    ///
    /// - Parameter keyCode: The virtual key code to check
    /// - Returns: true if the key code should break/reset the typing session
    public static func isBreakKeyCode(_ keyCode: UInt16) -> Bool {
        navigationBreaks.contains(keyCode)
    }
}
