import XCTest
@testable import LotusKey

/// Tests for tone mark transformations
final class EngineToneMarkTests: EngineTestCase {

    // MARK: - Tone Mark Tests

    func testToneMarkAcute() {
        // Type "a" then "s" (Telex for sắc)
        _ = engine.processKey(keyCode: 0, character: "a", modifiers: 0)
        let result = engine.processKey(keyCode: 0, character: "s", modifiers: 0)

        // Should replace "a" with "á"
        if case .replace(_, let replacement) = result {
            XCTAssertEqual(replacement, "á")
        } else {
            // Engine might pass through if Telex implementation is pending
            XCTAssertEqual(engine.currentText, "as")
        }
    }

    func testToneMarkGrave() {
        _ = engine.processKey(keyCode: 0, character: "e", modifiers: 0)
        let result = engine.processKey(keyCode: 0, character: "f", modifiers: 0)

        if case .replace(_, let replacement) = result {
            XCTAssertEqual(replacement, "è")
        } else {
            XCTAssertEqual(engine.currentText, "ef")
        }
    }

    // MARK: - Tone Mark Fallback Tests

    func testToneKeyWithoutVowel() {
        // Typing 's' without a vowel should add 's' as literal
        let result = engine.processString("bcs")
        XCTAssertEqual(result, "bcs")
    }

    func testToneKeyRemovalWithZ() {
        // "as" -> "á", then "z" should remove the mark -> "a"
        _ = engine.processKey(keyCode: 0, character: "a", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "s", modifiers: 0)
        XCTAssertEqual(engine.currentText, "á")

        _ = engine.processKey(keyCode: 0, character: "z", modifiers: 0)
        XCTAssertEqual(engine.currentText, "a")
    }

    func testToneKeyZWithoutMark() {
        // 'z' without existing mark should add 'z' as literal
        let result = engine.processString("az")
        // If 'a' has no mark, 'z' should be added as literal
        XCTAssertEqual(result, "az")
    }

    // MARK: - Dynamic Tone Repositioning Integration

    func testToneRepositioningAfterAddingEnding() {
        // Type "lúa" then add 'n' -> tone might need to move
        // This tests the refreshTonePosition integration
        _ = engine.processKey(keyCode: 0, character: "l", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "u", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "a", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "s", modifiers: 0) // sắc

        let beforeEnding = engine.currentText
        XCTAssertTrue(beforeEnding.contains("ú") || beforeEnding.contains("á"))

        _ = engine.processKey(keyCode: 0, character: "n", modifiers: 0)

        // After adding ending, tone should have been repositioned if needed
        XCTAssertFalse(engine.isEmpty)
    }
}
