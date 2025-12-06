import Foundation

/// Buffer that stores the current word being typed with complete state metadata.
///
/// Manages character storage, mark positioning, and Unicode output generation
/// according to Vietnamese orthography rules.
public struct TypingBuffer: Sendable {
    /// Maximum buffer capacity (matches original OpenKey)
    public static let maxCapacity = 64

    /// Characters in the buffer
    private var characters: [TypedCharacter] = []

    /// Track the number of characters that have been output
    /// (used to calculate backspace count)
    private var outputCount: Int = 0

    /// KeyStates buffer - stores original keystrokes before any transformation.
    /// Used for restore-on-invalid feature (matches OpenKey's KeyStates[MAX_BUFF]).
    private var keyStates: [Character] = []

    // MARK: - Initialization

    public init() {}

    // MARK: - Basic Properties

    /// Number of characters in the buffer
    public var count: Int { characters.count }

    /// Check if buffer is empty
    public var isEmpty: Bool { characters.isEmpty }

    /// Check if buffer is at maximum capacity
    public var isFull: Bool { count >= Self.maxCapacity }

    /// Access characters by index
    public subscript(index: Int) -> TypedCharacter {
        get { characters[index] }
        set { characters[index] = newValue }
    }

    /// All characters in the buffer
    public var allCharacters: [TypedCharacter] { characters }

    // MARK: - Buffer Operations

    /// Add a character to the buffer
    /// - Returns: true if successful, false if buffer is full
    @discardableResult
    public mutating func append(_ char: TypedCharacter) -> Bool {
        guard !isFull else { return false }
        characters.append(char)
        return true
    }

    /// Add a character from a Character value
    @discardableResult
    public mutating func append(_ char: Character) -> Bool {
        append(TypedCharacter(character: char))
    }

    /// Add a character to the buffer and record original keystroke
    /// - Parameters:
    ///   - char: The TypedCharacter to add
    ///   - originalKey: The original key pressed (for restore-on-invalid)
    /// - Returns: true if successful, false if buffer is full
    @discardableResult
    public mutating func append(_ char: TypedCharacter, originalKey: Character) -> Bool {
        guard !isFull else { return false }
        characters.append(char)
        keyStates.append(originalKey)
        return true
    }

    /// Record an original keystroke without adding a character (for transformation keys)
    public mutating func recordOriginalKey(_ key: Character) {
        guard keyStates.count < Self.maxCapacity else { return }
        keyStates.append(key)
    }

    /// Remove and return the last character
    @discardableResult
    public mutating func removeLast() -> TypedCharacter? {
        guard !isEmpty else { return nil }
        // Also remove from keyStates if present
        if !keyStates.isEmpty {
            keyStates.removeLast()
        }
        return characters.removeLast()
    }

    /// Clear the buffer
    public mutating func clear() {
        characters.removeAll()
        keyStates.removeAll()
        outputCount = 0
    }

    /// Get the last character without removing it
    public var last: TypedCharacter? {
        characters.last
    }

    /// Get character at index from the end (0 = last)
    public func fromEnd(_ offset: Int) -> TypedCharacter? {
        let index = count - 1 - offset
        guard index >= 0 else { return nil }
        return characters[index]
    }

    // MARK: - Syllable Structure Analysis

    /// Get base characters as array for analysis
    private var baseChars: [Character] {
        characters.compactMap { $0.baseCharacter }
    }

    /// Find the start index of the vowel nucleus (skipping qu-/gi- consonant clusters)
    public func findVowelStartIndex() -> Int? {
        let chars = baseChars
        guard !chars.isEmpty else { return nil }

        for i in 0..<chars.count {
            let char = chars[i]

            // Skip 'u' if part of 'qu' cluster
            if char == "u" && VietnameseConstants.isUPartOfQu(buffer: chars, uIndex: i) {
                continue
            }

            // Skip 'i' if part of 'gi' cluster
            if char == "i" && VietnameseConstants.isIPartOfGi(buffer: chars, iIndex: i) {
                continue
            }

            if VietnameseConstants.baseVowels.contains(char) {
                return i
            }
        }
        return nil
    }

