# Design: Spell Checking Validation

## Context

Vietnamese syllables follow strict phonological rules. The spell checker validates user input against these rules to:
1. Prevent invalid character combinations
2. Support "restore-on-invalid" feature (restore original input if word is invalid)
3. Enable temporary spell check bypass via Control key

### Reference Implementations

**OpenKey** (`Engine.cpp`) - Rule-based validation:
- `_consonantTable`: Valid initial consonant patterns (26 entries)
- `_vowelCombine`: Valid vowel combinations with end-consonant compatibility flags
- `_endConsonantTable`: Valid final consonant patterns (11 entries)
- Direct table lookups, O(n) iteration

**ibus-lotus** (`bamboo-core/spelling.go`) - Matrix-based validation:
- `cvMatrix`: Consonant-Vowel compatibility matrix (5 consonant groups × 8 vowel groups)
- `vcMatrix`: Vowel-Consonant compatibility matrix (8 vowel groups × 5 consonant groups)
- Group-based indexing for O(1) lookups
- Supports both rule-based AND dictionary-based checking

### Key Insight from ibus-lotus

ibus-lotus uses a **matrix approach** that groups consonants/vowels by compatibility patterns:
- `firstConsonantSeqs` groups: "b d đ g gh..." | "c h k kh qu th" | "ch gi l ng ngh x" | ...
- `vowelSeqs` groups: "ê i ua uê uy y" | "a iê oa uyê yê" | "â ă e o oo ô ơ..." | ...
- Matrix lookup: `cvMatrix[consonantGroup][vowelGroup]` returns validity

This is more elegant than OpenKey's direct table scan but requires careful grouping.

## Goals / Non-Goals

**Goals:**
- Complete syllable validation matching OpenKey's behavior
- Swift-native implementation using Sets/Dictionaries for O(1) lookups
- Clear separation between syllable parsing and validation
- Comprehensive test coverage (all 50+ vowel combinations)
- **CV/VC matrix validation** (inspired by ibus-lotus for better maintainability)
- **KeyStates buffer** for original input restoration

**Non-Goals:**
- Dictionary-based spell checking (only phonological rules) - *can add later*
- Suggestions for corrections
- Grammar checking beyond tone mark rules

## Decisions

### Decision 1: Syllable Structure Model

Use a `SyllableParts` struct to represent parsed syllable:

```swift
struct SyllableParts {
    let initialConsonant: String  // "", "b", "ch", "ngh", etc.
    let vowelNucleus: String      // "a", "oa", "ươi", etc.
    let finalConsonant: String    // "", "n", "ng", "ch", etc.
    let tonePosition: Int?        // Index of vowel with tone mark
    let tone: CharacterState?     // The tone mark applied
}
```

**Rationale**: Explicit structure makes validation logic clear and testable.

### Decision 2: Vowel Combination Table Format

Port OpenKey's `_vowelCombine` format with Swift enhancements:

```swift
struct VowelCombinationInfo: Sendable {
    /// Can this combination be followed by an ending consonant?
    let allowsEndConsonant: Bool
    /// Pattern including modifiers (e.g., "iê" has circumflex on e)
    let pattern: [VowelElement]
}

enum VowelElement: Sendable {
    case plain(Character)           // a, e, i, o, u, y
    case circumflex(Character)      // â, ê, ô
    case horn(Character)            // ơ, ư
    case breve(Character)           // ă
}
```

**Rationale**: Encode modifier requirements directly in pattern for accurate matching.

### Decision 3: Validation Flow

```
Input: "thuong"
  ↓
1. Parse initial consonant: "th"
   - Check against firstConsonantClusters ✓
  ↓
2. Parse vowel nucleus: "uo" (with horn modifiers → "ươ")
   - Check against vowelCombinations["u"] ✓
   - Get allowsEndConsonant flag: true
  ↓
3. Parse final consonant: "ng"
   - Check against endConsonants ✓
   - If vowel didn't allow ending, FAIL
  ↓
4. Validate tone (if present)
   - If sharp ending (c,ch,p,t), only acute/dotBelow allowed
  ↓
Result: VALID
```

### Decision 4: Static Data Tables

Define as static Sets/Dictionaries on `VietnameseSpellingRules` enum:

```swift
enum VietnameseSpellingRules {
    /// Valid initial consonant clusters (matches OpenKey _consonantTable)
    static let initialConsonants: Set<String> = [
        "b", "c", "ch", "d", "g", "gh", "gi", "h", "k", "kh",
        "l", "m", "n", "ng", "ngh", "nh", "p", "ph", "qu", "r",
        "s", "t", "th", "tr", "v", "x"
    ]

    /// Valid ending consonants (matches OpenKey _endConsonantTable)
    static let finalConsonants: Set<String> = [
        "c", "ch", "m", "n", "ng", "nh", "p", "t"
    ]

    /// Vowel combinations keyed by first vowel
    static let vowelCombinations: [Character: [VowelCombinationInfo]] = [
        "a": [...], "e": [...], "i": [...],
        "o": [...], "u": [...], "y": [...]
    ]
}
```

