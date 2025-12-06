# Tasks: Implement Spell Checking Validation

## 1. Data Structures

- [x] 1.1 Create `SyllableParts` struct for parsed syllable representation
- [x] 1.2 Create `VowelCombinationInfo` struct with `allowsEndConsonant` flag
- [x] 1.3 Create `VietnameseSpellingRules` enum with static lookup tables
- [x] 1.4 Port `_vowelCombine` data from OpenKey (50+ combinations)
- [x] 1.5 Create CV compatibility matrix (consonant-vowel validation)
- [x] 1.6 Create VC compatibility matrix (vowel-consonant validation)
- [x] 1.7 Add comprehensive tests for data table correctness

## 2. Syllable Parsing

- [x] 2.1 Implement `SyllableParser` to extract consonant/vowel/ending parts
- [x] 2.2 Handle qu- consonant cluster (always absorbs 'u')
- [x] 2.3 Handle gi- special cases:
  - [x] 2.3.1 "gi" + vowel only → "gi" is consonant (già → gi + a)
  - [x] 2.3.2 "g" + "iê" + consonant → "g" is consonant, "iê" is vowel (giếng → g + iê + ng)
- [x] 2.4 Handle ngh- trigraph (only valid before i, e, ê)
- [x] 2.5 Handle đ as consonant (equivalent to 'd')
- [x] 2.6 Add tests for syllable parsing (valid and invalid inputs)

## 3. Validation Logic

- [x] 3.1 Implement `isValidInitialConsonant()` with cluster validation
- [x] 3.2 Implement `isValidVowelCombination()` with modifier matching
- [x] 3.3 Implement `isValidFinalConsonant()` with vowel compatibility check
- [x] 3.4 Implement `isValidToneWithEnding()` for sharp ending restrictions (c, ch, p, t)
- [x] 3.5 Implement CV matrix validation (consonant can precede vowel?)
- [x] 3.6 Implement VC matrix validation (vowel can have ending consonant?)
- [x] 3.7 Implement complete `check(_:)` method combining all validations
- [x] 3.8 Add comprehensive tests for validation logic

## 4. KeyStates Buffer (Restore Feature)

- [x] 4.1 Add `KeyStates` buffer to track original keystrokes
- [x] 4.2 Update `insertKey()` to store original keycode in KeyStates
- [x] 4.3 Implement `checkRestoreIfWrongSpelling()` function
- [x] 4.4 Wire restore logic at word boundary (space, punctuation)
- [x] 4.5 Add tests for restore-on-invalid feature

## 5. Engine Integration

- [x] 5.1 Wire `SpellChecker` into `VietnameseEngine` for real-time checking
- [x] 5.2 Implement `tempDisableKey` flag behavior (disable transformation on invalid)
- [x] 5.3 Call `checkSpelling()` after each character insertion
- [x] 5.4 Call `checkSpelling(forceCheck: true)` at word boundary
- [x] 5.5 Support temporary spell check bypass (Control key via `vTempOffSpellChecking`)
- [x] 5.6 Add settings: `spellCheckEnabled`, `restoreIfWrongSpelling`
- [x] 5.7 Add integration tests for engine + spell checker

## 6. Cleanup & Documentation

- [x] 6.1 Remove TODO comments from `SpellChecker.swift`
- [x] 6.2 Add DocC documentation for public APIs
- [x] 6.3 Run full test suite, ensure 100% pass
- [ ] 6.4 Manual testing with Vietnamese typing
- [x] 6.5 Test edge cases:
  - [x] 6.5.1 Empty buffer
  - [x] 6.5.2 Consonant-only (incomplete)
  - [x] 6.5.3 Vowel-only words (ái, ơi, ư)
  - [x] 6.5.4 All 5 tone marks with sharp endings
  - [x] 6.5.5 gi-/qu-/ngh- special cases
