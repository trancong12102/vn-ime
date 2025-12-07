# Design: Break Keycode Handling

## Context

Vietnamese input methods track typing state in a buffer. When user types "ho", the buffer contains `['h', 'o']`. Certain keys should "break" this session - reset the buffer and start fresh. The current implementation only checks characters for word breaks, missing keycode-based breaks like ESC.

### Stakeholders
- End users expecting ESC to cancel input
- Developers maintaining OpenKey compatibility

### Constraints
- Must maintain compatibility with existing word break characters
- Must follow OpenKey's proven patterns
- macOS-only initially (cross-platform extensible)

## Goals / Non-Goals

### Goals
- ESC key resets typing session completely
- Navigation keys (arrows, Home, End) reset session
- Tab and Enter reset session
- Punctuation keys continue to work as word breaks
- Clear separation between keycode-based and character-based breaks

### Non-Goals
- Windows/Linux support in this change
- Macro functionality (OpenKey's `_macroBreakCode`)
- Quick consonant handling on break codes

## Decisions

### Decision 1: Dual-layer break detection

**What:** Check keycode first, then character.

**Why:** Some keys (ESC, arrows) produce control characters or no character at all. Checking keycode first ensures they're caught. Character check handles printable punctuation.

**Implementation:**
```swift
func processKey(keyCode: UInt16, character: Character?, ...) -> EngineResult {
    // Layer 1: Keycode-based break (ESC, arrows, etc.)
    if BreakKeyCodes.isBreakKeyCode(keyCode) {
        reset()
        return .passThrough
    }

    // Layer 2: Character-based break (punctuation, space)
    if let char = character, VietnameseConstants.isWordBreak(char) {
        return handleWordBreak(wordBreakChar: char)
    }

    // Normal processing...
}
```

**Alternatives considered:**
1. **Character-only approach**: Add `\u{1B}` to wordBreakChars. Rejected because arrows/function keys don't produce consistent characters.
2. **Replace character check entirely**: Use keycodes for everything. Rejected because punctuation mapping varies by keyboard layout.

### Decision 2: Break keycode categories

**What:** Separate break keycodes into two categories:
1. **Navigation breaks**: ESC, arrows, Tab, Enter, Return - always reset session
2. **Punctuation keycodes**: Handled separately via character-based word break (existing logic)

**Why:**
- Navigation keys should ALWAYS break regardless of character produced
- Punctuation depends on character for proper word break handling (e.g., space triggers spell check)

**Implementation:**
```swift
enum BreakKeyCodes {
    // macOS virtual key codes
    static let navigationBreaks: Set<UInt16> = [
        53,   // ESC
        48,   // Tab
        36,   // Return
        76,   // Enter (numpad)
        123,  // Left Arrow
        124,  // Right Arrow
        125,  // Down Arrow
        126,  // Up Arrow
    ]

    static func isBreakKeyCode(_ keyCode: UInt16) -> Bool {
        navigationBreaks.contains(keyCode)
    }
}
```

### Decision 3: Location of keycode constants

**What:** Add `BreakKeyCodes` to `TypedCharacter.swift` alongside existing `backspaceKeyCode`.

**Why:** Keeps key code constants centralized. TypedCharacter already defines backspace key code.

**Alternatives considered:**
1. **New file `KeyCodes.swift`**: More separation but adds file for small amount of code.
2. **In `Extensions.swift` with NSEvent.KeyCode**: Already has escape = 53, but that enum is for different purpose.

### Decision 4: Backspace remains special

**What:** Backspace (keyCode 51) is NOT a break keycode - it has dedicated handling.

**Why:** OpenKey treats backspace specially with character removal, history management, etc. It should not trigger full session reset.

### Decision 5: Restore-if-wrong-spelling behavior

**What:** All break keycodes (including ESC) should trigger restore-if-wrong-spelling when enabled.

**Why:**
- OpenKey's `isWordBreak()` returns true for ALL break codes (ESC, Tab, Enter, arrows)
- The restore logic at lines 1335-1342 applies to all word breaks
- User answered: ESC should "restore rồi cancel" - restore original keystrokes before clearing

**Behavior matrix:**

| Key | In _breakCode | Triggers Restore | After Restore |
|-----|---------------|------------------|---------------|
| ESC | Yes | Yes (if invalid spelling) | Clear buffer |
| Tab | Yes | Yes (if invalid spelling) | Clear buffer |
| Enter/Return | Yes | Yes (if invalid spelling) | Clear buffer |
| Arrows | Yes | Yes (if invalid spelling) | Clear buffer |
| Space | No (separate) | Yes (if invalid spelling) | Clear buffer |

**Implementation approach:**
- Break keycodes use similar restore logic as word breaks, but WITHOUT appending break character
- New method `checkRestoreIfWrongSpellingForBreakKey()` returns restore result without word break char
- After restore (or if no restore needed), reset buffer and return `.passThrough`

```swift
func processKey(keyCode: UInt16, character: Character?, ...) -> EngineResult {
    // Break keycodes trigger restore-if-wrong-spelling then reset
    if BreakKeyCodes.isBreakKeyCode(keyCode) {
        return handleBreakKeycode()
    }
    // ... existing code
}

private func handleBreakKeycode() -> EngineResult {
    // Check restore first (similar to handleWordBreak but no char appended)
    if let restoreResult = checkRestoreIfWrongSpellingForBreakKey() {
        reset()
        return restoreResult  // .replace(backspaces, originalKeys) - NO break char
    }
    reset()
    return .passThrough  // Let break key event pass through to app
}

private func checkRestoreIfWrongSpellingForBreakKey() -> EngineResult? {
    guard restoreIfWrongSpelling, spellCheckEnabled, !tempOffSpellChecking else { return nil }
    guard !buffer.isEmpty, case .invalid(_) = spellChecker.check(buffer.toUnicodeString()) else { return nil }

    // Unlike word breaks: NO word break char appended to replacement
    return .replace(backspaceCount: previousOutputLength, replacement: buffer.originalKeystrokes)
}
```

### Decision 6: No history save for break keycodes

**What:** Break keycodes do NOT save to history before reset (unlike character word breaks).

**Why:**
- OpenKey clears `_typingStates` for non-character break codes
- ESC = cancel action, user doesn't want to undo back to this state
- Arrows = navigation, same reasoning

## Risks / Trade-offs

### Risk 1: Keyboard layout variations
- **Risk**: Non-QWERTY layouts might have different keycodes
- **Mitigation**: Virtual key codes on macOS are layout-independent (physical key position)
- **Note**: This is why we use keycode 53 for ESC, not the character `\u{1B}`

### Risk 2: Missing break keys
- **Risk**: Some keys users expect to break might be missing
- **Mitigation**: Start with OpenKey's proven set, add more based on feedback
- **Current set matches OpenKey**: ESC, Tab, Enter, Return, arrows

### Trade-off: No character break key list
- OpenKey has `_charKeyCode` array to save state for "punctuation" break keys (comma, dot, etc.)
- **Decision**: Skip this for now - the character-based word break handling already covers punctuation
- **Future**: Add if macro/quick consonant features need it

## Migration Plan

1. Add `BreakKeyCodes` enum with navigation key codes
2. Update `processKey()` to check break keycodes first
3. Run existing tests - should all pass
4. Add new tests for ESC/arrow behavior
5. No user-facing migration needed - behavior becomes correct

### Rollback
- Remove keycode check from `processKey()`
- Delete `BreakKeyCodes` enum
- Existing character-based logic continues to work (with ESC bug)

## Open Questions

1. **Should function keys (F1-F12) be break codes?**
   - OpenKey doesn't include them
   - Decision: No, keep minimal set for now

2. **Should Home/End/PageUp/PageDown be break codes?**
   - OpenKey includes them on Windows (`VK_HOME`, `VK_END`, etc.)
   - Decision: Add in future PR if users report issues

## Appendix: OpenKey Reference

### Break codes (macOS)
```cpp
// Engine.cpp lines 21-28
static vector<Uint8> _breakCode = {
    KEY_ESC,        // 53
    KEY_TAB,        // 48
    KEY_ENTER,      // 76
    KEY_RETURN,     // 36
    KEY_LEFT,       // 123
    KEY_RIGHT,      // 124
    KEY_DOWN,       // 125
    KEY_UP,         // 126
    KEY_COMMA,      // 43 (character-based in LotusKey)
    KEY_DOT,        // 47 (character-based in LotusKey)
    // ... more punctuation keycodes
};
```

### isWordBreak function
```cpp
// Engine.cpp lines 145-154
bool isWordBreak(const vKeyEvent& event, const vKeyEventState& state, const Uint16& data) {
    if (event == vKeyEvent::Mouse)
        return true;
    for (i = 0; i < _breakCode.size(); i++) {
        if (_breakCode[i] == data) {  // data = keycode
            return true;
        }
    }
    return false;
}
```

### State reset
```cpp
// Engine.cpp lines 457-466
void startNewSession() {
    _index = 0;
    hBPC = 0;
    hNCC = 0;
    tempDisableKey = false;
    _stateIndex = 0;
    _hasHandledMacro = false;
    _hasHandleQuickConsonant = false;
    _longWordHelper.clear();
}
```
