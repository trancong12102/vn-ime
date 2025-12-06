import Foundation

/// Represents a Vietnamese input method (Telex, Simple Telex)
public protocol InputMethod: Sendable {
    /// The name of the input method
    var name: String { get }

    /// Process a character and return the transformation rules to apply
    /// - Parameters:
    ///   - character: The input character
    ///   - context: The current input context (previous characters)
    /// - Returns: The transformation to apply, if any
    func processCharacter(_ character: Character, context: String) -> InputTransformation?

    /// Process a character with undo context
    /// - Parameters:
    ///   - character: The input character
    ///   - context: The current input context (previous characters)
    ///   - state: The current input method state (for undo tracking)
    /// - Returns: The transformation to apply, if any
    func processCharacter(_ character: Character, context: String, state: inout InputMethodState) -> InputTransformation?

    /// Check if a character is a special key for this input method
    /// - Parameter character: The character to check
    /// - Returns: True if the character has special meaning
    func isSpecialKey(_ character: Character) -> Bool
}

/// Default implementation for backward compatibility
public extension InputMethod {
    func processCharacter(_ character: Character, context: String, state: inout InputMethodState) -> InputTransformation? {
        // Default: delegate to simple version without state
        return processCharacter(character, context: context)
    }
}

/// Represents a transformation to apply to the input
public struct InputTransformation: Sendable {
    /// Type of transformation
    public enum TransformationType: Sendable {
        /// Add a tone mark (sắc, huyền, hỏi, ngã, nặng)
        case tone(ToneMark)
        /// Add a modifier mark (circumflex, breve, horn, stroke)
        case modifier(ModifierMark)
        /// Replace characters (e.g., dd -> đ)
        case replace(String)
        /// Undo last transformation (restores original characters)
        case undo(originalChars: String)
        /// Standalone character insertion (e.g., [→ơ, ]→ư)
        case standalone(Character)
        /// No transformation needed
        case none
    }

    public let type: TransformationType
    public let targetPosition: Int? // Position relative to end (nil = current)
    public let category: TransformationCategory? // For undo tracking

    public init(type: TransformationType, targetPosition: Int? = nil, category: TransformationCategory? = nil) {
        self.type = type
        self.targetPosition = targetPosition
        self.category = category
    }
}

/// Vietnamese tone marks
public enum ToneMark: Sendable, Equatable {
    case acute      // sắc (á)
    case grave      // huyền (à)
    case hook       // hỏi (ả)
    case tilde      // ngã (ã)
    case dot        // nặng (ạ)
    case none       // remove tone
}

/// Vietnamese modifier marks
public enum ModifierMark: Sendable {
    case circumflex // mũ (â, ê, ô)
    case breve      // trăng (ă)
    case horn       // móc (ơ, ư)
    case stroke     // gạch (đ)
}

// MARK: - Input Method State

/// Tracks state for undo mechanism and temp key disabling
public struct InputMethodState: Sendable {
    /// The last transformation that was applied
    public var lastTransformation: LastTransformation?

    /// Key temporarily disabled after undo (to prevent re-transformation)
    public var tempDisabledKey: Character?

    public init() {
        self.lastTransformation = nil
        self.tempDisabledKey = nil
    }

    /// Disable a key temporarily (after undo)
    public mutating func disableKey(_ char: Character) {
        tempDisabledKey = char.lowercased().first ?? char
    }

    /// Check if a key is temporarily disabled
    public func isDisabled(_ char: Character) -> Bool {
        guard let disabled = tempDisabledKey else { return false }
        return disabled == (char.lowercased().first ?? char)
    }

    /// Reset temporary disabled key (on word break or new session)
    public mutating func resetTempDisabled() {
        tempDisabledKey = nil
    }

    /// Reset all state
    public mutating func reset() {
        lastTransformation = nil
        tempDisabledKey = nil
    }
}

/// Represents the last transformation for undo tracking
public struct LastTransformation: Sendable {
    /// The type of transformation that was applied
    public let type: TransformationCategory

    /// The key that triggered this transformation
    public let triggerKey: Character

    /// The original characters before transformation (for restoration)
    public let originalChars: String

    public init(type: TransformationCategory, triggerKey: Character, originalChars: String) {
        self.type = type
        self.triggerKey = triggerKey
        self.originalChars = originalChars
    }
}

/// Category of transformation for undo matching
public enum TransformationCategory: Sendable, Equatable {
    case circumflex      // aa→â, ee→ê, oo→ô
    case horn            // ow→ơ, uw→ư
    case breve           // aw→ă
    case stroke          // dd→đ
    case tone(ToneMark)  // s→sắc, f→huyền, etc.
    case standaloneHorn  // [→ơ, ]→ư, standalone w→ư
}
