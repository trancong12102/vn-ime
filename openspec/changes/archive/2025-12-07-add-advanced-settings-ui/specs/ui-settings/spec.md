# ui-settings Spec Delta

## ADDED Requirements

### Requirement: Advanced Text Injection Settings

The system SHALL provide settings to control text injection behavior for compatibility with different applications.

#### Scenario: Fix browser autocomplete toggle
- **WHEN** user accesses Advanced settings section
- **THEN** toggle "Fix browser autocomplete" is displayed
- **AND** default value is enabled (true)
- **AND** help text explains "Injects invisible character to prevent autocomplete interference"

#### Scenario: Fix browser autocomplete persistence
- **WHEN** user changes "Fix browser autocomplete" setting
- **THEN** setting is saved to UserDefaults with key `LotusKeyFixBrowserAutocomplete`
- **AND** setting is restored on next app launch

#### Scenario: Fix browser autocomplete effect
- **WHEN** "Fix browser autocomplete" is enabled
- **THEN** `TextInjector.fixBrowserAutocomplete` is set to true
- **AND** NNBSP character is injected before backspaces to dismiss autocomplete dropdowns

#### Scenario: Fix Chromium browser toggle
- **WHEN** user accesses Advanced settings section
- **THEN** toggle "Fix Chromium browsers" is displayed
- **AND** default value is enabled (true)
- **AND** help text explains "Uses Shift+Arrow workaround for Chrome, Edge, Brave"

#### Scenario: Fix Chromium browser persistence
- **WHEN** user changes "Fix Chromium browsers" setting
- **THEN** setting is saved to UserDefaults with key `LotusKeyFixChromiumBrowser`
- **AND** setting is restored on next app launch

#### Scenario: Fix Chromium browser effect
- **WHEN** "Fix Chromium browsers" is enabled
- **THEN** `TextInjector.fixChromiumBrowser` is set to true
- **AND** when a Chromium-based app (Chrome, Edge, Brave, etc.) is active, Shift+LeftArrow workaround is used instead of plain backspaces

#### Scenario: Fix Chromium browser disabled
- **WHEN** "Fix Chromium browsers" is disabled
- **THEN** `TextInjector.fixChromiumBrowser` is set to false
- **AND** standard backspace injection is used even in Chromium-based apps

#### Scenario: Send key step-by-step toggle
- **WHEN** user accesses Advanced settings section
- **THEN** toggle "Send keys one by one" is displayed
- **AND** default value is disabled (false)
- **AND** help text explains "Slower but more compatible with some applications"

#### Scenario: Send key step-by-step persistence
- **WHEN** user changes "Send keys one by one" setting
- **THEN** setting is saved to UserDefaults with key `LotusKeySendKeyStepByStep`
- **AND** setting is restored on next app launch

#### Scenario: Send key step-by-step effect
- **WHEN** "Send keys one by one" is enabled
- **THEN** `TextInjector.sendKeyStepByStep` is set to true
- **AND** each character is injected as separate key event instead of batched

#### Scenario: Advanced settings grouped
- **WHEN** user accesses General settings tab
- **THEN** advanced options are grouped in a dedicated "Advanced" section
- **AND** section appears after existing sections (Startup, Spelling, Features)

#### Scenario: Settings take effect immediately
- **WHEN** any advanced setting is changed
- **THEN** change takes effect immediately without app restart
- **AND** `TextInjector` properties are updated via settings subscription

#### Scenario: Reset advanced settings to defaults
- **WHEN** user resets settings to defaults
- **THEN** "Fix browser autocomplete" is reset to enabled (true)
- **AND** "Fix Chromium browsers" is reset to enabled (true)
- **AND** "Send keys one by one" is reset to disabled (false)
