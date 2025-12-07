# Tasks: Scaffold Swift Project Structure

## 1. Package Configuration

- [x] 1.1 Create `Package.swift` with Swift 5.9+, macOS 13+ platform target
- [x] 1.2 Configure executable target `LotusKey` with strict concurrency
- [x] 1.3 Configure test targets `LotusKeyTests` and `LotusKeyUITests`
- [x] 1.4 Add resource processing rules for Assets.xcassets

## 2. Source Directory Structure

- [x] 2.1 Create `Sources/LotusKey/App/` with `LotusKeyApp.swift` and `AppDelegate.swift` stubs
- [x] 2.2 Create `Sources/LotusKey/Core/Engine/` with `VietnameseEngine.swift` protocol stub
- [x] 2.3 Create `Sources/LotusKey/Core/InputMethods/` with `InputMethod.swift` protocol and `TelexInputMethod.swift` stub
- [x] 2.4 Create `Sources/LotusKey/Core/CharacterTables/` with `CharacterTable.swift` protocol and `UnicodeCharacterTable` stub
- [x] 2.5 Create `Sources/LotusKey/Core/Spelling/` with `SpellChecker.swift` protocol stub
- [x] 2.6 Create `Sources/LotusKey/EventHandling/` with `KeyboardEventHandler.swift` stub
- [x] 2.7 Create `Sources/LotusKey/Features/` with `SmartSwitch.swift`, `QuickTelex.swift` stubs
- [x] 2.8 Create `Sources/LotusKey/UI/` with `SettingsView.swift` and `MenuBarController.swift` stubs
- [x] 2.9 Create `Sources/LotusKey/Storage/` with `SettingsStore.swift` stub
- [x] 2.10 Create `Sources/LotusKey/Utilities/` with `Extensions.swift` stub

## 3. Test Directory Structure

- [x] 3.1 Create `Tests/LotusKeyTests/` with `EngineTests.swift`, `InputMethodTests.swift` stubs
- [x] 3.2 Create `Tests/LotusKeyUITests/` with `SettingsUITests.swift` stub

## 4. Resources

- [x] 4.1 Create `Sources/LotusKey/Resources/Assets.xcassets/` with AppIcon placeholder
- [x] 4.2 Create `Sources/LotusKey/Resources/Localizable.strings` for Vietnamese/English
- [x] 4.3 Create `Sources/LotusKey/Resources/LotusKey-Info.plist` with required keys (accessibility description)

## 5. Code Quality

- [x] 5.1 Create `.swiftlint.yml` with rules matching `project.md` conventions
- [x] 5.2 Update `.gitignore` with Swift-specific entries

## 6. Validation

- [x] 6.1 Run `swift build` to verify package compiles
- [x] 6.2 Run `swift test` to verify test targets work
- [x] 6.3 Open in Xcode and verify project loads correctly (SPM auto-generates Xcode project)
