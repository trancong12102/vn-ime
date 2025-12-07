# Change: Scaffold Swift Project Structure

## Why

The project currently lacks a Swift codebase structure. OpenKey Swift needs a proper Swift Package Manager project scaffold following 2024-2025 best practices to enable development of the Vietnamese input method application for macOS.

## What Changes

- Create `Package.swift` with Swift 5.9+ configuration targeting macOS 13+
- Scaffold `Sources/LotusKey/` directory tree matching `project.md` architecture:
  - `App/` - Entry point, AppDelegate
  - `Core/Engine/`, `Core/InputMethods/`, `Core/CharacterTables/`, `Core/Spelling/`
  - `EventHandling/` - CGEventTap, keyboard hook
  - `Features/` - Smart Switch, Quick Telex
  - `UI/` - SwiftUI views, Menu bar
  - `Storage/` - UserDefaults, settings
  - `Utilities/` - Extensions, helpers
- Scaffold test directories:
  - `Tests/LotusKeyTests/` - Unit tests
  - `Tests/LotusKeyUITests/` - UI tests
- Add stub files with placeholder implementations
- Create `Resources/` directory with asset catalog structure
- Add `.swiftlint.yml` for code style enforcement

## Impact

- **Affected specs**: Creates new `project-structure` capability
- **Affected code**: Creates new Swift project (no existing Swift code to modify)
- **External dependencies**: None (Apple frameworks only per `project.md`)
