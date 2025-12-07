import Foundation

/// Result of processing a keyboard event
public enum EngineResult: Sendable, Equatable {
    /// No action needed, pass through the original key
    case passThrough
    /// Suppress the key, engine handled it internally
    case suppress
    /// Replace with new characters (backspace count, new string)
    case replace(backspaceCount: Int, replacement: String)
}

/// Protocol defining the Vietnamese input processing engine
public protocol VietnameseEngine: Sendable {
    /// Process a key press event
    /// - Parameters:
    ///   - keyCode: The virtual key code
    ///   - character: The character representation of the key
    ///   - modifiers: Modifier flags (shift, control, etc.)
    /// - Returns: The result indicating how to handle the event
    func processKey(keyCode: UInt16, character: Character?, modifiers: UInt64) -> EngineResult

    /// Reset the engine state (e.g., when focus changes)
    func reset()

    /// Get the current input method
    var inputMethod: any InputMethod { get }

    /// Set the input method
    func setInputMethod(_ method: any InputMethod)

    /// Get the current character table
    var characterTable: any CharacterTable { get }

    /// Set the character table
    func setCharacterTable(_ table: any CharacterTable)

    /// Enable or disable spell checking
    var spellCheckEnabled: Bool { get set }

    /// Get the current buffer content as Unicode string
    var currentText: String { get }

    /// Check if the buffer is empty
    var isEmpty: Bool { get }
}

/// Default implementation of Vietnamese input processing engine
public final class DefaultVietnameseEngine: VietnameseEngine, @unchecked Sendable {
    // MARK: - Properties

    private var _inputMethod: any InputMethod
    private var _characterTable: any CharacterTable
    public var spellCheckEnabled: Bool = true

    /// Enable restore-on-invalid feature (restore original keystrokes when spelling is invalid)
    public var restoreIfWrongSpelling: Bool = true

    /// Temporary disable spell checking (e.g., when Control key is held)
    public var tempOffSpellChecking: Bool = false

    /// Flag to temporarily disable transformation (set when current word is invalid)
    private var tempDisableTransformation: Bool = false

    /// The typing buffer holding current word
    private var buffer: TypingBuffer = TypingBuffer()

    /// Track previous output length for backspace calculation
    private var previousOutputLength: Int = 0

    /// State history for undo/restore functionality (like OpenKey's _typingStates)
    private var stateHistory: [[TypedCharacter]] = []
    private let maxHistorySize = 10

    /// Input method state for undo tracking
    private var inputMethodState: InputMethodState = InputMethodState()

    /// Quick Telex handler for consonant shortcuts (cc=ch, gg=gi, etc.)
    public var quickTelex: QuickTelex = QuickTelex()

    /// Spell checker instance
    private let spellChecker: SpellChecker = DefaultSpellChecker()

    public var inputMethod: any InputMethod { _inputMethod }
    public var characterTable: any CharacterTable { _characterTable }

    public var currentText: String { buffer.toUnicodeString() }
    public var isEmpty: Bool { buffer.isEmpty }

    // MARK: - Initialization

    public init(
        inputMethod: any InputMethod = TelexInputMethod(),
        characterTable: any CharacterTable = UnicodeCharacterTable()
    ) {
        self._inputMethod = inputMethod
        self._characterTable = characterTable
    }

    // MARK: - Main Processing

