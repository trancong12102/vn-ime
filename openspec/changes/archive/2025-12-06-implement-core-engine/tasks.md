# Tasks: Implement Core Vietnamese Engine

## 1. Data Structures

- [x] 1.1 Implement `CharacterState` OptionSet với bit layout (caps, tone modifiers, mark flags, stroke)
- [x] 1.2 Implement `TypedCharacter` struct (base code + state + computed helpers)
- [x] 1.3 Implement `TypingBuffer` struct (array of TypedCharacter, max 64)
- [x] 1.4 Write unit tests cho CharacterState và TypedCharacter (16 tests)

## 2. Vietnamese Character Constants

- [x] 2.1 Define vowel constants (a, ă, â, e, ê, i, o, ô, ơ, u, ư, y)
- [x] 2.2 Define consonant cluster constants (23 first clusters, 9 end consonants)
- [x] 2.3 Define sharp ending consonants (c, ch, p, t) for tone validation
- [x] 2.4 Implement `isUPartOfQu()` and `isIPartOfGi()` cluster detection
- [x] 2.5 Implement `isValidToneWithEnding()` for spell validation

## 3. Vietnamese Character Tables

- [x] 3.1 Implement vowel classification helpers (isVowel, isModifiedVowel)
- [x] 3.2 Implement Unicode lookup table cho all Vietnamese characters (134 chars)
- [x] 3.3 Write tests for VietnameseTable (18 tests)

## 4. Mark Positioning (Modern Orthography)

- [x] 4.1 Implement `findVowelPositions()` with qu-/gi- cluster handling
- [x] 4.2 Implement `findMarkPosition()` - xác định vowel để đặt dấu
- [x] 4.3 Handle single vowel case
- [x] 4.4 Handle vowel combinations (oa, oe, uy → mark on second)
- [x] 4.5 Handle vowel combinations (ai, ao, au, ay → mark on first)
- [x] 4.6 Handle modified vowel priority (â, ê, ô, ơ, ư, ă get mark)
- [x] 4.7 Handle iê/yê/uô + ending consonant (mark on second vowel)
- [x] 4.8 Handle ươ combination (mark on ơ)
- [x] 4.9 Handle triple vowels (oai, uoi, ieu → mark on middle)
- [x] 4.10 Write tests cho all mark positioning rules (20+ tests)

## 5. Ending Consonant Detection

- [x] 5.1 Implement `findEndingConsonant()` - detect c, ch, m, n, ng, nh, p, t
- [x] 5.2 Implement `hasSharpEnding` computed property
- [x] 5.3 Write tests for ending consonant detection (5 tests)

## 6. Dynamic Tone Repositioning

- [x] 6.1 Implement `findMarkedVowelPosition()` - find current tone position
- [x] 6.2 Implement `refreshTonePosition()` - reposition after structure change
- [x] 6.3 Integrate repositioning after modifier application
- [x] 6.4 Integrate repositioning after adding ending consonant
- [x] 6.5 Write tests for dynamic repositioning (2 tests)

## 7. Spell Validation

- [x] 7.1 Implement `isValidVietnameseSyllable()` - phonotactic rules
- [x] 7.2 Validate tone + ending consonant combinations
- [x] 7.3 Integrate validation into tone application
- [x] 7.4 Write tests for spell validation (3 tests)

## 8. Core Engine Processing

- [x] 8.1 Implement `processKey()` main logic
- [x] 8.2 Handle regular character input (add to buffer)
- [x] 8.3 Handle word break characters (space, punctuation)
- [x] 8.4 Handle delete/backspace key with tone refresh
- [x] 8.5 Implement `reset()` method

## 9. State History Management

- [x] 9.1 Implement `stateHistory` array (max 10 states)
- [x] 9.2 Implement `saveToHistory()` - save before changes
- [x] 9.3 Implement `restoreFromHistory()` - undo on empty buffer backspace
- [x] 9.4 Integrate history into word break and backspace handling

## 10. Horn Modifier Enhancement

- [x] 10.1 Handle ươ combination - apply horn to both u and o
- [x] 10.2 Write test for ươ combination handling

## 11. Processing Result Generation

- [x] 11.1 Implement `toUnicodeString()` - convert buffer to Unicode string
- [x] 11.2 Calculate backspace count (chars to replace)
- [x] 11.3 Generate replacement string from buffer state
- [x] 11.4 Handle do-nothing case (passthrough)

## 12. Integration Tests

- [x] 12.1 Test basic character input flow
- [x] 12.2 Test tone mark application with correct positioning
- [x] 12.3 Test qu-/gi- consonant cluster handling (4 tests)
- [x] 12.4 Test iê/yê/uô/ươ + ending consonant (4 tests)
- [x] 12.5 Test spell validation with sharp endings (2 tests)
- [x] 12.6 Test word break detection and session reset
- [x] 12.7 Test delete key handling
- [x] 12.8 Test buffer overflow handling (64 char limit)

## 13. Validation

- [x] 13.1 Run `swift build` to verify compilation
- [x] 13.2 Run `swift test` to verify all tests pass
- [x] 13.3 Achieve 80%+ test coverage cho Core/Engine

**Final Result**: 156 tests passed (53 TypingBuffer, 58 Engine, 16 CharacterState, 18 VietnameseTable, 5 InputMethod, 6 UI skipped)
