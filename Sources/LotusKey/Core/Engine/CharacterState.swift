import Foundation

/// Bit-packed character state flags for Vietnamese input processing.
///
/// Matches the original OpenKey bit layout for compatibility:
/// - Bits 0-15: Base character code (stored separately in TypedCharacter)
/// - Bit 16: Capitalization flag
/// - Bits 17-18: Tone modifiers (circumflex, horn/breve)
/// - Bits 19-23: Tone mark flags (5 marks)
/// - Bits 24-25: Control flags
public struct CharacterState: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    // MARK: - Bit 16: Capitalization

    /// Character is uppercase
    public static let caps = CharacterState(rawValue: 1 << 16)

    // MARK: - Bits 17-18: Tone Modifiers (dấu mũ)

    /// Circumflex modifier (^) for â, ê, ô
    public static let circumflex = CharacterState(rawValue: 1 << 17)

    /// Horn or breve modifier (w) for ơ, ư, ă
    public static let hornOrBreve = CharacterState(rawValue: 1 << 18)

    // MARK: - Bits 19-23: Tone Marks (dấu thanh)

    /// Acute mark - Sắc (́)
    public static let acute = CharacterState(rawValue: 1 << 19)

    /// Grave mark - Huyền (̀)
    public static let grave = CharacterState(rawValue: 1 << 20)

    /// Hook above mark - Hỏi (̉)
    public static let hook = CharacterState(rawValue: 1 << 21)

    /// Tilde mark - Ngã (̃)
    public static let tilde = CharacterState(rawValue: 1 << 22)

    /// Dot below mark - Nặng (̣)
    public static let dotBelow = CharacterState(rawValue: 1 << 23)

    // MARK: - Bit 19: Consonant Modifier

    /// Stroke modifier for đ/Đ (separate from vowel modifiers)
    public static let stroke = CharacterState(rawValue: 1 << 26)

    // MARK: - Bits 24-25: Control Flags

    /// Character stands alone (not part of Vietnamese processing)
    public static let standalone = CharacterState(rawValue: 1 << 24)

    /// Value represents character code (vs keycode)
    public static let isCharCode = CharacterState(rawValue: 1 << 25)

    // MARK: - Convenience Sets

    /// All tone marks combined
    public static let allToneMarks: CharacterState = [.acute, .grave, .hook, .tilde, .dotBelow]

    /// All modifiers combined
    public static let allModifiers: CharacterState = [.circumflex, .hornOrBreve]

    // MARK: - Computed Properties

    /// Check if any tone mark is present
    public var hasToneMark: Bool {
        !intersection(Self.allToneMarks).isEmpty
    }

    /// Check if any modifier is present (circumflex or horn/breve)
    public var hasModifier: Bool {
        !intersection(Self.allModifiers).isEmpty
    }

    /// Get the current tone mark, if any
    public var toneMark: CharacterState? {
        let mark = intersection(Self.allToneMarks)
        return mark.isEmpty ? nil : mark
    }

    /// Get the current modifier, if any
    public var modifier: CharacterState? {
        let mod = intersection(Self.allModifiers)
        return mod.isEmpty ? nil : mod
    }

    // MARK: - Mutation Helpers

    /// Remove any existing tone mark
    public mutating func clearToneMark() {
        remove(Self.allToneMarks)
    }

    /// Remove any existing modifier
    public mutating func clearModifier() {
        remove(Self.allModifiers)
    }

    /// Set a new tone mark, replacing any existing one
    public mutating func setToneMark(_ mark: CharacterState) {
        clearToneMark()
        insert(mark.intersection(Self.allToneMarks))
    }

    /// Set a new modifier, replacing any existing one
    public mutating func setModifier(_ modifier: CharacterState) {
        clearModifier()
        insert(modifier.intersection(Self.allModifiers))
    }
}

// MARK: - CustomStringConvertible

extension CharacterState: CustomStringConvertible {
    public var description: String {
        var parts: [String] = []

        if contains(.caps) { parts.append("caps") }
        if contains(.circumflex) { parts.append("^") }
        if contains(.hornOrBreve) { parts.append("w") }
        if contains(.stroke) { parts.append("đ") }
        if contains(.acute) { parts.append("sắc") }
        if contains(.grave) { parts.append("huyền") }
        if contains(.hook) { parts.append("hỏi") }
        if contains(.tilde) { parts.append("ngã") }
        if contains(.dotBelow) { parts.append("nặng") }
        if contains(.standalone) { parts.append("standalone") }
        if contains(.isCharCode) { parts.append("charCode") }

        return parts.isEmpty ? "[]" : "[\(parts.joined(separator: ", "))]"
    }
}