    public func processKey(keyCode: UInt16, character: Character?, modifiers: UInt64) -> EngineResult {
        // Handle modifier keys (Cmd, Ctrl, etc.) - pass through
        // Cmd = 0x100000, Ctrl = 0x40000
        let cmdMask: UInt64 = 0x100000
        let ctrlMask: UInt64 = 0x40000

        if modifiers & cmdMask != 0 {
            return .passThrough
        }

        // Control key temporarily disables spell checking
        let controlPressed = (modifiers & ctrlMask) != 0
        tempOffSpellChecking = controlPressed

        // Handle backspace
        if keyCode == TypedCharacter.backspaceKeyCode {
            return handleBackspace()
        }

        // Handle break keycodes (ESC, arrows, Tab, Enter) - reset session
        // Check keycode BEFORE character to catch navigation keys that may produce
        // control characters or no character at all.
        // Reference: OpenKey Engine.cpp isWordBreak() checks _breakCode array
        if BreakKeyCodes.isBreakKeyCode(keyCode) {
            return handleBreakKeycode()
        }

        // Need a character to process
        guard let char = character else {
            return .passThrough
        }

        // Check for special keys BEFORE word break check
        // This allows bracket keys ([, ]) to be processed as shortcuts
        if _inputMethod.isSpecialKey(char) {
            return processCharacter(char)
        }

        // Handle word break
        if VietnameseConstants.isWordBreak(char) {
            return handleWordBreak(wordBreakChar: char)
        }

        // Process the character through input method
        return processCharacter(char)
    }

    // MARK: - Character Processing

    private func processCharacter(_ char: Character) -> EngineResult {
        // Record original keystroke for restore-on-invalid feature
        buffer.recordOriginalKey(char)

        // If transformation is temporarily disabled due to invalid spelling, just add as literal
        if tempDisableTransformation {
            return addCharacterToBufferLiteral(char)
        }

        // 1. Check Quick Telex first (before input method)
        if quickTelex.isEnabled,
           let lastChar = buffer.last?.baseCharacter,
           let expansion = quickTelex.processShortcut(char, previousCharacter: lastChar) {
            return applyQuickTelexExpansion(expansion, originalChar: char)
        }

        // Get context string for input method
        let context = buffer.toUnicodeString()

        // 2. Check if input method has a transformation (with state for undo support)
        if let transformation = _inputMethod.processCharacter(char, context: context, state: &inputMethodState) {
            // For undo tracking, we capture what the buffer would look like
            // if we just added the character without transformation.
            // e.g., for "a" + "a" → "â", the originalChars should be "aa" (to restore on undo)
            // Note: undo restores to originalChars WITHOUT adding the undo key again
            let originalCharsForUndo = context + String(char)

            let result = applyTransformation(transformation, originalChar: char)

            // Track this transformation for potential undo (if it was successful and has a category)
            // Only track non-undo transformations
            if case .undo(_) = transformation.type {
                // Don't track undo itself
            } else if case .replace(_, _) = result,
                      let category = transformation.category {
                inputMethodState.lastTransformation = LastTransformation(
                    type: category,
                    triggerKey: char,
                    originalChars: originalCharsForUndo
                )
            }

            // After transformation, check spell validity
            checkSpellingAfterChange()

            return result
        }

        // No transformation - just add character to buffer
        // Clear last transformation since this is a new character
        inputMethodState.lastTransformation = nil
        let result = addCharacterToBuffer(char)

        // Check spelling after adding character
        checkSpellingAfterChange()

        return result
    }

    /// Add character to buffer as literal (no transformation, used when tempDisable is active)
    private func addCharacterToBufferLiteral(_ char: Character) -> EngineResult {
        let oldLength = buffer.toUnicodeString().count

        buffer.append(char)

        return generateResult(previousLength: oldLength)
    }

    /// Check spelling after any change and update tempDisableTransformation flag
    private func checkSpellingAfterChange() {
        // Skip if spell checking is disabled or temporarily off
        guard spellCheckEnabled && !tempOffSpellChecking else {
            tempDisableTransformation = false
            return
        }

        let currentText = buffer.toUnicodeString()
        guard !currentText.isEmpty else {
            tempDisableTransformation = false
            return
        }

        let result = spellChecker.check(currentText)
        switch result {
        case .valid, .unknown:
            // Valid or incomplete - allow transformation
            tempDisableTransformation = false
        case .invalid(_):
            // Invalid spelling - disable further transformations
            tempDisableTransformation = true
        }
    }

