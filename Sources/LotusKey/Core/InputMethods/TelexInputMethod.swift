import Foundation

/// Telex input method implementation
public struct TelexInputMethod: InputMethod {
    public let name = "Telex"

    /// Characters that block standalone w/bracket transformation
    public static let standaloneBlockers: Set<Character> = ["w", "e", "y", "f", "j", "k", "z"]

    /// Vietnamese vowels for context checking
    private static let vowels: Set<Character> = ["a", "e", "i", "o", "u", "y", "ă", "â", "ê", "ô", "ơ", "ư"]

    public init() {}

    // MARK: - Simple Processing (backward compatibility)

    public func processCharacter(_ character: Character, context: String) -> InputTransformation? {
        var state = InputMethodState()
        return processCharacter(character, context: context, state: &state)
    }

    // MARK: - Processing with State (supports undo)

    public func processCharacter(_ character: Character, context: String, state: inout InputMethodState) -> InputTransformation? {
        let char = character.lowercased().first ?? character

        // Check if key is temporarily disabled (after undo)
        if state.isDisabled(char) {
            return nil
        }

        // Check for undo opportunity FIRST
        if let undoTransform = checkForUndo(char, context: context, state: &state) {
            return undoTransform
        }

        // Check for bracket key shortcuts
        if char == "[" || char == "]" {
            return handleBracketKey(char, context: context, state: &state)
        }

        switch char {
        // Tone marks
        case "s":
            return InputTransformation(type: .tone(.acute), category: .tone(.acute))
        case "f":
            return InputTransformation(type: .tone(.grave), category: .tone(.grave))
        case "r":
            return InputTransformation(type: .tone(.hook), category: .tone(.hook))
        case "x":
            return InputTransformation(type: .tone(.tilde), category: .tone(.tilde))
        case "j":
            return InputTransformation(type: .tone(.dot), category: .tone(.dot))
        case "z":
            return InputTransformation(type: .tone(.none), category: .tone(.none))

        // Modifier marks (circumflex: aa, ee, oo)
        case "a" where context.lowercased().hasSuffix("a"):
            return InputTransformation(type: .modifier(.circumflex), category: .circumflex)
        case "e" where context.lowercased().hasSuffix("e"):
            return InputTransformation(type: .modifier(.circumflex), category: .circumflex)
        case "o" where context.lowercased().hasSuffix("o"):
            return InputTransformation(type: .modifier(.circumflex), category: .circumflex)

        // W key handling (breve/horn)
        case "w":
            return handleWKey(context: context, state: &state)

        // Stroke (dd)
        case "d" where context.lowercased().hasSuffix("d"):
            return InputTransformation(type: .modifier(.stroke), category: .stroke)

        default:
            return nil
        }
    }

    public func isSpecialKey(_ character: Character) -> Bool {
        let specialKeys: Set<Character> = ["s", "f", "r", "x", "j", "z", "w", "[", "]"]
        return specialKeys.contains(character.lowercased().first ?? character)
    }

    // MARK: - W Key Handling

    private func handleWKey(context: String, state: inout InputMethodState) -> InputTransformation? {
        let lower = context.lowercased()

        if lower.hasSuffix("a") {
            // aw → ă (breve)
            return InputTransformation(type: .modifier(.breve), category: .breve)
        } else if lower.hasSuffix("u") || lower.hasSuffix("o") {
            // uw → ư, ow → ơ (horn)
            return InputTransformation(type: .modifier(.horn), category: .horn)
        } else {
            // Standalone w → ư (only in Telex, not Simple Telex)
            return handleStandaloneW(context: context, state: &state)
        }
    }

    /// Handle standalone w → ư transformation
    internal func handleStandaloneW(context: String, state: inout InputMethodState) -> InputTransformation? {
        // Empty context → transform to ư
        guard let lastChar = context.last?.lowercased().first else {
            return InputTransformation(type: .standalone("ư"), category: .standaloneHorn)
        }

        // After vowel → no transformation (vowel handling above)
        if Self.vowels.contains(lastChar) {
            return nil
        }

        // After blocker character → literal
        if Self.standaloneBlockers.contains(lastChar) {
            return nil
        }

        // After consonant → transform to ư
        return InputTransformation(type: .standalone("ư"), category: .standaloneHorn)
    }

    // MARK: - Bracket Key Shortcuts

    /// Handle [ → ơ and ] → ư shortcuts
    internal func handleBracketKey(_ char: Character, context: String, state: inout InputMethodState) -> InputTransformation? {
        let replacement: Character = char == "[" ? "ơ" : "ư"

        // Empty context → transform
        guard let lastChar = context.last?.lowercased().first else {
            return InputTransformation(type: .standalone(replacement), category: .standaloneHorn)
        }

        // Special case: u[ → uơ
        if char == "[" && lastChar == "u" {
            return InputTransformation(type: .standalone("ơ"), category: .standaloneHorn)
        }

        // After vowel → literal (pass through)
        if Self.vowels.contains(lastChar) {
            return nil
        }

        // After blocker character → literal
        if Self.standaloneBlockers.contains(lastChar) {
            return nil
        }

        // After consonant → transform
        return InputTransformation(type: .standalone(replacement), category: .standaloneHorn)
    }

    // MARK: - Undo Detection

    /// Check if current character would undo the last transformation
    private func checkForUndo(_ char: Character, context: String, state: inout InputMethodState) -> InputTransformation? {
        guard let last = state.lastTransformation else {
            return nil
        }

        let triggerLower = last.triggerKey.lowercased().first ?? last.triggerKey

        // Undo is triggered when the same key is pressed again
        guard char == triggerLower else {
            return nil
        }

        switch last.type {
        case .circumflex:
            // aaa → aa (undo circumflex)
            if char == "a" || char == "e" || char == "o" {
                state.disableKey(char)
                state.lastTransformation = nil
                return InputTransformation(type: .undo(originalChars: last.originalChars))
            }

        case .stroke:
            // ddd → dd (undo stroke)
            if char == "d" {
                state.disableKey(char)
                state.lastTransformation = nil
                return InputTransformation(type: .undo(originalChars: last.originalChars))
            }

        case .horn:
            // oww → ow, uww → uw (undo horn)
            if char == "w" {
                state.disableKey(char)
                state.lastTransformation = nil
                return InputTransformation(type: .undo(originalChars: last.originalChars))
            }

        case .breve:
            // aww → aw (undo breve)
            if char == "w" {
                state.disableKey(char)
                state.lastTransformation = nil
                return InputTransformation(type: .undo(originalChars: last.originalChars))
            }

        case .tone(let toneMark):
            // ass → as, aff → af (undo tone)
            let toneKey = toneKeyFor(toneMark)
            if char == toneKey {
                state.disableKey(char)
                state.lastTransformation = nil
                return InputTransformation(type: .undo(originalChars: last.originalChars))
            }

        case .standaloneHorn:
            // Not undoable in the same way
            break
        }

        return nil
    }

    /// Get the Telex key for a tone mark
    private func toneKeyFor(_ mark: ToneMark) -> Character {
        switch mark {
        case .acute: return "s"
        case .grave: return "f"
        case .hook: return "r"
        case .tilde: return "x"
        case .dot: return "j"
        case .none: return "z"
        }
    }
}
