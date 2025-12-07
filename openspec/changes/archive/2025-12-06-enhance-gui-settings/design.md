# Design: Cải thiện GUI Settings

## Context

LotusKey engine đã implement tính năng `restoreIfWrongSpelling` nhưng chưa expose trong UI. Change này đơn giản là thêm UI toggle và wire vào engine.

## Goals / Non-Goals

### Goals
- Expose `restoreIfWrongSpelling` setting trong GUI
- Document tính năng Ctrl bypass đã hoạt động
- Cải thiện tổ chức UI với spelling options grouped

### Non-Goals
- Implement tính năng mới trong engine
- Thay đổi behavior hiện có

## Decisions

### 1. Settings Key mới

```swift
public enum SettingsKey: String {
    // ... existing keys ...
    case restoreIfWrongSpelling = "LotusKeyRestoreIfWrongSpelling"
}
```

Default value: `true` (matching engine default)

### 2. UI Layout Changes

Current:
```
┌─ General ─────────────────────────────┐
│ ┌─ Startup ────────────────────────┐ │
│ │ ☑ Launch at login               │ │
│ │ ☐ Show Dock icon                │ │
│ └──────────────────────────────────┘ │
│ ┌─ Features ───────────────────────┐ │
│ │ ☑ Enable spell checking         │ │  ← Spell check mixed with smart switch
│ │ ☑ Smart language switch per app │ │
│ └──────────────────────────────────┘ │
└───────────────────────────────────────┘
```

Proposed:
```
┌─ General ─────────────────────────────┐
│ ┌─ Startup ────────────────────────┐ │
│ │ ☑ Launch at login               │ │
│ │ ☐ Show Dock icon                │ │
│ └──────────────────────────────────┘ │
│ ┌─ Spelling ───────────────────────┐ │
│ │ ☑ Enable spell checking         │ │
│ │   ☑ Restore keys if invalid     │ │  ← Sub-option, disabled when master off
│ │   (Hold Ctrl to bypass)         │ │  ← Help text
│ └──────────────────────────────────┘ │
│ ┌─ Features ───────────────────────┐ │
│ │ ☑ Smart language switch per app │ │
│ └──────────────────────────────────┘ │
└───────────────────────────────────────┘
```

### 3. Settings Wiring

In `AppDelegate.handleSettingsChange()`:
```swift
case .restoreIfWrongSpelling:
    engine.restoreIfWrongSpelling = settings.restoreIfWrongSpelling
```

## Risks / Trade-offs

- **Risk**: None - this is exposing existing functionality
- **Trade-off**: Minimal UI complexity increase

## Migration Plan

No migration needed - new setting defaults to `true` matching existing engine behavior.
