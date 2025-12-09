import XCTest
@testable import LotusKey

final class TelexInputMethodTests: XCTestCase {
    // MARK: - Tone Mark Tests

    func testTelexToneMarks() {
        let telex = TelexInputMethod()

        // Test tone mark keys
        XCTAssertNotNil(telex.processCharacter("s", context: "a"))  // sắc
        XCTAssertNotNil(telex.processCharacter("f", context: "a"))  // huyền
        XCTAssertNotNil(telex.processCharacter("r", context: "a"))  // hỏi
        XCTAssertNotNil(telex.processCharacter("x", context: "a"))  // ngã
        XCTAssertNotNil(telex.processCharacter("j", context: "a"))  // nặng
        XCTAssertNotNil(telex.processCharacter("z", context: "a"))  // remove tone
    }

    // MARK: - Modifier Mark Tests

    func testTelexModifierMarks() {
        let telex = TelexInputMethod()

        // Test circumflex (aa -> â)
        let aaResult = telex.processCharacter("a", context: "a")
        XCTAssertNotNil(aaResult)
        if case .modifier(.circumflex) = aaResult?.type {
            // Expected
        } else {
            XCTFail("Expected circumflex modifier for 'aa'")
        }

        // Test ee -> ê
        let eeResult = telex.processCharacter("e", context: "e")
        XCTAssertNotNil(eeResult)

        // Test oo -> ô
        let ooResult = telex.processCharacter("o", context: "o")
        XCTAssertNotNil(ooResult)

        // Test dd -> đ
        let ddResult = telex.processCharacter("d", context: "d")
        XCTAssertNotNil(ddResult)
        if case .modifier(.stroke) = ddResult?.type {
            // Expected
        } else {
            XCTFail("Expected stroke modifier for 'dd'")
        }
    }

    // MARK: - W Key Tests

    func testTelexWKey() {
        let telex = TelexInputMethod()

        // aw -> ă
        let awResult = telex.processCharacter("w", context: "a")
        XCTAssertNotNil(awResult)
        if case .modifier(.breve) = awResult?.type {
            // Expected
        } else {
            XCTFail("Expected breve modifier for 'aw'")
        }

        // uw -> ư
        let uwResult = telex.processCharacter("w", context: "u")
        XCTAssertNotNil(uwResult)
        if case .modifier(.horn) = uwResult?.type {
            // Expected
        } else {
            XCTFail("Expected horn modifier for 'uw'")
        }

        // ow -> ơ
        let owResult = telex.processCharacter("w", context: "o")
        XCTAssertNotNil(owResult)
    }

    // MARK: - Special Keys Tests

    func testTelexSpecialKeys() {
        let telex = TelexInputMethod()

        XCTAssertTrue(telex.isSpecialKey("s"))
        XCTAssertTrue(telex.isSpecialKey("f"))
        XCTAssertTrue(telex.isSpecialKey("r"))
        XCTAssertTrue(telex.isSpecialKey("x"))
        XCTAssertTrue(telex.isSpecialKey("j"))
        XCTAssertTrue(telex.isSpecialKey("z"))
        XCTAssertTrue(telex.isSpecialKey("w"))
        XCTAssertTrue(telex.isSpecialKey("["))
        XCTAssertTrue(telex.isSpecialKey("]"))

        XCTAssertFalse(telex.isSpecialKey("a"))
        XCTAssertFalse(telex.isSpecialKey("b"))
        XCTAssertFalse(telex.isSpecialKey("1"))
    }

    // MARK: - Bracket Key Tests

    func testBracketKeyAtStart() {
        let telex = TelexInputMethod()

        // [ at start → ơ
        let bracketOpenResult = telex.processCharacter("[", context: "")
        XCTAssertNotNil(bracketOpenResult)
        if case .standalone(let char) = bracketOpenResult?.type {
            XCTAssertEqual(char, "ơ")
        } else {
            XCTFail("Expected standalone ơ for '[' at start")
        }

        // ] at start → ư
        let bracketCloseResult = telex.processCharacter("]", context: "")
        XCTAssertNotNil(bracketCloseResult)
        if case .standalone(let char) = bracketCloseResult?.type {
            XCTAssertEqual(char, "ư")
        } else {
            XCTFail("Expected standalone ư for ']' at start")
        }
    }

    func testBracketKeyAfterConsonant() {
        let telex = TelexInputMethod()

        // b[ → bơ
        let result = telex.processCharacter("[", context: "b")
        XCTAssertNotNil(result)
        if case .standalone(let char) = result?.type {
            XCTAssertEqual(char, "ơ")
        } else {
            XCTFail("Expected standalone ơ for 'b['")
        }
    }

