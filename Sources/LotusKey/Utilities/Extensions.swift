import AppKit
import Foundation

// MARK: - String Extensions

public extension String {
    /// Returns the string with Vietnamese diacritics removed
    var withoutDiacritics: String {
        self.folding(options: .diacriticInsensitive, locale: .init(identifier: "vi"))
    }

    /// Returns true if the string contains Vietnamese characters
    var containsVietnamese: Bool {
        let vietnameseCharacters = CharacterSet(charactersIn: "àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđÀÁẢÃẠĂẰẮẲẴẶÂẦẤẨẪẬÈÉẺẼẸÊỀẾỂỄỆÌÍỈĨỊÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢÙÚỦŨỤƯỪỨỬỮỰỲÝỶỸỴĐ")
        return self.unicodeScalars.contains { vietnameseCharacters.contains($0) }
    }

    /// Returns the last character as a Character, or nil if empty
    var lastCharacter: Character? {
        self.last
    }
}

// MARK: - Character Extensions

public extension Character {
    /// Returns true if this is a Vietnamese vowel (with or without diacritics)
    var isVietnameseVowel: Bool {
        let vowels = "aăâeêioôơuưyAĂÂEÊIOÔƠUƯY"
        let baseVowels = "aeiouAEIOU"
        let base = String(self).withoutDiacritics
        return vowels.contains(self) || baseVowels.contains(base)
    }

    /// Returns true if this is a Vietnamese consonant
    var isVietnameseConsonant: Bool {
        let consonants = "bcdfghjklmnpqrstvxzđBCDFGHJKLMNPQRSTVXZĐ"
        return consonants.contains(self)
    }

    /// Returns true if this is a letter (Vietnamese or ASCII)
    var isVietnameseLetter: Bool {
        isVietnameseVowel || isVietnameseConsonant
    }
}

// MARK: - NSEvent Extensions

public extension NSEvent {
    /// Virtual key code for common keys
    enum KeyCode: UInt16 {
        case returnKey = 36
        case tab = 48
        case space = 49
        case delete = 51
        case escape = 53
        case leftArrow = 123
        case rightArrow = 124
        case downArrow = 125
        case upArrow = 126
    }

    /// Returns true if the event is a modifier key only press
    var isModifierOnly: Bool {
        guard type == .flagsChanged else { return false }
        return true
    }
}

// MARK: - CGEvent Extensions

public extension CGEvent {
    /// Returns the key code for keyboard events
    var keyCode: UInt16 {
        UInt16(getIntegerValueField(.keyboardEventKeycode))
    }

    /// Returns the character for the key event, if available
    var character: Character? {
        var actualLength = 0
        var chars = [UniChar](repeating: 0, count: 4)
        keyboardGetUnicodeString(
            maxStringLength: 4,
            actualStringLength: &actualLength,
            unicodeString: &chars
        )

        guard actualLength > 0 else { return nil }
        return Character(UnicodeScalar(chars[0])!)
    }
}

// MARK: - UserDefaults Extensions

public extension UserDefaults {
    /// Typed getter for Codable types
    func object<T: Codable>(forKey key: String, as type: T.Type) -> T? {
        guard let data = data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    /// Typed setter for Codable types
    func setObject<T: Codable>(_ value: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(value) {
            set(data, forKey: key)
        }
    }
}

// MARK: - Notification Names

public extension Notification.Name {
    static let lotusKeyLanguageChanged = Notification.Name("LotusKeyLanguageChanged")
    static let lotusKeySettingsChanged = Notification.Name("LotusKeySettingsChanged")
    static let lotusKeyEngineReset = Notification.Name("LotusKeyEngineReset")
}
