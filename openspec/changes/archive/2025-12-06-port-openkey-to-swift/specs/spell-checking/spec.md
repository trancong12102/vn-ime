# Spell Checking Capability

## ADDED Requirements

### Requirement: Vietnamese Spell Checking

The system SHALL validate Vietnamese word spelling when spell checking is enabled.

#### Scenario: Enable spell checking
- **WHEN** spell checking is enabled in settings
- **THEN** each word is validated against Vietnamese spelling rules

#### Scenario: Disable spell checking
- **WHEN** spell checking is disabled in settings
- **THEN** all character combinations are accepted without validation

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
- **WHEN** word starts with invalid consonant combination
- **THEN** spelling check fails for that word

---

### Requirement: Vowel Combination Validation

The system SHALL validate vowel combinations according to Vietnamese phonology.

#### Scenario: Valid single vowels
- **WHEN** word contains single vowel (a, ă, â, e, ê, i, o, ô, ơ, u, ư, y)
- **THEN** vowel validation passes

#### Scenario: Valid vowel combinations
- **WHEN** word contains valid vowel combination (ai, ao, au, ay, âu, ây, eo, êu, ia, iê, oa, oai, oay, oe, ôi, ơi, ua, uâ, uê, ui, uô, ưa, ưi, ưu, yê)
- **THEN** vowel validation passes

#### Scenario: Invalid vowel combination
- **WHEN** word contains invalid vowel sequence
- **THEN** spelling check fails

---

### Requirement: End Consonant Validation

The system SHALL validate ending consonant combinations.

#### Scenario: Valid end consonants
- **WHEN** word ends with valid consonant (c, ch, m, n, ng, nh, p, t)
- **THEN** end consonant validation passes

#### Scenario: Tone mark restrictions with end consonants
- **WHEN** word ends with 'ch' or 't'
- **THEN** only certain tone marks are allowed (specific Vietnamese phonological rules)

#### Scenario: No end consonant
- **WHEN** word ends with vowel
- **THEN** end consonant validation passes

---

### Requirement: Invalid Word Handling

The system SHALL handle invalid spelling according to user preference.

#### Scenario: Restore invalid word
- **WHEN** spell checking is enabled
- **AND** restore-on-invalid is enabled
- **AND** word spelling is invalid
- **THEN** original unprocessed input is restored

#### Scenario: Keep invalid word
- **WHEN** spell checking is enabled
- **AND** restore-on-invalid is disabled
- **AND** word spelling is invalid
- **THEN** processed text is kept despite invalid spelling

#### Scenario: Temporary spelling disable
- **WHEN** user triggers temporary spelling disable (e.g., Ctrl key)
- **THEN** spelling check is bypassed for current word
- **AND** re-enabled for next word
