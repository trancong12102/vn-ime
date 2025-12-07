# Implementation Tasks

## 1. CharacterState.swift (91.67% → 100%) ✅

**Uncovered code:**
- Line 88-91: `modifier` computed property

**Tasks:**
- [x] 1.1 Add test for `modifier` property when no modifier present (returns nil)
- [x] 1.2 Add test for `modifier` property when circumflex present
- [x] 1.3 Add test for `modifier` property when hornOrBreve present

**Status:** 100% line coverage achieved

---

## 2. TypedCharacter.swift (66.97% → 91.74%) ✅

**Uncovered code:**
- Lines 18-21: `init(baseCode:state:)` - used for OpenKey compatibility
- Lines 40-43: `init(rawValue:)` - unpacking from UInt32
- Lines 48-50: `rawValue` computed property - packing to UInt32
- Lines 79-82: `description` - CustomStringConvertible
- Lines 137-139: `isVowel(_:)` static function
- Lines 142-144: `isConsonant(_:)` static function

**Tasks:**
- [x] 2.1 Add tests for `init(baseCode:state:)` constructor
- [x] 2.2 Add tests for `init(rawValue:)` unpacking (round-trip with rawValue)
- [x] 2.3 Add tests for `rawValue` property (verify bit packing)
- [x] 2.4 Add test for `description` property
- [x] 2.5 Add tests for `VietnameseConstants.isVowel(_:)` static function
- [x] 2.6 Add tests for `VietnameseConstants.isConsonant(_:)` static function
- [x] 2.7 Added tests for `isValidToneWithEnding` no-tone fallback

**Status:** 91.74% line coverage achieved

---

## 3. TypingBuffer.swift (76.11% → 83.12%) ✅

**Uncovered code:**
- Lines 69-74: `append(_:originalKey:)` method - REMOVED (unused)
- Lines 106-110: `fromEnd(_:)` method - REMOVED (unused)
- Lines 120-142: `findVowelStartIndex()` method - REMOVED (unused)

**Tasks:**
- [x] 3.1-3.9: Removed unused methods `append(_:originalKey:)`, `fromEnd(_:)`, `findVowelStartIndex()` per design.md decision

**Status:** 83.12% line coverage achieved (improved by removing unused code)

---

## 4. VietnameseEngine.swift (87.85%) - Partial

**Status:** 87.85% line coverage. Remaining uncovered paths are complex integration scenarios and edge cases in restoration logic.

---

## 5. VietnameseTable.swift (69.47%) - Deferred

**Status:** 69.47% line coverage. The `parse(_:)` reverse lookup method is not currently used in the main codebase path.

---

## 6. InputMethod.swift (73.53% → 82.35%) ✅

**Tasks:**
- [x] 6.2 Add test for `InputMethodState.resetTempDisabled()` method

**Status:** 82.35% line coverage achieved

---

## 7. InputMethodRegistry.swift (50.00% → 100%) ✅

**Tasks:**
- [x] 7.1 Add test for `allMethods` property
- [x] 7.2 Add test for `getByName(_:)` with valid name (Telex)
- [x] 7.3 Add test for `getByName(_:)` with invalid name
- [x] 7.4 Add test for `getByName(_:)` case insensitivity

**Status:** 100% line coverage achieved

---

## 8. TelexInputMethod.swift & SimpleTelexInputMethod.swift (91-95% → 94-98%) ✅

**Tasks:**
- [x] 8.1 Add tests for edge cases in Telex undo handling (standaloneHorn case)
- [x] 8.2 Add tests for Simple Telex fallback paths (disabled key check)
- [x] 8.3 Add tests for standalone W after blocker

**Status:** TelexInputMethod 98.01%, SimpleTelexInputMethod 94.59% line coverage

---

## 9. SpellChecker.swift (94.09% → 97.16%) ✅

**Tasks:**
- [x] 9.1 Add test for "giê" pattern parsing
- [x] 9.2 Add test that triggers `allVowelCombinations` access
- [x] 9.3 Add tests for invalid consonant reasons
- [x] 9.4 Add tests for vowel without ending check
- [x] 9.5 Add tests for edge cases in vowelAllowsEnding

**Status:** 97.16% line coverage achieved

---

## 10. QuickTelex.swift (96.30% → 100%) ✅

**Tasks:**
- [x] 10.1 Add test for QuickTelex when `isEnabled = false` (direct call to processShortcut)
- [x] 10.2 Add test for QuickTelex with nil previousCharacter

**Status:** 100% line coverage achieved

---

## 11. CharacterTable.swift (18.18% → 100%) ✅

**Tasks:**
- [x] 11.1 Add tests for `UnicodeCharacterTable.encode(_:)`
- [x] 11.2 Add tests for `UnicodeCharacterTable.decode(_:)`
- [x] 11.3 Add tests for `UnicodeCharacterTable.supports(_:)`

**Status:** 100% line coverage achieved

---

## 12. Final Verification ✅

- [x] 12.1 Run full test suite: `swift test` - All 131 tests pass
- [x] 12.2 Generate coverage report: `swift test --enable-code-coverage`
- [x] 12.3 Verify core logic components show high coverage

**Coverage Summary (Line Coverage):**
| File | Before | After |
|------|--------|-------|
| CharacterState.swift | 91.67% | 100% |
| TypedCharacter.swift | 66.97% | 91.74% |
| TypingBuffer.swift | 76.11% | 83.12% |
| VietnameseEngine.swift | 87.85% | 87.85% |
| VietnameseTable.swift | 69.47% | 69.47% |
| InputMethod.swift | 73.53% | 82.35% |
| InputMethodRegistry.swift | 50.00% | 100% |
| SimpleTelexInputMethod.swift | 91.89% | 94.59% |
| TelexInputMethod.swift | 95.52% | 98.01% |
| SpellChecker.swift | 94.09% | 97.16% |
| QuickTelex.swift | 96.30% | 100% |
| CharacterTable.swift | 18.18% | 100% |

**Files Achieving 100% Coverage:**
- CharacterState.swift
- InputMethodRegistry.swift
- QuickTelex.swift
- CharacterTable.swift

**Notes:**
- Removed unused methods from TypingBuffer.swift per design.md decision
- Remaining uncovered code is primarily in complex integration paths and rarely-exercised edge cases