    /// Find all vowel positions in the buffer (accounting for qu-/gi- clusters)
    public func findVowelPositions() -> [Int] {
        let chars = baseChars
        var positions: [Int] = []

        for i in 0..<chars.count {
            let char = chars[i]

            // Skip 'u' if part of 'qu' cluster
            if char == "u" && VietnameseConstants.isUPartOfQu(buffer: chars, uIndex: i) {
                continue
            }

            // Skip 'i' if part of 'gi' cluster
            if char == "i" && VietnameseConstants.isIPartOfGi(buffer: chars, iIndex: i) {
                continue
            }

            if characters[i].isVowel {
                positions.append(i)
            }
        }

        return positions
    }

    /// Find ending consonant pattern (if any) after the vowels
    public func findEndingConsonant() -> (pattern: String, startIndex: Int)? {
        let vowelPositions = findVowelPositions()
        guard let lastVowelIndex = vowelPositions.last else { return nil }

        let chars = baseChars
        guard lastVowelIndex + 1 < chars.count else { return nil }

        // Build ending consonant string
        var ending = ""
        let startIndex = lastVowelIndex + 1
        for i in startIndex..<chars.count {
            ending.append(chars[i])
        }

        // Check if it's a valid Vietnamese ending consonant
        if VietnameseConstants.endConsonants.contains(ending.lowercased()) {
            return (ending.lowercased(), startIndex)
        }

        // Check single character ending
        if ending.count > 1 {
            let firstChar = String(ending.prefix(1)).lowercased()
            if VietnameseConstants.endConsonants.contains(firstChar) {
                return (firstChar, startIndex)
            }
        }

        return nil
    }

    /// Check if buffer has a "sharp" ending consonant (c, ch, p, t)
    public var hasSharpEnding: Bool {
        guard let ending = findEndingConsonant() else { return false }
        return VietnameseConstants.sharpEndConsonants.contains(ending.pattern)
    }

    // MARK: - Mark Positioning (Modern Vietnamese Orthography)

    /// Find the position where a tone mark should be placed (modern orthography)
    ///
    /// Vietnamese tone mark placement rules (modern style):
    /// 1. Single vowel: mark on that vowel
    /// 2. Modified vowel (â, ê, ô, ơ, ư, ă): mark on modified vowel
    /// 3. Double vowels with ending consonant: specific rules apply
    /// 4. Double vowels without ending: specific rules apply
    /// 5. Triple vowels: mark usually on middle vowel
    public func findMarkPosition() -> Int? {
        let vowelPositions = findVowelPositions()

        // No vowels - cannot place mark
        guard !vowelPositions.isEmpty else { return nil }

        // Single vowel - place mark there
        if vowelPositions.count == 1 {
            return vowelPositions[0]
        }

        // Check for modified vowels (â, ê, ô, ơ, ư, ă) - they get priority
        let modifiedPositions = vowelPositions.filter { characters[$0].isModifiedVowel }
        if modifiedPositions.count == 1 {
            return modifiedPositions[0]
        }

        // Get vowel pattern for rule matching
        let chars = baseChars
        let vowelChars = vowelPositions.compactMap { chars[$0] }
        let pattern = String(vowelChars)
        let hasEnding = findEndingConsonant() != nil

        // Handle triple vowel combinations (3+ vowels)
        if vowelPositions.count >= 3 {
            if let pos = handleTripleVowelMarkPosition(pattern: pattern, positions: vowelPositions, hasEnding: hasEnding) {
                return pos
            }
        }

        // Handle double vowel combinations
        if vowelPositions.count >= 2 {
            if let pos = handleDoubleVowelMarkPosition(pattern: pattern, positions: vowelPositions, hasEnding: hasEnding) {
                return pos
            }
        }

        // Default: last vowel
        return vowelPositions.last
    }

