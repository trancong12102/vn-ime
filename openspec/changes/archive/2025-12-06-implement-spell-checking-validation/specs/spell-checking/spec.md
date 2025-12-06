## MODIFIED Requirements

### Requirement: Vietnamese Spell Checking

The system SHALL validate Vietnamese word spelling when spell checking is enabled.

#### Scenario: Enable spell checking
- **WHEN** spell checking is enabled in settings
- **THEN** each word is validated against Vietnamese spelling rules
- **AND** invalid combinations trigger the `tempDisable` flag

#### Scenario: Disable spell checking
- **WHEN** spell checking is disabled in settings
- **THEN** all character combinations are accepted without validation

#### Scenario: Spell check integration with engine
- **WHEN** a character is inserted into the typing buffer
- **AND** spell checking is enabled
- **THEN** the spell checker validates the current syllable
- **AND** sets `tempDisable` flag if invalid to prevent further transformations

---

### Requirement: Initial Consonant Validation

The system SHALL validate initial consonant combinations.

#### Scenario: Valid single consonants
- **WHEN** word starts with valid single consonant (b, c, d, đ, g, h, k, l, m, n, p, r, s, t, v, x)
- **THEN** spelling check passes for consonant portion

#### Scenario: Valid consonant digraphs
- **WHEN** word starts with valid digraph (ch, gh, gi, kh, ng, nh, ph, qu, th, tr)
- **THEN** spelling check passes for consonant portion

#### Scenario: Valid trigraph 'ngh'
- **WHEN** word starts with 'ngh'
- **AND** followed by 'i', 'e', or 'ê'
- **THEN** spelling check passes

#### Scenario: Invalid consonant combination
- **WHEN** word starts with invalid consonant combination (e.g., "sr", "bt", "pk")
- **THEN** spelling check fails for that word

#### Scenario: Standalone đ consonant
- **WHEN** word starts with 'đ'
- **THEN** it is treated as valid initial consonant

---

### Requirement: Vowel Combination Validation

The system SHALL validate vowel combinations according to Vietnamese phonology using the `_vowelCombine` lookup table.

#### Scenario: Valid single vowels
- **WHEN** word contains single vowel (a, ă, â, e, ê, i, o, ô, ơ, u, ư, y)
- **THEN** vowel validation passes

#### Scenario: Valid vowel combinations
- **WHEN** word contains valid vowel combination (ai, ao, au, ay, âu, ây, eo, êu, ia, iê, oa, oai, oay, oe, ôi, ơi, ua, uâ, uê, ui, uô, ưa, ưi, ưu, yê)
- **THEN** vowel validation passes

#### Scenario: Valid triple vowel combinations
- **WHEN** word contains valid triple vowel (oai, oay, oeo, iêu, yêu, uôi, ươi, ươu, uya, uyu, uyê)
- **THEN** vowel validation passes

#### Scenario: Invalid vowel combination
- **WHEN** word contains invalid vowel sequence (e.g., "ae", "ii", "uu" without modifier)
- **THEN** spelling check fails

#### Scenario: Vowel modifier matching
- **WHEN** checking vowel combination "iê" or "yê"
- **THEN** the 'ê' must have circumflex modifier for combination to be valid

#### Scenario: End consonant compatibility
- **WHEN** vowel combination has `allowsEndConsonant = false` (e.g., "ai", "ao", "ay")
- **AND** word has an ending consonant
- **THEN** spelling check fails

---

### Requirement: End Consonant Validation

The system SHALL validate ending consonant combinations.

#### Scenario: Valid end consonants
- **WHEN** word ends with valid consonant (c, ch, m, n, ng, nh, p, t)
- **THEN** end consonant validation passes