    func testBracketKeyAfterVowelLiteral() {
        let telex = TelexInputMethod()

        // a[ → a[ (literal, pass through)
        let result = telex.processCharacter("[", context: "a")
        XCTAssertNil(result, "Bracket after vowel should be nil (pass through)")
    }

    func testBracketKeyUSpecialCase() {
        let telex = TelexInputMethod()

        // u[ → uơ (special case!)
        let result = telex.processCharacter("[", context: "u")
        XCTAssertNotNil(result)
        if case .standalone(let char) = result?.type {
            XCTAssertEqual(char, "ơ")
        } else {
            XCTFail("Expected standalone ơ for 'u[' special case")
        }
    }

    func testBracketKeyAfterBlocker() {
        let telex = TelexInputMethod()

        // w[ → w[ (literal, after blocker)
        let wResult = telex.processCharacter("[", context: "w")
        XCTAssertNil(wResult, "Bracket after blocker 'w' should be nil")

        // e] → e] (literal, e is blocker AND vowel)
        let eResult = telex.processCharacter("]", context: "e")
        XCTAssertNil(eResult, "Bracket after blocker 'e' should be nil")
    }

    func testBracketKeyAfterDoubleConsonant() {
        let telex = TelexInputMethod()

        // tr[ → trơ (after double consonant)
        let result = telex.processCharacter("[", context: "tr")
        XCTAssertNotNil(result)
        if case .standalone(let char) = result?.type {
            XCTAssertEqual(char, "ơ")
        } else {
            XCTFail("Expected standalone ơ for 'tr['")
        }
    }

    // MARK: - Standalone W Tests

    func testStandaloneWAtStart() {
        let telex = TelexInputMethod()

        // w at start → ư (in Telex)
        let result = telex.processCharacter("w", context: "")
        XCTAssertNotNil(result)
        if case .standalone(let char) = result?.type {
            XCTAssertEqual(char, "ư")
        } else {
            XCTFail("Expected standalone ư for 'w' at start in Telex")
        }
    }

    func testStandaloneWAfterConsonant() {
        let telex = TelexInputMethod()

        // bw → bư (in Telex)
        let result = telex.processCharacter("w", context: "b")
        XCTAssertNotNil(result)
        if case .standalone(let char) = result?.type {
            XCTAssertEqual(char, "ư")
        } else {
            XCTFail("Expected standalone ư for 'bw' in Telex")
        }
    }

    func testTelexStandaloneWAfterBlocker() {
        // Test standalone w after blocker character (should return nil)
        let telex = TelexInputMethod()

        // w after 'w' (blocker) → nil
        let wwResult = telex.processCharacter("w", context: "w")
        XCTAssertNil(wwResult, "w after blocker 'w' should return nil")

        // w after 'f' (blocker) → nil
        let fwResult = telex.processCharacter("w", context: "f")
        XCTAssertNil(fwResult, "w after blocker 'f' should return nil")
    }

    // MARK: - Undo Tests

    func testTelexStandaloneHornUndoReturnsUndo() {
        // Test undo on standaloneHorn - now supported!
        // When the same trigger key is pressed again, it should return undo transformation
        let telex = TelexInputMethod()
        var state = InputMethodState()

        // Set lastTransformation to standaloneHorn with trigger key '['
        state.lastTransformation = LastTransformation(type: .standaloneHorn, triggerKey: "[", originalChars: "[")

        // Try pressing [ again - should trigger undo
        let undoResult = telex.processCharacter("[", context: "ơ", state: &state)
        
        // Should return an undo transformation that restores original character
        XCTAssertNotNil(undoResult, "standaloneHorn undo should return transformation")
        if case .undo(let originalChars) = undoResult?.type {
            XCTAssertEqual(originalChars, "[", "Undo should restore to original character '['")
        } else {
            XCTFail("Expected undo transformation, got: \(String(describing: undoResult?.type))")
        }
        
        // State should be cleared after undo
        XCTAssertNil(state.lastTransformation, "lastTransformation should be nil after undo")
        XCTAssertTrue(state.isDisabled("["), "Trigger key should be temporarily disabled after undo")
    }

    func testTelexDisabledKeyReturnsNil() {
        let telex = TelexInputMethod()
        var state = InputMethodState()

        // Disable the 's' key
        state.disableKey("s")

        // Try to use 's' key - should return nil
        let result = telex.processCharacter("s", context: "a", state: &state)
        XCTAssertNil(result, "Disabled key should return nil")
    }

    // MARK: - Input Method Name Tests

    func testInputMethodName() {
        XCTAssertEqual(TelexInputMethod().name, "Telex")
    }
}
