# Change: Implement Complete Spell Checking Validation

## Why

The current spell checking implementation (`SpellChecker.swift`) is incomplete with two TODO comments:
1. `check(_:)` returns `.unknown` for all words
2. `isValidVowelCombination(_:)` returns `true` for any non-empty input

This leaves Vietnamese syllable validation non-functional, meaning users receive no feedback on invalid combinations. OpenKey's `checkSpelling()` function in `Engine.cpp` (lines 176-288) demonstrates a complete working implementation that validates:
- Initial consonant clusters against `_consonantTable`
- Vowel combinations against `_vowelCombine` map
- End consonants against `_endConsonantTable`
- Tone mark restrictions with sharp endings (c, ch, p, t)

## What Changes

- **New data structures**: Add `VowelCombination` lookup tables ported from OpenKey's `_vowelCombine`
- **Complete `DefaultSpellChecker.check(_:)`**: Parse syllable structure and validate all components
- **Complete `isValidVowelCombination(_:)`**: Validate against the vowel combination table
- **Add syllable parser**: Extract initial consonant, vowel nucleus, and final consonant
- **Add tone-ending validation**: Restrict huyền/hỏi/ngã with sharp endings (c, ch, p, t)
- **Integration**: Wire spell checker into engine for real-time validation
- **Tests**: Comprehensive test coverage for all Vietnamese syllable patterns

## Impact

- Affected specs: `spell-checking`
- Affected code:
  - `Sources/LotusKey/Core/Spelling/SpellChecker.swift` - Main implementation
  - `Sources/LotusKey/Core/Engine/TypedCharacter.swift` - May add vowel combination constants
  - `Sources/LotusKey/Core/Engine/VietnameseEngine.swift` - Integration with spell checker
  - `Tests/LotusKeyTests/SpellCheckerTests.swift` - New test file
