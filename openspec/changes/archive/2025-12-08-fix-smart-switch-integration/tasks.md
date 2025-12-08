# Tasks: Fix Smart Switch Integration

## 1. Integration Setup
- [x] 1.1 Add `SmartSwitch` instance property to `AppDelegate`
- [x] 1.2 Initialize `SmartSwitch` in `initializeEventHandler()`
- [x] 1.3 Use existing `ApplicationDetector.applicationChanged` for app switch events (no separate SmartSwitch monitoring needed)
- [x] 1.4 Add `hasPreference(for:)` method to `SmartSwitch` to detect first-time apps (current `shouldEnableVietnamese` can't distinguish "no preference" vs "preference=true")

## 2. App Change Handling
- [x] 2.1 Track previous app bundle ID in AppDelegate for saving preference on switch
- [x] 2.2 On app change (when `smartSwitchEnabled`):
  - Save current language mode for previous app (if previous app exists)
  - Check if new app has saved preference via `hasPreference(for:)`
  - If has preference: restore via direct property set `handler.isVietnameseMode = value` (no publish)
  - If no preference: save current mode for new app
  - Update menu bar icon via `updateLanguageModeMenuItem()`
- [x] 2.3 Ensure restore uses direct property set (not toggle method) to avoid triggering save

## 3. Language Toggle Handling
- [x] 3.1 Add Combine publisher `languageModeChanged` to `KeyboardEventHandler`
  - Publisher fires ONLY from `toggleVietnameseMode()` method
  - Direct property set `isVietnameseMode = value` does NOT publish (for restore)
- [x] 3.2 Update `AppDelegate.toggleLanguageMode()` to call `handler.toggleVietnameseMode()` instead of direct `handler.isVietnameseMode.toggle()`
- [x] 3.3 Subscribe to `languageModeChanged` in AppDelegate
- [x] 3.4 When publisher fires and `smartSwitchEnabled`:
  - Get current app bundle ID from ApplicationDetector
  - Save new language preference via SmartSwitch

## 4. Settings Integration
- [x] 4.1 Subscribe to `smartSwitchEnabled` setting changes
- [x] 4.2 When disabled: skip save/restore logic only (preserve stored data for future re-enable)
- [x] 4.3 When enabled: immediately save current mode for current app

## 5. Testing & Verification
- [x] 5.1 Manual test: Switch apps and verify language mode restores correctly
- [x] 5.2 Manual test: Toggle language in app A, switch to B, return to A - verify A has new mode
- [x] 5.3 Manual test: Disable Smart Switch - verify language is global
- [x] 5.4 Manual test: App restart - verify preferences persist
- [x] 5.5 Add unit tests for SmartSwitch integration logic
