# Design: Port OpenKey to Swift

## Context

OpenKey is an open-source Vietnamese input method for macOS/Windows that uses a backspace-based technique to provide seamless Vietnamese text input. The original implementation uses C++ for the core engine with Objective-C for macOS platform integration.

This document details the technical architecture, design decisions, and implementation patterns for porting OpenKey to pure Swift.

## Goals / Non-Goals

### Goals

- Complete feature parity with original OpenKey (macOS version, scoped features)
- Modern Swift codebase with strong typing and value semantics
- Comprehensive test coverage (80%+ for core engine)
- Clean separation of concerns for testability
- Support macOS 13.0+ (Ventura)

### Non-Goals

- Windows/Linux support (macOS only)
- Traditional orthography support (modern only)
- VNI input method (Telex/Simple Telex only)
- Legacy encodings (Unicode only)
- Macro/text expansion system

---

## Original OpenKey Architecture Analysis

### System Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                        macOS System                              │
│  ┌─────────────────┐                                             │
│  │  CGEventTap     │ ─── Intercepts keyboard events              │
│  └────────┬────────┘                                             │
│           │                                                       │
│           ▼                                                       │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                 OpenKey Application                          │ │
│  │  ┌───────────────────────────────────────────────────────┐  │ │
│  │  │              Platform Layer (macOS)                    │  │ │
│  │  │  - OpenKey.mm (Event callback)                         │  │ │
│  │  │  - AppDelegate.m (Lifecycle)                           │  │ │
│  │  │  - NSUserDefaults (Settings)                           │  │ │
│  │  └───────────────────────┬───────────────────────────────┘  │ │
│  │                          │                                   │ │
│  │                          ▼                                   │ │
│  │  ┌───────────────────────────────────────────────────────┐  │ │
│  │  │              Core Engine (C++)                         │  │ │
│  │  │  - Engine.cpp (Main processing)                        │  │ │
│  │  │  - Vietnamese.cpp (Character tables)                   │  │ │
│  │  │  - DataType.h (Constants & structures)                 │  │ │
│  │  └───────────────────────────────────────────────────────┘  │ │
│  └─────────────────────────────────────────────────────────────┘ │
│           │                                                       │
│           ▼                                                       │
│  ┌─────────────────┐                                             │
│  │  Target App     │ ─── Receives transformed text                │
│  └─────────────────┘                                             │
└──────────────────────────────────────────────────────────────────┘
```

### Core Data Structures

#### TypingWord Buffer (Original C++)

The `TypingWord` array stores the current word being typed. Each element is a `Uint32` with bit-packed data:

```
Bit Layout (Uint32):
┌────────────────────────────────────────────────────────────────┐
│ 31-26 │  25  │  24  │ 23-19 │ 18 │ 17 │ 16  │    15-0        │
├───────┼──────┼──────┼───────┼────┼────┼─────┼────────────────┤
│unused │isChar│stand │ marks │ w  │ ^  │caps │  key/char code │
│       │ Code │alone │ 5bits │    │    │     │                │
└────────────────────────────────────────────────────────────────┘

Mark bits (19-23):
- Bit 19: Sắc (acute)
- Bit 20: Huyền (grave)
- Bit 21: Hỏi (hook)
- Bit 22: Ngã (tilde)
- Bit 23: Nặng (dot below)

Tone bits:
- Bit 17: ^ (circumflex for â, ê, ô)
- Bit 18: w (horn/breve for ơ, ư, ă)
```

#### Hook State Structure (Original C++)

```cpp
typedef struct vKeyHookState {
    Byte code;           // Action: 0=nothing, 1=process, 2=break, 3=restore
    Byte backspaceCount; // Number of backspaces to send
    Byte newCharCount;   // Number of new characters
    Byte extCode;        // Additional flags
    Uint32 charData[MAX_BUFF];  // Characters to output
} vKeyHookState;
```

### Event Processing Flow

```
1. Keyboard Event Received
         │
         ▼
