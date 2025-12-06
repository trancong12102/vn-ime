# Design: Launch at Login and Dock Icon Toggle

## Context

VnIme is a Vietnamese input method editor that runs as a menu bar application. Two features have placeholder implementations:
1. Launch at Login - currently saves preference but doesn't register with system
2. Dock Icon Toggle - currently saves preference but doesn't change app behavior

macOS 13+ introduced `SMAppService` as the modern API for login items, replacing deprecated `SMLoginItemSetEnabled`.

## Goals / Non-Goals

**Goals:**
- Implement working launch at login using modern macOS API
- Implement dock icon visibility toggle
- Maintain thread safety (SMAppService requires main thread)
- Handle errors gracefully with user feedback
- Keep implementation simple and maintainable

**Non-Goals:**
- Support macOS < 13 (project minimum is macOS 13.0)
- Helper tool / privileged helper patterns
- Launch agent/daemon patterns (overkill for simple login item)

## Decisions

### Decision 1: Use `SMAppService.mainAppService`

**Rationale:**
- Simplest API for login item registration
- No Info.plist modifications required
- Automatically integrates with System Settings > Login Items
- Handles user consent flow
- Available on macOS 13+ (our minimum target)

**Alternatives considered:**
- `SMAppService.agent()` - Requires embedded launch agent plist, more complex
- Legacy `SMLoginItemSetEnabled` - Deprecated, removed in macOS 13
- `LSSharedFileList` - Deprecated

### Decision 2: Use `NSApp.setActivationPolicy()` for dock icon

**Rationale:**
- Standard macOS API for changing app presentation
- `.regular` = shows in Dock and app switcher
- `.accessory` = menu bar only, no Dock icon
- Immediate effect without restart

**Policies:**
```swift
NSApplication.ActivationPolicy.regular    // Show in Dock
NSApplication.ActivationPolicy.accessory  // Menu bar only (default for IME)
```

### Decision 3: Create dedicated `AppLifecycleManager`

**Rationale:**
- Separates lifecycle concerns from settings storage
- Easier to test (can mock the manager)
- Single responsibility principle
- Encapsulates platform-specific APIs

**Structure:**
```swift
@MainActor
final class AppLifecycleManager {
    static let shared = AppLifecycleManager()

    // Launch at Login
    func setLaunchAtLogin(_ enabled: Bool) throws
    var launchAtLoginStatus: SMAppService.Status

    // Dock Icon
    func setDockIconVisible(_ visible: Bool)
    var isDockIconVisible: Bool
}
```

### Decision 4: Sync setting with system state on init

**Rationale:**
- User might change login items in System Settings directly
- On app launch, read actual system state and update UserDefaults
- Prevents UI showing incorrect state

```swift
// In AppDelegate.applicationDidFinishLaunching
let actualStatus = AppLifecycleManager.shared.launchAtLoginStatus
settings.launchAtLogin = (actualStatus == .enabled)
```

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| `SMAppService` calls must be on main thread | Use `@MainActor` annotation |
| Registration may require user approval | Check `.requiresApproval` status, guide user to System Settings |
| Dock icon change may not take effect immediately in some cases | Call `NSApp.activate()` after policy change |
| Testing login item requires real app context | Use integration tests / manual testing |

## Error Handling

```swift
enum AppLifecycleError: LocalizedError {
    case registrationFailed(underlying: Error)
    case unregistrationFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .registrationFailed(let error):
            return "Failed to enable launch at login: \(error.localizedDescription)"
        case .unregistrationFailed(let error):
            return "Failed to disable launch at login: \(error.localizedDescription)"
        }
    }
}
```

## API Reference

### SMAppService (macOS 13+)

```swift
import ServiceManagement

// Register
try SMAppService.mainAppService.register()

// Unregister
try SMAppService.mainAppService.unregister()

// Check status
let status = SMAppService.mainAppService.status
// .notRegistered, .enabled, .requiresApproval
```

### NSApplication.ActivationPolicy

```swift
// Hide from Dock (menu bar only)
NSApp.setActivationPolicy(.accessory)

// Show in Dock
NSApp.setActivationPolicy(.regular)

// Check current policy
let policy = NSApp.activationPolicy()
```

## Open Questions

None - implementation approach is straightforward.
