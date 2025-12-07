# Change: Add Launch at Login and Dock Icon Toggle

## Why

The application has two incomplete features marked with TODO comments in `SettingsStore.swift`:
1. **Launch at Login** - Users expect the IME to start automatically when they log in
2. **Dock Icon Toggle** - Users want to choose between menu-bar-only mode or showing in Dock

These are essential features for a production-ready macOS input method application.

## What Changes

- Implement launch at login using `SMAppService.mainAppService` API (macOS 13+)
- Implement dock icon toggle using `NSApp.setActivationPolicy()`
- Add `ServiceManagement` framework to the project
- Create `AppLifecycleManager` to handle both features with proper error handling
- Update settings observers to trigger lifecycle changes
- Add unit tests for the new functionality

## Impact

- **Affected specs**: `ui-settings`
- **Affected code**:
  - `Sources/LotusKey/Storage/SettingsStore.swift` - Remove TODOs, add lifecycle manager calls
  - `Sources/LotusKey/App/AppDelegate.swift` - Initialize lifecycle manager, apply settings on launch
  - New file: `Sources/LotusKey/App/AppLifecycleManager.swift`
  - `Package.swift` - No changes needed (ServiceManagement is system framework)
- **Breaking changes**: None
- **User-facing changes**: Features now work as expected from UI toggles
