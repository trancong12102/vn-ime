# input-methods Specification

## Purpose
TBD - created by archiving change port-openkey-to-swift. Update Purpose after archive.
## Requirements
### Requirement: Telex Input Method

The system SHALL support the Telex input method for Vietnamese text entry.

#### Scenario: Vowel transformation with double letter
- **WHEN** user types 'aa', 'ee', or 'oo'
- **THEN** the system transforms to 'â', 'ê', or 'ô' respectively

#### Scenario: Horn and breve transformation with 'w'
- **WHEN** user types 'aw', 'ow', or 'uw'
- **THEN** the system transforms to 'ă', 'ơ', or 'ư' respectively

#### Scenario: Stroke transformation for 'd'
- **WHEN** user types 'dd'
- **THEN** the system transforms to 'đ'

#### Scenario: Tone mark keys
- **WHEN** user types tone mark keys (s, f, r, x, j)
- **THEN** the system applies corresponding marks (sắc, huyền, hỏi, ngã, nặng)

#### Scenario: Remove mark with 'z'
- **WHEN** user types 'z' after a marked character
- **THEN** the system removes the tone mark

#### Scenario: Undo transformation
- **WHEN** user types the same transformation key twice
- **THEN** the transformation is undone (e.g., 'aaa' → 'aa')

---

### Requirement: Simple Telex Input Method

The system SHALL support Simple Telex variants with reduced key combinations.

#### Scenario: Simple Telex variant 1
- **WHEN** Simple Telex 1 is selected
- **THEN** simplified transformation rules apply (fewer double-letter requirements)

#### Scenario: Simple Telex variant 2
- **WHEN** Simple Telex 2 is selected
- **THEN** alternative simplified rules apply

---

### Requirement: Quick Telex Consonant Shortcuts

The system SHALL support Quick Telex shortcuts for common consonant combinations when enabled.

#### Scenario: Quick consonant 'cc' to 'ch'
- **WHEN** Quick Telex is enabled
- **AND** user types 'cc'
- **THEN** the system transforms to 'ch'

#### Scenario: Quick consonant 'gg' to 'gi'
- **WHEN** Quick Telex is enabled
- **AND** user types 'gg'
- **THEN** the system transforms to 'gi'

#### Scenario: Quick consonant 'nn' to 'ng'
- **WHEN** Quick Telex is enabled
- **AND** user types 'nn'
- **THEN** the system transforms to 'ng'

#### Scenario: All quick consonant mappings
- **WHEN** Quick Telex is enabled
- **THEN** the following shortcuts are available: cc→ch, gg→gi, kk→kh, nn→ng, pp→ph, qq→qu, tt→th

#### Scenario: Quick Telex disabled
- **WHEN** Quick Telex is disabled
- **AND** user types 'cc'
- **THEN** 'cc' is output as-is without transformation

---

### Requirement: Input Method Switching

The system SHALL allow switching between Telex and Simple Telex at runtime.

#### Scenario: Switch input method
- **WHEN** user changes input method
- **THEN** new session starts
- **AND** subsequent input uses new method rules

#### Scenario: Preserve language state on method switch
- **WHEN** input method is changed
- **THEN** Vietnamese/English language state is preserved

