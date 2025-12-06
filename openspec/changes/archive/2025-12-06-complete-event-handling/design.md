# Design: Complete Event Handling

## Context

The event handling system is the bridge between macOS keyboard events and the Vietnamese input engine. It must:
- Intercept all keyboard events system-wide
- Process them through the Vietnamese engine
- Inject replacement text back to applications
- Handle edge cases across different applications

Reference implementation: OpenKey's `OpenKey.mm` (Objective-C/C++)

## Goals / Non-Goals

**Goals:**
- Reliable keyboard interception and text injection
- No infinite loops from own events
- Compatibility with major applications (browsers, editors, terminals)
- Sub-millisecond event processing latency
- Clean Swift implementation following existing patterns
- Support for non-QWERTY keyboard layouts
- Graceful coexistence with other IMEs

**Non-Goals:**
- Support for non-Unicode encodings (VNI Windows, TCVN3, CP1258)
- Support for macOS < 13.0
- Sandboxed operation (impossible due to CGEventTap requirement)
- Macro/abbreviation system (separate feature)
- Convert tool (separate feature)

## Decisions

### Decision 1: Private Event Source for Own-Event Filtering

**What:** Create a private `CGEventSource` at initialization and use its state ID to identify events we inject.

**Why:** This is how OpenKey prevents infinite loops. When our callback receives an event, we check if its source state ID matches our private source. If so, pass through without processing.

**Alternative considered:**
- Flag-based approach (set flag before injection, clear after) - Race conditions possible
- Timer-based debounce - Unreliable timing

**Code pattern:**
```swift
private var eventSource: CGEventSource?

init() {
    eventSource = CGEventSource(stateID: .privateState)
}

func shouldProcessEvent(_ event: CGEvent) -> Bool {
    guard let source = eventSource else { return true }
    let eventSourceID = event.getIntegerValueField(.eventSourceStateID)
    let mySourceID = CGEventSourceGetSourceStateID(source)
    return eventSourceID != mySourceID
}
```

### Decision 2: CGEventTapPostEvent for Injection

**What:** Use `CGEventTapPostEvent(proxy, event)` instead of `event.post(tap:)`.

**Why:**
- `CGEventTapPostEvent` posts through the proxy, maintaining proper event ordering
- More reliable in callback context
- Matches OpenKey's proven approach

**Code pattern:**
```swift
func injectBackspace(proxy: CGEventTapProxy) {
    guard let source = eventSource,
          let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x33, keyDown: true),
          let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x33, keyDown: false)
    else { return }

    CGEventTapPostEvent(proxy, keyDown)
    CGEventTapPostEvent(proxy, keyUp)
}
```

### Decision 3: Batch vs Step-by-Step Character Sending

**What:** Support two modes of character injection, configurable via settings.

**Why:**
- Batch mode (default): Faster, sends up to 16 chars in single event
- Step-by-step mode: More compatible with certain applications that don't handle batch Unicode well

**OpenKey reference:** `vSendKeyStepByStep` flag controls this behavior.

**Code pattern:**
```swift
func injectString(_ string: String, proxy: CGEventTapProxy, stepByStep: Bool) {
    if stepByStep {
        for char in string {
            injectSingleCharacter(char, proxy: proxy)
        }
    } else {
        injectBatchCharacters(string, proxy: proxy, maxBatch: 16)
    }
}
```

### Decision 4: Separate TextInjector Component

**What:** Extract text injection logic into a dedicated `TextInjector` class.

**Why:**
- Single responsibility - handler focuses on event routing
- Easier to test injection logic in isolation
- Cleaner handling of application-specific quirks

**Interface:**
```swift
protocol TextInjecting: AnyObject {
    func injectBackspaces(count: Int, proxy: CGEventTapProxy)
    func injectString(_ string: String, proxy: CGEventTapProxy)
    func injectEmptyCharacter(proxy: CGEventTapProxy)
    func injectShiftLeftArrow(count: Int, proxy: CGEventTapProxy)
}
```

### Decision 5: Application Detection via Bundle ID

**What:** Use `NSWorkspace.shared.frontmostApplication?.bundleIdentifier` to detect current app.

**Why:**
- Reliable across app versions
- Standard macOS approach
- Can cache and update only on app switch

