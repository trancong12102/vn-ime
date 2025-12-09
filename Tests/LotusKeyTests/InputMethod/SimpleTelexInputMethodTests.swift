import XCTest
@testable import LotusKey

final class SimpleTelexInputMethodTests: XCTestCase {
    // MARK: - Tone Mark Tests

    func testSimpleTelexToneMarks() {
        let simpleTelex = SimpleTelexInputMethod()

        // Same as Telex
        XCTAssertNotNil(simpleTelex.processCharacter("s", context: "a"))
        XCTAssertNotNil(simpleTelex.processCharacter("f", context: "a"))
    }

    // MARK: - Circumflex Tests

    func testSimpleTelexCircumflex() {
        let simpleTelex = SimpleTelexInputMethod()

        // aa → â (same as Telex)
        let result = simpleTelex.processCharacter("a", context: "a")
        XCTAssertNotNil(result)
        if case .modifier(.circumflex) = result?.type {
            // Expected
        } else {
            XCTFail("Expected circumflex for 'aa' in Simple Telex")
        }
    }

    // MARK: - Horn Modifier Tests

    func testSimpleTelexOWHorn() {
        let simpleTelex = SimpleTelexInputMethod()

        // ow → ơ (horn WORKS in Simple Telex - pattern matching runs regardless)
        let result = simpleTelex.processCharacter("w", context: "o")
        XCTAssertNotNil(result)
        if case .modifier(.horn) = result?.type {
            // Expected
        } else {
            XCTFail("Expected horn modifier for 'ow' in Simple Telex")
        }
    }

    func testSimpleTelexUWHorn() {
        let simpleTelex = SimpleTelexInputMethod()

        // uw → ư (horn WORKS in Simple Telex - pattern matching runs regardless)
        let result = simpleTelex.processCharacter("w", context: "u")
        XCTAssertNotNil(result)
        if case .modifier(.horn) = result?.type {
            // Expected
        } else {
            XCTFail("Expected horn modifier for 'uw' in Simple Telex")
        }
    }

    // MARK: - Breve Modifier Tests

    func testSimpleTelexAWBreve() {
        let simpleTelex = SimpleTelexInputMethod()

        // aw → ă (breve WORKS in Simple Telex)
        let result = simpleTelex.processCharacter("w", context: "a")
        XCTAssertNotNil(result)
        if case .modifier(.breve) = result?.type {
            // Expected
        } else {
            XCTFail("Expected breve for 'aw' in Simple Telex")
        }
    }

    // MARK: - Standalone W Tests

    func testSimpleTelexStandaloneWNoConversion() {
        let simpleTelex = SimpleTelexInputMethod()

        // w at start → w (NO → ư in Simple Telex)
        let result = simpleTelex.processCharacter("w", context: "")
        XCTAssertNil(result, "Standalone w should be nil (pass through) in Simple Telex")
    }

    // MARK: - Bracket Tests

    func testSimpleTelexBracketPassthrough() {
        let simpleTelex = SimpleTelexInputMethod()

        // [ → [ (literal, pass through in Simple Telex)
        // Reference: OpenKey Engine.cpp:1541 - bracket keys cause word break
        let openResult = simpleTelex.processCharacter("[", context: "")
        XCTAssertNil(openResult, "[ should pass through (nil) in Simple Telex")

        // ] → ] (literal, pass through)
        let closeResult = simpleTelex.processCharacter("]", context: "")
        XCTAssertNil(closeResult, "] should pass through (nil) in Simple Telex")

        // a[ → a[ (literal, pass through)
        let afterVowelResult = simpleTelex.processCharacter("[", context: "a")
        XCTAssertNil(afterVowelResult, "[ after vowel should pass through in Simple Telex")
    }

    func testSimpleTelexBracketNotSpecialKey() {
        let simpleTelex = SimpleTelexInputMethod()

        // Brackets are NOT special keys in Simple Telex
        XCTAssertFalse(simpleTelex.isSpecialKey("["), "[ should NOT be special in Simple Telex")
        XCTAssertFalse(simpleTelex.isSpecialKey("]"), "] should NOT be special in Simple Telex")

        // But other special keys remain special
        XCTAssertTrue(simpleTelex.isSpecialKey("s"), "s should still be special in Simple Telex")
        XCTAssertTrue(simpleTelex.isSpecialKey("w"), "w should still be special in Simple Telex")
    }

