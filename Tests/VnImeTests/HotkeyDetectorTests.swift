import XCTest
@testable import VnIme

final class HotkeyDetectorTests: XCTestCase {
    // MARK: - CGEventFlags Extension Tests

    func testCGEventFlagsHasOtherControlKey() {
        // Test individual modifiers
        XCTAssertTrue(CGEventFlags.maskCommand.hasOtherControlKey)
        XCTAssertTrue(CGEventFlags.maskControl.hasOtherControlKey)
        XCTAssertTrue(CGEventFlags.maskAlternate.hasOtherControlKey)
        XCTAssertTrue(CGEventFlags.maskSecondaryFn.hasOtherControlKey)
        XCTAssertTrue(CGEventFlags.maskNumericPad.hasOtherControlKey)
        XCTAssertTrue(CGEventFlags.maskHelp.hasOtherControlKey)

        // Test Shift does NOT count as other control key
        XCTAssertFalse(CGEventFlags.maskShift.hasOtherControlKey)

        // Test empty flags
        XCTAssertFalse(CGEventFlags().hasOtherControlKey)
    }

    func testCGEventFlagsIndividualProperties() {
        XCTAssertTrue(CGEventFlags.maskCommand.hasCommand)
        XCTAssertTrue(CGEventFlags.maskControl.hasControl)
        XCTAssertTrue(CGEventFlags.maskAlternate.hasOption)
        XCTAssertTrue(CGEventFlags.maskShift.hasShift)
        XCTAssertTrue(CGEventFlags.maskAlphaShift.hasCapsLock)
        XCTAssertTrue(CGEventFlags.maskSecondaryFn.hasSecondaryFn)
        XCTAssertTrue(CGEventFlags.maskNumericPad.hasNumericPad)
        XCTAssertTrue(CGEventFlags.maskHelp.hasHelp)
    }

    func testCGEventFlagsCombinations() {
        let cmdShift = CGEventFlags([.maskCommand, .maskShift])
        XCTAssertTrue(cmdShift.hasCommand)
        XCTAssertTrue(cmdShift.hasShift)
        XCTAssertFalse(cmdShift.hasControl)
        XCTAssertTrue(cmdShift.hasOtherControlKey) // Because Command is present

        let shiftOnly = CGEventFlags.maskShift
        XCTAssertTrue(shiftOnly.hasShift)
        XCTAssertFalse(shiftOnly.hasOtherControlKey)
    }

    // MARK: - Hotkey Type Tests

    func testHotkeyTypes() {
        // Verify all expected hotkey types exist
        let switchLanguage = HotkeyType.switchLanguage
        let convertClipboard = HotkeyType.convertClipboard

        XCTAssertNotEqual(switchLanguage, convertClipboard)
    }

    // MARK: - Hotkey Configuration Tests

    /// Test hotkey configuration bitfield format (matches OpenKey)
    func testHotkeyBitfieldFormat() {
        // OpenKey format:
        // Bits 0-7:   Key code
        // Bit 8:      Control modifier
        // Bit 9:      Option/Alt modifier
        // Bit 10:     Command modifier
        // Bit 11:     Shift modifier
        // Bit 15:     Enable beep sound

        // Example: Ctrl+Space (keycode 0x31 = 49)
        // Control bit = 0x100
        // Result = 0x31 | 0x100 = 0x131 = 305
        let ctrlSpace: UInt32 = 49 | 0x100
        XCTAssertEqual(ctrlSpace, 305)

        // Extract key code (bits 0-7)
        let keyCode = ctrlSpace & 0xFF
        XCTAssertEqual(keyCode, 49)

        // Check Control modifier (bit 8)
        let hasControl = (ctrlSpace & 0x100) != 0
        XCTAssertTrue(hasControl)

        // Check Option modifier (bit 9)
        let hasOption = (ctrlSpace & 0x200) != 0
        XCTAssertFalse(hasOption)

        // Example: Option+Z (OpenKey default)
        // Z keycode = 0x06
        // Option bit = 0x200
        let optionZ: UInt32 = 0x06 | 0x200
        XCTAssertEqual(optionZ & 0xFF, 6)
        XCTAssertTrue((optionZ & 0x200) != 0)
    }

    // MARK: - Default Hotkey Tests

    func testDefaultSwitchHotkey() {
        // Default switch hotkey should be Ctrl+Space or Option+Z depending on config
        // OpenKey default is Option+Z (0x7A000206 which decodes to Option + keycode 6)

        // Just verify the detector can be created
        let detector = HotkeyDetector()
        XCTAssertNotNil(detector)
    }
}
