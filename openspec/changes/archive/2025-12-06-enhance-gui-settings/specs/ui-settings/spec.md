## MODIFIED Requirements

### Requirement: Settings Panel

The system SHALL provide a settings panel for configuration.

#### Scenario: Open settings panel
- **WHEN** user selects "Settings..." from menu
- **THEN** settings window is displayed

#### Scenario: Input method settings
- **WHEN** user accesses input method settings
- **THEN** options for Telex, Simple Telex are available

#### Scenario: Spelling settings grouped
- **WHEN** user accesses General settings tab
- **THEN** spelling options are grouped in a dedicated "Spelling" section

#### Scenario: Spelling master toggle
- **WHEN** user toggles "Enable spell checking"
- **THEN** spell checking is enabled/disabled system-wide
- **AND** sub-options (restore if invalid) become enabled/disabled accordingly

#### Scenario: Restore if invalid word setting
- **WHEN** user enables "Restore keys if invalid word"
- **AND** spell checking is enabled
- **THEN** engine restores original keystrokes when word is invalid at word boundary

#### Scenario: Restore setting disabled state
- **WHEN** spell checking is disabled
- **THEN** "Restore keys if invalid word" toggle is visually disabled
- **AND** user cannot interact with it

#### Scenario: Ctrl bypass help text
- **WHEN** user views spelling settings
- **THEN** help text indicates "(Hold Ctrl to temporarily disable)"

#### Scenario: Feature toggles
- **WHEN** user accesses feature settings
- **THEN** options include: Quick Telex, Smart Switch, auto-capitalization

#### Scenario: Hotkey configuration
- **WHEN** user accesses hotkey settings
- **THEN** language switch hotkey can be customized

---

### Requirement: Configuration Persistence

The system SHALL persist all user settings.

#### Scenario: Settings key consistency
- **WHEN** settings are read or written
- **THEN** both SwiftUI `@AppStorage` and `SettingsStore` use the same UserDefaults keys
- **AND** keys follow the pattern `LotusKey{SettingName}` (e.g., `LotusKeySpellCheckEnabled`)

#### Scenario: Settings saved automatically
- **WHEN** user changes any setting
- **THEN** setting is saved to UserDefaults immediately

#### Scenario: Settings restored on launch
- **WHEN** application launches
- **THEN** all settings are restored from UserDefaults

#### Scenario: Default settings
- **WHEN** settings are not found
- **THEN** sensible defaults are applied:
  - Language: Vietnamese
  - Input method: Telex
  - Spell check: enabled
  - Restore if wrong spelling: enabled

---

## ADDED Requirements

### Requirement: Restore If Wrong Spelling Setting

The system SHALL provide a setting to control restore-on-invalid behavior.

#### Scenario: Setting persistence
- **WHEN** user changes "Restore keys if invalid word" setting
- **THEN** setting is saved to UserDefaults with key `LotusKeyRestoreIfWrongSpelling`
- **AND** setting is restored on next app launch

#### Scenario: Default value
- **WHEN** app is first launched (no settings exist)
- **THEN** "Restore keys if invalid word" defaults to enabled (true)

#### Scenario: Engine integration
- **WHEN** setting is changed
- **THEN** engine's `restoreIfWrongSpelling` property is updated
- **AND** change takes effect immediately (no restart required)

#### Scenario: Reset to defaults
- **WHEN** user resets settings to defaults
- **THEN** "Restore keys if invalid word" is reset to enabled (true)