**Quirk handling:**
| Application | Bundle ID Prefix | Workaround |
|-------------|------------------|------------|
| Sublime Text | `com.sublimetext` | Use ZWNJ (0x200C) instead of NNBSP |
| Chrome/Chromium | `com.google.Chrome`, `com.brave.Browser`, `com.microsoft.Edge*` | Shift+Arrow for backspace |
| Apple apps | `com.apple.` | Unicode Compound handling |

### Decision 6: Mouse Event Monitoring

**What:** Add mouse events to the event mask and reset session on click/drag.

**Why:**
- User clicking means they're starting a new typing context
- Must clear the typing buffer to avoid incorrect processing
- Matches OpenKey behavior

**Event mask:**
```swift
let eventMask: CGEventMask = (
    (1 << CGEventType.keyDown.rawValue) |
    (1 << CGEventType.keyUp.rawValue) |
    (1 << CGEventType.flagsChanged.rawValue) |
    (1 << CGEventType.leftMouseDown.rawValue) |
    (1 << CGEventType.rightMouseDown.rawValue) |
    (1 << CGEventType.leftMouseDragged.rawValue) |
    (1 << CGEventType.rightMouseDragged.rawValue)
)
```

### Decision 7: Hotkey Detection with Bitfield Configuration

**What:** Use bitfield-packed hotkey configuration matching OpenKey's format.

**Why:**
- Compact storage in UserDefaults
- Easy comparison with event flags
- Compatible with potential migration from OpenKey settings

**OpenKey format:**
```
Bits 0-7:   Key code
Bit 8:      Control modifier
Bit 9:      Option/Alt modifier
Bit 10:     Command modifier
Bit 11:     Shift modifier
Bit 15:     Enable beep sound
```

**Default:** Option+Z (0x7A000206) - same as OpenKey default

### Decision 8: Keyboard Layout Compatibility

**What:** Convert physical key codes to logical characters for non-QWERTY layouts.

**Why:**
- Users with Dvorak, Colemak, or international layouts expect Vietnamese input to work
- Key codes are physical positions, not logical characters
- OpenKey has `vPerformLayoutCompat` flag for this

**Code pattern:**
```swift
func convertToLayoutIndependent(_ event: CGEvent, fallback: UInt16) -> UInt16 {
    guard let nsEvent = NSEvent(cgEvent: event),
          let chars = nsEvent.charactersIgnoringModifiers,
          let char = chars.first,
          let keyCode = charToKeyCode[char]
    else { return fallback }
    return keyCode
}
```

### Decision 9: Other Language Detection via TIS

**What:** Use Text Input Services (TIS) to detect current system input source language.

**Why:**
- When user switches to Japanese, Chinese, or Korean IME, we should not interfere
- Prevents double-processing of keyboard events
- OpenKey has `vOtherLanguage` flag for this

**Code pattern:**
```swift
func isEnglishInputSource() -> Bool {
    guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
          let languages = TISGetInputSourceProperty(source, kTISPropertyInputSourceLanguages) as? [String],
          let primary = languages.first
    else { return true }
    return primary.hasPrefix("en")
}
```

### Decision 10: Temporary Disable Mechanisms

**What:** Allow temporary bypass of Vietnamese processing via modifier keys.

**Why:**
- Releasing Command: Toggle IME bypass for keyboard shortcuts
- Releasing Control: Toggle spell check disable
- Users need quick way to type without IME interference

**Implementation (Updated after review):**
- Track modifier state changes via `flagsChanged` events
- **Only process on modifier RELEASE** (when lastFlags > currentFlags)
- **Toggle** `tempOffEngine` flag when Command released (not set/clear)
- **Toggle** `tempOffSpellCheck` flag when Control released
- Track `hasJustUsedHotkey` to avoid toggle right after hotkey activation

**OpenKey pattern:**
```objc
} else if (_lastFlag > _flag) {  // Modifier released
    // Check hotkeys first
    if (checkHotKey(...)) { ... }
    // Then check temp toggles
    if (vTempOffSpelling && !_hasJustUsedHotKey && _lastFlag & kCGEventFlagMaskControl) {
        vTempOffSpellChecking();  // This is a TOGGLE function
    }
    if (vTempOffOpenKey && !_hasJustUsedHotKey && _lastFlag & kCGEventFlagMaskCommand) {
        vTempOffEngine();  // This is a TOGGLE function
    }
    _lastFlag = 0;
}
```

### Decision 11: Shared Event Source (Review Fix)