    /// Handle mark position for double vowel combinations
    private func handleDoubleVowelMarkPosition(pattern: String, positions: [Int], hasEnding: Bool) -> Int? {
        // Rules based on OpenKey's handleModernMark() and Vietnamese orthography

        // iê, yê with ending consonant: mark on ê (second vowel)
        // Example: "tiến", "yến" → mark on 'ê'
        if (pattern == "ie" || pattern == "ye") && hasEnding {
            // Check if 'e' has circumflex modifier
            if characters[positions[1]].state.contains(.circumflex) {
                return positions[1]
            }
            return positions[1]
        }

        // uô with ending consonant: mark on ô (second vowel)
        // Example: "cuốn", "muốn" → mark on 'ô'
        if pattern == "uo" && hasEnding {
            if characters[positions[1]].state.contains(.circumflex) {
                return positions[1]
            }
            return positions[1]
        }

        // ươ: mark on ơ (second vowel) - both have horn modifier
        // Example: "nước", "được" → mark on 'ơ'
        if pattern == "uo" {
            let uHasHorn = characters[positions[0]].state.contains(.hornOrBreve)
            let oHasHorn = characters[positions[1]].state.contains(.hornOrBreve)
            if uHasHorn && oHasHorn {
                return positions[1]  // Mark on ơ
            }
        }

        // Modern orthography: oa, oe, uy → mark on SECOND vowel
        // Example: "hoà", "loè", "quý"
        let markOnSecond: Set<String> = ["oa", "oe", "uy"]
        if markOnSecond.contains(pattern) {
            return positions[1]
        }

        // ai, ao, au, ay, âu, ây: mark on FIRST vowel
        // Example: "hai", "cao", "đau", "bay", "đâu", "lây"
        let markOnFirst: Set<String> = [
            "ai", "ao", "au", "ay",
            "eo", "eu",
            "iu",
            "oi", "ou",
            "ui",
        ]
        if markOnFirst.contains(pattern) {
            return positions[0]
        }

        // ia, ua without ending: mark on FIRST vowel
        // Example: "mía", "lúa"
        // ia, ua WITH ending: mark on SECOND vowel
        // Example: "miến" (but this is "iê" not "ia")
        if pattern == "ia" || pattern == "ua" {
            if hasEnding {
                return positions[1]
            }
            return positions[0]
        }

        // io, uo without horn: mark on first
        if pattern == "io" {
            return positions[0]
        }

        // ưa: mark on first (ư)
        // Example: "mưa", "lừa"
        if pattern == "ua" && characters[positions[0]].state.contains(.hornOrBreve) {
            return positions[0]
        }

        // Default for double vowels: first vowel
        return positions[0]
    }

    /// Handle mark position for triple vowel combinations
    private func handleTripleVowelMarkPosition(pattern: String, positions: [Int], hasEnding: Bool) -> Int? {
        // Triple vowel patterns - mark usually goes on middle vowel

        // Check for modified vowel first - it takes priority
        for pos in positions {
            if characters[pos].isModifiedVowel {
                return pos
            }
        }

        // uôi, ươi: mark on middle vowel (ô or ơ)
        // Example: "tưởi", "suối"
        if pattern == "uoi" {
            return positions[1]
        }

        // iêu, yêu: mark on middle vowel (ê)
        // Example: "tiếu", "yểu"
        if pattern == "ieu" || pattern == "yeu" {
            return positions[1]
        }

        // oai, oay: mark on middle vowel (a)
        // Example: "ngoài", "xoáy"
        if pattern == "oai" || pattern == "oay" {
            return positions[1]
        }

        // uai, uây: mark on middle vowel
        // Example: "khuấy"
        if pattern == "uai" || pattern == "uay" {
            return positions[1]
        }

        // uya, uyu: mark on middle vowel (y)
        // Example: "khuya"
        if pattern == "uya" || pattern == "uyu" {
            return positions[1]
        }

        // Default for triple vowels: middle vowel
        return positions[1]
    }

    // MARK: - Mark Operations

    /// Apply a tone mark to the appropriate vowel
    /// - Returns: true if mark was applied, false if no suitable vowel
    @discardableResult
    public mutating func applyMark(_ mark: CharacterState) -> Bool {
        guard let position = findMarkPosition() else { return false }

        // Clear any existing mark and set new one
        characters[position].state.clearToneMark()
        characters[position].state.insert(mark.intersection(.allToneMarks))
        return true
    }

    /// Apply a modifier (circumflex or horn/breve) to a vowel at position
    /// - Returns: true if modifier was applied
    @discardableResult
    public mutating func applyModifier(_ modifier: CharacterState, at position: Int) -> Bool {
        guard position >= 0, position < count else { return false }
        guard characters[position].isVowel else { return false }

        characters[position].state.clearModifier()
        characters[position].state.insert(modifier.intersection(.allModifiers))
        return true
    }

