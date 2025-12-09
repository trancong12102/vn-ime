import XCTest
@testable import LotusKey

/// Tests for buffer restoration after backspace removes space
final class EngineBufferRestorationTests: EngineTestCase {

    func testBufferRestorationAfterSpaceBackspace() {
        // Type "dda" → "đa"
        _ = engine.processKey(keyCode: 0, character: "d", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "d", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "a", modifiers: 0)
        XCTAssertEqual(engine.currentText, "đa")

        // Type space then backspace
        _ = engine.processKey(keyCode: 0, character: " ", modifiers: 0)
        XCTAssertTrue(engine.isEmpty)
        _ = engine.processKey(keyCode: 51, character: nil, modifiers: 0)
        XCTAssertEqual(engine.currentText, "đa")

        // Type 'f' to apply grave tone
        let result = engine.processKey(keyCode: 0, character: "f", modifiers: 0)
        XCTAssertEqual(engine.currentText, "đà")

        if case .replace(let backspaces, let replacement) = result {
            XCTAssertEqual(backspaces, 2)
            XCTAssertEqual(replacement, "đà")
        } else {
            XCTFail("Should return .replace, got \(result)")
        }
    }

    func testMultipleSpacesThenBackspace() {
        _ = engine.processKey(keyCode: 0, character: "v", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "i", modifiers: 0)
        XCTAssertEqual(engine.currentText, "vi")

        // Type 3 spaces
        _ = engine.processKey(keyCode: 0, character: " ", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: " ", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: " ", modifiers: 0)
        XCTAssertTrue(engine.isEmpty)

        // Backspace first two spaces
        _ = engine.processKey(keyCode: 51, character: nil, modifiers: 0)
        _ = engine.processKey(keyCode: 51, character: nil, modifiers: 0)
        XCTAssertTrue(engine.isEmpty)

        // Backspace third (last) space - should restore buffer
        _ = engine.processKey(keyCode: 51, character: nil, modifiers: 0)
        XCTAssertEqual(engine.currentText, "vi")
    }

    func testChangeToneAfterBufferRestore() {
        // Type "hoaf" → "hoà"
        _ = engine.processKey(keyCode: 0, character: "h", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "o", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "a", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "f", modifiers: 0)
        XCTAssertEqual(engine.currentText, "hoà")

        // Space then backspace
        _ = engine.processKey(keyCode: 0, character: " ", modifiers: 0)
        _ = engine.processKey(keyCode: 51, character: nil, modifiers: 0)
        XCTAssertEqual(engine.currentText, "hoà")

        // Type 's' to change tone from grave to acute
        let result = engine.processKey(keyCode: 0, character: "s", modifiers: 0)
        XCTAssertEqual(engine.currentText, "hoá")

        if case .replace(_, let replacement) = result {
            XCTAssertEqual(replacement, "hoá")
        } else {
            XCTFail("Should return .replace")
        }
    }

    func testWordRestorationWithCircumflex() {
        _ = engine.processKey(keyCode: 0, character: "c", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "o", modifiers: 0)
        XCTAssertEqual(engine.currentText, "co")

        // Space + backspace
        _ = engine.processKey(keyCode: 0, character: " ", modifiers: 0)
        _ = engine.processKey(keyCode: 51, character: nil, modifiers: 0)
        XCTAssertEqual(engine.currentText, "co")

        // Type 'o' again to apply circumflex
        let result = engine.processKey(keyCode: 0, character: "o", modifiers: 0)
        XCTAssertEqual(engine.currentText, "cô")

        if case .replace(_, let replacement) = result {
            XCTAssertEqual(replacement, "cô")
        } else {
            XCTFail("Should return .replace for circumflex")
        }
    }

    func testWordRestorationWithHorn() {
        _ = engine.processKey(keyCode: 0, character: "t", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "u", modifiers: 0)
        XCTAssertEqual(engine.currentText, "tu")

        // Space + backspace
        _ = engine.processKey(keyCode: 0, character: " ", modifiers: 0)
        _ = engine.processKey(keyCode: 51, character: nil, modifiers: 0)
        XCTAssertEqual(engine.currentText, "tu")

        // Type 'w' to apply horn
        let result = engine.processKey(keyCode: 0, character: "w", modifiers: 0)
        XCTAssertEqual(engine.currentText, "tư")

        if case .replace(_, let replacement) = result {
            XCTAssertEqual(replacement, "tư")
        } else {
            XCTFail("Should return .replace for horn")
        }
    }
}