2. OpenKeyCallback() - macOS event tap
         │
         ├── Is own event? ──────────► Pass through
         │
         ├── Is hotkey? ─────────────► Handle (switch language, etc.)
         │
         ├── Is mouse event? ────────► Reset session, pass through
         │
         └── Is keyboard event
                  │
                  ▼
3. Check language mode
         │
         ├── English mode ───────────► Pass through
         │
         └── Vietnamese mode
                  │
                  ▼
4. vKeyHandleEvent() - Core engine
         │
         ├── Word break character? ──► Process pending, start new
         │
         ├── Delete key? ────────────► Update buffer, backspace
         │
         └── Regular key
                  │
                  ▼
5. Process key
         │
         ├── Is special key (mark/tone)?
         │         │
         │         ├── insertMark() ──► Apply tone mark
         │         │
         │         ├── insertAOE() ───► Apply â, ê, ô
         │         │
         │         ├── insertW() ─────► Apply ơ, ư, ă
         │         │
         │         └── insertD() ─────► Apply đ
         │
         └── Regular character
                  │
                  └── insertKey() ────► Add to buffer
                           │
                           ▼
6. Check spelling (if enabled)
         │
         ├── Invalid? ───────────────► Restore or mark invalid
         │
         └── Valid
                  │
                  ▼
7. Generate Unicode output
         │
         ├── Calculate backspaces needed
         │
         └── Return HookState with charData[]
                  │
                  ▼
8. Platform layer sends output
         │
         ├── Send backspaces
         │
         └── Send new Unicode characters
