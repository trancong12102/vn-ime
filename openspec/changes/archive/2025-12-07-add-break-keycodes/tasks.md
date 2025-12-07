# Implementation Tasks

## 1. Add Break Keycode Infrastructure

- [x] 1.1 Create `BreakKeyCodes` enum in `TypedCharacter.swift` with macOS key codes
- [x] 1.2 Add `isBreakKeyCode(_:)` static method to check if keycode is a break key

## 2. Update Engine Processing

- [x] 2.1 Add `handleBreakKeycode()` private method in `VietnameseEngine.swift`
- [x] 2.2 Modify `processKey()` to check keycode-based break BEFORE character processing
- [x] 2.3 Create `checkRestoreIfWrongSpellingForBreakKey()` method (no `wordBreakChar` param, unlike word breaks)
- [x] 2.4 In `handleBreakKeycode()`: check restore first, then call `reset()`
- [x] 2.5 Return restore result (without appending break char) if invalid spelling, else `.passThrough`
- [x] 2.6 Do NOT save to history for break keycodes (unlike character word breaks)

## 3. Update KeyboardEventHandler

- [x] 3.1 Ensure keycode is passed to engine for all key events (already done)
- [x] 3.2 Verify ESC, Tab, Enter, arrows are processed correctly

## 4. Testing

- [x] 4.1 Add unit tests for break keycode detection
- [x] 4.2 Test "ho" + ESC + "a" scenario (should output "hoa", not "ho\u{1B}a")
- [x] 4.3 Test "hoas" (invalid) + ESC → restore original "hoas", clear buffer, ESC passes through
- [x] 4.4 Test arrow keys reset session
- [x] 4.5 Test "hoas" (invalid) + Tab → restore original "hoas", clear buffer, Tab passes through
- [x] 4.6 Test "hoas" (invalid) + Enter → restore original "hoas", clear buffer, Enter passes through
- [x] 4.7 Test punctuation keys (comma, dot) still work as word breaks (with char appended)
- [x] 4.8 Test valid word + ESC → no restore, just clear buffer, ESC passes through

## 5. Documentation

- [x] 5.1 Update code comments explaining break keycode vs word break character
- [x] 5.2 Document restore-if-wrong-spelling behavior for break keycodes