    /// Apply Quick Telex expansion (e.g., cc → ch, gg → gi)
    private func applyQuickTelexExpansion(_ expansion: String, originalChar: Character) -> EngineResult {
        let oldLength = previousOutputLength

        // Remove the last character (the first of the doubled pair)
        _ = buffer.removeLast()

        // Add the expansion characters
        for char in expansion {
            buffer.append(char)
        }

        // Clear undo state (Quick Telex expansions are not undoable)
        inputMethodState.lastTransformation = nil

        return generateResult(previousLength: oldLength, wasTransformed: true)
    }

    private func applyTransformation(_ transformation: InputTransformation, originalChar: Character) -> EngineResult {
        let oldOutput = buffer.toUnicodeString()
        let oldLength = oldOutput.count

        var wasTransformed = false

        switch transformation.type {
        case .tone(let toneMark):
            wasTransformed = applyToneMark(toneMark, originalChar: originalChar)

        case .modifier(let modifierMark):
            wasTransformed = applyModifier(modifierMark, originalChar: originalChar)
            // After applying modifier, check if tone needs repositioning
            if wasTransformed {
                _ = buffer.refreshTonePosition()
            }

        case .replace(let replacement):
            applyReplacement(replacement)
            wasTransformed = true

        case .undo(let originalChars):
            // Restore original characters and add the trigger key
            applyUndo(originalChars: originalChars, triggerKey: originalChar)
            wasTransformed = true

        case .standalone(let char):
            // Add standalone character (e.g., [ → ơ, ] → ư)
            // For Vietnamese characters (ơ, ư), we need to compose them properly
            let isUpper = originalChar.isUppercase
            applyStandaloneVowel(char, uppercase: isUpper)
            wasTransformed = true

        case .none:
            // Add character as-is
            buffer.append(originalChar)
        }

        // After any transformation, refresh tone position if needed
        // This handles cases like typing "thuor" then adding more characters
        if wasTransformed {
            _ = buffer.refreshTonePosition()
        }

        return generateResult(previousLength: oldLength, wasTransformed: wasTransformed)
    }

    /// Apply undo: restore original characters
    /// The originalChars already includes the key sequence (e.g., "aa" for circumflex undo)
    private func applyUndo(originalChars: String, triggerKey: Character) {
        // Save original keystrokes before clearing (they were recorded in processCharacter)
        // This preserves the full keystroke history for restore-on-invalid feature
        let savedKeystrokes = buffer.allOriginalKeys

        // Clear current buffer (this also clears keyStates)
        buffer.clear()

        // Restore original characters (already includes the key sequence)
        for char in originalChars {
            buffer.append(char)
        }

        // Restore the saved keystrokes so restore-on-invalid works correctly
        for key in savedKeystrokes {
            buffer.recordOriginalKey(key)
        }
        // Note: We do NOT add triggerKey again - originalChars already has the complete sequence
    }

    /// Apply a standalone Vietnamese vowel (e.g., ơ, ư)
    /// These need to be composed from base + modifier since we store ASCII bases
    private func applyStandaloneVowel(_ char: Character, uppercase: Bool) {
        switch char {
        case "ơ", "Ơ":
            // ơ = o + horn
            var typedChar = TypedCharacter(character: "o", caps: uppercase)
            typedChar.state.insert(.hornOrBreve)
            buffer.append(typedChar)

        case "ư", "Ư":
            // ư = u + horn
            var typedChar = TypedCharacter(character: "u", caps: uppercase)
            typedChar.state.insert(.hornOrBreve)
            buffer.append(typedChar)

        case "ă", "Ă":
            // ă = a + breve
            var typedChar = TypedCharacter(character: "a", caps: uppercase)
            typedChar.state.insert(.hornOrBreve)
            buffer.append(typedChar)

        case "â", "Â":
            // â = a + circumflex
            var typedChar = TypedCharacter(character: "a", caps: uppercase)
            typedChar.state.insert(.circumflex)
            buffer.append(typedChar)

        case "ê", "Ê":
            // ê = e + circumflex
            var typedChar = TypedCharacter(character: "e", caps: uppercase)
            typedChar.state.insert(.circumflex)
            buffer.append(typedChar)

        case "ô", "Ô":
            // ô = o + circumflex
            var typedChar = TypedCharacter(character: "o", caps: uppercase)
            typedChar.state.insert(.circumflex)
            buffer.append(typedChar)

        case "đ", "Đ":
            // đ = d + stroke
            var typedChar = TypedCharacter(character: "d", caps: uppercase)
            typedChar.state.insert(.stroke)
            buffer.append(typedChar)

        default:
            // For regular ASCII characters, just add them
            buffer.append(TypedCharacter(character: char, caps: uppercase))
        }
    }