```

### Telex Input Method Rules

| Input | Output | Description |
|-------|--------|-------------|
| `aa`  | `â`    | Double vowel for circumflex |
| `ee`  | `ê`    | |
| `oo`  | `ô`    | |
| `aw`  | `ă`    | a + w for breve |
| `ow`  | `ơ`    | o + w for horn |
| `uw`  | `ư`    | u + w for horn |
| `dd`  | `đ`    | Double d for stroke |
| `s`   | sắc    | Acute tone mark |
| `f`   | huyền  | Grave tone mark |
| `r`   | hỏi    | Hook tone mark |
| `x`   | ngã    | Tilde tone mark |
| `j`   | nặng   | Dot below tone mark |
| `z`   | remove | Remove mark |

### Quick Telex Shortcuts

| Input | Output | Description |
|-------|--------|-------------|
| `cc`  | `ch`   | Common digraph |
| `gg`  | `gi`   | |
| `kk`  | `kh`   | |
| `nn`  | `ng`   | |
| `pp`  | `ph`   | |
| `qq`  | `qu`   | |
| `tt`  | `th`   | |

### Modern Orthography Mark Positioning Rules

In modern Vietnamese orthography, mark positioning follows these rules:

1. For single vowel: place on that vowel
2. For `oa`, `oe`, `uy`: place on second vowel (`hoà`, `hoè`, `quý`)
3. For `ai`, `ao`, `au`, `ay`, `eo`, `eu`, `iu`, `oi`, `ou`, `ui`: place on first vowel
4. For vowels with circumflex/horn: place on modified vowel
5. Special cases: `uye` → `uyê`, `oai` → `oái`, `uya` → `uyá`

### Spell Checking Rules

1. **Initial Consonants**: Validate against allowed combinations
   - Valid: `b`, `c`, `ch`, `d`, `đ`, `g`, `gh`, `gi`, `h`, `k`, `kh`, `l`, `m`, `n`, `ng`, `ngh`, `nh`, `p`, `ph`, `qu`, `r`, `s`, `t`, `th`, `tr`, `v`, `x`

2. **Vowel Combinations**: Check valid sequences
   - Examples: `a`, `ai`, `ao`, `au`, `ay`, `â`, `âu`, `ây`, `ă`, `e`, `eo`, `ê`, `êu`, `i`, `ia`, `iê`, `iêu`, `o`, `oa`, `oai`, `oay`, `oă`, `oăn`, `oe`, `ô`, `ôi`, `ơ`, `ơi`, `u`, `ua`, `uâ`, `uây`, `ue`, `uê`, `ui`, `uô`, `uôi`, `ư`, `ưa`, `ưi`, `ưu`, `y`, `yê`, `yêu`

3. **End Consonants**: Validate endings
   - Valid: `c`, `ch`, `m`, `n`, `ng`, `nh`, `p`, `t`
   - Special rules: `ch`, `t` limited with certain tone marks

---

## Swift Architecture Design

### Project Structure

```
Sources/
├── OpenKeySwift/
│   ├── App/
│   │   ├── OpenKeySwiftApp.swift      # Entry point
│   │   └── AppDelegate.swift          # NSApplicationDelegate
│   │
│   ├── Core/
│   │   ├── Engine/
│   │   │   ├── InputEngine.swift      # Main processing protocol
│   │   │   ├── VietnameseEngine.swift # Implementation
│   │   │   ├── TypingBuffer.swift     # Character buffer
│   │   │   ├── CharacterState.swift   # Bit-packed state (OptionSet)
│   │   │   └── ProcessingResult.swift # Hook state equivalent
│   │   │
│   │   ├── InputMethods/
│   │   │   ├── InputMethod.swift      # Protocol
│   │   │   ├── TelexMethod.swift      # Telex rules
│   │   │   └── SimpleTelexMethod.swift # Simple Telex variants
│   │   │
│   │   ├── CharacterTables/
│   │   │   ├── VowelTable.swift       # Vowel definitions
│   │   │   ├── ConsonantTable.swift   # Consonant rules
│   │   │   └── UnicodeTable.swift     # Unicode encoding
│   │   │
│   │   └── Spelling/
│   │       ├── SpellChecker.swift     # Protocol
│   │       ├── VietnameseSpellChecker.swift
│   │       ├── ConsonantRules.swift   # Consonant validation
│   │       ├── VowelRules.swift       # Vowel validation
│   │       └── ToneRules.swift        # Tone compatibility
│   │
│   ├── EventHandling/
│   │   ├── KeyboardHook.swift         # CGEventTap wrapper
│   │   ├── KeyEvent.swift             # Event model
│   │   ├── KeyCode.swift              # Key code constants
│   │   ├── OutputInjector.swift       # Send characters
│   │   └── AppCompatibility.swift     # Browser/app quirks
│   │
│   ├── Features/
│   │   ├── SmartSwitch/
│   │   │   ├── SmartSwitchManager.swift # Per-app memory
│   │   │   └── AppLanguageStore.swift   # Storage
│   │   │
│   │   └── QuickTelex/
│   │       └── QuickTelexHandler.swift  # Consonant shortcuts
│   │
│   ├── UI/
│   │   ├── MenuBar/
│   │   │   ├── StatusBarController.swift
│   │   │   └── MenuBuilder.swift
│   │   │
│   │   └── Settings/
│   │       ├── SettingsView.swift       # Main settings
│   │       ├── InputMethodPicker.swift
│   │       ├── SpellingSettingsView.swift
│   │       └── AboutView.swift
│   │
│   ├── Storage/
│   │   ├── SettingsManager.swift      # UserDefaults wrapper
│   │   └── Settings.swift             # Settings model
│   │
│   └── Utilities/
│       ├── Extensions/
│       │   ├── UInt32+CharacterState.swift
│       │   └── String+Vietnamese.swift
│       └── Constants.swift
│
├── OpenKeySwiftTests/
│   ├── Core/
│   │   ├── EngineTests.swift
│   │   ├── TypingBufferTests.swift
│   │   ├── CharacterStateTests.swift
│   │   ├── TelexMethodTests.swift
│   │   ├── SpellCheckerTests.swift
│   │   └── UnicodeTableTests.swift
│   │
│   ├── Features/
│   │   ├── SmartSwitchTests.swift
│   │   └── QuickTelexTests.swift
│   │
│   └── Integration/
│       ├── EventPipelineTests.swift
│       └── SettingsPersistenceTests.swift
│
└── OpenKeySwiftUITests/
    ├── SettingsUITests.swift
    └── MenuBarUITests.swift
