# Design: Add Advanced Settings UI

## Architecture Decision

### Settings Wiring Path

```
┌─────────────────────────────────────────────────────────────────┐
│                         AppDelegate                              │
│  ┌──────────────┐    ┌─────────────────┐    ┌──────────────┐   │
│  │SettingsStore │───▶│handleSettings   │───▶│ textInjector │   │
│  │              │    │Change(_:)       │    │              │   │
│  └──────────────┘    └─────────────────┘    └──────────────┘   │
│         │                                          │            │
│         │ Combine                                  │            │
│         ▼                                          ▼            │
│  ┌──────────────┐                         ┌──────────────────┐ │
│  │SettingsView  │                         │KeyboardEventHandler│
│  │(@AppStorage) │                         │(uses textInjector) │
│  └──────────────┘                         └──────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### Why AppDelegate Holds TextInjector Reference

**Current Implementation** (AppDelegate.swift:18, 171):
```swift
private var textInjector: TextInjector?
// ...
self.textInjector = injector
```

**Rationale**:
1. **Shared Event Source**: TextInjector needs the same CGEventSource as KeyboardEventHandler to filter own events
2. **Direct Access**: AppDelegate can directly configure TextInjector without exposing it through KeyboardEventHandler
3. **Follows Existing Pattern**: Similar to how `engine` is configured directly

### Alternatives Considered

| Approach | Pros | Cons | Decision |
|----------|------|------|----------|
| **A: Direct via AppDelegate** | Simple, follows existing pattern | Couples AppDelegate to TextInjector details | ✅ Selected |
| B: Expose via KeyboardEventHandler | Better encapsulation | Requires protocol changes, more complex | Rejected |
| C: TextInjector observes settings | Most decoupled | TextInjector would need SettingsStore dependency | Rejected |

### Settings Keys

| Setting | UserDefaults Key | Default | Type |
|---------|-----------------|---------|------|
| Fix browser autocomplete | `VnImeFixBrowserAutocomplete` | `true` | Bool |
| Fix Chromium browsers | `VnImeFixChromiumBrowser` | `true` | Bool |
| Send keys one by one | `VnImeSendKeyStepByStep` | `false` | Bool |

### UI Layout

```
┌─────────────────────────────────────────┐
│ General Settings                        │
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │
│ │ Startup                             │ │
│ │ ☑ Launch at login                   │ │
│ │ ☐ Show Dock icon                    │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ Spelling                            │ │
│ │ ☑ Enable spell checking             │ │
│ │   ☑ Restore keys if invalid word    │ │
│ │     (Hold Ctrl to temporarily...)   │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ Features                            │ │
│ │ ☑ Smart language switch per app     │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ Advanced                      [NEW] │ │
│ │ ☑ Fix browser autocomplete          │ │
│ │   (Prevents suggestions from...)    │ │
│ │ ☑ Fix Chromium browsers             │ │
│ │   (For Chrome, Edge, Brave...)      │ │
│ │ ☐ Send keys one by one              │ │
│ │   (Slower but more compatible)      │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

## Data Flow

### On App Launch
```
1. AppDelegate.initializeEventHandler()
2. Create TextInjector
3. Apply settings from SettingsStore:
   - injector.fixBrowserAutocomplete = settings.fixBrowserAutocomplete
   - injector.fixChromiumBrowser = settings.fixChromiumBrowser
   - injector.sendKeyStepByStep = settings.sendKeyStepByStep
4. Configure KeyboardEventHandler with injector
```

### On Settings Change
```
1. User toggles setting in SettingsView
2. @AppStorage writes to UserDefaults
3. SettingsStore.settingsChanged publisher fires
4. AppDelegate.handleSettingsChange(_:) receives event
5. AppDelegate updates textInjector property
6. Next keyboard event uses new setting
```

## Test Strategy

### Unit Tests (StorageTests.swift)
- Default values are correct
- Values persist to UserDefaults
- `settingsChanged` publisher fires on change
- `resetToDefaults()` resets to expected values

### Manual Testing
- Toggle each setting, verify behavior changes
- Restart app, verify settings persist
- Test in Chromium browser with fix enabled/disabled
- Test browser autocomplete behavior
