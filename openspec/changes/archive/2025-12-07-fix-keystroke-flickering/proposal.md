# Proposal: Fix Keystroke Flickering

## Problem Statement

When typing Vietnamese text, every vowel keystroke causes a visible screen flicker. For example, typing "hi":

1. User presses "h" → displays "h" (OK)
2. User presses "i" → screen shows: delete "h", then display "hi" (FLICKER!)

This occurs because the current engine implementation uses a "replace entire buffer" strategy for every keystroke, even when no transformation is needed. The backspace+replace sequence causes visible text flickering that is distracting and can cause conflicts with some applications.

## Root Cause Analysis

### Current Behavior (lotus-key)

The `generateResult()` function in `VietnameseEngine.swift` always returns `.replace()` when the buffer has more than one character:

```swift
// Current logic (simplified)
let backspaces = previousOutputLength  // e.g., 1 for "h"
if backspaces == 0 && newLength == 1 && !wasTransformed {
    return .passThrough  // Only works for FIRST character
}
return .replace(backspaceCount: backspaces, replacement: newOutput)  // Always replace otherwise
```

This means:
- Typing "h" → `.passThrough` (buffer was empty)
- Typing "i" → `.replace(1, "hi")` (backspace 1, send "hi") ← CAUSES FLICKER!

### OpenKey's Approach

OpenKey separates two distinct cases in `vKeyHandleEvent()`:

1. **Normal keys** (`vDoNothing`): Just update internal buffer, let keystroke pass through
2. **Special keys with transformation** (`vWillProcess`): Send backspace + replacement

```cpp
// OpenKey logic (Engine.cpp:1486-1501)
if (!IS_SPECIALKEY(data) || tempDisableKey) {
    hCode = vDoNothing;      // ← Pass through!
    insertKey(data, _isCaps); // Only update internal buffer
} else {
    handleMainKey(data, _isCaps); // Check for transformation
}
```

**Result**: OpenKey only sends backspace+replace when a transformation actually occurs (tone mark, modifier, grammar correction).

## Proposed Solution

Change the engine result logic to match OpenKey's "only replace when transformed" pattern:

1. **Pass through** when character is simply appended (no transformation)
2. **Replace** only when the engine actually transforms text (tone marks, modifiers, grammar corrections)

### Key Changes

1. Modify `generateResult()` to detect "append-only" cases and return `.passThrough`
2. Track whether actual transformation occurred vs. simple character append
3. Only return `.replace()` when backspaces are needed for character modification

## Success Criteria

- No flickering when typing normal Vietnamese syllables (e.g., "con", "người", "việt")
- Correct transformation behavior preserved (e.g., "aa" → "â", "as" → "á")
- All existing tests pass
- No perceptible keyboard input lag

## Scope

- **In scope**: Engine result generation logic, keystroke handling optimization
- **Out of scope**: UI changes, new features, input method changes

## Related Specs

- `core-engine`: Processing Result Communication requirement
- `event-handling`: Keyboard Event Processing requirement
