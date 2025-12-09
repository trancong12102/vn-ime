import XCTest
@testable import LotusKey

/// Tests for break keycodes (ESC, arrows, Tab, Enter) and session reset
final class EngineBreakKeycodeTests: EngineTestCase {

    func testBreakKeyCodesConstants() {
        XCTAssertEqual(BreakKeyCodes.escape, 53)
        XCTAssertEqual(BreakKeyCodes.tab, 48)
        XCTAssertEqual(BreakKeyCodes.returnKey, 36)
        XCTAssertEqual(BreakKeyCodes.enter, 76)
        XCTAssertEqual(BreakKeyCodes.leftArrow, 123)
        XCTAssertEqual(BreakKeyCodes.rightArrow, 124)
        XCTAssertEqual(BreakKeyCodes.downArrow, 125)
        XCTAssertEqual(BreakKeyCodes.upArrow, 126)
    }

    func testBreakKeyCodeDetection() {
        XCTAssertTrue(BreakKeyCodes.isBreakKeyCode(53))
        XCTAssertTrue(BreakKeyCodes.isBreakKeyCode(48))
        XCTAssertTrue(BreakKeyCodes.isBreakKeyCode(36))
        XCTAssertTrue(BreakKeyCodes.isBreakKeyCode(76))
        XCTAssertTrue(BreakKeyCodes.isBreakKeyCode(123))
        XCTAssertTrue(BreakKeyCodes.isBreakKeyCode(124))
        XCTAssertTrue(BreakKeyCodes.isBreakKeyCode(125))
        XCTAssertTrue(BreakKeyCodes.isBreakKeyCode(126))
    }

    func testNonBreakKeyCodeDetection() {
        XCTAssertFalse(BreakKeyCodes.isBreakKeyCode(0))
        XCTAssertFalse(BreakKeyCodes.isBreakKeyCode(51))
        XCTAssertFalse(BreakKeyCodes.isBreakKeyCode(49))
    }

    func testEscapeResetsSessionCleanly() {
        _ = engine.processKey(keyCode: 0, character: "h", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "o", modifiers: 0)
        XCTAssertEqual(engine.currentText, "ho")
        let result = engine.processKey(keyCode: 53, character: "\u{1B}", modifiers: 0)
        XCTAssertEqual(result, .passThrough)
        XCTAssertTrue(engine.isEmpty)
    }

    func testTypingAfterEscapeWorks() {
        _ = engine.processKey(keyCode: 0, character: "h", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "o", modifiers: 0)
        _ = engine.processKey(keyCode: 53, character: "\u{1B}", modifiers: 0)
        XCTAssertTrue(engine.isEmpty)
        let result = engine.processKey(keyCode: 0, character: "a", modifiers: 0)
        XCTAssertEqual(result, .passThrough)
        XCTAssertEqual(engine.currentText, "a")
    }

    func testArrowKeysResetSession() {
        _ = engine.processKey(keyCode: 0, character: "h", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "i", modifiers: 0)
        let result = engine.processKey(keyCode: 123, character: nil, modifiers: 0)
        XCTAssertEqual(result, .passThrough)
        XCTAssertTrue(engine.isEmpty)
    }

    func testTabResetsSession() {
        _ = engine.processKey(keyCode: 0, character: "v", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "i", modifiers: 0)
        let result = engine.processKey(keyCode: 48, character: "\t", modifiers: 0)
        XCTAssertEqual(result, .passThrough)
        XCTAssertTrue(engine.isEmpty)
    }

    func testEnterResetsSession() {
        _ = engine.processKey(keyCode: 0, character: "a", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "n", modifiers: 0)
        let result = engine.processKey(keyCode: 36, character: "\r", modifiers: 0)
        XCTAssertEqual(result, .passThrough)
        XCTAssertTrue(engine.isEmpty)
    }

    func testValidWordWithEscapeNoRestore() {
        engine.spellCheckEnabled = true
        engine.restoreIfWrongSpelling = true
        _ = engine.processKey(keyCode: 0, character: "v", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "i", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "e", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "t", modifiers: 0)
        let result = engine.processKey(keyCode: 53, character: "\u{1B}", modifiers: 0)
        XCTAssertEqual(result, .passThrough)
        XCTAssertTrue(engine.isEmpty)
    }

    func testAllArrowKeysResetSession() {
        let arrowCodes: [UInt16] = [123, 124, 125, 126]
        for keyCode in arrowCodes {
            engine.reset()
            _ = engine.processKey(keyCode: 0, character: "a", modifiers: 0)
            XCTAssertFalse(engine.isEmpty)
            let result = engine.processKey(keyCode: keyCode, character: nil, modifiers: 0)
            XCTAssertEqual(result, .passThrough)
            XCTAssertTrue(engine.isEmpty)
        }
    }

    func testBreakKeycodeEmptyBuffer() {
        XCTAssertTrue(engine.isEmpty)
        let result = engine.processKey(keyCode: 53, character: "\u{1B}", modifiers: 0)
        XCTAssertEqual(result, .passThrough)
    }
}
