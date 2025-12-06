## ADDED Requirements

### Requirement: Typing Buffer Data Structure

The system SHALL provide a TypingBuffer data structure that stores typed characters with complete state metadata using bit-packed encoding compatible with the original OpenKey format.

#### Scenario: Character state encoding

- **WHEN** a character is stored in the buffer
- **THEN** it contains base code (16 bits), caps flag (1 bit), tone modifiers (3 bits for circumflex/horn-breve/stroke), and mark flags (5 bits for sắc/huyền/hỏi/ngã/nặng)

#### Scenario: Buffer append operation

- **WHEN** a new character is appended to a non-full buffer
- **THEN** the character is added at the end preserving its state metadata

#### Scenario: Buffer remove operation

- **WHEN** the last character is removed from a non-empty buffer
- **THEN** the buffer count decreases by one and the removed character is returned

---

### Requirement: qu-/gi- Consonant Cluster Handling

The system SHALL correctly identify when 'u' in 'qu' and 'i' in 'gi' are parts of consonant clusters rather than vowels.

#### Scenario: qu- cluster detection

- **WHEN** the buffer contains 'qu' followed by another vowel
- **THEN** the 'u' is excluded from vowel position analysis
- **AND** tone marks are placed on the following vowel

#### Scenario: gi- cluster detection

- **WHEN** the buffer contains 'gi' followed by another vowel
- **THEN** the 'i' is excluded from vowel position analysis
- **AND** tone marks are placed on the following vowel

#### Scenario: gi- without following vowel

- **WHEN** the buffer contains 'gi' NOT followed by another vowel
- **THEN** the 'i' is treated as a vowel
- **AND** tone marks can be placed on 'i'

---

### Requirement: State History for Undo

The system SHALL maintain a history of buffer states for undo functionality.

#### Scenario: History on word break

- **WHEN** a word break character is typed
- **THEN** the current buffer state is saved to history before clearing

#### Scenario: History on backspace

- **WHEN** backspace is pressed and buffer is not empty
- **THEN** the current state is saved before removing the character

#### Scenario: Restore from history

- **WHEN** backspace is pressed and buffer is empty
- **THEN** the system attempts to restore the previous state from history
- **AND** maintains up to 10 historical states

---

### Requirement: iê/yê/uô/ươ Mark Positioning with Ending

The system SHALL place tone marks on the second vowel when iê/yê/uô/ươ combinations have ending consonants.

#### Scenario: iê + ending consonant

- **WHEN** the syllable contains 'iê' with a following ending consonant
- **THEN** the tone mark is placed on 'ê' (e.g., "tiến")

#### Scenario: yê + ending consonant

- **WHEN** the syllable contains 'yê' with a following ending consonant
- **THEN** the tone mark is placed on 'ê' (e.g., "yến")

#### Scenario: uô + ending consonant

- **WHEN** the syllable contains 'uô' with a following ending consonant
- **THEN** the tone mark is placed on 'ô' (e.g., "cuốn")

#### Scenario: ươ combination

- **WHEN** the syllable contains 'ươ' (both u and o have horn)
- **THEN** the tone mark is placed on 'ơ' (e.g., "nước")

---

### Requirement: Triple Vowel Mark Positioning

The system SHALL place tone marks on the middle vowel for triple vowel combinations.

#### Scenario: oai/oay mark positioning

- **WHEN** the syllable contains 'oai' or 'oay'
- **THEN** the tone mark is placed on 'a' (middle vowel)

#### Scenario: uoi mark positioning

- **WHEN** the syllable contains 'uoi'
- **THEN** the tone mark is placed on 'o' (middle vowel)

#### Scenario: ieu/yeu mark positioning

- **WHEN** the syllable contains 'ieu' or 'yeu'
- **THEN** the tone mark is placed on 'e' (middle vowel)

#### Scenario: uya/uyu mark positioning

- **WHEN** the syllable contains 'uya' or 'uyu'
- **THEN** the tone mark is placed on 'y' (middle vowel)
