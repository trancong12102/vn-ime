## ADDED Requirements

### Requirement: Keycode-Based Session Break

The system SHALL reset the typing session when specific navigation keycodes are detected, before any character processing occurs.

#### Scenario: Break keycode triggers reset
- **WHEN** `processKey()` receives a break keycode (ESC, arrows, Tab, Enter)
- **THEN** the engine checks restore-if-wrong-spelling first
- **AND** then calls `reset()` to clear all state
- **AND** returns restore result or `.passThrough` to let the key event proceed
- **AND** no character processing occurs

#### Scenario: Break keycode priority
- **WHEN** a key event has a break keycode
- **AND** the event also has an associated character
- **THEN** the keycode check happens BEFORE character processing
- **AND** the session is reset regardless of the character

#### Scenario: Non-break keycode proceeds to character processing
- **WHEN** `processKey()` receives a keycode that is NOT a break keycode
- **THEN** normal character processing continues
- **AND** character-based word break detection still applies

#### Scenario: Break keycode with invalid spelling triggers restore
- **WHEN** `processKey()` receives a break keycode
- **AND** the buffer contains text with invalid Vietnamese spelling
- **AND** restoreIfWrongSpelling is enabled
- **THEN** original keystrokes are restored (same behavior as word break)
- **AND** then buffer is cleared

#### Scenario: Break keycode with valid spelling does not restore
- **WHEN** `processKey()` receives a break keycode
- **AND** the buffer contains valid Vietnamese spelling
- **THEN** no restore occurs
- **AND** buffer is cleared directly

#### Scenario: Break keycode does not save to history
- **WHEN** `processKey()` receives a break keycode
- **THEN** the current buffer state is NOT saved to history before clearing
- **AND** this differs from character word breaks which DO save to history

---

### Requirement: Break Keycode Registry

The system SHALL maintain a registry of keycodes that trigger session breaks.

#### Scenario: Navigation break keycodes
- **WHEN** checking if a keycode should break the session
- **THEN** the following macOS keycodes are recognized as breaks:
  - 53 (ESC)
  - 48 (Tab)
  - 36 (Return)
  - 76 (Enter/numpad)
  - 123 (Left Arrow)
  - 124 (Right Arrow)
  - 125 (Down Arrow)
  - 126 (Up Arrow)

#### Scenario: Punctuation handled by character
- **WHEN** a punctuation key is pressed (comma, dot, semicolon, etc.)
- **THEN** it is NOT in the break keycode registry
- **AND** character-based word break detection handles it via `handleWordBreak()`

#### Scenario: Backspace excluded from break keycodes
- **WHEN** checking if backspace (keycode 51) should break session
- **THEN** it is NOT recognized as a break keycode
- **AND** dedicated `handleBackspace()` logic processes it instead

---

## MODIFIED Requirements

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

#### Scenario: Break keycode detection
- **WHEN** user presses a break keycode (ESC, arrows, Tab, Enter)
- **THEN** the system resets the typing session immediately
- **AND** clears the buffer without saving to history
- **AND** returns passthrough for the key event
