# Tasks: Fix Backspace Handling

## 1. Core Fix: Simplify handleBackspace()

- [x] 1.1 Remove `restoreFromHistory()` OUTPUT behavior - keep only internal state restore
- [x] 1.2 Make handleBackspace() ALWAYS return `.passThrough`
- [x] 1.3 Before passthrough, update internal state:
  - If buffer not empty: `saveToHistory()`, `removeLast()`
  - If buffer becomes empty: consider calling equivalent of `startNewSession()`
- [x] 1.4 Remove `.replace(backspaceCount: X, replacement: Y)` paths from backspace handling

## 2. previousOutputLength Tracking

- [x] 2.1 Decrement `previousOutputLength` by 1 on each backspace (NFC = 1 char per visual char)
- [x] 2.2 Set to 0 when buffer becomes empty
- [x] 2.3 Ensure tracking stays in sync with actual display

## 3. Internal State Restoration (OpenKey Pattern)

- [x] 3.1 When buffer becomes empty from backspace, call `startNewSession()` equivalent
- [x] 3.2 Optionally restore previous word state INTERNALLY (for context continuity, NOT output)
- [x] 3.3 Ensure restored state does NOT trigger text output

## 4. Spell Checking Consistency

- [x] 4.1 After backspace removes character, run spell check on remaining buffer
- [x] 4.2 Ensure `tempDisableTransformation` flag is updated correctly

## 5. Update Tests

- [x] 5.1 Update `testBackspaceAfterTransformation` - expect `.passThrough` always
- [x] 5.2 Add test: backspace on empty buffer returns `.passThrough` without output
- [x] 5.3 Add test: multiple backspaces don't produce duplicate characters
- [x] 5.4 Add test: backspace after "việt" returns `.passThrough`, buffer = "việ"
- [x] 5.5 Add test: previousOutputLength correctly tracks after backspace

## 6. Manual Validation

- [ ] 6.1 Test: "as" → "á" → backspace → empty (no "áá")
- [ ] 6.2 Test: repeated backspace on empty produces nothing
- [ ] 6.3 Test: no perceptible delay when pressing backspace
- [ ] 6.4 Test: "việt" → backspace → "việ" (tone preserved)
- [ ] 6.5 Test: backspace across word boundary works correctly
- [x] 6.6 Run full test suite (239/239 tests pass)

## 7. Bonus Fix: applyUndo() keystroke preservation

While investigating, found and fixed a related bug in `applyUndo()`:

- [x] 7.1 Fix `applyUndo()` to preserve keyStates when restoring characters
- [x] 7.2 Fix `checkRestoreIfWrongSpelling()` to include word break character in replacement
- [x] 7.3 Update `testUndoResetAfterWordBreak` to reflect correct behavior

## Implementation Notes

### New handleBackspace() Structure

```swift
private func handleBackspace() -> EngineResult {
    if buffer.isEmpty {
        // Optionally restore internal state for context (not output)
        startNewSession()
        return .passThrough
    }

    // Save current state for potential undo
    saveToHistory()

    // Update internal buffer
    _ = buffer.removeLast()

    // Update output length tracking
    previousOutputLength = max(0, previousOutputLength - 1)

    if buffer.isEmpty {
        previousOutputLength = 0
        startNewSession()
    } else {
        // Refresh tone position and check spelling
        _ = buffer.refreshTonePosition()
        checkSpelling()
    }

    // ALWAYS pass through - let system handle the deletion
    return .passThrough
}
```

### Key Principle

**Engine manages internal state. System manages display.**

Backspace key event passes through unchanged. Engine tracks what's left in buffer.
No fake backspaces. No text injection. Simple and fast.
