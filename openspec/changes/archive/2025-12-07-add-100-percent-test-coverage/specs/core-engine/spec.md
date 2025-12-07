## ADDED Requirements

### Requirement: Test Coverage for Logic Components
All logic components in the Core module SHALL have 100% line coverage.

Logic components include:
- CharacterState.swift
- TypedCharacter.swift
- TypingBuffer.swift
- VietnameseEngine.swift
- VietnameseTable.swift
- CharacterTable.swift
- InputMethod.swift
- InputMethodRegistry.swift
- TelexInputMethod.swift
- SimpleTelexInputMethod.swift
- SpellChecker.swift
- QuickTelex.swift

Non-logic components (UI, EventHandling, Storage, App) are excluded from this requirement.

#### Scenario: Coverage verification passes
- **WHEN** running `swift test --enable-code-coverage`
- **AND** generating coverage report with `xcrun llvm-cov report`
- **THEN** all logic components show 100% line coverage

### Requirement: All Public APIs Are Tested
Every public function and property in logic components SHALL have at least one test exercising it.

#### Scenario: Public API coverage
- **GIVEN** a public function in a logic component
- **WHEN** analyzing test coverage
- **THEN** at least one test calls that function

### Requirement: Dead Code Removal
Unused public APIs SHALL be removed rather than tested.

Removal criteria:
- No callers in production code
- No planned usage documented
- Not part of established public API contract

#### Scenario: Identifying dead code
- **GIVEN** a public function with 0% coverage
- **WHEN** searching for callers in production code
- **AND** no callers are found
- **THEN** the function is a candidate for removal

#### Scenario: Preserving API contract
- **GIVEN** a function that is part of documented public API
- **WHEN** the function has no current callers
- **THEN** the function SHOULD be tested rather than removed
