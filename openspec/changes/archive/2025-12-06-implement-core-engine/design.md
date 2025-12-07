# Design: Core Vietnamese Engine Implementation

## Context

Đây là implementation phase cho core engine đã được spec trong `port-openkey-to-swift`. Design document này chi tiết các data structures và algorithms đã được implement, dựa trên research từ nhiều Vietnamese IME engines (OpenKey, bamboo-core/ibus-lotus, ibus-unikey, vi-rs).

## Goals / Non-Goals

### Goals
- Implement data structures matching original OpenKey bit layout
- Type-safe Swift equivalents using OptionSet và structs
- Testable design với dependency injection
- Performance: < 1ms per keystroke processing
- **Complete mark positioning rules** (qu-/gi- clusters, iê/yê/uô/ươ + ending)
- **Dynamic tone repositioning** (like bamboo-core)
- **Spell validation** (tone + ending consonant rules)
- **State history for undo/restore** (like OpenKey's _typingStates)

### Non-Goals
- Input method rules (implemented riêng trong TelexInputMethod)
- Full dictionary-based spell checking (only phonotactic rules)
- Event handling/CGEventTap (sẽ implement riêng)

---

## Data Structures

### CharacterState (OptionSet)

Port từ C++ bit masks, sử dụng Swift OptionSet cho type safety:

```swift
struct CharacterState: OptionSet, Sendable {
    let rawValue: UInt32

    // Bit 16: Capitalization
    static let caps = CharacterState(rawValue: 1 << 16)

    // Bits 17-18: Tone modifiers
    static let circumflex = CharacterState(rawValue: 1 << 17)  // ^ for â, ê, ô
    static let hornOrBreve = CharacterState(rawValue: 1 << 18) // w for ơ, ư, ă, đ

    // Bits 19-23: Mark flags (dấu thanh)
    static let acute = CharacterState(rawValue: 1 << 19)       // Sắc ́
    static let grave = CharacterState(rawValue: 1 << 20)       // Huyền ̀
    static let hook = CharacterState(rawValue: 1 << 21)        // Hỏi ̉
    static let tilde = CharacterState(rawValue: 1 << 22)       // Ngã ̃
    static let dotBelow = CharacterState(rawValue: 1 << 23)    // Nặng ̣

    // Bits 24-25: Control flags
    static let standalone = CharacterState(rawValue: 1 << 24)
    static let isCharCode = CharacterState(rawValue: 1 << 25)

    // Bit 26: Stroke modifier (for đ)
    static let stroke = CharacterState(rawValue: 1 << 26)

    // Computed helpers
    var hasToneMark: Bool { ... }
    var hasModifier: Bool { ... }
    var toneMark: CharacterState? { ... }
    mutating func clearToneMark() { ... }
    mutating func clearModifier() { ... }
}
```

### TypedCharacter

Represents a single character in the typing buffer:

```swift
struct TypedCharacter: Sendable, Hashable {
    var baseCode: UInt16
    var state: CharacterState

    var baseCharacter: Character? { ... }
    var isVowel: Bool { ... }
    var isModifiedVowel: Bool { ... }  // â, ê, ô, ơ, ư, ă
    var isUppercase: Bool { ... }
}
```

### TypingBuffer

Manages the current word being typed with complete syllable analysis:

```swift
struct TypingBuffer: Sendable {
    static let maxCapacity = 64
    private var characters: [TypedCharacter] = []

    // Basic operations
    mutating func append(_ char: TypedCharacter) -> Bool
    mutating func removeLast() -> TypedCharacter?
    mutating func clear()

    // Vowel analysis (handles qu-/gi- clusters)
    func findVowelPositions() -> [Int]
    func findVowelStartIndex() -> Int?

    // Ending consonant detection
    func findEndingConsonant() -> (pattern: String, startIndex: Int)?
    var hasSharpEnding: Bool

    // Mark positioning (modern orthography)
    func findMarkPosition() -> Int?
    mutating func applyMark(_ mark: CharacterState) -> Bool
    mutating func applyModifier(_ modifier: CharacterState, at position: Int) -> Bool
    mutating func removeMark() -> Bool

    // Dynamic tone repositioning
    mutating func refreshTonePosition() -> Bool
    func findMarkedVowelPosition() -> Int?

    // Spell validation
    func isValidVietnameseSyllable() -> Bool

    // Unicode output
    func toUnicodeString() -> String
}
```

### VietnameseConstants

Constants for Vietnamese character processing:

```swift
enum VietnameseConstants {
    static let baseVowels: Set<Character> = ["a", "e", "i", "o", "u", "y"]

    // Consonant clusters (23 patterns)
    static let firstConsonantClusters: Set<String> = [
        "b", "c", "ch", "d", "g", "gh", "gi", "h", "k", "kh",
        "l", "m", "n", "ng", "ngh", "nh", "p", "ph", "qu", "r",
        "s", "t", "th", "tr", "v", "x"
    ]

    // Ending consonants (9 patterns)
    static let endConsonants: Set<String> = [
        "c", "ch", "m", "n", "ng", "nh", "p", "t"
    ]

    // Sharp endings - only sắc/nặng valid
    static let sharpEndConsonants: Set<String> = ["c", "ch", "p", "t"]

    // Cluster detection
    static func isUPartOfQu(buffer: [Character], uIndex: Int) -> Bool
    static func isIPartOfGi(buffer: [Character], iIndex: Int) -> Bool
    static func isValidToneWithEnding(tone: CharacterState, ending: String) -> Bool
}
```

---

## Algorithms

### Mark Positioning (Modern Orthography)

Based on research from OpenKey, bamboo-core, and ibus-unikey:

```
Algorithm: findMarkPosition(buffer) -> Int?

1. Find all vowel positions (excluding qu-/gi- cluster vowels)
2. If no vowels: return nil
3. If single vowel: return its position
4. If has single modified vowel (â, ê, ô, ơ, ư, ă): return its position

5. For triple vowels (oai, uoi, ieu, uya, etc.):
   - Check for modified vowel first
   - Default to middle vowel position

6. For double vowels:
   a. Check for iê/yê + ending: return second (ê) position
   b. Check for uô + ending: return second (ô) position
   c. Check for ươ: return second (ơ) position
   d. For oa, oe, uy: return second vowel position
   e. For ai, ao, au, ay, eo, eu, iu, oi, ou, ui: return first vowel position
   f. For ia, ua without ending: return first vowel position
   g. Default: return first vowel position
```

### qu-/gi- Consonant Cluster Detection

Critical for correct mark positioning:

```
Algorithm: isUPartOfQu(buffer, uIndex) -> Bool

1. If uIndex == 0: return false (no preceding char)
2. If buffer[uIndex-1] != 'q': return false
3. If uIndex+1 < buffer.count:
   - If buffer[uIndex+1] is vowel: return true (u is consonant part)
4. Return true (at end, treat as potential cluster)

Algorithm: isIPartOfGi(buffer, iIndex) -> Bool

1. If iIndex == 0: return false
2. If buffer[iIndex-1] != 'g': return false
3. If iIndex+1 < buffer.count:
   - If buffer[iIndex+1] is vowel: return true (i is consonant part)
4. Return false (i alone after g is treated as vowel)
```

### Dynamic Tone Repositioning

Like bamboo-core's refreshLastToneTarget():

```
Algorithm: refreshTonePosition(buffer) -> Bool

1. Find current tone mark position
2. If no tone mark: return false
3. Calculate correct position using findMarkPosition()
4. If positions differ:
   - Clear tone from current position
   - Apply tone to correct position
   - Return true
5. Return false (no change needed)
```

### Spell Validation (Phonotactic Rules)

Based on Vietnamese phonology:

```
Algorithm: isValidVietnameseSyllable(buffer) -> Bool

1. If no vowels: return true (still typing consonants)
2. Find ending consonant (if any)
3. If has sharp ending (c, ch, p, t):
   - Check each vowel's tone mark
   - If tone is huyền, hỏi, or ngã: return false
4. Return true
```

### Processing Flow

```
Algorithm: processKey(keyCode, character, modifiers) -> EngineResult

1. If modifier keys (Cmd, Ctrl): return .passThrough

2. If backspace:
   - If buffer empty: try restore from history, else .passThrough
   - Save current state to history
   - Remove last character
   - Refresh tone position
   - Return .replace(backspaceCount, newString)

3. If word break (space, punctuation):
   - Save to history
   - Clear buffer
   - Return .passThrough

4. Process character through InputMethod
5. If transformation (tone/modifier):
   - Apply transformation
   - Check spell validity (if enabled)
   - Refresh tone position
   - Return .replace(backspaceCount, newString)

6. Else: add to buffer, return result
```

---

## Unicode Lookup Tables

### VietnameseTable

Pre-composed NFC character lookup:

```swift
enum VietnameseTable {
    // All Vietnamese characters indexed by:
    // base (a/ă/â/e/ê/i/o/ô/ơ/u/ư/y/d) × modifier × tone × case

    static func lookup(
        base: Character,
        modifier: CharacterState,
        tone: CharacterState,
        uppercase: Bool
    ) -> Character

    // 134 distinct Vietnamese characters covered
}
```

---

## Comparison with Other Engines

| Feature | LotusKey | OpenKey | bamboo-core | ibus-unikey |
|---------|-------|---------|-------------|-------------|
| Language | Swift | C++ | Go | C++ |
| Buffer | `[TypedCharacter]` | `Uint32[32]` bit-packed | `[]*Transformation` | Structured buffer |
| qu-/gi- handling | ✅ | ✅ | ✅ | ✅ |
| Dynamic tone reposition | ✅ | ✅ | ✅ | Partial |
| Spell validation | ✅ (phonotactic) | ✅ (tables) | ✅ (trie) | ✅ (tables) |
| State history | ✅ | ✅ | ✅ | ❌ |

---

## Risks / Trade-offs

### Risk: Performance in hot path

- **Mitigation**: Pre-compute lookup tables, avoid allocations, use value types
- **Result**: All tests pass in < 50ms total for 156 tests

### Risk: Unicode normalization issues

- **Decision**: Use NFC (pre-composed) for output, matching original OpenKey
- **Mitigation**: Comprehensive lookup table for all 134 Vietnamese characters

### Risk: Edge cases in mark positioning

- **Mitigation**: Researched OpenKey, bamboo-core, ibus-unikey implementations
- **Result**: 53 TypingBuffer tests, 58 Engine tests covering edge cases

---

## Resolved Questions

1. **Thread safety**: Engine uses `@unchecked Sendable` as it's only accessed from single thread (CGEventTap callback).

2. **Buffer size**: 64 chars sufficient. Vietnamese words rarely exceed 10 chars.

3. **qu-/gi- handling**: Implemented as vowel position filtering, not consonant detection.

4. **State history size**: 10 states maximum, matching typical undo depth.

5. **Spell checking scope**: Phonotactic rules only (tone + ending validation). Full dictionary checking is future work.
