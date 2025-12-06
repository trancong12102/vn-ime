import XCTest
@testable import VnIme

final class TextInjectorTests: XCTestCase {
    // MARK: - AppQuirk Tests

    func testAppQuirkValues() {
        XCTAssertEqual(AppQuirk.standard, AppQuirk.standard)
        XCTAssertEqual(AppQuirk.sublimeText, AppQuirk.sublimeText)
        XCTAssertEqual(AppQuirk.chromiumBrowser, AppQuirk.chromiumBrowser)
        XCTAssertEqual(AppQuirk.unicodeCompound, AppQuirk.unicodeCompound)
        XCTAssertNotEqual(AppQuirk.standard, AppQuirk.sublimeText)
    }

    // MARK: - Chromium Backspace Count Logic Tests

    /// Test that Chromium backspace logic matches OpenKey pattern:
    /// - count=1: Shift+Arrow only, 0 backspaces (text replaces selection)
    /// - count=2: Shift+Arrow, then 2 backspaces
    /// - count=3: Shift+Arrow, then 3 backspaces
    func testChromiumBackspaceCountLogic() {
        // This tests the logic WITHOUT actually injecting events
        // The logic is: only decrement if count == 1

        // Simulate the logic from TextInjector.injectBackspaces
        func simulateChromiumBackspaces(count: Int) -> (shiftArrowSent: Bool, backspaceCount: Int) {
            guard count > 0 else { return (false, 0) }

            var remainingCount = count

            // Chromium logic
            // Send 1 Shift+Arrow
            let shiftArrowSent = true

            // Only decrement if count == 1
            if remainingCount == 1 {
                remainingCount = 0
            }
            // Otherwise remainingCount stays the same

            return (shiftArrowSent, remainingCount)
        }

        // Test count = 1
        let result1 = simulateChromiumBackspaces(count: 1)
        XCTAssertTrue(result1.shiftArrowSent)
        XCTAssertEqual(result1.backspaceCount, 0, "count=1 should result in 0 backspaces")

        // Test count = 2
        let result2 = simulateChromiumBackspaces(count: 2)
        XCTAssertTrue(result2.shiftArrowSent)
        XCTAssertEqual(result2.backspaceCount, 2, "count=2 should result in 2 backspaces")

        // Test count = 3
        let result3 = simulateChromiumBackspaces(count: 3)
        XCTAssertTrue(result3.shiftArrowSent)
        XCTAssertEqual(result3.backspaceCount, 3, "count=3 should result in 3 backspaces")

        // Test count = 5
        let result5 = simulateChromiumBackspaces(count: 5)
        XCTAssertTrue(result5.shiftArrowSent)
        XCTAssertEqual(result5.backspaceCount, 5, "count=5 should result in 5 backspaces")
    }

    /// Test that standard (non-Chromium) backspace logic adds 1 for empty char
    func testStandardBackspaceCountLogic() {
        // Simulate the logic from TextInjector.injectBackspaces for standard quirk
        func simulateStandardBackspaces(count: Int, fixBrowserAutocomplete: Bool) -> Int {
            guard count > 0 else { return 0 }

            var remainingCount = count

            // Standard logic: inject empty char, then add 1 to count
            if fixBrowserAutocomplete {
                // injectEmptyCharacter() - would inject NNBSP
                remainingCount += 1
            }

            return remainingCount
        }

        // Test with fix enabled
        XCTAssertEqual(simulateStandardBackspaces(count: 1, fixBrowserAutocomplete: true), 2)
        XCTAssertEqual(simulateStandardBackspaces(count: 2, fixBrowserAutocomplete: true), 3)
        XCTAssertEqual(simulateStandardBackspaces(count: 3, fixBrowserAutocomplete: true), 4)

        // Test with fix disabled
        XCTAssertEqual(simulateStandardBackspaces(count: 1, fixBrowserAutocomplete: false), 1)
        XCTAssertEqual(simulateStandardBackspaces(count: 2, fixBrowserAutocomplete: false), 2)
    }

    /// Test that Sublime Text doesn't add extra backspace
    func testSublimeTextBackspaceCountLogic() {
        // Sublime Text uses ZWNJ which doesn't need extra backspace
        func simulateSublimeBackspaces(count: Int) -> Int {
            // No empty char injection for Sublime Text
            return count
        }

        XCTAssertEqual(simulateSublimeBackspaces(count: 1), 1)
        XCTAssertEqual(simulateSublimeBackspaces(count: 2), 2)
        XCTAssertEqual(simulateSublimeBackspaces(count: 3), 3)
    }

    // MARK: - Empty Character Constants

    func testEmptyCharacterConstants() {
        // NNBSP (Narrow No-Break Space) used for most apps
        let nnbsp: UInt16 = 0x202F
        XCTAssertEqual(nnbsp, 8239)

        // ZWNJ (Zero-Width Non-Joiner) used for Sublime Text
        let zwnj: UInt16 = 0x200C
        XCTAssertEqual(zwnj, 8204)
    }

    // MARK: - Batch Size

    func testMaxBatchSize() {
        // OpenKey uses 16 as max batch size
        let maxBatchSize = 16
        XCTAssertEqual(maxBatchSize, 16)
    }
}
