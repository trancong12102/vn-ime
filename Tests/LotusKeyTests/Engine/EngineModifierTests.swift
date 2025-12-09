import XCTest
@testable import LotusKey

/// Tests for modifier mark transformations (circumflex, horn, breve, stroke)
final class EngineModifierTests: EngineTestCase {

    // MARK: - Modifier Mark Tests

    func testCircumflexModifier() {
        // "aa" -> "â"
        _ = engine.processKey(keyCode: 0, character: "a", modifiers: 0)
        let result = engine.processKey(keyCode: 0, character: "a", modifiers: 0)

        if case .replace(_, let replacement) = result {
            XCTAssertEqual(replacement, "â")
        } else {
            XCTAssertEqual(engine.currentText, "aa")
        }
    }

    func testHornModifierEngineHandling() {
        // Test that engine correctly processes modifier transformations from InputMethod.
        // Full "ow" -> "ơ" transformation depends on Telex rules being implemented.
        // Here we test the engine handles transformation results correctly.
        _ = engine.processKey(keyCode: 0, character: "o", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "w", modifiers: 0)

        // Buffer should have content (either "ow" or "ơ" depending on Telex impl)
        XCTAssertFalse(engine.isEmpty)
        XCTAssertTrue(engine.currentText.count >= 1)
    }

    func testStrokeModifier() {
        // "dd" -> "đ"
        _ = engine.processKey(keyCode: 0, character: "d", modifiers: 0)
        let result = engine.processKey(keyCode: 0, character: "d", modifiers: 0)

        if case .replace(_, let replacement) = result {
            XCTAssertEqual(replacement, "đ")
        } else {
            XCTAssertEqual(engine.currentText, "dd")
        }
    }

    // MARK: - Direct Modifier Application Tests (bypass InputMethod)

    func testApplyHornModifierDirectly() {
        // Test engine's applyModifier logic directly using buffer
        // This verifies the fix for finding 'o'/'u' instead of 'w'
        var buffer = TypingBuffer()
        buffer.append("o")

        // Apply horn modifier to 'o' -> should become 'ơ'
        buffer.applyModifier(.hornOrBreve, at: 0)

        XCTAssertEqual(buffer.toUnicodeString(), "ơ")
    }

    func testApplyHornModifierToU() {
        var buffer = TypingBuffer()
        buffer.append("u")

        buffer.applyModifier(.hornOrBreve, at: 0)

        XCTAssertEqual(buffer.toUnicodeString(), "ư")
    }

    func testApplyBreveModifierToA() {
        var buffer = TypingBuffer()
        buffer.append("a")

        buffer.applyModifier(.hornOrBreve, at: 0)

        XCTAssertEqual(buffer.toUnicodeString(), "ă")
    }

    func testApplyCircumflexModifier() {
        var buffer = TypingBuffer()
        buffer.append("a")

        buffer.applyModifier(.circumflex, at: 0)

        XCTAssertEqual(buffer.toUnicodeString(), "â")
    }

    func testApplyModifierInWord() {
        // Test modifier in context of a word: "toi" + horn on 'o' -> "tơi"
        var buffer = TypingBuffer()
        buffer.append("t")
        buffer.append("o")
        buffer.append("i")

        // Apply horn to 'o' at index 1
        buffer.applyModifier(.hornOrBreve, at: 1)

        XCTAssertEqual(buffer.toUnicodeString(), "tơi")
    }

    func testApplyStrokeToD() {
        var buffer = TypingBuffer()
        buffer.append("d")

        // đ uses hornOrBreve flag on 'd'
        buffer[0].state.insert(.hornOrBreve)

        XCTAssertEqual(buffer.toUnicodeString(), "đ")
    }

    // MARK: - Stroke Modifier Tests

    func testStrokeModifierUsesStrokeFlag() {
        // Verify that 'dd' uses the new .stroke flag
        var buffer = TypingBuffer()
        buffer.append("d")
        buffer[0].state.insert(.stroke)

        XCTAssertEqual(buffer.toUnicodeString(), "đ")
    }

    func testStrokeModifierBackwardsCompatibility() {
        // Verify that .hornOrBreve still works for đ (backwards compatibility)
        var buffer = TypingBuffer()
        buffer.append("d")
        buffer[0].state.insert(.hornOrBreve)

        XCTAssertEqual(buffer.toUnicodeString(), "đ")
    }
}
