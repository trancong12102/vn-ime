# Change: Fix Smart Switch Integration

## Why
The Smart Switch feature (per-application language memory) is defined in spec and the `SmartSwitch` class is fully implemented, but it is **not integrated** into the application. When users switch between applications, the language mode (Vietnamese/English) is not saved or restored, contrary to the spec requirements.

## What Changes
- Integrate `SmartSwitch` into `AppDelegate` lifecycle
- Connect `ApplicationDetector.applicationChanged` events to SmartSwitch logic
- Save language preference when user manually switches language (via hotkey or menu)
- Restore language preference when switching to a different application
- Respect `smartSwitchEnabled` setting toggle

## Impact
- Affected specs: `smart-switch`
- Affected code:
  - `Sources/LotusKey/App/AppDelegate.swift` - Add SmartSwitch integration
  - `Sources/LotusKey/EventHandling/KeyboardEventHandler.swift` - Expose callback for language change
  - `Sources/LotusKey/Features/SmartSwitch.swift` - Minor adjustments if needed

## Root Cause Analysis
Current state:
1. `SmartSwitch.swift` has complete implementation (storage, load/save, monitoring)
2. `ApplicationDetector` publishes `applicationChanged` events
3. `AppDelegate` subscribes to `applicationChanged` but only calls `updateAppQuirks()`
4. `SmartSwitch` is **never instantiated** anywhere in the app
5. Setting `smartSwitchEnabled` exists in UI but has no effect

OpenKey reference implementation:
1. `OnActiveAppChanged()` - Called when app changes, restores saved language
2. `OnInputMethodChanged()` - Called when user switches language, saves preference
3. Both check `vUseSmartSwitchKey` before executing

## Solution
Follow OpenKey's pattern:
1. Create `SmartSwitch` instance in `AppDelegate`
2. On app change: restore saved preference (if exists) or save current
3. On language toggle: save new preference for current app
