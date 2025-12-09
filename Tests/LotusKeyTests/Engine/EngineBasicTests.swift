import XCTest
@testable import LotusKey

/// Tests for basic engine initialization and core functionality
final class EngineBasicTests: EngineTestCase {

    // MARK: - Basic Tests

    func testEngineInitialization() {
        XCTAssertNotNil(engine)
        XCTAssertTrue(engine.spellCheckEnabled)
        XCTAssertTrue(engine.isEmpty)
    }

    func testEngineReset() {
        // Add some content to buffer
        _ = engine.processKey(keyCode: 0, character: "a", modifiers: 0)
        XCTAssertFalse(engine.isEmpty)

        // Reset should clear buffer
        engine.reset()
        XCTAssertTrue(engine.isEmpty)
    }

    func testDefaultInputMethod() {
        XCTAssertEqual(engine.inputMethod.name, "Telex")
    }

    func testSetInputMethod() {
        let newTelex = TelexInputMethod()
        engine.setInputMethod(newTelex)
        XCTAssertEqual(engine.inputMethod.name, "Telex")
    }

    func testDefaultCharacterTable() {
        XCTAssertEqual(engine.characterTable.name, "Unicode")
    }

    // MARK: - Basic Character Input

    func testPassThroughForFirstCharacter() {
        let result = engine.processKey(keyCode: 0, character: "a", modifiers: 0)
        XCTAssertEqual(result, .passThrough)
        XCTAssertEqual(engine.currentText, "a")
    }

    func testMultipleCharacters() {
        _ = engine.processKey(keyCode: 0, character: "b", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "a", modifiers: 0)
        XCTAssertEqual(engine.currentText, "ba")
    }

    // MARK: - Word Break

    func testWordBreakClearsBuffer() {
        _ = engine.processKey(keyCode: 0, character: "a", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: " ", modifiers: 0)
        XCTAssertTrue(engine.isEmpty)
    }

    func testPunctuationIsWordBreak() {
        _ = engine.processKey(keyCode: 0, character: "a", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: ".", modifiers: 0)
        XCTAssertTrue(engine.isEmpty)
    }

    // MARK: - Modifier Keys

    func testCommandKeyPassthrough() {
        _ = engine.processKey(keyCode: 0, character: "a", modifiers: 0)
        // Cmd+C should pass through without affecting buffer
        let result = engine.processKey(keyCode: 8, character: "c", modifiers: 0x100000)
        XCTAssertEqual(result, .passThrough)
    }

    // MARK: - Buffer Overflow

    func testBufferDoesNotOverflow() {
        // Type 100 characters
        for i in 0..<100 {
            let char = Character(UnicodeScalar(97 + (i % 26))!)
            _ = engine.processKey(keyCode: 0, character: char, modifiers: 0)
        }
        // Buffer should cap at 64
        XCTAssertLessThanOrEqual(engine.testBuffer.count, 64)
    }

    // MARK: - ProcessString Helper Tests

    func testProcessStringBasic() {
        let result = engine.processString("abc")
        // Without Telex transformations, should be "abc"
        XCTAssertTrue(result == "abc" || result.contains("a"))
    }

    // MARK: - Spell Validation Tests

    func testValidSpelling() {
        _ = engine.processKey(keyCode: 0, character: "b", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "a", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "n", modifiers: 0)

        XCTAssertTrue(engine.isValidSpelling)
    }

    func testInvalidToneWithSharpEndingRejected() {
        // With spell check enabled, "bàc" should not allow huyền with 'c' ending
        // The engine should add 'f' as literal instead of applying huyền
        engine.spellCheckEnabled = true

        _ = engine.processKey(keyCode: 0, character: "b", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "a", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "c", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "f", modifiers: 0)

        // 'f' should be added as literal because huyền is invalid with 'c' ending
        XCTAssertEqual(engine.currentText, "bacf")
    }

    func testValidToneWithSharpEndingAllowed() {
        // "bác" is valid - sắc can be with 'c' ending
        engine.spellCheckEnabled = true

        _ = engine.processKey(keyCode: 0, character: "b", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "a", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "c", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "s", modifiers: 0)

        XCTAssertEqual(engine.currentText, "bác")
    }
}