### Decision 5: Integration Point

Spell checking is called:
1. After each character insertion (if enabled) - returns `tempDisable` flag
2. Before word break (space/punctuation) - for restore-on-invalid feature
3. Can be bypassed with Control key held

**Interface with Engine:**
```swift
protocol SpellChecker {
    func check(_ buffer: TypingBuffer) -> SpellCheckResult
    func shouldDisableTransformation(_ buffer: TypingBuffer) -> Bool
}
```

## Vietnamese Vowel Combination Reference

From OpenKey's `_vowelCombine` (Vietnamese.cpp:99-168):

| First Vowel | Combinations | Notes |
|-------------|--------------|-------|
| a | ai, ao, au, ău, ay, ây | No end consonant allowed |
| e | eo, êu | No end consonant allowed |
| i | ia, iê, iêu, iu | iê allows end consonant |
| o | oai, oao, oay, oeo, oa, oă, oe, oi, ôi, ơi, oo, ôô | oa, oă, oe, oo allow end consonant |
| u | uyu, uyê, uya, ươu, ươi, uôi, uây, uao, ua, ưa, uâ, uê, ui, ưi, uo, uô, ươ, ươ, ưu, uy | Many allow end consonant |
| y | yêu, yê | yê allows end consonant |

## Tone Mark Restrictions

From OpenKey's `checkSpelling()` (Engine.cpp:273-278):