**What:** Share a single `CGEventSource` between `KeyboardEventHandler` and `TextInjector`.

**Why:**
- Own-event filtering compares source state IDs
- If Handler and Injector have different sources, events from Injector won't be filtered by Handler
- Could cause infinite loops in edge cases

**Implementation:**
```swift
// AppDelegate.swift
try handler.start()  // Creates eventSource
guard let eventSource = handler.eventSource,
      let injector = TextInjector(eventSource: eventSource)  // Share it
```

### Decision 12: Chromium Backspace Workaround (Review Fix)

**What:** For Chromium browsers, use Shift+LeftArrow to select ONE character, then continue with standard backspaces.

**Why:**
- Original implementation sent Shift+Arrow for ALL backspaces, then one delete
- OpenKey sends ONE Shift+Arrow, decrements count by 1, then continues with backspace loop
- This ensures proper text replacement in Chrome's address bar and text fields

**OpenKey pattern:**
```objc
if (vFixChromiumBrowser && [_unicodeCompoundApp containsObject:FRONT_APP]) {
    if (pData->backspaceCount > 0) {
        SendShiftAndLeftArrow();  // Select 1 char
        if (pData->backspaceCount == 1)
            pData->backspaceCount--;  // If only 1, we're done
    }
}
// Then: for loop sends remaining backspaces
```

### Decision 13: Empty Character Handling (Review Fix)

**What:** Inject empty character (NNBSP) and increase backspace count to delete it.

**Why:**
- Empty char fixes browser autocomplete dropdown issues
- Must be deleted along with the characters being replaced
- OpenKey increments `backspaceCount++` after injecting

**Implementation:**
```swift
if fixBrowserAutocomplete && currentQuirk != .sublimeText && currentQuirk != .chromiumBrowser {
    injectEmptyCharacter(proxy: proxy)
    remainingCount += 1  // Delete the empty char too
}
```

**Note:** Chromium uses Shift+Arrow method instead. Sublime Text uses ZWNJ which doesn't need extra handling.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              CGEventTap                                      │
│  (keyDown, keyUp, flagsChanged, mouseDown, mouseDragged)                    │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         KeyboardEventHandler                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐ │
│  │ Own-event    │  │ Input Source │  │ Modifier     │  │ Keyboard Layout  │ │
│  │ filter       │  │ detector     │  │ tracker      │  │ converter        │ │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────────┘ │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────────────┐   │
│  │ Hotkey       │  │ Application  │  │ CGEventSource (SHARED)           │   │
│  │ detector     │  │ detector     │  │ Used by Handler + Injector       │   │
│  └──────────────┘  └──────────────┘  └──────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          VietnameseEngine                                    │
│  (processKey → EngineResult: passThrough | suppress | replace)              │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                     TextInjector (uses shared eventSource)                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐ │
│  │ Backspace    │  │ Unicode      │  │ Empty char   │  │ Shift+Arrow      │ │
│  │ (batch/step) │  │ (batch/step) │  │ (NNBSP/ZWNJ) │  │ (Chromium 1st)   │ │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Event Processing Flow