```

### Key Design Decisions

#### 1. Character State as OptionSet

Replace C++ bit masks with Swift's type-safe `OptionSet`:

```swift
struct CharacterState: OptionSet {
    let rawValue: UInt32

    // Tone modifiers (bits 17-18)
    static let circumflex = CharacterState(rawValue: 1 << 17)  // ^
    static let hornOrBreve = CharacterState(rawValue: 1 << 18) // w

    // Mark flags (bits 19-23)
    static let acuteMark = CharacterState(rawValue: 1 << 19)   // Sắc
    static let graveMark = CharacterState(rawValue: 1 << 20)   // Huyền
    static let hookMark = CharacterState(rawValue: 1 << 21)    // Hỏi
    static let tildeMark = CharacterState(rawValue: 1 << 22)   // Ngã
    static let dotBelowMark = CharacterState(rawValue: 1 << 23) // Nặng

    // Flags (bits 24-25)
    static let isStandalone = CharacterState(rawValue: 1 << 24)
    static let isCharacterCode = CharacterState(rawValue: 1 << 25)

    // Convenience
    static let caps = CharacterState(rawValue: 1 << 16)
}

struct TypedCharacter {
    var baseCode: UInt16       // First 16 bits
    var state: CharacterState

    var rawValue: UInt32 {
        UInt32(baseCode) | state.rawValue
    }
}
```

#### 2. Protocol-Oriented Input Methods

```swift
protocol InputMethod {
    var type: InputMethodType { get }

    /// Process a key and return transformation if applicable
    func processKey(_ key: KeyCode, in context: TypingContext) -> KeyTransformation?

    /// Check if key is a special key for this method
    func isSpecialKey(_ key: KeyCode) -> Bool

    /// Get the mark type for a key
    func markType(for key: KeyCode) -> MarkType?

    /// Get the tone modifier for a key
    func toneModifier(for key: KeyCode) -> ToneModifier?
}

enum KeyTransformation {
    case insertMark(MarkType)
    case insertTone(ToneModifier)
    case insertStroke  // đ
    case removeMark
    case quickConsonant(from: Character, to: String)
    case passThrough
}
```

#### 3. Processing Result

```swift
enum ProcessingAction {
    case doNothing
    case process(backspaces: Int, output: [UInt32])
    case wordBreak
    case restore(original: [UInt32])
}

struct ProcessingResult {
    let action: ProcessingAction
    let extendedInfo: ExtendedInfo?

    struct ExtendedInfo {
        var isWordBreak: Bool = false
        var isDeleteKey: Bool = false
        var shouldStartNewSession: Bool = false
    }
}
```

#### 4. Dependency Injection for Testing

```swift
protocol InputEngineProtocol {
    func processKeyEvent(_ event: KeyEvent) -> ProcessingResult
    func startNewSession()
    var currentLanguage: Language { get set }
}

class VietnameseEngine: InputEngineProtocol {
    private let inputMethod: InputMethod
    private let spellChecker: SpellChecker
    private var buffer: TypingBuffer

