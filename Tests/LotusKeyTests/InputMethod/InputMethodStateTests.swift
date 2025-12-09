import XCTest
@testable import LotusKey

final class InputMethodStateTests: XCTestCase {
    // MARK: - Initialization Tests

    func testInputMethodStateInit() {
        let state = InputMethodState()
        XCTAssertNil(state.lastTransformation)
        XCTAssertNil(state.tempDisabledKey)
    }

    // MARK: - Disable Key Tests

    func testInputMethodStateDisableKey() {
        var state = InputMethodState()
        state.disableKey("a")
        XCTAssertTrue(state.isDisabled("a"))
        XCTAssertTrue(state.isDisabled("A")) // Case insensitive
        XCTAssertFalse(state.isDisabled("b"))
    }

    // MARK: - Reset Tests

    func testInputMethodStateReset() {
        var state = InputMethodState()
        state.disableKey("a")
        state.lastTransformation = LastTransformation(type: .circumflex, triggerKey: "a", originalChars: "a")

        state.reset()

        XCTAssertNil(state.lastTransformation)
        XCTAssertNil(state.tempDisabledKey)
    }

    func testInputMethodStateResetTempDisabled() {
        var state = InputMethodState()
        state.disableKey("a")
        XCTAssertTrue(state.isDisabled("a"))

        state.resetTempDisabled()
        XCTAssertFalse(state.isDisabled("a"))
    }
}