    /// Apply tone mark to appropriate vowel
    /// - Returns: true if mark was applied, false if character was added as literal
    @discardableResult
    private func applyToneMark(_ mark: ToneMark, originalChar: Character) -> Bool {
        let state: CharacterState
        switch mark {
        case .acute: state = .acute
        case .grave: state = .grave
        case .hook: state = .hook
        case .tilde: state = .tilde
        case .dot: state = .dotBelow
        case .none:
            // Remove existing tone mark
            if buffer.removeMark() {
                return true
            }
            // No mark to remove, add character as literal
            buffer.append(originalChar)
            return false
        }

        // Check spell validity before applying (if enabled)
        if spellCheckEnabled {
            // Check if this tone would be valid with current ending consonant
            if let ending = buffer.findEndingConsonant() {
                if !VietnameseConstants.isValidToneWithEnding(tone: state, ending: ending.pattern) {
                    // Invalid tone for this ending - add as literal
                    buffer.append(originalChar)
                    return false
                }
            }
        }

        if buffer.applyMark(state) {
            return true
        }

        // No vowel to apply mark to - add character as literal
        buffer.append(originalChar)
        return false
    }

    /// Apply modifier mark to appropriate character
    /// - Returns: true if modifier was applied, false if character was added as literal
    @discardableResult
    private func applyModifier(_ modifier: ModifierMark, originalChar: Character) -> Bool {
        switch modifier {
        case .circumflex:
            // For double-letter like 'aa' -> 'â', 'ee' -> 'ê', 'oo' -> 'ô'
            // Find the matching vowel in buffer
            let loweredChar = originalChar.lowercased().first ?? originalChar
            if let index = findLastVowel(matching: loweredChar) {
                buffer.applyModifier(.circumflex, at: index)
                return true
            } else {
                buffer.append(originalChar)
                return false
            }

        case .breve:
            // 'w' after 'a' -> 'ă'
            if let index = findLastVowel(matching: "a") {
                buffer.applyModifier(.hornOrBreve, at: index)
                return true
            } else {
                buffer.append(originalChar)
                return false
            }

        case .horn:
            // 'w' after 'o' -> 'ơ', 'w' after 'u' -> 'ư'
            // For "ươ" combination, apply horn to both u and o
            let oIndex = findLastVowel(matching: "o")
            let uIndex = findLastVowel(matching: "u")

            // Check for "uo" pattern - apply horn to both for "ươ"
            if let oi = oIndex, let ui = uIndex, ui == oi - 1 {
                // "uo" pattern found - make it "ươ"
                buffer.applyModifier(.hornOrBreve, at: ui)
                buffer.applyModifier(.hornOrBreve, at: oi)
                return true
            }

            // Otherwise apply to 'o' first, then 'u'
            if let index = oIndex {
                buffer.applyModifier(.hornOrBreve, at: index)
                return true
            } else if let index = uIndex {
                buffer.applyModifier(.hornOrBreve, at: index)
                return true
            } else {
                buffer.append(originalChar)
                return false
            }

        case .stroke:
            // 'dd' -> 'đ'
            if let index = findLastConsonant(matching: "d") {
                buffer[index].state.insert(.stroke)
                return true
            } else {
                buffer.append(originalChar)
                return false
            }
        }
    }

    /// Find last vowel matching a specific character
    private func findLastVowel(matching char: Character) -> Int? {
        buffer.findVowelPositions().last { buffer[$0].baseCharacter == char }
    }

    /// Find last vowel matching any of the given characters
    private func findLastVowel(matchingAny chars: [Character]) -> Int? {
        buffer.findVowelPositions().last { index in
            if let base = buffer[index].baseCharacter {
                return chars.contains(base)
            }
            return false
        }
    }

