# ui-settings Specification

## Purpose
Defines the user interface components including the menu bar integration, settings panel, and application lifecycle management.
## Requirements
### Requirement: Menu Bar Integration

The system SHALL provide a status bar menu for quick access to features.

#### Scenario: Status bar icon display
- **WHEN** application is running
- **THEN** status bar icon is displayed showing current language (V/E)

#### Scenario: Menu bar menu access
- **WHEN** user clicks status bar icon
- **THEN** menu is displayed with input options

#### Scenario: Quick language toggle
- **WHEN** user selects language toggle from menu
- **THEN** input language switches immediately

#### Scenario: Input method selection
- **WHEN** user selects input method from submenu
- **THEN** input method changes (Telex, Simple Telex)

---

### Requirement: Settings Panel

The system SHALL provide a settings panel for configuration.

#### Scenario: Open settings panel
- **WHEN** user selects "Control Panel" from menu
- **THEN** settings window is displayed

#### Scenario: Input method settings
- **WHEN** user accesses input method settings
- **THEN** options for Telex, Simple Telex are available

#### Scenario: Spelling settings
- **WHEN** user accesses spelling settings
- **THEN** options include: enable/disable spell check, restore invalid words

#### Scenario: Feature toggles
- **WHEN** user accesses feature settings
- **THEN** options include: Quick Telex, Smart Switch, auto-capitalization

#### Scenario: Hotkey configuration
- **WHEN** user accesses hotkey settings
- **THEN** language switch hotkey can be customized

---

### Requirement: About Window

The system SHALL provide application information.

#### Scenario: Display about window
- **WHEN** user selects "About" from menu
- **THEN** window displays: app name, version, copyright, credits

---

### Requirement: Configuration Persistence

The system SHALL persist all user settings.

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

---

### Requirement: Application Lifecycle

The system SHALL manage application lifecycle properly.

#### Scenario: Background app mode
- **WHEN** dock icon is hidden in settings
- **THEN** application runs as menu bar only (`.accessory` activation policy)
- **AND** application does not appear in Dock or app switcher

#### Scenario: Dock icon mode
- **WHEN** dock icon is enabled in settings
- **THEN** application appears in Dock (`.regular` activation policy)
- **AND** application appears in app switcher (Cmd+Tab)

#### Scenario: Dock icon toggle takes effect immediately
- **WHEN** user toggles dock icon setting
- **THEN** dock visibility changes immediately without restart

#### Scenario: Login item registration
- **WHEN** launch at login is enabled
- **THEN** application registers with `SMAppService.mainAppService`
- **AND** application appears in System Settings > General > Login Items

#### Scenario: Login item unregistration
- **WHEN** launch at login is disabled
- **THEN** application unregisters from `SMAppService.mainAppService`
- **AND** application is removed from System Settings > General > Login Items

#### Scenario: Login item requires approval
- **WHEN** registration returns `.requiresApproval` status
- **THEN** application guides user to System Settings to approve

#### Scenario: Login item state sync on launch
- **WHEN** application launches
- **THEN** setting is synced with actual system state
- **AND** UI reflects the true registration status

#### Scenario: Graceful exit
- **WHEN** user quits application
- **THEN** event tap is cleaned up
- **AND** settings are saved
- **AND** login item registration state is preserved

---

### Requirement: System Notifications

The system SHALL respond to system notifications.

#### Scenario: System wake handling
- **WHEN** system wakes from sleep
- **THEN** event tap is re-initialized if needed

#### Scenario: System sleep handling
- **WHEN** system goes to sleep
- **THEN** event tap is properly suspended

#### Scenario: Space change handling
- **WHEN** user switches to different macOS space
- **THEN** new typing session is started

### Requirement: App Lifecycle Manager

The system SHALL provide a dedicated manager for application lifecycle operations.

#### Scenario: Launch at login management
- **WHEN** `AppLifecycleManager.setLaunchAtLogin(true)` is called
- **THEN** application is registered as login item via `SMAppService`
- **AND** errors are thrown if registration fails

#### Scenario: Launch at login status check
- **WHEN** `AppLifecycleManager.launchAtLoginStatus` is accessed
- **THEN** current `SMAppService.Status` is returned (`.enabled`, `.notRegistered`, `.requiresApproval`)

#### Scenario: Dock icon management
- **WHEN** `AppLifecycleManager.setDockIconVisible(true)` is called
- **THEN** `NSApp.setActivationPolicy(.regular)` is invoked

#### Scenario: Dock icon hidden
- **WHEN** `AppLifecycleManager.setDockIconVisible(false)` is called
- **THEN** `NSApp.setActivationPolicy(.accessory)` is invoked

#### Scenario: Thread safety
- **WHEN** lifecycle methods are called
- **THEN** execution happens on main thread (enforced by `@MainActor`)

