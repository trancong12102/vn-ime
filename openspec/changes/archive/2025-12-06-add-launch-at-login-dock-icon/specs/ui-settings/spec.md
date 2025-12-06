## MODIFIED Requirements

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

## ADDED Requirements

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
