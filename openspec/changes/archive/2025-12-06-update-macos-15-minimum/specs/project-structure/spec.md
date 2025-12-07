## MODIFIED Requirements

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
