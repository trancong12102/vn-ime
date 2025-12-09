import XCTest
@testable import LotusKey

/// Tests for backspace handling in the Vietnamese engine
final class EngineBackspaceTests: EngineTestCase {

    // MARK: - Backspace Handling

    func testBackspaceEmptyBuffer() {
        let result = engine.processKey(keyCode: 51, character: nil, modifiers: 0)
        XCTAssertEqual(result, .passThrough)
    }

    func testBackspaceRemovesCharacter() {
        _ = engine.processKey(keyCode: 0, character: "a", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "b", modifiers: 0)
        XCTAssertEqual(engine.currentText, "ab")

        _ = engine.processKey(keyCode: 51, character: nil, modifiers: 0)
        XCTAssertEqual(engine.currentText, "a")
    }

    // MARK: - Backspace Edge Cases

    func testBackspaceAfterTransformation() {
        // Type "as" -> "á", then backspace should clear properly
        _ = engine.processKey(keyCode: 0, character: "a", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "s", modifiers: 0)
        XCTAssertEqual(engine.currentText, "á")

        let result = engine.processKey(keyCode: 51, character: nil, modifiers: 0)

        // Buffer should be empty after removing the only character
        XCTAssertTrue(engine.isEmpty)
        // Backspace ALWAYS passes through - engine only manages internal state
        XCTAssertEqual(result, .passThrough)
    }

    func testMultipleBackspaces() {
        // Type "abc", then backspace 3 times
        _ = engine.processKey(keyCode: 0, character: "a", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "b", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "c", modifiers: 0)
        XCTAssertEqual(engine.currentText, "abc")

        var result = engine.processKey(keyCode: 51, character: nil, modifiers: 0)
        XCTAssertEqual(result, .passThrough)
        XCTAssertEqual(engine.currentText, "ab")

        result = engine.processKey(keyCode: 51, character: nil, modifiers: 0)
        XCTAssertEqual(result, .passThrough)
        XCTAssertEqual(engine.currentText, "a")

        result = engine.processKey(keyCode: 51, character: nil, modifiers: 0)
        XCTAssertEqual(result, .passThrough)
        XCTAssertTrue(engine.isEmpty)
    }

    func testBackspaceOnEmptyBufferNoOutput() {
        // Backspace on empty buffer should pass through without producing any text
        let result = engine.processKey(keyCode: 51, character: nil, modifiers: 0)
        XCTAssertEqual(result, .passThrough)
        XCTAssertTrue(engine.isEmpty)
    }

    func testRepeatedBackspaceOnEmptyBuffer() {
        // Multiple backspaces on empty buffer should all pass through
        // This tests the bug fix: no duplicate characters should appear
        for _ in 0..<5 {
            let result = engine.processKey(keyCode: 51, character: nil, modifiers: 0)
            XCTAssertEqual(result, .passThrough)
            XCTAssertTrue(engine.isEmpty)
        }
    }

    func testBackspaceAfterVietnameseWord() {
        // Type "việt" then backspace should preserve remaining tone
        _ = engine.processKey(keyCode: 0, character: "v", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "i", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "e", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "e", modifiers: 0) // ê
        _ = engine.processKey(keyCode: 0, character: "j", modifiers: 0) // ệ
        _ = engine.processKey(keyCode: 0, character: "t", modifiers: 0)
        XCTAssertEqual(engine.currentText, "việt")

        let result = engine.processKey(keyCode: 51, character: nil, modifiers: 0)
        XCTAssertEqual(result, .passThrough)
        XCTAssertEqual(engine.currentText, "việ")
    }

    func testBackspaceEmptyBufferNoHistory() {
        engine.reset()  // Clears everything including history
        XCTAssertTrue(engine.isEmpty)

        // Backspace should pass through
        let result = engine.processKey(keyCode: 51, character: nil, modifiers: 0)
        XCTAssertEqual(result, .passThrough)
        XCTAssertTrue(engine.isEmpty)
    }
}
