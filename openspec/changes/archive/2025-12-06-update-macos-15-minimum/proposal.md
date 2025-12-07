# Change: Update Minimum macOS Version to 15.0 (Sequoia)

## Why

The project currently targets macOS 13.0+ (Ventura). Updating to macOS 15.0+ (Sequoia) as the minimum version allows:

1. **Modern APIs**: Access to newer SwiftUI features, improved concurrency, and Swift 6 language mode
2. **Simplified Codebase**: Remove `#available` checks and conditional code paths for older OS versions
3. **Better Observability**: Use `@Observable` macro instead of `ObservableObject` for cleaner, more performant code
4. **Xcode 16 Alignment**: Full support for Swift 6 strict concurrency checking and latest build tools
5. **Reduced Maintenance**: Focus testing and development on a single major OS version

## What Changes

### Build Configuration
- Update `Package.swift` deployment target from `.macOS(.v13)` to `.macOS(.v15)`
- Update Swift tools version from `5.9` to `6.2` (latest stable: Swift 6.2.1)
- Enable Swift 6 language mode with Approachable Concurrency
- Remove `StrictConcurrency` experimental feature flag (now default in Swift 6)

### Code Modernization
- **@Observable Migration**: Convert `AccessibilityPermissionViewModel` from `ObservableObject` to `@Observable`
- **View Updates**: Replace `@ObservedObject` with plain property and `@Bindable` where needed
- **Remove Compatibility Code**: Remove `#available(macOS 14.0, *)` checks in `AppDelegate.openSettings()`
- **project.md Update**: Update documented minimum requirements

### Dependencies
- **Xcode 26** required for development (ships with Swift 6.2)
- Swift 6.2+ compiler (latest: 6.2.1 as of Dec 2025)

## Impact

- **Affected specs**: `project-structure`
- **Affected files**:
  - `Package.swift` - Platform and Swift version updates
  - `Sources/LotusKey/UI/AccessibilityPermissionView.swift` - Observable migration
  - `Sources/LotusKey/App/AppDelegate.swift` - Remove availability checks
  - `openspec/project.md` - Documentation updates

## Risk Assessment

- **Low Risk**: macOS 15 has been stable since September 2024
- **User Impact**: Users on macOS 13-14 will need to upgrade or use older app versions
- **Migration**: No data migration needed; settings persist via UserDefaults

## Notes on CGEventTap in macOS 15

Research indicates macOS 15 has changes to Option key handling in CGEventTap for security reasons. However, this app:
- Uses CGEventTap for character input, not Option-key shortcuts
- Does not rely on Option-only hotkeys
- Uses Control+Space pattern for language switching (unaffected)

The current event handling approach remains compatible with macOS 15.
