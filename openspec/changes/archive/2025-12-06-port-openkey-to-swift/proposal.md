# Change: Port OpenKey to Swift

## Why

OpenKey is currently written in C++/Objective-C, which creates maintenance challenges for macOS development. Porting to Swift provides:

- **Better maintainability**: Swift's modern syntax, type safety, and memory management reduce bugs
- **Native integration**: First-class support for macOS APIs (SwiftUI, Combine, async/await)
- **Comprehensive testing**: Swift's testing frameworks enable unit tests, integration tests, and UI tests
- **Future-proofing**: Aligns with Apple's development direction

## What Changes

### Core Engine (Complete Rewrite)

- Port Vietnamese input processing logic from C++ to Swift
- Implement `TypingWord` buffer with Swift's value types
- Convert bit mask operations to Swift OptionSet/struct patterns
- **Modern orthography only** (oà, uý style)

### Input Methods

- Port Telex input method rules
- Port Simple Telex variants (1 & 2)
- Implement Quick Telex consonant shortcuts
- **No VNI support**

### Character Encoding

- **Unicode only** (UTF-8/UTF-16, pre-composed NFC)
- No legacy encoding support (TCVN3, VNI Windows, etc.)

### Spell Checking

- Port consonant validation rules
- Port vowel combination rules
- Port end consonant rules
- Implement tone mark compatibility checking
- Implement auto-restore for invalid words

### Event Handling

- Port CGEventTap keyboard interception to Swift
- Implement backspace and character injection
- Handle application-specific compatibility (browsers, editors)
- Implement keyboard layout compatibility

### Features

- **Smart Switch**: Per-application language memory
- **Auto-capitalization**: First letter of sentences
- **No macro/text expansion support**

### UI & Settings

- SwiftUI settings panel
- AppKit menu bar integration
- UserDefaults configuration storage
- Accessibility permission handling

### Testing Strategy

- **Unit Tests**: Core engine, input methods, character conversion, spelling rules
- **Integration Tests**: Event handling pipeline, settings persistence
- **E2E Tests**: Real application testing (Terminal, Chrome, Safari, VSCode)

## Impact

### New Capabilities

- `core-engine`: Vietnamese input processing engine (modern orthography, Unicode)
- `event-handling`: macOS keyboard event interception
- `input-methods`: Telex, Simple Telex handlers
- `spell-checking`: Vietnamese spelling validation
- `smart-switch`: Per-app language memory
- `ui-settings`: Configuration and menu bar

### Out of Scope

- Traditional orthography (òa, úy style)
- VNI input method
- Legacy encodings (TCVN3, VNI Windows, Unicode Compound, CP 1258)
- Macro/text expansion system

### Technical Risk

- **High complexity**: Core engine has intricate bit manipulation and state management
- **Platform APIs**: CGEventTap requires careful handling for stability

### Testing Requirements

- Minimum 80% code coverage for core engine
- E2E tests on:
  - Terminal.app
  - Safari
  - Google Chrome
  - Visual Studio Code
  - Notes.app
  - TextEdit