    init(
        inputMethod: InputMethod = TelexMethod(),
        spellChecker: SpellChecker = VietnameseSpellChecker()
    ) {
        self.inputMethod = inputMethod
        self.spellChecker = spellChecker
        self.buffer = TypingBuffer()
    }
}
```

---

## Risks / Trade-offs

### Risk 1: Performance in Event Handler

- **Risk**: CGEventTap callback must return quickly (< 1ms)
- **Mitigation**:
  - Pre-compute lookup tables at startup
  - Avoid allocations in hot path
  - Profile and optimize critical sections
  - Consider using `@inlinable` for performance-critical functions

### Risk 2: Application Compatibility

- **Risk**: Different apps need different handling (Chrome autocomplete, etc.)
- **Mitigation**:
  - Port existing compatibility list from OpenKey
  - Implement app detection and quirks system
  - Allow user-configurable app-specific settings

### Risk 3: Accessibility Permissions

- **Risk**: App may not work without proper permissions
- **Mitigation**:
  - Clear permission request flow
  - Guide users through System Settings
  - Graceful degradation with helpful error messages

---

## Testing Strategy

### Sandbox Limitations & Keyboard Simulation

#### The Sandbox Problem

CGEventTap và CGEvent.post() **không hoạt động trong sandbox** vì:

- Yêu cầu Accessibility permissions (System Settings → Privacy & Security → Accessibility)
- App Store apps bị sandbox nên không thể dùng CGEventTap
- Đây là lý do app phải distribute ngoài App Store (DMG hoặc Homebrew)

#### Keyboard Simulation Methods

| Method | Sandbox? | Use Case |
|--------|----------|----------|
| CGEvent.post() | ❌ No | Production - send keys to other apps |
| XCUIApplication.typeText() | ✅ Yes | UI tests - but bypasses IME |
| Mock KeyEvent injection | ✅ Yes | Unit/Integration tests |
| sendkeys CLI | ❌ No | Automated E2E scripts |

#### CGEvent Keyboard Simulation (Production)

```swift
// Gửi Unicode string (như OpenKey làm)
func sendUnicodeString(_ text: String) {
    let utf16Chars = Array(text.utf16)
    let source = CGEventSource(stateID: .hidSystemState)

    let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true)
    keyDown?.keyboardSetUnicodeString(stringLength: utf16Chars.count, unicodeString: utf16Chars)
    keyDown?.post(tap: .cghidEventTap)

    let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
    keyUp?.post(tap: .cghidEventTap)
}
```

#### XCTest UI Testing (Limited)

```swift
// XCUIApplication typeText - KHÔNG đi qua IME engine!
func testTypingVietnamese() {
    let app = XCUIApplication()
    app.launch()

    let textField = app.textFields["inputField"]
    textField.tap()
    textField.typeText("hello")  // Gửi text trực tiếp, bypass IME
}
```

**Hạn chế**: `typeText()` gửi text trực tiếp vào app, KHÔNG trigger CGEventTap callback, nên không test được IME logic.

### Testing Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Testing Pyramid                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│    ┌───────────────┐                                                │
│    │   E2E Tests   │  ← Manual + sendkeys CLI (requires permission) │
│    │   (5-10%)     │                                                │
│    └───────┬───────┘                                                │
│            │                                                         │
│    ┌───────┴───────┐                                                │
│    │  Integration  │  ← Mock events, test pipeline (sandbox OK)     │
│    │   (15-20%)    │                                                │
│    └───────┬───────┘                                                │
│            │                                                         │
│    ┌───────┴───────┐                                                │
│    │  Unit Tests   │  ← Core engine, pure functions (sandbox OK)    │
│    │   (70-80%)    │                                                │
│    └───────────────┘                                                │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Mock-Based Testing (Recommended Approach)

#### Mock KeyEvent for Engine Testing

```swift
/// Mock key event để test engine mà không cần CGEventTap
struct MockKeyEvent {
    let keyCode: UInt16
    let characters: String
    let isKeyDown: Bool
    let modifiers: NSEvent.ModifierFlags

    /// Tạo từ character (convenience)
    static func key(_ char: Character) -> MockKeyEvent {
        MockKeyEvent(
            keyCode: keyCodeFor(char),
            characters: String(char),
            isKeyDown: true,
            modifiers: []
        )
    }
}

/// Protocol cho testability
protocol KeyEventProvider {
    var keyCode: UInt16 { get }
    var characters: String { get }
    var modifiers: NSEvent.ModifierFlags { get }
}

// Production implementation
extension CGEvent: KeyEventProvider { ... }

// Test implementation
extension MockKeyEvent: KeyEventProvider { ... }
```

#### Engine Test với Mock Events

```swift
class VietnameseEngineTests: XCTestCase {
    var engine: VietnameseEngine!

    override func setUp() {
        engine = VietnameseEngine(
            inputMethod: TelexMethod(),
            spellChecker: VietnameseSpellChecker()
        )
    }