| Ending | Allowed Tones | Forbidden Tones |
|--------|---------------|-----------------|
| c, ch, p, t | sắc (´), nặng (.) | huyền (`), hỏi (?), ngã (~) |
| m, n, ng, nh | All tones | None |
| No ending | All tones | None |

## Risks / Trade-offs

**Risk 1**: Performance overhead on every keystroke
- **Mitigation**: Use O(1) Set lookups, lazy parsing, early exit on first failure

**Risk 2**: Edge cases in syllable parsing
- **Mitigation**: Comprehensive test suite covering all patterns from OpenKey

**Risk 3**: Mismatch with OpenKey behavior
- **Mitigation**: Port data tables directly, test against known OpenKey outputs

## Migration Plan

1. Add new data structures and parsing logic
2. Implement validation with tests
3. Wire into engine (behind feature flag if needed)
4. Remove TODO comments
5. Integration testing with actual typing

## Open Questions

1. Should invalid detection be case-sensitive? (Recommend: No, normalize to lowercase) ✅ Resolved: Case-insensitive
2. Handle đ as consonant or special case? (Recommend: Treat as "d" variant, validate same as consonant) ✅ Resolved: Treated as "d"

## Known Limitations

### gi- Special Case Parsing

**Current behavior**: "giếng" parses as `["gi", "ê", "ng"]`
**Ideal behavior**: "giếng" should parse as `["g", "iê", "ng"]` (per ibus-lotus algorithm)

The parser currently treats "gi" as a single digraph consonant cluster in all cases. According to strict Vietnamese phonology:
- "gi" + single vowel → "gi" is consonant: "già" = `["gi", "a", ""]` ✅
- "gi" + "iê" + consonant → "g" is consonant: "giếng" = `["g", "iê", "ng"]` ❌ (not implemented)

**Impact**: The spell checker still correctly validates these words because:
1. "gi" is a valid initial consonant
2. "ê" is a valid vowel
3. "ng" is a valid ending
4. The tone (acute) is valid with "ng" ending

So words like "giếng", "giết", "giếc" pass validation correctly even with the simplified parsing.

**Future improvement**: Implement the full gi-/qu- special case handling as described in ibus-lotus's `extractCvcTrans()` algorithm if needed for features like tone mark repositioning.

---

## Appendix: Detailed Comparison OpenKey vs ibus-lotus

### Feature Comparison

| Feature | OpenKey | ibus-lotus | VN-IME (proposed) |
|---------|---------|------------|-------------------|
| Validation approach | Direct table scan | Matrix-based groups | Hybrid (matrix + direct) |
| CV compatibility | Implicit in `_vowelCombine` | Explicit `cvMatrix` | Explicit matrix |
| VC compatibility | `allowsEndConsonant` flag | Explicit `vcMatrix` | Explicit matrix |
| Tone validation | Inline in `checkSpelling()` | Separate `hasValidTone()` | Separate function |
| qu-/gi- handling | `findVowelStartIndex()` | `extractCvcTrans()` | `SyllableParser` |
| Dictionary support | No | Yes (`vietnamese.cm.dict`) | No (future) |
| Restore on invalid | `vRestoreIfWrongSpelling` | `IBautoNonVnRestore` | Yes |

### ibus-lotus Tone Validation Logic (hasValidTone)

```go
// Invalid if: tone is NOT (none, acute, dot) AND has last consonant in [c,k,p,t,ch]
if tone != ToneNone && tone != ToneAcute && tone != ToneDot {
    if lastConsonant in ["c", "k", "p", "t", "ch"] {
        return false  // Invalid
    }
}
return true
```

Note: ibus-lotus includes "k" in sharp endings (OpenKey only has c,ch,p,t). "k" appears as END consonant in some loan words. VN-IME should follow OpenKey's stricter rule.

### ibus-lotus CV Matrix (5 consonant groups × 8 vowel groups)

```
cvMatrix = [
    [0, 1, 2, 5],        // Group 0: b,d,đ,g,gh,m,n,nh,p,ph,r,s,t,tr,v,z
    [0, 1, 2, 3, 4, 5],  // Group 1: c,h,k,kh,qu,th
    [0, 1, 2, 3, 5],     // Group 2: ch,gi,l,ng,ngh,x
    [6],                 // Group 3: đ,l (special)
    [7],                 // Group 4: h (special)
]
```

### ibus-lotus VC Matrix (8 vowel groups × 5 consonant groups)

```
vcMatrix = [
    [0, 2],     // Vowel group 0: ê,i,ua,uê,uy,y
    [0, 1, 2],  // Vowel group 1: a,iê,oa,uyê,yê
    [1, 2],     // Vowel group 2: â,ă,e,o,oo,ô,ơ,oe,u,ư,uâ,uô,ươ
    [1, 2],     // Vowel group 3: oă
    [],         // Vowel group 4: uơ (no end consonant)
    [],         // Vowel group 5: ai,ao,au,... (no end consonant)
    [3],        // Vowel group 6: ă (special)
    [4],        // Vowel group 7: i (special)
]
```

### gi- Special Case (from ibus-lotus extractCvcTrans)

```
// "gi" followed by vowel+consonant keeps "g" as consonant:
// "giếng" → ["g", "iê", "ng"] NOT ["gi", "ê", "ng"]
//
// "gi" followed by just vowel treats "gi" as consonant:
// "già" → ["gi", "a", ""]
```

This edge case is important for proper syllable parsing.

### KeyStates Buffer (from OpenKey)

OpenKey maintains a parallel `KeyStates[MAX_BUFF]` array that stores the ORIGINAL keycodes typed by user (before any transformation). When `vRestoreIfWrongSpelling` is triggered:
1. Calculate backspaces needed = current buffer length
2. Output characters from `KeyStates` (original input)

VN-IME needs to implement this pattern for restore-on-invalid feature.

### Complete OpenKey _vowelCombine Entries

From `Vietnamese.cpp:99-168`:

```cpp
KEY_A: {
    {0, a, i}, {0, a, o}, {0, a, u}, {0, â, u},    // No end consonant
    {0, a, y}, {0, â, y}                           // No end consonant
}
KEY_E: {
    {0, e, o}, {0, ê, u}                           // No end consonant
}
KEY_I: {
    {1, i, ê, u},  // iêu - allows end consonant
    {0, i, a},     // ia - no end consonant
    {1, i, ê},     // iê - allows end consonant
    {0, i, u}      // iu - no end consonant
}
KEY_O: {
    {0, o, a, i}, {0, o, a, o}, {0, o, a, y}, {0, o, e, o},  // Triple, no end
    {1, o, a}, {1, o, ă}, {1, o, e},                         // Double, allows end
    {0, o, i}, {0, ô, i}, {0, ơ, i},                         // No end
    {1, o, o}, {1, ô, ô}                                     // Allows end (thoong)
}
KEY_U: {
    {0, u, y, u}, {1, u, y, ê}, {0, u, y, a},                // uy-variants
    {0, ư, ơ, u}, {0, ư, ơ, i}, {0, u, ô, i},                // ươ-variants
    {0, u, â, y}, {1, u, a, o}, {1, u, a}, {1, ư, a},        // ua-variants
    {1, u, â}, {1, u, ê}, {0, u, i}, {0, ư, i},              // More
    {1, u, o}, {1, u, ô}, {0, u, ơ}, {1, ư, ơ},              // uo-variants
    {0, ư, u}, {1, u, y}                                     // ưu, uy
}
KEY_Y: {
    {0, y, ê, u}, {1, y, ê}                                  // yê-variants
}
```

Total: 50+ distinct vowel combinations with modifier and end-consonant flags.
