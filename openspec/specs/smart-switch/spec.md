# smart-switch Specification

## Purpose
TBD - created by archiving change port-openkey-to-swift. Update Purpose after archive.
## Requirements
### Requirement: Per-Application Language Memory

The system SHALL remember language preference for each application when Smart Switch is enabled.

#### Scenario: Remember language on app switch
- **WHEN** user switches to a different application
- **AND** Smart Switch is enabled
- **THEN** the language preference for previous app is saved
- **AND** saved preference for new app is restored (if any)

#### Scenario: First time app use
- **WHEN** user switches to an app without saved preference
- **THEN** current language mode is used
- **AND** saved for future switches to that app

#### Scenario: Smart Switch disabled
- **WHEN** Smart Switch is disabled
- **THEN** language preference is not saved per app
- **AND** language state is global

---

### Requirement: Application Detection

The system SHALL detect the frontmost application for Smart Switch.

#### Scenario: Application switch detection
- **WHEN** user clicks on a different application window
- **OR** uses Cmd+Tab to switch apps
- **THEN** the system detects the new frontmost application

#### Scenario: Application identification
- **WHEN** frontmost application changes
- **THEN** the application is identified by bundle identifier

---

### Requirement: Smart Switch Storage

The system SHALL persist Smart Switch data.

#### Scenario: Persist app preferences
- **WHEN** app preference is saved
- **THEN** it survives application restart

#### Scenario: Clear app preferences
- **WHEN** user clears Smart Switch data
- **THEN** all per-app preferences are removed

