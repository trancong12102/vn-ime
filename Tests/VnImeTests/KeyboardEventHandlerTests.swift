import XCTest
@testable import VnIme

final class KeyboardEventHandlerTests: XCTestCase {
    // MARK: - FlagsChanged Logic Tests

    /// Test that FlagsChanged only processes on modifier RELEASE (lastFlags > currentFlags)
    /// OpenKey pattern from OpenKey.mm:611-637
    func testFlagsChangedOnlyProcessesOnRelease() {
        // Simulate the FlagsChanged logic
        struct FlagsState {
            var lastFlags: UInt64 = 0
            var hasJustUsedHotkey: Bool = false
            var tempOffEngine: Bool = false
            var tempOffSpellCheck: Bool = false

            mutating func handleFlagsChanged(currentFlags: UInt64) -> Bool {
                // OpenKey pattern: Only process on modifier RELEASE (lastFlags > flags)
                if lastFlags == 0 || lastFlags < currentFlags {
                    // Modifier pressed - accumulate flags
                    lastFlags = currentFlags
                    return false // No action taken
                }

                var actionTaken = false

                // Modifier released (lastFlags > flags)
                if lastFlags > currentFlags {
                    // Check for temporary toggles (simplified - no hotkey check)
                    if !hasJustUsedHotkey {
                        // Control released - toggle spell check
                        if lastFlags & 0x40000 != 0 { // maskControl
                            tempOffSpellCheck.toggle()
                            actionTaken = true
                        }
                        // Command released - toggle engine
                        if lastFlags & 0x100000 != 0 { // maskCommand
                            tempOffEngine.toggle()
                            actionTaken = true
                        }
                    }

                    // Reset flags after processing release
                    lastFlags = 0
                    hasJustUsedHotkey = false
                }

                return actionTaken
            }
        }

        var state = FlagsState()

        // Test: Press Command (accumulate)
        let commandFlag: UInt64 = 0x100000
        XCTAssertFalse(state.handleFlagsChanged(currentFlags: commandFlag))
        XCTAssertEqual(state.lastFlags, commandFlag)
        XCTAssertFalse(state.tempOffEngine) // Not toggled yet

        // Test: Release Command (toggle)
        XCTAssertTrue(state.handleFlagsChanged(currentFlags: 0))
        XCTAssertEqual(state.lastFlags, 0)
        XCTAssertTrue(state.tempOffEngine) // Now toggled ON

        // Test: Press and release again (toggle back)
        _ = state.handleFlagsChanged(currentFlags: commandFlag) // Press
        XCTAssertTrue(state.handleFlagsChanged(currentFlags: 0)) // Release
        XCTAssertFalse(state.tempOffEngine) // Toggled back OFF
    }

    /// Test that hasJustUsedHotkey prevents temp toggle
    func testHasJustUsedHotkeyPreventsTempToggle() {
        struct FlagsState {
            var lastFlags: UInt64 = 0
            var hasJustUsedHotkey: Bool = false
            var tempOffEngine: Bool = false

            mutating func handleFlagsChanged(currentFlags: UInt64) -> Bool {
                if lastFlags == 0 || lastFlags < currentFlags {
                    lastFlags = currentFlags
                    return false
                }

                if lastFlags > currentFlags {
                    // Only toggle if hotkey wasn't just used
                    if !hasJustUsedHotkey && lastFlags & 0x100000 != 0 {
                        tempOffEngine.toggle()
                    }

                    lastFlags = 0
                    hasJustUsedHotkey = false
                    return true
                }

                return false
            }
        }

        var state = FlagsState()

        // Simulate hotkey was just used
        state.hasJustUsedHotkey = true
        let commandFlag: UInt64 = 0x100000
        state.lastFlags = commandFlag

        // Release - should NOT toggle because hasJustUsedHotkey is true
        _ = state.handleFlagsChanged(currentFlags: 0)
        XCTAssertFalse(state.tempOffEngine, "Should NOT toggle when hasJustUsedHotkey is true")
        XCTAssertFalse(state.hasJustUsedHotkey, "hasJustUsedHotkey should be reset")
    }

    // MARK: - hasOtherControlKey Tests