    /// Find last consonant matching a specific character
    private func findLastConsonant(matching char: Character) -> Int? {
        for i in stride(from: buffer.count - 1, through: 0, by: -1) {
            if buffer[i].baseCharacter == char && !buffer[i].isVowel {
                return i
            }
        }
        return nil
    }

    private func applyReplacement(_ replacement: String) {
        // Remove last character and add replacement
        _ = buffer.removeLast()
        for char in replacement {
            buffer.append(char)
        }
    }

    private func addCharacterToBuffer(_ char: Character) -> EngineResult {
        let oldLength = buffer.toUnicodeString().count

        buffer.append(char)

        // After adding a character, check if tone needs repositioning
        // This handles cases like adding ending consonant after vowel with tone
        _ = buffer.refreshTonePosition()

        // Track whether grammar auto-adjustment occurred (triggers replace instead of passthrough)
        var wasTransformed = false

        // Check grammar auto-adjust when a trigger consonant is typed
        // This handles non-standard typing orders like "thuwon" → "thương"
        if isGrammarTriggerConsonant(char.lowercased().first) {
            wasTransformed = checkGrammar()
            if wasTransformed {
                // Grammar was adjusted - need to regenerate output
                // since vowel modifiers changed
                _ = buffer.refreshTonePosition()
            }
        }

        return generateResult(previousLength: oldLength, wasTransformed: wasTransformed)
    }

    // MARK: - Grammar Auto-Adjust

    /// Grammar trigger consonants - when typed after "uo" pattern, check for auto-correction
    /// These are ending consonants that finalize the syllable structure
    private static let grammarTriggerConsonants: Set<Character> = ["n", "c", "i", "m", "p", "t"]

    /// Check for "uo" pattern with partial horn and auto-correct (XOR logic).
    ///
    /// Implements OpenKey's `checkGrammar()` behavior (Engine.cpp:290-347):
    /// - Only adjusts if exactly one of U/O has horn (XOR = true)
    /// - ưo → ươ (u has horn, o doesn't)
    /// - uơ → ươ (o has horn, u doesn't)
    /// - Does NOT change: uo (neither has horn) or ươ (both have horn)
    ///
    /// This handles non-standard typing orders like "thuwong" → "thương"
    /// where user types horn on "u" first, then "o", then ending consonant.
    ///
    /// - Returns: true if grammar was adjusted, false otherwise
    @discardableResult
    private func checkGrammar() -> Bool {
        // Need at least 3 characters for "uo" + consonant pattern
        guard buffer.count >= 3 else { return false }

        let chars = buffer.allCharacters

        // Scan backward looking for "uo" + trigger consonant pattern
        // The pattern we're looking for: u at [i-2], o at [i-1], consonant at [i]
        for i in stride(from: buffer.count - 1, through: 2, by: -1) {
            guard let base = chars[i].baseCharacter else { continue }

            // Check if current char is a grammar trigger consonant
            guard Self.grammarTriggerConsonants.contains(base) else { continue }

            // Check for "uo" pattern before the consonant
            let oIndex = i - 1
            let uIndex = i - 2

            guard let oBase = chars[oIndex].baseCharacter,
                  let uBase = chars[uIndex].baseCharacter,
                  oBase == "o", uBase == "u" else { continue }

            let oHasHorn = chars[oIndex].state.contains(.hornOrBreve)
            let uHasHorn = chars[uIndex].state.contains(.hornOrBreve)

            // XOR check: exactly one has horn → apply horn to both
            // ưo (true, false) → ươ
            // uơ (false, true) → ươ
            // uo (false, false) → no change (user didn't intend horn)
            // ươ (true, true) → no change (already correct)
            if uHasHorn != oHasHorn {
                buffer[uIndex].state.insert(.hornOrBreve)
                buffer[oIndex].state.insert(.hornOrBreve)
                return true
            }
        }

        return false
    }

