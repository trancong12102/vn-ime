# Tasks: Cải thiện GUI Settings

## 0. Bug Fix - @AppStorage Keys Mismatch (CRITICAL)

- [x] 0.1 Fix `GeneralSettingsView` @AppStorage keys để sử dụng `SettingsKey.rawValue`:
  - `"launchAtLogin"` → `"LotusKeyLaunchAtLogin"`
  - `"showDockIcon"` → `"LotusKeyShowDockIcon"`
  - `"spellCheckEnabled"` → `"LotusKeySpellCheckEnabled"`
  - `"smartSwitchEnabled"` → `"LotusKeySmartSwitchEnabled"`
- [x] 0.2 Fix `InputMethodSettingsView` @AppStorage keys:
  - `"inputMethod"` → `"LotusKeyInputMethod"`
  - `"quickTelexEnabled"` → `"LotusKeyQuickTelexEnabled"`
  - `"autoCapitalize"` → `"LotusKeyAutoCapitalize"`
- [x] 0.3 Test: Verify settings sync giữa UI và engine sau khi fix

## 1. Settings Infrastructure

- [x] 1.1 Add `restoreIfWrongSpelling` case to `SettingsKey` enum in `SettingsStore.swift`
- [x] 1.2 Add `restoreIfWrongSpelling` property to `SettingsStore` class với UserDefaults persistence
- [x] 1.3 Register default value `true` in `registerDefaults()`
- [x] 1.4 Add key to `resetToDefaults()` method
- [x] 1.5 Add `restoreIfWrongSpelling` to `SettingsStoring` protocol

## 2. Settings View Updates

- [x] 2.1 Refactor `GeneralSettingsView` - tách Spelling ra khỏi Features GroupBox
- [x] 2.2 Add "Restore keys if invalid word" toggle as sub-option của spell checking
- [x] 2.3 Add help text "(Hold Ctrl to temporarily disable)"
- [x] 2.4 Wire up `@AppStorage` binding cho setting mới (dùng đúng key `"LotusKeyRestoreIfWrongSpelling"`)
- [x] 2.5 Disable sub-options when spell check master toggle is off

## 3. Engine Wiring

- [x] 3.1 Update `AppDelegate.handleSettingsChange()` to handle `.restoreIfWrongSpelling`
- [x] 3.2 Update `AppDelegate.initializeEventHandler()` to set initial value from settings

## 4. Testing

- [x] 4.1 Verify all toggles sync correctly between UI changes and engine
- [x] 4.2 Verify setting persists across app restart
- [x] 4.3 Verify restore behavior changes based on setting
- [x] 4.4 Verify sub-option disabled state when spell check is off