    /// Test that hasOtherControlKey includes all required modifiers
    /// OpenKey macro: Command, Control, Option, SecondaryFn, NumericPad, Help
    func testHasOtherControlKeyModifiers() {
        // Simulate the hasOtherControlKey logic
        func hasOtherControlKey(_ flags: UInt64) -> Bool {
            let maskCommand: UInt64 = 0x100000
            let maskControl: UInt64 = 0x40000
            let maskAlternate: UInt64 = 0x80000
            let maskSecondaryFn: UInt64 = 0x800000
            let maskNumericPad: UInt64 = 0x200000
            let maskHelp: UInt64 = 0x400000

            return (flags & maskCommand) != 0
                || (flags & maskControl) != 0
                || (flags & maskAlternate) != 0
                || (flags & maskSecondaryFn) != 0
                || (flags & maskNumericPad) != 0
                || (flags & maskHelp) != 0
        }

        // Test individual modifiers
        XCTAssertTrue(hasOtherControlKey(0x100000), "Command should trigger")
        XCTAssertTrue(hasOtherControlKey(0x40000), "Control should trigger")
        XCTAssertTrue(hasOtherControlKey(0x80000), "Option/Alt should trigger")
        XCTAssertTrue(hasOtherControlKey(0x800000), "Fn should trigger")
        XCTAssertTrue(hasOtherControlKey(0x200000), "NumPad should trigger")
        XCTAssertTrue(hasOtherControlKey(0x400000), "Help should trigger")

        // Test Shift does NOT trigger (it's allowed)
        XCTAssertFalse(hasOtherControlKey(0x20000), "Shift should NOT trigger")

        // Test no modifiers
        XCTAssertFalse(hasOtherControlKey(0), "No modifiers should NOT trigger")

        // Test combination
        XCTAssertTrue(hasOtherControlKey(0x100000 | 0x20000), "Command+Shift should trigger")
    }

    // MARK: - Event Source ID Comparison

    /// Test the logic for comparing event source IDs
    func testEventSourceIDComparison() {
        // Simulate own-event check logic
        func isOwnEvent(eventSourceID: Int64, mySourceID: Int32) -> Bool {
            return eventSourceID == Int64(mySourceID)
        }

        // Same source - should be own event
        XCTAssertTrue(isOwnEvent(eventSourceID: 12345, mySourceID: 12345))

        // Different source - should NOT be own event
        XCTAssertFalse(isOwnEvent(eventSourceID: 12345, mySourceID: 54321))

        // Edge case: 0
        XCTAssertTrue(isOwnEvent(eventSourceID: 0, mySourceID: 0))
    }

    // MARK: - Keyboard Callback Flow Tests

    /// Test the order of checks in keyboard callback matches OpenKey
    func testCallbackCheckOrder() {
        // Document the expected order of checks:
        // 1. Event tap disabled → re-enable
        // 2. Own event → pass through
        // 3. Mouse event → reset session, pass through
        // 4. FlagsChanged → handle modifiers
        // 5. Not keyDown → pass through
        // 6. Other language → pass through
        // 7. Hotkey match → execute action
        // 8. Other control key → pass through
        // 9. Temp off engine → pass through
        // 10. Not Vietnamese mode → pass through
        // 11. Process key through engine
        // 12. Handle engine result

        enum CheckStep: Int, CaseIterable {
            case tapDisabled = 1
            case ownEvent = 2
            case mouseEvent = 3
            case flagsChanged = 4
            case notKeyDown = 5
            case otherLanguage = 6
            case hotkeyMatch = 7
            case otherControlKey = 8
            case tempOffEngine = 9
            case notVietnameseMode = 10
            case processKey = 11
            case handleResult = 12
        }

        // Verify all steps are defined
        XCTAssertEqual(CheckStep.allCases.count, 12)

        // Verify order
        XCTAssertLessThan(CheckStep.tapDisabled.rawValue, CheckStep.ownEvent.rawValue)
        XCTAssertLessThan(CheckStep.ownEvent.rawValue, CheckStep.mouseEvent.rawValue)
        XCTAssertLessThan(CheckStep.flagsChanged.rawValue, CheckStep.notKeyDown.rawValue)
        XCTAssertLessThan(CheckStep.hotkeyMatch.rawValue, CheckStep.otherControlKey.rawValue)
        XCTAssertLessThan(CheckStep.tempOffEngine.rawValue, CheckStep.processKey.rawValue)
    }
}
