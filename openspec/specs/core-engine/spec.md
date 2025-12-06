# core-engine Specification

## Purpose
TBD - created by archiving change port-openkey-to-swift. Update Purpose after archive.
## Requirements
### Requirement: Vietnamese Input Processing Engine

The system SHALL provide a Vietnamese input processing engine that transforms keyboard input into properly accented Vietnamese text using the backspace-and-replace technique with modern orthography and Unicode encoding.

#### Scenario: Basic character input
- **WHEN** user types a regular character
- **THEN** the character is added to the typing buffer
- **AND** the buffer maintains character state metadata

#### Scenario: Tone mark application
- **WHEN** user types a tone mark key (e.g., 's' for Telex)
- **THEN** the system identifies the appropriate vowel using modern orthography rules
- **AND** applies the tone mark
- **AND** returns the number of backspaces and new Unicode characters to output

#### Scenario: Word break detection
- **WHEN** user types a word break character (space, punctuation, etc.)
- **THEN** the system finalizes current word processing
- **AND** starts a new session for the next word

---

### Requirement: Typing Buffer Management

The system SHALL maintain a typing buffer that stores the current word being typed with complete character state metadata.

#### Scenario: Character state encoding
- **WHEN** a character is added to the buffer
- **THEN** the buffer stores: base character code (16 bits), caps flag, tone modifiers (circumflex, horn/breve), and mark flags (5 tone marks)

#### Scenario: Buffer capacity
- **WHEN** the typing buffer reaches maximum capacity (64 characters)
- **THEN** the system starts a new session
- **AND** preserves the last typed characters

#### Scenario: Delete key handling
- **WHEN** user presses delete/backspace key
- **THEN** the last character is removed from the buffer
- **AND** related state is updated accordingly

---

### Requirement: Modern Orthography Mark Positioning

The system SHALL position tone marks on the correct vowel according to modern Vietnamese orthography rules only.

#### Scenario: Single vowel mark positioning
- **WHEN** the word contains a single vowel
- **THEN** the tone mark is placed on that vowel

#### Scenario: Vowel combination 'oa' mark positioning
- **WHEN** the word contains vowel combination 'oa'
- **THEN** the tone mark is placed on 'a' (e.g., "hoà")

#### Scenario: Vowel combination 'oe' mark positioning
- **WHEN** the word contains vowel combination 'oe'
- **THEN** the tone mark is placed on 'e' (e.g., "hoè")

#### Scenario: Vowel combination 'uy' mark positioning
- **WHEN** the word contains vowel combination 'uy'
- **THEN** the tone mark is placed on 'y' (e.g., "quý")

#### Scenario: Modified vowel priority
- **WHEN** the word contains a modified vowel (â, ê, ô, ơ, ư)
- **THEN** the tone mark is placed on the modified vowel regardless of position

---

### Requirement: Unicode Output

The system SHALL output Vietnamese text using Unicode pre-composed characters (NFC form).

#### Scenario: Unicode character output
- **WHEN** Vietnamese processing generates output
- **THEN** characters are encoded as standard Unicode codepoints (pre-composed NFC)

#### Scenario: Character injection
- **WHEN** new characters need to be sent to application
- **THEN** characters are injected using CGEventKeyboardSetUnicodeString

---

### Requirement: Processing Result Communication

The system SHALL communicate processing results to the platform layer with precise instructions for text manipulation.

#### Scenario: Process result with character replacement
- **WHEN** Vietnamese processing transforms input
- **THEN** the result includes: number of backspaces to send, array of new Unicode characters to output

#### Scenario: Do nothing result
- **WHEN** the input does not require Vietnamese processing
- **THEN** the result indicates no action needed
- **AND** original keystroke passes through