    /// Test helper: process sequence of keys
    func processKeys(_ keys: String) -> String {
        var output = ""
        for char in keys {
            let event = MockKeyEvent.key(char)
            let result = engine.processKeyEvent(event)

            switch result.action {
            case .process(let backspaces, let chars):
                // Remove backspaces from output
                output.removeLast(min(backspaces, output.count))
                // Append new characters
                output += chars.map { Character(UnicodeScalar($0)!) }
            case .doNothing:
                output.append(char)
            default:
                break
            }
        }
        return output
    }

    func testTelexBasicWord() {
        XCTAssertEqual(processKeys("xinf chaof"), "xìn chào")
    }

    func testTelexVowelTransform() {
        XCTAssertEqual(processKeys("aa"), "â")
        XCTAssertEqual(processKeys("uw"), "ư")
        XCTAssertEqual(processKeys("dd"), "đ")
    }

    func testModernOrthography() {
        XCTAssertEqual(processKeys("hoaf"), "hoà")  // mark on 'a'
        XCTAssertEqual(processKeys("quys"), "quý")  // mark on 'y'
    }

    func testSpellCheckRestore() {
        engine.settings.restoreOnInvalid = true
        // "ngha" is invalid (ngh can only precede i, e, ê)
        XCTAssertEqual(processKeys("ngha"), "ngha")  // restored
        XCTAssertEqual(processKeys("nghi"), "nghi")  // valid
    }

    func testQuickTelex() {
        engine.settings.quickTelexEnabled = true
        XCTAssertEqual(processKeys("cc"), "ch")
        XCTAssertEqual(processKeys("gg"), "gi")
    }
}
```

### Unit Test Coverage Goals

| Component | Target Coverage | Priority |
|-----------|----------------|----------|
| Core Engine | 90% | P0 |
| Input Methods | 90% | P0 |
| Spell Checker | 85% | P0 |
| Unicode Table | 85% | P0 |
| Smart Switch | 75% | P1 |
| Event Handling | 70% | P1 |
| UI Components | 60% | P2 |

### Test Categories

#### 1. Unit Tests (OpenKeySwiftTests/) - 70-80%

Chạy trong sandbox, không cần permissions:

- **CharacterStateTests**: Bit manipulation, OptionSet operations
- **TypingBufferTests**: Add/remove characters, state tracking
- **TelexMethodTests**: All transformation rules
- **SpellCheckerTests**: Consonant, vowel, end consonant rules
- **MarkPositioningTests**: Modern orthography rules
- **UnicodeTableTests**: Character encoding

```swift
// CharacterStateTests.swift
func testBitMaskOperations() {
    var state = CharacterState()
    state.insert(.acuteMark)
    state.insert(.circumflex)

    XCTAssertTrue(state.contains(.acuteMark))
    XCTAssertTrue(state.contains(.circumflex))
    XCTAssertFalse(state.contains(.graveMark))
}

// TypingBufferTests.swift
func testBufferOverflow() {
    var buffer = TypingBuffer(maxSize: 64)
    for i in 0..<100 {
        buffer.append(TypedCharacter(baseCode: UInt16(65 + i % 26)))
    }
    XCTAssertEqual(buffer.count, 64)
}
```

#### 2. Integration Tests - 15-20%

Test các components kết hợp với nhau:

- **EventPipelineTests**: KeyEvent → Engine → ProcessingResult
- **SettingsPersistenceTests**: UserDefaults read/write
- **SmartSwitchTests**: App detection + language switching

```swift
// EventPipelineTests.swift
func testFullPipeline() {
    let pipeline = EventPipeline(
        engine: VietnameseEngine(),
        outputHandler: MockOutputHandler()
    )

    // Simulate typing "vieejt"
    let events = "vieejt".map { MockKeyEvent.key($0) }
    for event in events {
        pipeline.process(event)
    }

    XCTAssertEqual(pipeline.outputHandler.result, "việt")
}
```

#### 3. E2E Tests - 5-10%

Yêu cầu Accessibility permission, chạy ngoài sandbox:

**Manual Testing Checklist:**

| App | Test Cases |
|-----|------------|
| Terminal.app | Basic typing, special characters, Ctrl+C |
| Safari | Address bar, search field, form inputs |
| Chrome | Autocomplete handling, DevTools |
| VSCode | Editor, terminal, command palette |
| Notes.app | Rich text, lists |
| TextEdit | Plain text, RTF |

**Automated E2E với sendkeys CLI:**

```bash
#!/bin/bash
# e2e-test.sh - Requires: brew install socsieng/tap/sendkeys

