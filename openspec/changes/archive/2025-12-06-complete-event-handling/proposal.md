# Change: Complete Event Handling Implementation

## Status: IMPLEMENTED (with review fixes)

Initial implementation completed. Deep review against OpenKey reference identified and fixed 6 issues.

## Why

The current `KeyboardEventHandler` has basic scaffolding but lacks critical functionality for a working IME:
- No mechanism to filter own events (causes infinite loops)
- No mouse event handling (session reset)
- No application-specific quirks handling (Chrome, Sublime Text)
- No hotkey support for language switching
- Missing accessibility permission UI flow
- No keyboard layout compatibility
- No temporary disable mechanisms
- No batch vs step-by-step sending modes
- No other-language detection

Without these, the IME cannot function reliably in real-world usage.

## What Changes

### Core Event Handling
- Add private event source (`CGEventSourceCreate`) to identify own events
- Implement own-event filtering using source state ID comparison
- Add mouse event monitoring for session reset
- Handle event tap timeout/disabled recovery
- Add keyUp event monitoring (for proper event flow)
- Add flagsChanged event monitoring (for modifier tracking)
- **Share event source between Handler and Injector** (review fix)

### Text Injection
- Pre-create backspace events for performance
- Use `CGEventTapPostEvent` instead of `CGEvent.post` for reliability
- Implement batch character sending (up to 16 chars per event)
- Implement step-by-step character sending mode (configurable)
- **Chromium workaround**: Send ONE Shift+LeftArrow to select 1 char, then continue with remaining backspaces (review fix - matches OpenKey pattern)
- **Empty char injection**: Inject NNBSP then increase backspace count by 1 to delete it (review fix)
- **Sublime Text**: Uses ZWNJ which doesn't need extra backspace handling

### Application Compatibility
- Add application bundle ID detection
- Implement Chromium browser workaround (Shift+Arrow for first backspace only)
- Implement Sublime Text special character handling (ZWNJ 0x200C)
- Handle Unicode Compound issues in Chrome-based browsers
- Implement empty character injection for autocomplete fixes (NNBSP 0x202F)

### Hotkey Support
- Implement configurable language switch hotkey (default: Ctrl+Space)
- Detect modifier key combinations in FlagsChanged events
- **FlagsChanged logic**: Only process on modifier RELEASE (lastFlags > flags) (review fix)
- **Temp disable is TOGGLE**: Command/Control release toggles temp off state (review fix)
- **hasJustUsedHotkey tracking**: Avoid temp toggle right after hotkey use (review fix)

### Keyboard Layout Compatibility
- Implement layout-independent key code conversion
- Use NSEvent to get characters ignoring modifiers
- Support non-QWERTY layouts (Dvorak, Colemak, etc.)

### Other Language Detection
- Use TIS (Text Input Services) to detect current system input source
- Auto-bypass Vietnamese processing when non-English IME active
- Prevent conflicts with other language input methods

### Modifier Key Tracking
- Track all modifier states: Shift, Control, Command, Option, **Fn, NumPad, Help** (review fix)
- Detect OTHER_CONTROL_KEY (any modifier except Shift) to bypass processing
- Handle Caps Lock vs Shift distinction for proper capitalization

### Accessibility Permissions
- Add permission check with user prompt
- Provide clear error messaging for permission denied
- Guide user to System Settings > Privacy & Security > Accessibility

## Review Fixes Applied

Issues identified during deep review against OpenKey reference implementation:

| # | Issue | Severity | Fix |
|---|-------|----------|-----|
| 1 | Chromium Shift+Arrow sent for ALL chars | HIGH | Send only 1 Shift+Arrow |
| 2 | Empty char injected for Chromium (wrong) | HIGH | Only inject for non-Chromium apps |
| 3 | FlagsChanged processed on press (should be release) | MEDIUM | Process only when lastFlags > currentFlags |
| 4 | Temp off was set/unset (should toggle) | MEDIUM | Changed to toggle on modifier release |
| 5 | Handler and Injector had separate event sources | MEDIUM | Share single event source |
| 6 | hasOtherControlKey missing Fn/NumPad/Help | LOW | Added all modifiers from OpenKey |
| 7 | Chromium backspace count wrong when count > 1 | HIGH | Only decrement if count == 1, else keep original |

### Issue 7 Detail (Double-check review)

**OpenKey pattern** (`OpenKey.mm:721-725`):
```objc
if (backspaceCount > 0) {
    SendShiftAndLeftArrow();       // Always send once
    if (backspaceCount == 1)
        backspaceCount--;          // Only decrement if == 1
}
// Then: for loop sends backspaceCount backspaces
```

**Behavior**:
- `count=1`: Shift+Arrow, then 0 backspaces (new text replaces selection)
- `count=2`: Shift+Arrow, then 2 backspaces
- `count=3`: Shift+Arrow, then 3 backspaces

**Fix**: Only set `remainingCount = 0` when original count == 1, otherwise keep original count for backspace loop.

## Impact

- **Affected specs**: `event-handling`
- **Affected code**:
  - `Sources/VnIme/EventHandling/KeyboardEventHandler.swift` (major changes)
  - `Sources/VnIme/App/AppDelegate.swift` (wire up handler, share event source)
  - New: `Sources/VnIme/EventHandling/ApplicationDetector.swift`
  - New: `Sources/VnIme/EventHandling/TextInjector.swift`
  - New: `Sources/VnIme/EventHandling/HotkeyDetector.swift`
  - New: `Sources/VnIme/EventHandling/KeyboardLayoutConverter.swift`
  - New: `Sources/VnIme/EventHandling/InputSourceDetector.swift`
  - New: `Sources/VnIme/UI/AccessibilityPermissionView.swift`
- **Dependencies**: None (uses only Apple frameworks: Carbon, AppKit, InputMethodKit)
- **Breaking changes**: None (additive changes only)

## Out of Scope (Deferred to Future Changes)

These features exist in OpenKey but are NOT included in this change:
- Macro/abbreviation expansion system
- Convert tool (clipboard conversion)
- Smart switch (per-app language memory) - separate spec exists
- Auto-capitalize first letter - handled by engine
- Multi-byte encodings (TCVN3, VNI Windows, CP1258) - Unicode only for now
- Sync key mechanism for VNI/Unicode Compound (not needed for Unicode-only mode)