    /// Remove tone mark from the marked vowel
    /// - Returns: true if a mark was removed
    @discardableResult
    public mutating func removeMark() -> Bool {
        // Find vowel with existing tone mark
        let vowelPositions = findVowelPositions()
        for pos in vowelPositions {
            if characters[pos].state.hasToneMark {
                characters[pos].state.clearToneMark()
                return true
            }
        }
        return false
    }

    // MARK: - Dynamic Tone Repositioning

    /// Recalculate and reposition tone mark after syllable structure changes
    /// This is called after adding characters that may change the mark position
    /// Example: "thuor" → "thưở" then add "n" → tone may need to move
    /// - Returns: true if tone was repositioned
    @discardableResult
    public mutating func refreshTonePosition() -> Bool {
        // Find current tone mark position
        let vowelPositions = findVowelPositions()
        var currentTonePos: Int?
        var currentTone: CharacterState?

        for pos in vowelPositions {
            if characters[pos].state.hasToneMark {
                currentTonePos = pos
                currentTone = characters[pos].state.toneMark
                break
            }
        }

        // No tone mark to reposition
        guard let existingPos = currentTonePos, let tone = currentTone else {
            return false
        }

        // Calculate correct position
        guard let correctPos = findMarkPosition() else {
            return false
        }

        // Already in correct position
        if existingPos == correctPos {
            return false
        }

        // Move tone to correct position
        characters[existingPos].state.clearToneMark()
        characters[correctPos].state.insert(tone)
        return true
    }

    /// Find position of vowel that currently has a tone mark
    public func findMarkedVowelPosition() -> Int? {
        let vowelPositions = findVowelPositions()
        for pos in vowelPositions {
            if characters[pos].state.hasToneMark {
                return pos
            }
        }
        return nil
    }

    // MARK: - Spell Validation

    /// Check if the current buffer content is a valid Vietnamese syllable structure
    /// This is a basic check - not a full dictionary lookup
    public func isValidVietnameseSyllable() -> Bool {
        guard !isEmpty else { return true }

        let vowelPositions = findVowelPositions()

        // Must have at least one vowel for a Vietnamese syllable
        guard !vowelPositions.isEmpty else {
            // Could be just consonants being typed - allow
            return true
        }

        // Check tone validity with ending consonant
        if let ending = findEndingConsonant() {
            for pos in vowelPositions {
                if characters[pos].state.hasToneMark {
                    let tone = characters[pos].state
                    if !VietnameseConstants.isValidToneWithEnding(tone: tone, ending: ending.pattern) {
                        return false
                    }
                }
            }
        }

        return true
    }

    // MARK: - Output Generation

    /// Track that output has been sent
    public mutating func markAsOutput() {
        outputCount = count
    }

    /// Calculate how many backspaces needed to replace current output
    public var backspaceCount: Int {
        outputCount
    }

    /// Reset output tracking (after word break)
    public mutating func resetOutputTracking() {
        outputCount = 0
    }

    // MARK: - KeyStates (Original Input Tracking)

    /// Get the original keystrokes (before any transformation)
    /// Used for restore-on-invalid feature
    public var originalKeystrokes: String {
        String(keyStates)
    }

    /// Number of original keystrokes recorded
    public var keystrokeCount: Int {
        keyStates.count
    }

    /// Check if we have original keystrokes to restore
    public var hasOriginalKeystrokes: Bool {
        !keyStates.isEmpty
    }

    /// Get the original keystrokes as array
    public var allOriginalKeys: [Character] {
        keyStates
    }
}

// MARK: - CustomStringConvertible

extension TypingBuffer: CustomStringConvertible {
    public var description: String {
        let chars = characters.compactMap { $0.baseCharacter }.map { String($0) }.joined()
        return "TypingBuffer(\(count)/\(Self.maxCapacity): \"\(chars)\")"
    }
}

// MARK: - Collection Conformance

extension TypingBuffer: RandomAccessCollection {
    public var startIndex: Int { characters.startIndex }
    public var endIndex: Int { characters.endIndex }

    public func index(after i: Int) -> Int {
        characters.index(after: i)
    }
}
