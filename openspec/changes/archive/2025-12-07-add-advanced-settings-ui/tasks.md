# Tasks: Add Advanced Settings UI

## Overview
Add UI controls for existing TextInjector configuration options.

## Task List

### Phase 1: Storage Layer
- [x] **T1: Add settings keys to SettingsKey enum**
  - Add `fixBrowserAutocomplete`, `fixChromiumBrowser`, `sendKeyStepByStep`
  - File: `Sources/VnIme/Storage/SettingsStore.swift`
  - Verification: Build passes

- [x] **T2: Add properties to SettingsStoring protocol**
  - Add three new `Bool` properties with getters/setters
  - File: `Sources/VnIme/Storage/SettingsStore.swift`
  - Verification: Build passes

- [x] **T3: Implement properties in SettingsStore**
  - Follow existing pattern (lock, defaults, subject.send)
  - Register defaults: `fixBrowserAutocomplete=true`, `fixChromiumBrowser=true`, `sendKeyStepByStep=false`
  - File: `Sources/VnIme/Storage/SettingsStore.swift`
  - Verification: Build passes

- [x] **T4: Add keys to resetToDefaults()**
  - Include new keys in reset array
  - File: `Sources/VnIme/Storage/SettingsStore.swift`
  - Verification: Build passes

### Phase 2: UI Layer
- [x] **T5: Add @AppStorage bindings in SettingsView**
  - Add three `@AppStorage` properties in `GeneralSettingsView`
  - File: `Sources/VnIme/UI/SettingsView.swift`
  - Verification: Build passes

- [x] **T6: Add "Advanced" GroupBox with toggles**
  - Create new GroupBox("Advanced") section after existing sections
  - Add Toggle for each setting with descriptive labels:
    - "Fix browser autocomplete" (default: ON)
    - "Fix Chromium browsers" (default: ON)
    - "Send keys one by one" (default: OFF)
  - Add help text explaining each option
  - File: `Sources/VnIme/UI/SettingsView.swift`
  - Verification: UI preview shows new section

### Phase 3: Wiring
- [x] **T7: Apply initial settings to TextInjector**
  - In `initializeEventHandler()`, after creating `textInjector`, apply settings:
    ```swift
    injector.fixBrowserAutocomplete = settings.fixBrowserAutocomplete
    injector.fixChromiumBrowser = settings.fixChromiumBrowser
    injector.sendKeyStepByStep = settings.sendKeyStepByStep
    ```
  - Note: `AppDelegate` holds direct reference to `textInjector` (line 18, 171)
  - File: `Sources/VnIme/App/AppDelegate.swift`
  - Verification: Build passes

- [x] **T8: Subscribe to settings changes for TextInjector**
  - In `handleSettingsChange(_:)`, add cases for new settings:
    ```swift
    case .fixBrowserAutocomplete:
        textInjector?.fixBrowserAutocomplete = settings.fixBrowserAutocomplete
    case .fixChromiumBrowser:
        textInjector?.fixChromiumBrowser = settings.fixChromiumBrowser
    case .sendKeyStepByStep:
        textInjector?.sendKeyStepByStep = settings.sendKeyStepByStep
    ```
  - File: `Sources/VnIme/App/AppDelegate.swift`
  - Verification: Build passes, settings changes take effect immediately

### Phase 4: Testing
- [x] **T9: Add unit tests for new settings**
  - Create new file or add to existing tests
  - Test default values (fixBrowserAutocomplete=true, fixChromiumBrowser=true, sendKeyStepByStep=false)
  - Test persistence (set value, read back)
  - Test settingsChanged publisher fires for each key
  - Test resetToDefaults() resets new keys
  - File: `Tests/VnImeTests/StorageTests.swift` (new file)
  - Verification: `swift test` passes

### Phase 5: Validation
- [x] **T10: Run full verification**
  - `swift build && swift test && swiftlint lint`
  - `openspec validate add-advanced-settings-ui --strict`
  - Verification: All commands pass

## Dependencies
```
T1 → T2 → T3 → T4 (sequential - storage layer)
T5 → T6 (sequential - UI layer)
T4 + T6 → T7 → T8 (wiring depends on storage + UI)
T8 → T9 → T10 (sequential - testing)
```

## Parallelization
- Phase 1 (T1-T4) and Phase 2 (T5-T6) can run in parallel
- Phase 3 (T7-T8) depends on both Phase 1 and Phase 2
- Phase 4-5 run sequentially after Phase 3
