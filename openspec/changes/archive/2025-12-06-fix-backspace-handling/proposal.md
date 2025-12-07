# Change: Fix Backspace Handling Logic

## Why

Backspace handling is broken - pressing backspace after typing Vietnamese text (e.g., "as" → "á") causes duplicate characters to appear ("áá") instead of properly deleting. The root cause is that `restoreFromHistory()` is incorrectly triggered on every backspace when buffer is empty, outputting the restored text instead of just managing internal state.

## What Changes

- **BREAKING**: Remove auto-restore behavior on backspace when buffer is empty
- Align backspace handling with OpenKey's proven approach: update internal buffer only, pass through the original backspace event
- Separate "undo" (explicit user action) from "backspace" (simple deletion)
- Fix delay caused by unnecessary event injection when simple passthrough suffices

## Impact

- Affected specs: `core-engine` (State History for Undo, Delete key handling)
- Affected code:
  - `Sources/LotusKey/Core/Engine/VietnameseEngine.swift:527-569` (handleBackspace)
  - `Sources/LotusKey/Core/Engine/VietnameseEngine.swift:571-600` (history management)

## Problem Analysis

### Current Broken Flow

1. Type "as" → "á" (buffer stores the character)
2. Press backspace:
   - `saveToHistory()` saves "á"
   - `removeLast()` empties buffer
   - Returns `.passThrough` → backspace deletes "á" from screen ✓
3. Press backspace again (buffer empty):
   - `restoreFromHistory()` restores "á" into buffer
   - Returns `.replace(backspaceCount: 1, replacement: "á")`
   - Result: deletes nothing, outputs "á" → "áá" appears ✗

### OpenKey's Correct Approach (Engine.cpp:1420-1465)

```cpp
else if (data == KEY_DELETE) {
    hCode = vDoNothing;  // Always pass through!
    hExt = 2; // delete flag

    // Only update internal buffer
    if (_index > 0) {
        _index--;
    }

    hBPC = 0;  // NO fake backspaces
    hNCC = 0;  // NO new characters

    if (_index == 0) {
        startNewSession();
    }
}
```

Key insight: OpenKey **never outputs text on backspace** - it only manages internal state and passes the event through.

## Design Decision

Adopt OpenKey's approach:
1. Backspace always passes through to the application
2. Engine only updates internal buffer state
3. History restore becomes an explicit "undo" feature (separate from backspace)
4. No text injection during delete operations

## Deep Analysis: Additional Issues Found

### Issue 1: THREE Bugs in handleBackspace(), Not Just One

```swift
private func handleBackspace() -> EngineResult {
    // BUG 1: Empty buffer → restore → OUTPUT text (should just passthrough)
    if buffer.isEmpty {
        if restoreFromHistory() {
            return .replace(backspaceCount: 1, replacement: newOutput)  // ❌
        }
        return .passThrough  // ✓
    }

    // ... remove last char ...

    // BUG 2: Buffer becomes empty, oldLength > 1 → sends extra backspaces
    if buffer.isEmpty {
        if oldLength > 1 {
            return .replace(backspaceCount: oldLength, replacement: "")  // ❌
        }
        return .passThrough  // ✓
    }

    // BUG 3: Buffer not empty → regenerates ENTIRE output
    return .replace(backspaceCount: oldLength, replacement: newOutput)  // ❌
}
```

**All three cases should return `.passThrough`** - only update internal state.

### Issue 2: Performance - Excessive Event Injection

Current approach for backspace when buffer has 4 chars:
- Send 4 backspace events (8 CGEvents: down + up each)
- Send 3 new character events (6 CGEvents)
- Total: **14 CGEvents**

Passthrough approach:
- Original backspace passes through
- Total: **1 CGEvent**

This explains the delay.

### Issue 3: OpenKey DOES Call restoreLastTypingState on Empty Buffer

Looking closer at OpenKey (Engine.cpp:1458-1461):

```cpp
if (_index == 0) {
    startNewSession();
    _specialChar.clear();
    restoreLastTypingState();  // Called here!
}
```

**BUT** it's called AFTER setting `hBPC = 0` and `hNCC = 0`, so it only restores **internal state** without outputting text.

This is for the "undo" use case: when user backspaces across word boundary, OpenKey restores the previous word's state internally so that if user types again, the context is correct.

### Issue 4: Spell Checking After Backspace

OpenKey calls `checkGrammar(1)` after backspace (line 1463):
```cpp
} else {
    checkGrammar(1);
}
```

LotusKey should maintain spell checking consistency after backspace too.

### Issue 5: previousOutputLength Tracking

After passthrough backspace, `previousOutputLength` needs to be decremented by the number of visual characters deleted (usually 1 for NFC Unicode).

### Edge Cases to Handle

| Scenario | Expected Behavior |
|----------|-------------------|
| "á" + backspace | Pass through, buffer empty, previousOutputLength = 0 |
| "việt" + backspace | Pass through, buffer = "việ", previousOutputLength = 3 |
| Empty buffer + backspace | Pass through, start new session, optionally restore internal state for undo |
| After word break + backspace | Pass through, delete space, restore previous word state (internal only) |

## Revised Design

1. **Backspace ALWAYS returns `.passThrough`**
2. **Internal state updates:**
   - If buffer not empty: `removeLast()`, decrement `previousOutputLength`
   - If buffer becomes empty: `startNewSession()`, optionally restore internal state
3. **History:**
   - Still save to history before removing
   - `restoreFromHistory()` only restores internal state, NEVER outputs text
4. **Spell checking:** Run after buffer update
