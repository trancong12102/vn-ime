## MODIFIED Requirements

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