#### Scenario: Tone mark restrictions with end consonants
- **WHEN** word ends with sharp consonant (c, ch, p, t)
- **THEN** only sắc (´) or nặng (.) tone marks are allowed
- **AND** huyền (`), hỏi (?), ngã (~) tones cause spelling check to fail

#### Scenario: No end consonant
- **WHEN** word ends with vowel
- **THEN** end consonant validation passes

#### Scenario: Invalid end consonant
- **WHEN** word ends with invalid consonant (e.g., "b", "d", "g", "h", "k", "l", "r", "s", "v", "x")
- **THEN** spelling check fails

#### Scenario: End consonant with incompatible vowel
- **WHEN** word has ending consonant
- **AND** vowel combination does not allow ending consonant
- **THEN** spelling check fails

---

## ADDED Requirements

### Requirement: Syllable Structure Parsing

The system SHALL parse Vietnamese syllables into constituent parts for validation.

#### Scenario: Parse complete syllable
- **GIVEN** input "thuong"
- **WHEN** syllable is parsed
- **THEN** initial consonant is "th"
- **AND** vowel nucleus is "uo" (with horn → "ươ")
- **AND** final consonant is "ng"

#### Scenario: Parse syllable with qu- cluster
- **GIVEN** input "quan"
- **WHEN** syllable is parsed
- **THEN** initial consonant is "qu" (u is part of consonant)
- **AND** vowel nucleus is "a"
- **AND** final consonant is "n"

#### Scenario: Parse syllable with gi- cluster
- **GIVEN** input "giang"
- **WHEN** syllable is parsed
- **THEN** initial consonant is "gi" (i is part of consonant)
- **AND** vowel nucleus is "a"
- **AND** final consonant is "ng"

#### Scenario: Parse vowel-initial syllable
- **GIVEN** input "anh"
- **WHEN** syllable is parsed
- **THEN** initial consonant is empty
- **AND** vowel nucleus is "a"
- **AND** final consonant is "nh"

---

### Requirement: Spell Check Result Types

The system SHALL return detailed spell check results.

#### Scenario: Valid syllable result
- **WHEN** syllable passes all validation checks
- **THEN** return `.valid`

#### Scenario: Invalid initial consonant result
- **WHEN** initial consonant validation fails
- **THEN** return `.invalid(reason: "Invalid initial consonant: ...")`

#### Scenario: Invalid vowel combination result
- **WHEN** vowel combination validation fails
- **THEN** return `.invalid(reason: "Invalid vowel combination: ...")`

#### Scenario: Invalid final consonant result
- **WHEN** final consonant validation fails
- **THEN** return `.invalid(reason: "Invalid final consonant: ...")`

#### Scenario: Invalid tone with ending result
- **WHEN** tone mark is incompatible with ending consonant
- **THEN** return `.invalid(reason: "Tone ... not allowed with ending ...")`

#### Scenario: Incomplete syllable
- **WHEN** syllable is still being typed (e.g., just consonants)
- **THEN** return `.unknown` to allow continued typing

---

### Requirement: Restore Original Input on Invalid

The system SHALL restore original (untransformed) input when spelling is invalid.

#### Scenario: Enable restore on invalid
- **WHEN** `restoreIfWrongSpelling` is enabled in settings
- **AND** user types a word that fails spell check
- **AND** user presses space or word-break character
- **THEN** the transformed text is replaced with original keystrokes

#### Scenario: KeyStates buffer tracking
- **WHEN** user types any key
- **THEN** the original keycode is stored in KeyStates buffer
- **AND** KeyStates is maintained in parallel with TypingBuffer

#### Scenario: Restore process
- **GIVEN** user has typed "thuongf" (invalid: huyền with ng ending not allowed)
- **WHEN** spell check detects invalid combination at word break
- **THEN** send backspaces equal to transformed text length
- **AND** output original characters from KeyStates buffer

#### Scenario: Disable restore on invalid
- **WHEN** `restoreIfWrongSpelling` is disabled
- **AND** word fails spell check
- **THEN** transformed text is kept (no restoration)

---

### Requirement: Special Consonant Cluster Parsing

The system SHALL correctly parse special consonant clusters that absorb following vowel-like characters.

#### Scenario: gi- followed by vowel only
- **GIVEN** input "già"
- **WHEN** syllable is parsed
- **THEN** initial consonant is "gi" (i absorbed into consonant)
- **AND** vowel nucleus is "a"

#### Scenario: gi- followed by vowel+consonant with iê
- **GIVEN** input "giếng"
- **WHEN** syllable is parsed
- **THEN** initial consonant is "g" (NOT "gi")
- **AND** vowel nucleus is "iê"
- **AND** final consonant is "ng"

#### Scenario: qu- always absorbs u
- **GIVEN** input "quốc"
- **WHEN** syllable is parsed
- **THEN** initial consonant is "qu" (u always absorbed)
- **AND** vowel nucleus is "ô"
- **AND** final consonant is "c"

#### Scenario: ngh- requires specific following vowels
- **GIVEN** input "nghĩ"
- **WHEN** syllable is parsed
- **THEN** initial consonant is "ngh"
- **AND** vowel nucleus is "i"

#### Scenario: ngh- with invalid following vowel
- **GIVEN** input "ngha" (invalid - ngh cannot precede 'a')
- **WHEN** syllable is validated
- **THEN** spell check fails

---

### Requirement: Vowel-Consonant Compatibility Matrix

The system SHALL validate vowel-consonant combinations using compatibility rules.

#### Scenario: Vowel allows end consonant
- **GIVEN** vowel combination "iê" (has `allowsEndConsonant = true`)
- **WHEN** followed by valid end consonant "ng"
- **THEN** validation passes

#### Scenario: Vowel forbids end consonant
- **GIVEN** vowel combination "ai" (has `allowsEndConsonant = false`)
- **WHEN** followed by any end consonant
- **THEN** validation fails

#### Scenario: Specific VC compatibility
- **GIVEN** vowel "ă" (breve)
- **WHEN** followed by end consonant
- **THEN** only certain consonants are valid (c, m, n, ng, p, t)

---

### Requirement: Consonant-Vowel Compatibility

The system SHALL validate that initial consonants can combine with given vowels.

#### Scenario: Standard CV combination
- **GIVEN** initial consonant "th"
- **AND** vowel "ương"
- **THEN** combination is valid (thương)

#### Scenario: Invalid CV combination
- **GIVEN** initial consonant "c"
- **AND** vowel "ơ" alone
- **THEN** combination validity depends on CV matrix rules

#### Scenario: Vowel-initial words
- **GIVEN** no initial consonant
- **AND** vowel "anh"
- **THEN** validation passes (vowel-initial words allowed)