```
1. CGEventTap callback receives event
   │
2. Check: Event tap disabled by timeout?
   │ YES → Re-enable tap, return event
   │ NO ↓
   │
3. Check: Is this our own event? (shared source state ID)
   │ YES → Return event unchanged
   │ NO ↓
   │
4. Check: Mouse event?
   │ YES → Reset typing session, return event
   │ NO ↓
   │
5. Check: FlagsChanged event? (modifier keys)
   │ YES → Go to FlagsChanged flow (below)
   │ NO ↓
   │
6. Check: KeyDown event?
   │ NO → Return event unchanged (keyUp, etc.)
   │ YES ↓
   │
7. Check: Other language input source active?
   │ YES → Return event unchanged
   │ NO ↓
   │
8. Check: Hotkey match? (language switch, etc.)
   │ YES → Set hasJustUsedHotkey, execute action, return NULL
   │ NO ↓
   │
9. Update hasJustUsedHotkey based on lastFlags
   │
10. Check: Has other control key? (Cmd, Ctrl, Option, Fn, NumPad, Help)
    │ YES → Return event unchanged
    │ NO ↓
    │
11. Check: Temporary engine disable active?
    │ YES → Return event unchanged
    │ NO ↓
    │
12. Check: Vietnamese mode?
    │ NO → Return event unchanged
    │ YES ↓
    │
13. Convert key code for layout compatibility (if enabled)
    │
14. Extract character, modifiers, caps status
    │
15. Call engine.processKey(keyCode, character, modifiers)
    │
16. Handle engine result:
    │ passThrough → Return event unchanged
    │ suppress → Return NULL
    │ replace(backspaceCount, newText) ↓
    │
17. Inject text via TextInjector:
    │ - Chromium: 1x Shift+Arrow, then (count-1) backspaces
    │ - Standard: Empty char (NNBSP), then (count+1) backspaces
    │ - Sublime: No empty char needed
    │
18. Inject replacement text (batch or step-by-step)
    │
19. Return NULL (consume original event)

FlagsChanged Flow (step 5):
   │
5a. Check: Modifier pressed? (lastFlags < currentFlags)
    │ YES → Accumulate lastFlags, return event
    │ NO ↓
    │
5b. Check: Modifier released? (lastFlags > currentFlags)
    │ NO → Return event
    │ YES ↓
    │
5c. Check: Hotkey match on release?
    │ YES → Set hasJustUsedHotkey, execute action, reset lastFlags, return NULL
    │ NO ↓
    │
5d. Check: Control released AND !hasJustUsedHotkey?
    │ YES → Toggle tempOffSpellCheck
    │
5e. Check: Command released AND !hasJustUsedHotkey?
    │ YES → Toggle tempOffEngine
    │
5f. Reset lastFlags and hasJustUsedHotkey, return event
```

## Risks / Trade-offs

### Risk 1: Event Tap Disabled by System
- **Issue:** macOS disables taps that take too long (>1 second)
- **Mitigation:** Handle `tapDisabledByTimeout` event type, re-enable tap
- **Already handled:** Current code has this check

### Risk 2: Accessibility Permission Denied
- **Issue:** App cannot function without permission
- **Mitigation:** Clear error message, guide user to System Settings
- **Implementation:** Check `AXIsProcessTrusted()` on start, show dialog if false

### Risk 3: Thread Safety
- **Issue:** Callback runs on run loop thread, engine may be accessed from main thread
- **Mitigation:**
  - Engine operations are synchronous and fast (<1ms)
  - Use `@unchecked Sendable` with documented thread safety guarantees
  - Settings access via atomic reads

### Risk 4: Application Compatibility Regression
- **Issue:** New apps may have undiscovered quirks
- **Mitigation:**
  - Default to standard behavior
  - Add new bundle IDs to quirks list as discovered
  - Settings option to disable quirk handling per-app

### Risk 5: Keyboard Layout Edge Cases
- **Issue:** Some layouts may have unexpected character mappings
- **Mitigation:**
  - Fallback to physical key code if mapping fails
  - Make layout compatibility opt-in (off by default)
  - Test with common alternative layouts (Dvorak, Colemak)

### Risk 6: Performance in Batch Mode
- **Issue:** Batch sending 16+ chars may cause issues in some apps
- **Mitigation:**
  - Provide step-by-step mode as fallback
  - Document which apps need step-by-step mode

## Configuration Options

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `switchHotkey` | UInt32 | 0x7A000206 | Language switch hotkey (bitfield) |
| `enableLayoutCompat` | Bool | false | Convert key codes for non-QWERTY layouts |
| `bypassOtherLanguage` | Bool | true | Bypass when non-English IME active |
| `sendKeyStepByStep` | Bool | false | Send chars one-by-one vs batch |
| `fixBrowserAutocomplete` | Bool | true | Send empty char to fix browser issues |
| `fixChromiumBrowser` | Bool | true | Use Shift+Arrow for Chromium |
| `enableBeepOnSwitch` | Bool | true | Beep sound when switching language |

## Migration Plan

No migration needed - this is additive implementation of existing scaffolding.

## Open Questions

1. **Should step-by-step mode be auto-detected per app?**
   - Pro: Better UX, no manual configuration
   - Con: Need to maintain app list, may miss edge cases
   - **Decision:** Start with manual toggle, consider auto-detection in future

2. **Should we support custom app quirks via settings?**
   - Pro: Users can work around unknown app issues
   - Con: Complexity, most users won't need it
   - **Decision:** Defer to future enhancement

3. **How to handle apps that use custom text frameworks?**
   - Some Electron apps or games may not respond to standard injection
   - **Decision:** Document known incompatibilities, no special handling for now
