# smart-switch Spec Delta

## MODIFIED Requirements

### Requirement: Per-Application Language Memory

The system SHALL remember language preference for each application when Smart Switch is enabled.

#### Scenario: Remember language on app switch
- **WHEN** user switches to a different application
- **AND** Smart Switch is enabled
- **THEN** the language preference for previous app is saved
- **AND** saved preference for new app is restored (if any)
- **AND** menu bar icon is updated to reflect restored mode

#### Scenario: First time app use
- **WHEN** user switches to an app without saved preference
- **THEN** current language mode is used
- **AND** saved for future switches to that app

#### Scenario: Smart Switch disabled
- **WHEN** Smart Switch is disabled
- **THEN** language preference is not saved per app
- **AND** language state is global

#### Scenario: Manual language toggle saves preference
- **WHEN** user manually toggles language mode (via hotkey or menu)
- **AND** Smart Switch is enabled
- **THEN** the new language preference is saved for the current application
