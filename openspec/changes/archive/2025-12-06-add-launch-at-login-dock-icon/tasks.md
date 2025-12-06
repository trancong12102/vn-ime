# Implementation Tasks

## 1. Create AppLifecycleManager

- [x] 1.1 Create `Sources/VnIme/App/AppLifecycleManager.swift`
- [x] 1.2 Implement `LaunchAtLoginManager` using `SMAppService.mainAppService`
  - [x] 1.2.1 Add `register()` method with error handling
  - [x] 1.2.2 Add `unregister()` method with error handling
  - [x] 1.2.3 Add `status` property to check current state
  - [x] 1.2.4 Ensure main thread safety with `@MainActor`
- [x] 1.3 Implement `DockIconManager` using `NSApp.setActivationPolicy()`
  - [x] 1.3.1 Add `showDockIcon()` method (`.regular` policy)
  - [x] 1.3.2 Add `hideDockIcon()` method (`.accessory` policy)
  - [x] 1.3.3 Add `isDockIconVisible` property

## 2. Integrate with SettingsStore

- [x] 2.1 Update `launchAtLogin` setter to call `LaunchAtLoginManager`
- [x] 2.2 Update `showDockIcon` setter to call `DockIconManager`
- [x] 2.3 Remove TODO comments from `SettingsStore.swift`
- [x] 2.4 Sync `launchAtLogin` getter with actual system state on init

## 3. Update AppDelegate

- [x] 3.1 Apply `showDockIcon` setting on app launch
- [x] 3.2 Handle `requiresApproval` status for launch at login (show alert if needed)

## 4. Testing

- [x] 4.1 Add unit tests for `AppLifecycleManager`
  - [x] 4.1.1 Test dock icon policy changes
  - [x] 4.1.2 Mock-based tests for launch at login (actual registration requires app context)
- [ ] 4.2 Manual testing checklist:
  - [ ] 4.2.1 Toggle "Launch at Login" in settings → verify in System Settings > Login Items
  - [ ] 4.2.2 Toggle "Show Dock Icon" → verify dock icon appears/disappears
  - [ ] 4.2.3 Restart app → verify settings persist correctly
  - [ ] 4.2.4 Log out and log in → verify app auto-starts (if enabled)

## 5. Validation

- [x] 5.1 Run `openspec validate add-launch-at-login-dock-icon --strict`
- [x] 5.2 Run full test suite: `swift test`
- [x] 5.3 Build release: `swift build -c release`