    /// Check if a character is a grammar trigger consonant
    private func isGrammarTriggerConsonant(_ char: Character?) -> Bool {
        guard let c = char else { return false }
        return Self.grammarTriggerConsonants.contains(c)
    }

    // MARK: - Backspace Handling

    /// Handles backspace key following OpenKey's proven approach:
    /// - Engine only updates internal state (buffer tracking)
    /// - Backspace ALWAYS passes through to let the system handle deletion
    /// - No text injection during backspace - simple and fast
    private func handleBackspace() -> EngineResult {
        if buffer.isEmpty {
            // Buffer already empty - just pass through
            // Do NOT restore from history here - that would create buffer/screen mismatch
            // History restoration is only for explicit "undo" action (Ctrl+Z), not backspace
            return .passThrough
        }

        // Save current state before removing (for potential undo via Ctrl+Z)
        saveToHistory()

        // Update internal buffer
        _ = buffer.removeLast()

        // Update output length tracking (NFC = 1 char per visual char)
        previousOutputLength = max(0, previousOutputLength - 1)

        if buffer.isEmpty {
            // Buffer is now empty - reset all state for new word
            previousOutputLength = 0
            inputMethodState.reset()
            tempDisableTransformation = false
            tempOffSpellChecking = false
        } else {
            // Refresh tone position and check spelling on remaining buffer
            _ = buffer.refreshTonePosition()
            checkSpellingAfterChange()
        }

        // ALWAYS pass through - let system handle the deletion
        // Key insight from OpenKey: never output text on backspace
        return .passThrough
    }

    // MARK: - State History Management

    /// Save current buffer state to history
    private func saveToHistory() {
        guard !buffer.isEmpty else { return }

        if stateHistory.count >= maxHistorySize {
            stateHistory.removeFirst()
        }
        stateHistory.append(buffer.allCharacters)
    }

    /// Restore buffer from history
    /// - Returns: true if restored successfully
    private func restoreFromHistory() -> Bool {
        guard let lastState = stateHistory.popLast(), !lastState.isEmpty else {
            return false
        }

        buffer.clear()
        for char in lastState {
            buffer.append(char)
        }
        return true
    }

    /// Clear state history
    private func clearHistory() {
        stateHistory.removeAll()
    }

    // MARK: - Break Keycode Handling

    /// Handles break keycodes (ESC, arrows, Tab, Enter) that reset the typing session.
    ///
    /// Unlike word break *characters* (space, punctuation), break *keycodes* are detected
    /// by their virtual key code, not the character they produce. This ensures navigation
    /// keys are caught even if they produce control characters or no character at all.
    ///
    /// Behavior:
    /// 1. Check restore-if-wrong-spelling (if enabled and spelling is invalid)
    /// 2. Reset the engine buffer
    /// 3. Return `.passThrough` to let the key event pass to the application
    ///
    /// Unlike word break characters, break keycodes do NOT:
    /// - Append any character to the output
    /// - Save to history (ESC = cancel, arrows = navigation)
    ///
    /// Reference: OpenKey Engine.cpp isWordBreak() and startNewSession()
    private func handleBreakKeycode() -> EngineResult {
        // Check for restore-on-invalid before resetting
        if let restoreResult = checkRestoreIfWrongSpellingForBreakKey() {
            reset()
            return restoreResult
        }

        // Reset buffer and state (no history save for break keycodes)
        reset()
        return .passThrough
    }

    /// Check if spelling is wrong and restore original keystrokes for break keycodes.
    /// Delegates to shared implementation with no suffix character.
    private func checkRestoreIfWrongSpellingForBreakKey() -> EngineResult? {
        checkRestoreIfWrongSpellingCore(suffixChar: nil)
    }

    // MARK: - Word Break Handling

    private func handleWordBreak(wordBreakChar: Character) -> EngineResult {
        // Check for restore-on-invalid at word boundary
        if let restoreResult = checkRestoreIfWrongSpelling(wordBreakChar: wordBreakChar) {
            // Clear state after restore
            buffer.clear()
            previousOutputLength = 0
            inputMethodState.reset()
            tempDisableTransformation = false
            return restoreResult
        }

        // Save current word to history before clearing
        if !buffer.isEmpty {
            saveToHistory()
        }

        // Finalize current word and start new session
        buffer.clear()
        previousOutputLength = 0
        inputMethodState.reset()
        tempDisableTransformation = false
        return .passThrough
    }