    // MARK: - UO Pattern Tests

    func testSimpleTelexUOPatternTransformation() {
        let simpleTelex = SimpleTelexInputMethod()

        // uow → ươ (horn transformation for "uo" pattern)
        // Reference: OpenKey Engine.cpp:899-910 - insertW handles "uo" specially
        let uowResult = simpleTelex.processCharacter("w", context: "uo")
        XCTAssertNotNil(uowResult)
        if case .modifier(.horn) = uowResult?.type {
            // Expected
        } else {
            XCTFail("Expected horn modifier for 'uow' in Simple Telex")
        }

        // thuow → horn transformation (for thương)
        let thuowResult = simpleTelex.processCharacter("w", context: "thuo")
        XCTAssertNotNil(thuowResult)
        if case .modifier(.horn) = thuowResult?.type {
            // Expected
        } else {
            XCTFail("Expected horn modifier for 'thuow' in Simple Telex")
        }

        // duow → horn transformation (for dương)
        let duowResult = simpleTelex.processCharacter("w", context: "duo")
        XCTAssertNotNil(duowResult)
        if case .modifier(.horn) = duowResult?.type {
            // Expected
        } else {
            XCTFail("Expected horn modifier for 'duow' in Simple Telex")
        }

        // quow → horn transformation (for qương variant)
        let quowResult = simpleTelex.processCharacter("w", context: "quo")
        XCTAssertNotNil(quowResult)
        if case .modifier(.horn) = quowResult?.type {
            // Expected
        } else {
            XCTFail("Expected horn modifier for 'quow' in Simple Telex")
        }
    }

    // MARK: - Disabled Key Tests

    func testSimpleTelexDisabledKeyReturnsNil() {
        let simpleTelex = SimpleTelexInputMethod()
        var state = InputMethodState()

        // Disable the 'w' key
        state.disableKey("w")

        // Try to use 'w' key - should return nil
        let result = simpleTelex.processCharacter("w", context: "a", state: &state)
        XCTAssertNil(result, "Disabled key should return nil in Simple Telex")
    }

    // MARK: - Undo Tests

    func testSimpleTelexUndoWithNonMatchingKey() {
        // Test undo detection when key doesn't match trigger
        let simpleTelex = SimpleTelexInputMethod()
        var state = InputMethodState()

        // First apply breve transformation
        let breveResult = simpleTelex.processCharacter("w", context: "a", state: &state)
        XCTAssertNotNil(breveResult, "aw should produce breve")

        // Now simulate that the transformation was applied, set lastTransformation
        state.lastTransformation = LastTransformation(type: .breve, triggerKey: "w", originalChars: "a")

        // Try pressing a different key (not 'w') - should not undo
        let differentKeyResult = simpleTelex.processCharacter("s", context: "ă", state: &state)
        // This should NOT be an undo, just normal processing
        XCTAssertNotNil(differentKeyResult, "'s' after 'ă' should be normal tone processing")
    }

    func testSimpleTelexUndoWithNonBreveType() {
        // Test undo detection when type is not breve (Simple Telex only undoes breve)
        // Note: Simple Telex delegates to Telex for non-W keys, and Telex has its own undo logic
        let simpleTelex = SimpleTelexInputMethod()
        var state = InputMethodState()

        // Set lastTransformation to circumflex (not breve)
        // But use a non-matching key to test the checkForUndo mismatch path
        state.lastTransformation = LastTransformation(type: .circumflex, triggerKey: "a", originalChars: "a")

        // Simple Telex's checkForUndo only handles breve
        // When we press 'w' (not 'a'), the guard char == triggerLower fails
        // This covers line 70 (return nil when char doesn't match trigger)
        let result = simpleTelex.processCharacter("w", context: "â", state: &state)
        // w after â doesn't match any pattern, should return nil
        XCTAssertNil(result, "w after â should return nil in Simple Telex")
    }

    // MARK: - Input Method Name Tests

    func testInputMethodName() {
        XCTAssertEqual(SimpleTelexInputMethod().name, "Simple Telex")
    }
}
