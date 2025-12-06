# core-engine Specification

## Purpose
Defines the core Vietnamese input processing engine that handles character conversion, tone mark placement, typing buffer management, and Unicode output.
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
- **AND** saves current state to history
- **AND** starts a new session for the next word

---

### Requirement: Typing Buffer Management

The system SHALL maintain a typing buffer that stores the current word being typed with complete character state metadata.

#### Scenario: Character state encoding
- **WHEN** a character is added to the buffer
- **THEN** the buffer stores: base character code (16 bits), caps flag, tone modifiers (circumflex, horn/breve, stroke), and mark flags (5 tone marks)

#### Scenario: Buffer capacity
- **WHEN** the typing buffer reaches maximum capacity (64 characters)
- **THEN** the system starts a new session
- **AND** preserves the last typed characters

#### Scenario: Delete key handling with content
- **WHEN** user presses delete/backspace key
- **AND** buffer is not empty
- **THEN** the last character is removed from the internal buffer
- **AND** previousOutputLength is decremented by 1
- **AND** the original backspace event is passed through to the application
- **AND** no text is output by the engine

#### Scenario: Delete key empties buffer
- **WHEN** user presses delete/backspace key
- **AND** buffer becomes empty after removal
- **THEN** previousOutputLength is set to 0
- **AND** a new session is started
- **AND** the original backspace event is passed through to the application

#### Scenario: Delete key with empty buffer
- **WHEN** user presses delete/backspace key
- **AND** buffer is already empty
- **THEN** the original backspace event is passed through to the application
- **AND** no text is output by the engine

#### Scenario: State history preservation on delete
- **WHEN** user presses backspace and buffer is not empty
- **THEN** the current buffer state is saved to history before removing the character
- **AND** history is available for future explicit undo operations

#### Scenario: Spell checking after delete
- **WHEN** user presses backspace
- **AND** buffer is not empty after removal
- **THEN** tone position is refreshed
- **AND** spell checking is performed on the remaining buffer

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
- **WHEN** the word contains a modified vowel (â, ê, ô, ơ, ư, ă)
- **THEN** the tone mark is placed on the modified vowel regardless of position

#### Scenario: qu- consonant cluster handling
- **WHEN** the word starts with 'qu' followed by a vowel
- **THEN** 'u' is treated as part of the consonant cluster, not a vowel
- **AND** the tone mark is placed on the following vowel (e.g., "quá", "quý")

#### Scenario: gi- consonant cluster handling
- **WHEN** the word starts with 'gi' followed by another vowel
- **THEN** 'i' is treated as part of the consonant cluster, not a vowel
- **AND** the tone mark is placed on the following vowel (e.g., "giá")

#### Scenario: iê/yê + ending consonant mark positioning
- **WHEN** the word contains 'iê' or 'yê' vowel combination with an ending consonant
- **THEN** the tone mark is placed on 'ê' (e.g., "tiến", "yến")

#### Scenario: uô + ending consonant mark positioning
- **WHEN** the word contains 'uô' vowel combination with an ending consonant
- **THEN** the tone mark is placed on 'ô' (e.g., "cuốn", "muốn")

#### Scenario: ươ combination mark positioning
- **WHEN** the word contains 'ươ' vowel combination
- **THEN** the tone mark is placed on 'ơ' (e.g., "nước", "được")

#### Scenario: Triple vowel mark positioning
- **WHEN** the word contains three vowels (e.g., 'oai', 'uoi', 'ieu')
- **THEN** the tone mark is placed on the middle vowel

---

### Requirement: Dynamic Tone Repositioning

The system SHALL automatically reposition tone marks when syllable structure changes during typing.

#### Scenario: Tone repositioning after adding ending consonant
- **WHEN** user adds an ending consonant after typing a vowel with tone
- **THEN** the system recalculates the correct tone position
- **AND** moves the tone to the correct vowel if needed

#### Scenario: Tone repositioning after modifier application
- **WHEN** user applies a modifier (circumflex, horn) to a vowel
- **THEN** the system refreshes the tone position based on new structure

---

### Requirement: Ending Consonant Detection

The system SHALL detect valid Vietnamese ending consonants and use them for tone placement decisions.

#### Scenario: Valid ending consonant detection
- **WHEN** the buffer contains characters after the last vowel
- **THEN** the system identifies if they form a valid ending consonant
- **AND** valid endings are: c, ch, m, n, ng, nh, p, t

#### Scenario: Sharp ending consonant identification
- **WHEN** the ending consonant is 'c', 'ch', 'p', or 't'
- **THEN** it is classified as a "sharp" ending
- **AND** only sắc (´) and nặng (.) tones are valid with this ending

---

### Requirement: Spell Validation

The system SHALL validate Vietnamese spelling rules to prevent invalid combinations.

#### Scenario: Invalid tone with sharp ending
- **WHEN** user attempts to apply huyền (`), hỏi (?), or ngã (~) tone
- **AND** the word has a sharp ending (c, ch, p, t)
- **THEN** the tone is rejected
- **AND** the tone key is added as a literal character

#### Scenario: Valid tone with sharp ending
- **WHEN** user attempts to apply sắc (´) or nặng (.) tone
- **AND** the word has a sharp ending (c, ch, p, t)
- **THEN** the tone is applied normally

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

The system SHALL maintain a history of buffer states for explicit undo functionality.

#### Scenario: History on word break
- **WHEN** a word break character is typed
- **THEN** the current buffer state is saved to history before clearing

#### Scenario: History on backspace
- **WHEN** backspace is pressed and buffer is not empty
- **THEN** the current state is saved before removing the character

#### Scenario: History capacity
- **WHEN** history reaches maximum capacity (10 states)
- **THEN** the oldest state is removed to make room for new state

#### Scenario: Undo is explicit action
- **WHEN** user wants to restore previously typed text
- **THEN** an explicit undo action is required (future feature)
- **AND** backspace alone does NOT trigger automatic text restoration

#### Scenario: Internal state restoration
- **WHEN** buffer becomes empty from backspace
- **THEN** previous word state MAY be restored internally for context
- **AND** this internal restoration does NOT output any text

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

