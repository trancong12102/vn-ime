import Foundation

/// Simple Telex input method variant.
///
/// Key differences from standard Telex:
/// - `ow` stays `ow` (no horn transformation to ơ)
/// - `uw` stays `uw` (no horn transformation to ư)
/// - `aw` → `ă` (breve still works)
/// - Standalone `w` stays `w` (no → ư conversion)
/// - Bracket keys `[` → ơ, `]` → ư still work
///
/// Reference: OpenKey's vSimpleTelex1 at Engine.cpp:1187
public struct SimpleTelexInputMethod: InputMethod {
    public let name = "Simple Telex"

    /// Delegate to standard Telex for most operations
    private let telex = TelexInputMethod()

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

        // Check for undo opportunity FIRST (before W handling)
        // This allows aww → aw (undo breve) to work in Simple Telex
        if let undoTransform = checkForUndo(char, state: &state) {
            return undoTransform
        }

        // Special handling for W key in Simple Telex
        if char == "w" {
            return handleSimpleTelexWKey(context: context, state: &state)
        }

        // Everything else delegates to standard Telex
        return telex.processCharacter(character, context: context, state: &state)
    }

    public func isSpecialKey(_ character: Character) -> Bool {
        telex.isSpecialKey(character)
    }

    // MARK: - Undo Detection

    /// Check if current character would undo the last transformation
    /// Simple Telex only supports undo for breve (aww → aw)
    private func checkForUndo(_ char: Character, state: inout InputMethodState) -> InputTransformation? {
        guard let last = state.lastTransformation else {
            return nil
        }

        let triggerLower = last.triggerKey.lowercased().first ?? last.triggerKey

        // Undo is triggered when the same key is pressed again
        guard char == triggerLower else {
            return nil
        }

        // Simple Telex only undoes breve (aww → aw)
        // Horn undo is not applicable since ow/uw don't transform
        if case .breve = last.type, char == "w" {
            state.disableKey(char)
            state.lastTransformation = nil
            return InputTransformation(type: .undo(originalChars: last.originalChars))
        }

        return nil
    }

    // MARK: - W Key Handling (Simple Telex specific)

    /// Handle W key with Simple Telex rules:
    /// - `ow` stays `ow` (no horn)
    /// - `uw` stays `uw` (no horn)
    /// - `aw` → `ă` (breve still works)
    /// - Standalone `w` stays `w`
    private func handleSimpleTelexWKey(context: String, state: inout InputMethodState) -> InputTransformation? {
        let lower = context.lowercased()

        // Case 1: w after o/u → no transformation (literal w)
        if lower.hasSuffix("o") || lower.hasSuffix("u") {
            return nil  // Pass through as literal
        }

        // Case 2: w after a → breve (ă)
        if lower.hasSuffix("a") {
            return InputTransformation(type: .modifier(.breve), category: .breve)
        }

        // Case 3: Standalone w → no transformation (unlike Telex)
        // Simple Telex does NOT convert standalone w to ư
        return nil
    }
}
