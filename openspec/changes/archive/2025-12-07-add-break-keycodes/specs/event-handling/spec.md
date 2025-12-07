## ADDED Requirements

### Requirement: Break Keycode Detection

The system SHALL detect navigation keys by keycode and reset the typing session, independent of character-based word break detection.

#### Scenario: ESC key resets session
- **WHEN** user presses ESC key (keycode 53)
- **THEN** restore-if-wrong-spelling is checked first
- **AND** the typing buffer is cleared via engine reset
- **AND** the ESC key event is passed through to the application
- **AND** no Vietnamese character processing occurs

#### Scenario: Arrow keys reset session
- **WHEN** user presses any arrow key (Left=123, Right=124, Down=125, Up=126)
- **THEN** the typing buffer is cleared via engine reset
- **AND** the arrow key event is passed through to the application

#### Scenario: Tab key resets session
- **WHEN** user presses Tab key (keycode 48)
- **THEN** the typing buffer is cleared via engine reset
- **AND** the Tab key event is passed through to the application

#### Scenario: Enter/Return keys reset session
- **WHEN** user presses Enter (keycode 76) or Return (keycode 36)
- **THEN** the typing buffer is cleared via engine reset
- **AND** the key event is passed through to the application

#### Scenario: Break keycode takes priority over character
- **WHEN** a key has both a break keycode and produces a character
- **THEN** the keycode check happens first
- **AND** session is reset before any character processing

---

### Requirement: Break Keycode Constants

The system SHALL define platform-specific virtual key codes for session-breaking keys.

#### Scenario: macOS navigation key codes
- **WHEN** the system needs to identify break keycodes on macOS
- **THEN** the following virtual key codes are recognized:
  - ESC = 53
  - Tab = 48
  - Return = 36
  - Enter = 76 (numpad)
  - Left Arrow = 123
  - Right Arrow = 124
  - Down Arrow = 125
  - Up Arrow = 126

#### Scenario: Backspace is not a break keycode
- **WHEN** user presses Backspace (keycode 51)
- **THEN** it is NOT treated as a break keycode
- **AND** dedicated backspace handling logic is used instead

---

## MODIFIED Requirements

### Requirement: Keyboard Event Processing

The system SHALL process keyboard events and determine appropriate action.

#### Scenario: Vietnamese mode key processing
- **WHEN** Vietnamese mode is active
- **AND** a key is pressed without control modifiers (except Shift)
- **THEN** the key is sent to Vietnamese engine for processing

#### Scenario: English mode passthrough
- **WHEN** English mode is active
- **AND** a key is pressed
- **THEN** the key is passed through unchanged

#### Scenario: Mouse event session reset
- **WHEN** a mouse click or drag event occurs
- **THEN** current typing session is reset via engine
- **AND** typing buffer is cleared

#### Scenario: Other control key bypass
- **WHEN** a key is pressed with Command, Control, or Option modifier
- **THEN** the key is passed through unchanged
- **AND** Vietnamese processing is skipped

#### Scenario: Temporary engine disable
- **WHEN** Command key is held down
- **THEN** Vietnamese processing is temporarily bypassed
- **AND** all keys pass through unchanged until Command is released

#### Scenario: Break keycode session reset
- **WHEN** a navigation break keycode is detected (ESC, arrows, Tab, Enter)
- **THEN** current typing session is reset via engine
- **AND** typing buffer is cleared
- **AND** the key event is passed through to the application
