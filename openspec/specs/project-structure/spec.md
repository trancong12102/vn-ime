# project-structure Specification

## Purpose
Defines the Swift Package Manager project structure, directory organization, resource management, and build configuration for the LotusKey macOS application.
## Requirements
### Requirement: Swift Package Manager Configuration

The project SHALL use Swift Package Manager as the build system with a `Package.swift` file at the repository root.

#### Scenario: Valid package configuration

- **WHEN** the package is initialized
- **THEN** it SHALL target Swift 6.2+ and macOS 15.0+ (Sequoia)
- **AND** it SHALL define an executable target named `LotusKey`
- **AND** it SHALL define test targets `LotusKeyTests` and `LotusKeyUITests`
- **AND** it SHALL use Swift 6 language mode with complete concurrency checking (default in Swift 6.x)

#### Scenario: No external dependencies

- **WHEN** the package dependencies are evaluated
- **THEN** the package SHALL have zero external dependencies
- **AND** it SHALL only use Apple system frameworks (Carbon, AppKit, SwiftUI, Combine, Observation)

### Requirement: Source Directory Organization

The project SHALL organize source code under `Sources/LotusKey/` following a feature-based directory structure.

#### Scenario: Core directories exist

- **WHEN** the project is scaffolded
- **THEN** the following directories SHALL exist:
  - `Sources/LotusKey/App/`
  - `Sources/LotusKey/Core/Engine/`
  - `Sources/LotusKey/Core/InputMethods/`
  - `Sources/LotusKey/Core/CharacterTables/`
  - `Sources/LotusKey/Core/Spelling/`
  - `Sources/LotusKey/EventHandling/`
  - `Sources/LotusKey/Features/`
  - `Sources/LotusKey/UI/`
  - `Sources/LotusKey/Storage/`
  - `Sources/LotusKey/Utilities/`

#### Scenario: Entry point structure

- **WHEN** the App directory is scaffolded
- **THEN** it SHALL contain `LotusKeyApp.swift` as the SwiftUI app entry point
- **AND** it SHALL contain `AppDelegate.swift` for AppKit integration

### Requirement: Test Directory Organization

The project SHALL organize tests under `Tests/` with separate targets for unit and UI tests.

#### Scenario: Test directories exist

- **WHEN** the project is scaffolded
- **THEN** `Tests/LotusKeyTests/` SHALL exist for unit tests
- **AND** `Tests/LotusKeyUITests/` SHALL exist for UI tests

#### Scenario: Test target dependencies

- **WHEN** test targets are defined
- **THEN** `LotusKeyTests` SHALL depend on `LotusKey` target
- **AND** `LotusKeyUITests` SHALL depend on `LotusKey` target

### Requirement: Resource Management

The project SHALL include resources for assets, localization, and configuration.

#### Scenario: Asset catalog exists

- **WHEN** the project is scaffolded
- **THEN** `Sources/LotusKey/Resources/Assets.xcassets/` SHALL exist
- **AND** it SHALL contain an AppIcon.appiconset placeholder

#### Scenario: Localization files exist

- **WHEN** the project is scaffolded
- **THEN** `Sources/LotusKey/Resources/Localizable.strings` SHALL exist
- **AND** it SHALL support Vietnamese (primary) and English languages

#### Scenario: Info.plist exists

- **WHEN** the project is scaffolded
- **THEN** `Sources/LotusKey/Resources/Info.plist` SHALL exist
- **AND** it SHALL include `NSAccessibilityUsageDescription` key for accessibility permissions

### Requirement: Protocol-First Design

Core components SHALL define protocols before implementations to enable dependency injection and testing.

#### Scenario: Engine protocol defined

- **WHEN** the Core/Engine directory is scaffolded
- **THEN** it SHALL contain a `VietnameseEngine` protocol defining the input processing interface

#### Scenario: Input method protocol defined

- **WHEN** the Core/InputMethods directory is scaffolded
- **THEN** it SHALL contain an `InputMethod` protocol
- **AND** it SHALL contain stub implementation for `TelexInputMethod`

#### Scenario: Character table protocol defined

- **WHEN** the Core/CharacterTables directory is scaffolded
- **THEN** it SHALL contain a `CharacterTable` protocol for encoding conversions

#### Scenario: Spell checker protocol defined

- **WHEN** the Core/Spelling directory is scaffolded
- **THEN** it SHALL contain a `SpellChecker` protocol for Vietnamese word validation

### Requirement: Build Verification

The scaffolded project SHALL compile and run tests successfully.

#### Scenario: Project compiles

- **WHEN** `swift build` is executed
- **THEN** the build SHALL succeed without errors

#### Scenario: Tests run

- **WHEN** `swift test` is executed
- **THEN** all test targets SHALL run without failures