    /// Check if spelling is wrong and restore original keystrokes if enabled.
    /// Called at word boundary (space, punctuation).
    /// - Parameter wordBreakChar: The word break character (space, punctuation) to append after restoration
    /// - Returns: EngineResult if restoration occurred, nil otherwise
    private func checkRestoreIfWrongSpelling(wordBreakChar: Character) -> EngineResult? {
        checkRestoreIfWrongSpellingCore(suffixChar: wordBreakChar)
    }

    /// Core implementation for restore-if-wrong-spelling check.
    ///
    /// - Parameter suffixChar: Optional character to append after restoration.
    ///   - For word break characters (space, punctuation): the break char is appended
    ///   - For break keycodes (ESC, arrows): nil, no character appended
    /// - Returns: EngineResult if restoration occurred, nil otherwise
    private func checkRestoreIfWrongSpellingCore(suffixChar: Character?) -> EngineResult? {
        // Skip if feature is disabled or spell checking is off/bypassed
        guard restoreIfWrongSpelling,
              spellCheckEnabled,
              !tempOffSpellChecking else {
            return nil
        }

        // Need both transformed text and original keystrokes
        let currentText = buffer.toUnicodeString()
        let originalKeys = buffer.originalKeystrokes
        guard !currentText.isEmpty, !originalKeys.isEmpty else {
            return nil
        }

        // Only restore if current spelling is invalid
        let result = spellChecker.check(currentText)
        guard case .invalid = result else {
            return nil
        }

        // Restore: delete transformed text and output original keystrokes
        let backspaceCount = previousOutputLength
        let replacement = suffixChar.map { originalKeys + String($0) } ?? originalKeys
        return .replace(backspaceCount: backspaceCount, replacement: replacement)
    }

    // MARK: - Result Generation

    private func generateResult(previousLength: Int, wasTransformed: Bool = false) -> EngineResult {
        let newOutput = buffer.toUnicodeString()
        let newLength = newOutput.count

        let backspaces = previousOutputLength
        previousOutputLength = newLength

        // Pass through when no transformation occurred.
        // The keystroke will be displayed by the system - we just track it internally.
        // This eliminates flickering for normal keystrokes (e.g., "hi" -> no backspace needed).
        if !wasTransformed {
            return .passThrough
        }

        // Transformation occurred - need to replace text.
        // Send backspaces to delete old chars, then send new transformed text.
        return .replace(backspaceCount: backspaces, replacement: newOutput)
    }

    // MARK: - State Management

    public func reset() {
        buffer.clear()
        previousOutputLength = 0
        clearHistory()
        inputMethodState.reset()
        tempDisableTransformation = false
        tempOffSpellChecking = false
    }

    public func setInputMethod(_ method: any InputMethod) {
        _inputMethod = method
    }

    public func setCharacterTable(_ table: any CharacterTable) {
        _characterTable = table
    }
}

// MARK: - Testing Helpers

extension DefaultVietnameseEngine {
    /// Process a string of characters (for testing)
    public func processString(_ string: String) -> String {
        reset()
        var result = ""

        for char in string {
            let engineResult = processKey(
                keyCode: 0,
                character: char,
                modifiers: 0
            )

            switch engineResult {
            case .passThrough:
                result.append(char)
            case .suppress:
                break
            case .replace(let backspaces, let replacement):
                // Remove backspaces from result
                if backspaces > 0 && result.count >= backspaces {
                    result.removeLast(backspaces)
                }
                result.append(replacement)
            }
        }

        return result
    }

    /// Get internal buffer for testing
    public var testBuffer: TypingBuffer {
        buffer
    }

    /// Check if current buffer has valid Vietnamese spelling
    public var isValidSpelling: Bool {
        buffer.isValidVietnameseSyllable()
    }
}