# Test in TextEdit
open -a TextEdit
sleep 1
sendkeys -a "TextEdit" -c "xinf chaof vieejt nam<enter>"
sleep 0.5

# Verify output (screenshot or OCR)
screencapture -x /tmp/e2e-result.png

# Compare with expected
# ... verification logic
```

**E2E Test Script với Swift:**

```swift
// E2ETests.swift (separate target, not sandboxed)
import XCTest

class E2ETests: XCTestCase {

    func testTypingInTextEdit() throws {
        // Launch TextEdit
        let textEdit = NSWorkspace.shared.open(
            URL(fileURLWithPath: "/Applications/TextEdit.app")
        )
        sleep(1)

        // Send keys via CGEvent
        sendKeys("xinf chaof")
        sleep(0.5)

        // Get text from TextEdit via Accessibility API
        let text = getTextFromFrontmostApp()
        XCTAssertEqual(text, "xìn chào")
    }

    private func sendKeys(_ string: String) {
        for char in string {
            let keyCode = keyCodeFor(char)

            let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)
            keyDown?.post(tap: .cghidEventTap)

            let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
            keyUp?.post(tap: .cghidEventTap)

            usleep(50_000) // 50ms delay between keys
        }
    }
}
```

### Test Data Sets

#### Vietnamese Syllable Test Cases

```swift
/// Comprehensive test cases for Vietnamese syllables
struct VietnameseTestData {
    /// Basic syllables without tone
    static let basicSyllables = [
        ("a", "a"), ("an", "an"), ("anh", "anh"),
        ("ba", "ba"), ("ban", "ban"), ("bang", "bang"),
        // ...
    ]

    /// Telex transformations
    static let telexTransforms = [
        // Vowels
        ("aa", "â"), ("aw", "ă"), ("ee", "ê"),
        ("oo", "ô"), ("ow", "ơ"), ("uw", "ư"),
        // Consonant
        ("dd", "đ"),
        // Tone marks
        ("as", "á"), ("af", "à"), ("ar", "ả"),
        ("ax", "ã"), ("aj", "ạ"),
        // Combined
        ("aas", "ấ"), ("aws", "ắ"), ("ees", "ế"),
    ]

    /// Mark positioning (modern orthography)
    static let markPositioning = [
        ("hoaf", "hoà"),   // oa → mark on a
        ("hoef", "hoè"),   // oe → mark on e
        ("quys", "quý"),   // uy → mark on y
        ("thuees", "thuế"), // ue → mark on ê (modified)
        ("khuyas", "khuyá"), // uya → mark on a
    ]

    /// Invalid spellings
    static let invalidSpellings = [
        "ngha",  // ngh only before i, e, ê
        "qua",   // q must be followed by u + vowel
        "kcm",   // invalid consonant cluster
    ]

    /// Edge cases
    static let edgeCases = [
        ("giif", "gì"),    // gi + tone
        ("quyf", "quỳ"),   // quy + tone
        ("nguowif", "người"), // complex syllable
    ]
}
```

### CI/CD Integration

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  unit-tests:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - name: Run Unit Tests
        run: swift test --filter "OpenKeySwiftTests"

  integration-tests:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - name: Run Integration Tests
        run: swift test --filter "IntegrationTests"

  # E2E tests run manually or on release branches
  # because they require Accessibility permissions
```

---

## Open Questions

1. **Unicode Normalization**: Should we normalize output (NFC vs NFD)? Original OpenKey uses pre-composed characters (NFC).

2. **Sandbox**: Can we request temporary exception for CGEventTap, or must we remain non-sandboxed?

3. **Distribution**: App Store (with limitations) or direct distribution only?
