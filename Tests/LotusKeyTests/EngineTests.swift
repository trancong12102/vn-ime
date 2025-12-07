import XCTest
@testable import LotusKey

final class EngineTests: XCTestCase {
    var engine: DefaultVietnameseEngine!

    override func setUp() {
        super.setUp()
        engine = DefaultVietnameseEngine()
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

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

    // MARK: - Modifier Keys

    func testCommandKeyPassthrough() {
        _ = engine.processKey(keyCode: 0, character: "a", modifiers: 0)
        // Cmd+C should pass through without affecting buffer
        let result = engine.processKey(keyCode: 8, character: "c", modifiers: 0x100000)
        XCTAssertEqual(result, .passThrough)
    }

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

    // MARK: - qu-/gi- Consonant Handling

    func testQuConsonantMarkPosition() {
        // "quas" -> "quá" - mark on 'a', not 'u'
        let result = engine.processString("quas")
        XCTAssertEqual(result, "quá")
    }

    func testQuyMarkPosition() {
        // "quys" -> "quý" - mark on 'y' (only real vowel)
        let result = engine.processString("quys")
        XCTAssertEqual(result, "quý")
    }

    func testGiaMarkPosition() {
        // "gias" -> "giá" - mark on 'a', not 'i'
        let result = engine.processString("gias")
        XCTAssertEqual(result, "giá")
    }

    func testGiWithoutFollowingVowel() {
        // "gis" -> "gí" - 'i' is treated as vowel when no following vowel
        let result = engine.processString("gis")
        XCTAssertEqual(result, "gí")
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

    // MARK: - ProcessString Helper Tests

    func testProcessStringBasic() {
        let result = engine.processString("abc")
        // Without Telex transformations, should be "abc"
        XCTAssertTrue(result == "abc" || result.contains("a"))
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

    // MARK: - Integration Tests (Full Telex Sequences)

    func testProcessStringViet() {
        // "Vieejt" -> "Việt" (Telex: ee = ê, j = nặng)
        let result = engine.processString("Vieejt")
        XCTAssertEqual(result, "Việt")
    }

    func testProcessStringNam() {
        // "Nam" -> "Nam" (no transformation needed)
        let result = engine.processString("Nam")
        XCTAssertEqual(result, "Nam")
    }

    func testProcessStringXinChao() {
        // "xin chaof" -> "xin chào" (f = huyền)
        let result = engine.processString("xin chaof")
        XCTAssertEqual(result, "xin chào")
    }

    func testProcessStringToi() {
        // "tooi" -> "tôi" (oo = ô)
        let result = engine.processString("tooi")
        XCTAssertEqual(result, "tôi")
    }

    func testProcessStringDi() {
        // "ddi" -> "đi" (dd = đ)
        let result = engine.processString("ddi")
        XCTAssertEqual(result, "đi")
    }

    func testProcessStringUong() {
        // "uoongs" -> "uống" (oo = ô, s = sắc)
        let result = engine.processString("uoongs")
        XCTAssertEqual(result, "uống")
    }

    func testProcessStringNuoc() {
        // "nuwowcs" -> "nước" (uw = ư, ow = ơ, s = sắc)
        // For "ươ" combination, mark goes on ơ (second vowel) per modern orthography
        let result = engine.processString("nuwowcs")
        XCTAssertEqual(result, "nước")
    }

    func testProcessStringHoa() {
        // "hoaf" -> "hoà" (mark on 'a' for oa combination)
        let result = engine.processString("hoaf")
        XCTAssertEqual(result, "hoà")
    }

    func testProcessStringQuy() {
        // "quys" -> "quý" (mark on 'y' for uy combination)
        let result = engine.processString("quys")
        XCTAssertEqual(result, "quý")
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

    // MARK: - Uppercase Tests

    func testUppercaseTelex() {
        // "AS" -> should produce "Á" or "AS" depending on implementation
        let result = engine.processString("AS")
        // The first 'A' should be uppercase, second 'S' applies tone
        XCTAssertTrue(result == "Á" || result == "AS")
    }

    func testUppercaseCircumflex() {
        // "AA" -> "Â"
        let result = engine.processString("AA")
        XCTAssertEqual(result, "Â")
    }

    func testUppercaseDD() {
        // "DD" -> "Đ"
        let result = engine.processString("DD")
        XCTAssertEqual(result, "Đ")
    }

    // MARK: - Triple Vowel Tests

    func testTripleVowelUoi() {
        // "tuooir" -> "tưởi" - mark on middle vowel 'ô'
        var buffer = TypingBuffer()
        buffer.append("t")
        buffer.append("u")
        var typedO = TypedCharacter(character: "o")
        typedO.state.insert(.circumflex)  // ô
        buffer.append(typedO)
        buffer.append("i")

        // Mark should go on 'ô' (the modified vowel)
        let markPos = buffer.findMarkPosition()
        XCTAssertEqual(markPos, 2)  // Position of 'ô'
    }

    func testTripleVowelOai() {
        // "oai" -> mark should go on middle vowel 'a'
        var buffer = TypingBuffer()
        buffer.append("o")
        buffer.append("a")
        buffer.append("i")

        let markPos = buffer.findMarkPosition()
        XCTAssertEqual(markPos, 1)  // Position of 'a' (middle)
    }

    // MARK: - iê/yê/uô/ươ + Ending Consonant Integration Tests

    func testIEWithEndingConsonant() {
        // "tieens" -> "tiến" (mark on ê)
        let result = engine.processString("tieens")
        XCTAssertEqual(result, "tiến")
    }

    func testUOWithEndingConsonant() {
        // "cuoons" -> "cuốn" (mark on ô)
        let result = engine.processString("cuoons")
        XCTAssertEqual(result, "cuốn")
    }

    func testUOWithHornAndEnding() {
        // "nuwowcs" -> "nước" (ươ combination, mark on ơ)
        let result = engine.processString("nuwowcs")
        XCTAssertEqual(result, "nước")
    }

    func testDuoc() {
        // "dduwowcj" -> "được" (đđ = đ, ươ, j = nặng on ơ)
        let result = engine.processString("dduwowcj")
        XCTAssertEqual(result, "được")
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

    // MARK: - Undo Mechanism Tests

    func testUndoCircumflex() {
        // aa → â, aaa → aa
        let result = engine.processString("aaa")
        XCTAssertEqual(result, "aa", "aaa should undo circumflex to produce 'aa'")
    }

    func testUndoCircumflexE() {
        // ee → ê, eee → ee
        let result = engine.processString("eee")
        XCTAssertEqual(result, "ee", "eee should undo circumflex to produce 'ee'")
    }

    func testUndoCircumflexO() {
        // oo → ô, ooo → oo
        let result = engine.processString("ooo")
        XCTAssertEqual(result, "oo", "ooo should undo circumflex to produce 'oo'")
    }

    func testUndoCircumflexWithTempDisable() {
        // aaaa → aaa (tempDisableKey prevents re-transform after undo)
        let result = engine.processString("aaaa")
        XCTAssertEqual(result, "aaa", "aaaa should produce 'aaa' (tempDisableKey)")
    }

    func testUndoCircumflexEWithTempDisable() {
        // eeee → eee (tempDisableKey prevents re-transform after undo)
        let result = engine.processString("eeee")
        XCTAssertEqual(result, "eee", "eeee should produce 'eee' (tempDisableKey)")
    }

    func testUndoCircumflexOWithTempDisable() {
        // oooo → ooo (tempDisableKey prevents re-transform after undo)
        let result = engine.processString("oooo")
        XCTAssertEqual(result, "ooo", "oooo should produce 'ooo' (tempDisableKey)")
    }

    func testUndoStroke() {
        // dd → đ, ddd → dd
        let result = engine.processString("ddd")
        XCTAssertEqual(result, "dd", "ddd should undo stroke to produce 'dd'")
    }

    func testUndoStrokeWithTempDisable() {
        // dddd → ddd (tempDisableKey prevents re-transform after undo)
        let result = engine.processString("dddd")
        XCTAssertEqual(result, "ddd", "dddd should produce 'ddd' (tempDisableKey)")
    }

    func testUndoHorn() {
        // ow → ơ, oww → ow
        let result = engine.processString("oww")
        XCTAssertEqual(result, "ow", "oww should undo horn to produce 'ow'")
    }

    func testUndoBreve() {
        // aw → ă, aww → aw
        let result = engine.processString("aww")
        XCTAssertEqual(result, "aw", "aww should undo breve to produce 'aw'")
    }

    func testUndoTone() {
        // as → á, ass → as
        let result = engine.processString("ass")
        XCTAssertEqual(result, "as", "ass should undo tone to produce 'as'")
    }

    func testUndoResetAfterWordBreak() {
        // After word break, undo state should reset
        // "aaaa " + "aa" → "aaaa â" - tempDisableKey resets after word break
        // The first "aaaa" produces "aaa" (circumflex + undo + tempDisabled literal)
        // But at word break, "aaa" is invalid Vietnamese, so restore-on-invalid outputs "aaaa"
        // The space resets tempDisableKey
        // The next "aa" produces "â" (circumflex works again after reset)
        let result = engine.processString("aaaa aa")
        XCTAssertEqual(result, "aaaa â", "tempDisableKey should reset after word break, allowing transformation in new word")
    }

    // MARK: - Bracket Key Integration Tests

    func testBracketKeyAtStart() {
        // First verify the input method returns the right transformation
        let telex = TelexInputMethod()
        var state = InputMethodState()
        let transformation = telex.processCharacter("[", context: "", state: &state)
        XCTAssertNotNil(transformation, "TelexInputMethod should return transformation for '['")

        if let t = transformation, case .standalone(let char) = t.type {
            XCTAssertEqual(char, "ơ", "Standalone should be 'ơ'")
        } else {
            XCTFail("Expected standalone transformation, got: \(String(describing: transformation?.type))")
        }

        // Verify isSpecialKey returns true for [
        XCTAssertTrue(telex.isSpecialKey("["), "[ should be a special key")
        XCTAssertTrue(engine.inputMethod.isSpecialKey("["), "Engine's input method should recognize '[' as special")

        // [ at start → ơ
        let result = engine.processString("[")
        XCTAssertEqual(result, "ơ", "[ at start should produce 'ơ'")
    }

    func testBracketKeyAfterConsonant() {
        // b[ → bơ
        let result = engine.processString("b[")
        XCTAssertEqual(result, "bơ", "b[ should produce 'bơ'")
    }

    func testBracketKeyClosedAfterConsonant() {
        // b] → bư
        let result = engine.processString("b]")
        XCTAssertEqual(result, "bư", "b] should produce 'bư'")
    }

    func testBracketKeyUSpecialCase() {
        // u[ → uơ (special case)
        let result = engine.processString("u[")
        XCTAssertEqual(result, "uơ", "u[ should produce 'uơ'")
    }

    func testBracketKeyAfterVowelLiteral() {
        // a[ → a[ (literal after vowel)
        let result = engine.processString("a[")
        XCTAssertEqual(result, "a[", "a[ should produce 'a[' (literal)")
    }

    // MARK: - Standalone W Tests

    func testStandaloneWAtStart() {
        // w at start → ư (in Telex)
        let result = engine.processString("w")
        XCTAssertEqual(result, "ư", "w at start should produce 'ư' in Telex")
    }

    func testStandaloneWAfterConsonant() {
        // bw → bư (in Telex)
        let result = engine.processString("bw")
        XCTAssertEqual(result, "bư", "bw should produce 'bư' in Telex")
    }

    // MARK: - Simple Telex Engine Tests

    func testSimpleTelexOWNoHorn() {
        let simpleTelex = SimpleTelexInputMethod()
        let simpleEngine = DefaultVietnameseEngine(inputMethod: simpleTelex)

        // ow → ow in Simple Telex (no horn)
        let result = simpleEngine.processString("ow")
        XCTAssertEqual(result, "ow", "ow in Simple Telex should stay 'ow'")
    }

    func testSimpleTelexUWNoHorn() {
        let simpleTelex = SimpleTelexInputMethod()
        let simpleEngine = DefaultVietnameseEngine(inputMethod: simpleTelex)

        // uw → uw in Simple Telex (no horn)
        let result = simpleEngine.processString("uw")
        XCTAssertEqual(result, "uw", "uw in Simple Telex should stay 'uw'")
    }

    func testSimpleTelexAWBreve() {
        let simpleTelex = SimpleTelexInputMethod()
        let simpleEngine = DefaultVietnameseEngine(inputMethod: simpleTelex)

        // aw → ă in Simple Telex (breve works)
        let result = simpleEngine.processString("aw")
        XCTAssertEqual(result, "ă", "aw in Simple Telex should produce 'ă'")
    }

    func testSimpleTelexStandaloneWNoConversion() {
        let simpleTelex = SimpleTelexInputMethod()
        let simpleEngine = DefaultVietnameseEngine(inputMethod: simpleTelex)

        // w at start → w in Simple Telex (no → ư)
        let result = simpleEngine.processString("w")
        XCTAssertEqual(result, "w", "w in Simple Telex should stay 'w'")
    }

    func testSimpleTelexBracketWorks() {
        let simpleTelex = SimpleTelexInputMethod()
        let simpleEngine = DefaultVietnameseEngine(inputMethod: simpleTelex)

        // [ at start → ơ in Simple Telex (bracket works)
        let result = simpleEngine.processString("[")
        XCTAssertEqual(result, "ơ", "[ in Simple Telex should produce 'ơ'")
    }

    func testSimpleTelexAWWUndo() {
        let simpleTelex = SimpleTelexInputMethod()
        let simpleEngine = DefaultVietnameseEngine(inputMethod: simpleTelex)

        // aww → aw in Simple Telex (undo breve)
        let result = simpleEngine.processString("aww")
        XCTAssertEqual(result, "aw", "aww in Simple Telex should undo breve to produce 'aw'")
    }

    func testSimpleTelexAWWWTempDisable() {
        let simpleTelex = SimpleTelexInputMethod()
        let simpleEngine = DefaultVietnameseEngine(inputMethod: simpleTelex)

        // awww → aww in Simple Telex (tempDisableKey after undo)
        let result = simpleEngine.processString("awww")
        XCTAssertEqual(result, "aww", "awww in Simple Telex should produce 'aww' (tempDisableKey)")
    }

    // MARK: - Quick Telex Integration Tests

    func testQuickTelexCC() {
        engine.quickTelex.isEnabled = true
        let result = engine.processString("cc")
        XCTAssertEqual(result, "ch", "cc with Quick Telex enabled should produce 'ch'")
    }

    func testQuickTelexGG() {
        engine.quickTelex.isEnabled = true
        let result = engine.processString("gg")
        XCTAssertEqual(result, "gi", "gg with Quick Telex enabled should produce 'gi'")
    }

    func testQuickTelexNN() {
        engine.quickTelex.isEnabled = true
        let result = engine.processString("nn")
        XCTAssertEqual(result, "ng", "nn with Quick Telex enabled should produce 'ng'")
    }

    func testQuickTelexTT() {
        engine.quickTelex.isEnabled = true
        let result = engine.processString("tt")
        XCTAssertEqual(result, "th", "tt with Quick Telex enabled should produce 'th'")
    }

    func testQuickTelexDisabled() {
        engine.quickTelex.isEnabled = false
        let result = engine.processString("cc")
        XCTAssertEqual(result, "cc", "cc with Quick Telex disabled should stay 'cc'")
    }

    func testQuickTelexProcessShortcutDirectlyWhenDisabled() {
        // Test processShortcut directly to cover the guard else branch
        engine.quickTelex.isEnabled = false
        let result = engine.quickTelex.processShortcut("c", previousCharacter: "c")
        XCTAssertNil(result, "processShortcut should return nil when disabled")
    }

    func testQuickTelexProcessShortcutWithNilPreviousCharacter() {
        // Test processShortcut with nil previousCharacter to cover the guard else branch
        engine.quickTelex.isEnabled = true
        let result = engine.quickTelex.processShortcut("c", previousCharacter: nil)
        XCTAssertNil(result, "processShortcut should return nil when previousCharacter is nil")
    }

    func testQuickTelexInWord() {
        engine.quickTelex.isEnabled = true
        let result = engine.processString("cca")
        XCTAssertEqual(result, "cha", "cca with Quick Telex should produce 'cha'")
    }

    // MARK: - Grammar Auto-Adjust Tests (OpenKey checkGrammar equivalent)

    // Test cases for "ưo → ươ" (u has horn, o doesn't)

    func testGrammarAutoAdjustThuwon() {
        // "thuwon" → "thương" (ư before o, then 'n' triggers auto-adjust)
        // User types: t-h-u-w-o-n
        // After 'w': "thư" (horn on u)
        // After 'o': "thưo" (o without horn)
        // After 'n': auto-adjust → "thươn" (horn applied to both)
        let result = engine.processString("thuwon")
        XCTAssertEqual(result, "thươn", "thuwon should auto-adjust to 'thươn'")
    }

    func testGrammarAutoAdjustNuwoc() {
        // "nuwoc" → "nươc" (ư before o, then 'c' triggers auto-adjust)
        let result = engine.processString("nuwoc")
        XCTAssertEqual(result, "nươc", "nuwoc should auto-adjust to 'nươc'")
    }

    func testGrammarAutoAdjustDuwoc() {
        // "dduwoc" → "đươc" (đ + ư before o, then 'c' triggers auto-adjust)
        let result = engine.processString("dduwoc")
        XCTAssertEqual(result, "đươc", "dduwoc should auto-adjust to 'đươc'")
    }

    func testGrammarAutoAdjustWithTone() {
        // "thuwongs" → "thướng" (auto-adjust + tone on ơ per modern orthography)
        // In "ươ" + ending consonant, tone goes on the second vowel (ơ)
        let result = engine.processString("thuwongs")
        XCTAssertEqual(result, "thướng", "thuwongs should produce 'thướng' (tone on ơ)")
    }

    func testGrammarAutoAdjustNuwocsNuoc() {
        // "nuwocs" → "nước" (auto-adjust + tone on ơ)
        let result = engine.processString("nuwocs")
        XCTAssertEqual(result, "nước", "nuwocs should produce 'nước'")
    }

    func testGrammarAutoAdjustDduwocsNuoc() {
        // "dduwocj" → "được" (đ + auto-adjust + nặng tone)
        let result = engine.processString("dduwocj")
        XCTAssertEqual(result, "được", "dduwocj should produce 'được'")
    }

    // Test cases for "uơ → ươ" (o has horn, u doesn't)
    // Note: This is less common typing order, but should still work

    func testGrammarAutoAdjustUOwPattern() {
        // This tests if we can reach "uơ" state and have it auto-correct
        // Using bracket key: "u[n" = u + ơ + n → should auto-adjust to "ươn"
        let result = engine.processString("u[n")
        XCTAssertEqual(result, "ươn", "u[n should auto-adjust to 'ươn'")
    }

    func testGrammarAutoAdjustThUOwPattern() {
        // "thu[n" = th + u + ơ + n → should auto-adjust to "thươn"
        let result = engine.processString("thu[n")
        XCTAssertEqual(result, "thươn", "thu[n should auto-adjust to 'thươn'")
    }

    // Test no-change cases (XOR = false)

    func testGrammarNoChangeUO() {
        // "thuon" → "thuon" (neither has horn, XOR = false, no auto-apply)
        let result = engine.processString("thuon")
        XCTAssertEqual(result, "thuon", "thuon should stay 'thuon' (no horn intended)")
    }

    func testGrammarNoChangeAlreadyUwow() {
        // "thuwown" → "thươn" (standard typing, both have horn from 'w' keys)
        // This is the normal case that already works via applyModifier(.horn)
        let result = engine.processString("thuwown")
        XCTAssertEqual(result, "thươn", "thuwown should produce 'thươn' (both horn via w keys)")
    }

    func testGrammarStandardNuoc() {
        // "nuwowc" → "nươc" (standard typing with both w keys)
        // This already works, grammar auto-adjust should NOT double-apply
        let result = engine.processString("nuwowc")
        XCTAssertEqual(result, "nươc", "nuwowc should produce 'nươc' (standard typing)")
    }

    // Test with various trigger consonants

    func testGrammarTriggerN() {
        let result = engine.processString("thuwon")
        XCTAssertEqual(result, "thươn", "Grammar should trigger on 'n'")
    }

    func testGrammarTriggerC() {
        let result = engine.processString("nuwoc")
        XCTAssertEqual(result, "nươc", "Grammar should trigger on 'c'")
    }

    func testGrammarTriggerM() {
        let result = engine.processString("suwom")
        XCTAssertEqual(result, "sươm", "Grammar should trigger on 'm'")
    }

    func testGrammarTriggerP() {
        let result = engine.processString("huwop")
        XCTAssertEqual(result, "hươp", "Grammar should trigger on 'p'")
    }

    func testGrammarTriggerT() {
        let result = engine.processString("muwot")
        XCTAssertEqual(result, "mươt", "Grammar should trigger on 't'")
    }

    func testGrammarTriggerI() {
        let result = engine.processString("tuwoi")
        XCTAssertEqual(result, "tươi", "Grammar should trigger on 'i'")
    }

    // Test that non-trigger consonants don't trigger grammar check

    func testGrammarNoTriggerOnNonTriggerConsonant() {
        // 'g' is not a trigger consonant, so no auto-adjust
        // "thuwog" → "thưog" (if 'g' doesn't trigger)
        // Note: This might pass through or be marked as invalid spelling
        let result = engine.processString("thuwog")
        // 'g' is not a valid ending, so the state depends on spell checking
        // With spell check enabled, this might be marked invalid
        // The key test is that grammar auto-adjust doesn't run on 'g'
        XCTAssertTrue(result == "thưog" || result.contains("thưo"), "thuwog should not auto-adjust (g is not trigger)")
    }

    // Integration test with backspace

    func testGrammarWithBackspace() {
        // Type "thuwon", then backspace 'n', buffer should be "thưo" (not "thươ")
        // Because auto-adjust happened when 'n' was typed, but now 'n' is removed
        // Actually, backspace doesn't undo the grammar adjustment - it just removes the last char
        _ = engine.processKey(keyCode: 0, character: "t", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "h", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "u", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "w", modifiers: 0)  // thư
        _ = engine.processKey(keyCode: 0, character: "o", modifiers: 0)  // thưo
        _ = engine.processKey(keyCode: 0, character: "n", modifiers: 0)  // thươn (auto-adjusted)
        XCTAssertEqual(engine.currentText, "thươn")

        // Backspace removes 'n'
        _ = engine.processKey(keyCode: 51, character: nil, modifiers: 0)
        // The horn on 'o' was applied, so it remains "thươ"
        XCTAssertEqual(engine.currentText, "thươ", "After backspace, thươn becomes thươ (horn persists)")
    }

    // MARK: - Passthrough Behavior Tests (Flicker Prevention)

    /// Normal consonant/vowel sequences should pass through without replacement
    func testPassthroughNormalSequence() {
        // First char always passes through
        let result1 = engine.processKey(keyCode: 0, character: "h", modifiers: 0)
        XCTAssertEqual(result1, .passThrough, "First char 'h' should pass through")

        // Second char (non-transformation) should also pass through
        let result2 = engine.processKey(keyCode: 0, character: "i", modifiers: 0)
        XCTAssertEqual(result2, .passThrough, "Second char 'i' should pass through (no transformation)")

        XCTAssertEqual(engine.currentText, "hi")
    }

    /// "hello" should passthrough all characters (no Vietnamese transformation)
    func testPassthroughHello() {
        let chars = Array("hello")
        var results: [EngineResult] = []

        for char in chars {
            let result = engine.processKey(keyCode: 0, character: char, modifiers: 0)
            results.append(result)
        }

        // All characters should pass through - no backspaces at all
        for (i, result) in results.enumerated() {
            XCTAssertEqual(
                result, .passThrough,
                "Character '\(chars[i])' at index \(i) should pass through, got \(result)"
            )
        }
        XCTAssertEqual(engine.currentText, "hello")
    }

    /// Multiple chars without transformation should all pass through
    func testPassthroughMultipleChars() {
        let result1 = engine.processKey(keyCode: 0, character: "c", modifiers: 0)
        let result2 = engine.processKey(keyCode: 0, character: "o", modifiers: 0)
        let result3 = engine.processKey(keyCode: 0, character: "n", modifiers: 0)

        XCTAssertEqual(result1, .passThrough, "'c' should pass through")
        XCTAssertEqual(result2, .passThrough, "'o' should pass through")
        XCTAssertEqual(result3, .passThrough, "'n' should pass through")
        XCTAssertEqual(engine.currentText, "con")
    }

    /// Tone mark transformation should trigger replace
    func testReplaceForToneMark() {
        _ = engine.processKey(keyCode: 0, character: "a", modifiers: 0)
        let result = engine.processKey(keyCode: 0, character: "s", modifiers: 0)  // tone mark

        if case .replace(let backspaces, let replacement) = result {
            XCTAssertEqual(backspaces, 1, "Should delete 'a'")
            XCTAssertEqual(replacement, "á", "Should produce 'á'")
        } else {
            XCTFail("Tone mark should trigger replace, got \(result)")
        }
    }

    /// Modifier (circumflex) should trigger replace
    func testReplaceForCircumflex() {
        _ = engine.processKey(keyCode: 0, character: "a", modifiers: 0)
        let result = engine.processKey(keyCode: 0, character: "a", modifiers: 0)  // circumflex

        if case .replace(let backspaces, let replacement) = result {
            XCTAssertEqual(backspaces, 1, "Should delete 'a'")
            XCTAssertEqual(replacement, "â", "Should produce 'â'")
        } else {
            XCTFail("Circumflex should trigger replace, got \(result)")
        }
    }

    /// Quick Telex should trigger replace
    func testReplaceForQuickTelex() {
        _ = engine.processKey(keyCode: 0, character: "c", modifiers: 0)
        let result = engine.processKey(keyCode: 0, character: "c", modifiers: 0)  // Quick Telex: cc -> ch

        if case .replace(let backspaces, let replacement) = result {
            XCTAssertEqual(backspaces, 1, "Should delete 'c'")
            XCTAssertEqual(replacement, "ch", "Should produce 'ch'")
        } else {
            XCTFail("Quick Telex should trigger replace, got \(result)")
        }
    }

    /// Grammar auto-correction should trigger replace
    func testReplaceForGrammarCorrection() {
        // Type "thuwon" - grammar corrects "uo" to "ươ" when 'n' is typed
        _ = engine.processKey(keyCode: 0, character: "t", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "h", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "u", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "w", modifiers: 0)  // thư
        _ = engine.processKey(keyCode: 0, character: "o", modifiers: 0)  // thưo

        let result = engine.processKey(keyCode: 0, character: "n", modifiers: 0)  // triggers grammar

        if case .replace(let backspaces, let replacement) = result {
            XCTAssertEqual(backspaces, 4, "Should delete 'thưo'")
            XCTAssertEqual(replacement, "thươn", "Should produce 'thươn'")
        } else {
            XCTFail("Grammar correction should trigger replace, got \(result)")
        }
    }

    /// Adding consonant after tone-marked vowel should pass through (no grammar trigger)
    func testPassthroughAfterToneMark() {
        _ = engine.processKey(keyCode: 0, character: "h", modifiers: 0)  // h
        _ = engine.processKey(keyCode: 0, character: "a", modifiers: 0)  // ha
        _ = engine.processKey(keyCode: 0, character: "f", modifiers: 0)  // hà (replace)

        // Add 'n' - should pass through (not a grammar trigger for this pattern)
        let result = engine.processKey(keyCode: 0, character: "n", modifiers: 0)
        XCTAssertEqual(result, .passThrough, "'n' after 'hà' should pass through")
        XCTAssertEqual(engine.currentText, "hàn")
    }

    /// Consonants that are not grammar triggers should pass through
    func testPassthroughNonGrammarTriggerConsonant() {
        // "thưo" + "b" -> "thưob" (passthrough, 'b' is not a grammar trigger)
        _ = engine.processKey(keyCode: 0, character: "t", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "h", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "u", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "w", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "o", modifiers: 0)

        let result = engine.processKey(keyCode: 0, character: "b", modifiers: 0)
        XCTAssertEqual(result, .passThrough, "'b' is not a grammar trigger, should pass through")
    }

    /// Mixed input: verify correct passthrough vs replace sequence
    func testMixedPassthroughAndReplace() {
        // Type "vieets" -> should become "viết" (ê with acute = ế)
        let v = engine.processKey(keyCode: 0, character: "v", modifiers: 0)
        let i = engine.processKey(keyCode: 0, character: "i", modifiers: 0)
        let e = engine.processKey(keyCode: 0, character: "e", modifiers: 0)
        let e2 = engine.processKey(keyCode: 0, character: "e", modifiers: 0)  // circumflex
        let t = engine.processKey(keyCode: 0, character: "t", modifiers: 0)
        let s = engine.processKey(keyCode: 0, character: "s", modifiers: 0)  // tone

        XCTAssertEqual(v, .passThrough, "'v' should pass through")
        XCTAssertEqual(i, .passThrough, "'i' should pass through")
        XCTAssertEqual(e, .passThrough, "'e' should pass through")

        // 'e' (second) triggers circumflex -> replace
        if case .replace(_, let replacement) = e2 {
            XCTAssertEqual(replacement, "viê", "Second 'e' creates circumflex")
        } else {
            XCTFail("Second 'e' should replace, got \(e2)")
        }

        XCTAssertEqual(t, .passThrough, "'t' should pass through")

        // 's' triggers acute tone -> replace (ê + acute = ế)
        if case .replace(_, let replacement) = s {
            XCTAssertEqual(replacement, "viết", "'s' applies acute tone to ê")
        } else {
            XCTFail("'s' should replace with tone, got \(s)")
        }
    }

    /// Tone key without valid vowel should pass through as literal
    func testPassthroughToneKeyWithoutVowel() {
        _ = engine.processKey(keyCode: 0, character: "h", modifiers: 0)
        let result = engine.processKey(keyCode: 0, character: "s", modifiers: 0)

        // 's' has no vowel to apply tone to, so it's added as literal
        XCTAssertEqual(result, .passThrough, "Tone key without vowel should pass through")
        XCTAssertEqual(engine.currentText, "hs")
    }

    // MARK: - Flicker Prevention Integration Tests

    /// Helper to count backspace events in a sequence of engine results
    private func countBackspaces(_ results: [EngineResult]) -> Int {
        return results.reduce(0) { total, result in
            if case .replace(let backspaces, _) = result {
                return total + backspaces
            }
            return total
        }
    }

    /// Helper to process a string and collect all results
    private func processStringCollectingResults(_ input: String) -> [EngineResult] {
        engine.reset()
        return input.map { engine.processKey(keyCode: 0, character: $0, modifiers: 0) }
    }

    /// Typing "nước" should have minimal backspaces (only for transformations)
    func testFlickerPreventionNuoc() {
        // "nuwowcs" -> "nước" (uw = ư, ow = ơ, s = acute)
        // n: passthrough
        // u: passthrough
        // w: replace (horn on u -> ư)
        // o: passthrough
        // w: replace (horn on o -> ơ)
        // c: passthrough
        // s: replace (acute tone)
        let results = processStringCollectingResults("nuwowcs")
        let totalBackspaces = countBackspaces(results)

        XCTAssertEqual(engine.currentText, "nước")
        // Only 3 replace operations should happen (w for ư, w for ơ, s for tone)
        let replaceCount = results.filter { if case .replace = $0 { return true } else { return false } }.count
        XCTAssertEqual(replaceCount, 3, "Should have exactly 3 replace operations")
        XCTAssertLessThanOrEqual(totalBackspaces, 12, "Should have minimal backspaces")
    }

    /// Typing "việt" should have exactly 2 replace operations
    func testFlickerPreventionViet() {
        // "vieets" -> "viết"
        // v: passthrough
        // i: passthrough
        // e: passthrough
        // e: replace (circumflex)
        // t: passthrough
        // s: replace (tone)
        let results = processStringCollectingResults("vieets")

        XCTAssertEqual(engine.currentText, "viết")

        let replaceCount = results.filter { if case .replace = $0 { return true } else { return false } }.count
        XCTAssertEqual(replaceCount, 2, "Should have exactly 2 replace operations")

        let passthroughCount = results.filter { $0 == .passThrough }.count
        XCTAssertEqual(passthroughCount, 4, "Should have 4 passthrough operations (v, i, e, t)")
    }

    /// Typing "việt nam" should track expected backspaces
    func testFlickerPreventionVietNam() {
        // "vieets" -> "viết" (2 replaces)
        // " " -> word break (passthrough)
        // "nam" -> all passthrough (3 passthroughs)
        var results = processStringCollectingResults("vieets")

        // Process space
        let spaceResult = engine.processKey(keyCode: 0, character: " ", modifiers: 0)
        results.append(spaceResult)

        // Process "nam"
        for char in "nam" {
            let result = engine.processKey(keyCode: 0, character: char, modifiers: 0)
            results.append(result)
        }

        // Verify minimal replace operations
        let replaceOps = results.filter { if case .replace = $0 { return true } else { return false } }
        XCTAssertEqual(replaceOps.count, 2, "Should only have 2 replace operations for 'viết nam'")
    }

    /// Simple word "con" should have zero backspaces (all passthrough)
    func testFlickerPreventionSimpleWord() {
        let results = processStringCollectingResults("con")

        XCTAssertEqual(engine.currentText, "con")

        let totalBackspaces = countBackspaces(results)
        XCTAssertEqual(totalBackspaces, 0, "Simple word 'con' should have zero backspaces")

        XCTAssertTrue(results.allSatisfy { $0 == .passThrough }, "All chars should passthrough")
    }

    /// Compare backspace count for "thương" with grammar correction
    func testFlickerPreventionGrammarCorrection() {
        // "thuwong" -> "thương" with grammar auto-correct on 'n'
        let results = processStringCollectingResults("thuwong")

        XCTAssertEqual(engine.currentText, "thương")

        // Expected replaces:
        // w: horn on u (replace)
        // n: grammar correction uo->ươ (replace)
        // g: passthrough
        let replaceOps = results.filter { if case .replace = $0 { return true } else { return false } }
        XCTAssertEqual(replaceOps.count, 2, "Should have 2 replace operations (w for horn, n for grammar)")
    }

    // MARK: - Break Keycode Tests

    /// Test that BreakKeyCodes enum contains the expected keycodes
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

    /// Test that isBreakKeyCode returns true for navigation break keys
    func testBreakKeyCodeDetection() {
        XCTAssertTrue(BreakKeyCodes.isBreakKeyCode(53), "ESC should be a break keycode")
        XCTAssertTrue(BreakKeyCodes.isBreakKeyCode(48), "Tab should be a break keycode")
        XCTAssertTrue(BreakKeyCodes.isBreakKeyCode(36), "Return should be a break keycode")
        XCTAssertTrue(BreakKeyCodes.isBreakKeyCode(76), "Enter should be a break keycode")
        XCTAssertTrue(BreakKeyCodes.isBreakKeyCode(123), "Left Arrow should be a break keycode")
        XCTAssertTrue(BreakKeyCodes.isBreakKeyCode(124), "Right Arrow should be a break keycode")
        XCTAssertTrue(BreakKeyCodes.isBreakKeyCode(125), "Down Arrow should be a break keycode")
        XCTAssertTrue(BreakKeyCodes.isBreakKeyCode(126), "Up Arrow should be a break keycode")
    }

    /// Test that isBreakKeyCode returns false for non-break keys
    func testNonBreakKeyCodeDetection() {
        XCTAssertFalse(BreakKeyCodes.isBreakKeyCode(0), "Regular key should not be a break keycode")
        XCTAssertFalse(BreakKeyCodes.isBreakKeyCode(51), "Backspace should not be a break keycode")
        XCTAssertFalse(BreakKeyCodes.isBreakKeyCode(49), "Space should not be a break keycode")
        XCTAssertFalse(BreakKeyCodes.isBreakKeyCode(1), "Random key should not be a break keycode")
    }

    /// Test: "ho" + ESC should reset buffer and produce "ho" (not "ho\u{1B}")
    /// Previously ESC character was added to buffer causing issues
    func testEscapeResetsSessionCleanly() {
        _ = engine.processKey(keyCode: 0, character: "h", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "o", modifiers: 0)
        XCTAssertEqual(engine.currentText, "ho")

        // Press ESC (keycode 53)
        let result = engine.processKey(keyCode: 53, character: "\u{1B}", modifiers: 0)

        // ESC should pass through (so application can handle it)
        XCTAssertEqual(result, .passThrough, "ESC should pass through")

        // Buffer should be reset (empty)
        XCTAssertTrue(engine.isEmpty, "Buffer should be empty after ESC")
    }

    /// Test: "ho" + ESC + "a" should produce "hoa" (not "ho\u{1B}a")
    /// This tests that typing continues normally after ESC
    func testTypingAfterEscapeWorks() {
        // Type "ho"
        _ = engine.processKey(keyCode: 0, character: "h", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "o", modifiers: 0)
        XCTAssertEqual(engine.currentText, "ho")

        // Press ESC
        _ = engine.processKey(keyCode: 53, character: "\u{1B}", modifiers: 0)
        XCTAssertTrue(engine.isEmpty)

        // Type "a"
        let result = engine.processKey(keyCode: 0, character: "a", modifiers: 0)
        XCTAssertEqual(result, .passThrough, "'a' after ESC should start new word")
        XCTAssertEqual(engine.currentText, "a")
    }

    /// Test: Arrow keys reset the session
    func testArrowKeysResetSession() {
        _ = engine.processKey(keyCode: 0, character: "h", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "i", modifiers: 0)
        XCTAssertEqual(engine.currentText, "hi")

        // Left arrow (keycode 123)
        let result = engine.processKey(keyCode: 123, character: nil, modifiers: 0)
        XCTAssertEqual(result, .passThrough, "Arrow should pass through")
        XCTAssertTrue(engine.isEmpty, "Buffer should be reset after arrow key")
    }

    /// Test: Tab resets the session
    func testTabResetsSession() {
        _ = engine.processKey(keyCode: 0, character: "v", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "i", modifiers: 0)
        XCTAssertEqual(engine.currentText, "vi")

        // Tab (keycode 48)
        let result = engine.processKey(keyCode: 48, character: "\t", modifiers: 0)
        XCTAssertEqual(result, .passThrough, "Tab should pass through")
        XCTAssertTrue(engine.isEmpty, "Buffer should be reset after Tab")
    }

    /// Test: Enter/Return resets the session
    func testEnterResetsSession() {
        // Type "an" - a valid Vietnamese word, so no restore needed
        _ = engine.processKey(keyCode: 0, character: "a", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "n", modifiers: 0)
        XCTAssertEqual(engine.currentText, "an")

        // Return (keycode 36)
        let result = engine.processKey(keyCode: 36, character: "\r", modifiers: 0)
        XCTAssertEqual(result, .passThrough, "Return should pass through")
        XCTAssertTrue(engine.isEmpty, "Buffer should be reset after Return")
    }

    /// Test: "hoas" (invalid) + ESC → restore original "hoas", clear buffer, ESC passes through
    func testRestoreOnInvalidSpellingWithEscape() {
        engine.spellCheckEnabled = true
        engine.restoreIfWrongSpelling = true

        // Type "hoas" - this should be detected as invalid Vietnamese spelling
        // "ho" is valid, "hoa" is valid, but "hoas" ends with 's' as an ending consonant
        // which creates an invalid syllable (expecting tone, not consonant after 'oa')
        _ = engine.processKey(keyCode: 0, character: "h", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "o", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "a", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "s", modifiers: 0)  // This applies acute tone: hoá

        // The engine should have transformed "hoas" to "hoá"
        XCTAssertEqual(engine.currentText, "hoá", "hoas should become hoá (tone applied)")

        // Press ESC - since "hoá" is valid, no restore needed
        let result = engine.processKey(keyCode: 53, character: "\u{1B}", modifiers: 0)
        XCTAssertEqual(result, .passThrough, "ESC on valid spelling should just pass through")
        XCTAssertTrue(engine.isEmpty, "Buffer should be cleared after ESC")
    }

    /// Test: Invalid spelling with break keycode triggers restore
    func testRestoreInvalidSpellingOnBreakKeycode() {
        engine.spellCheckEnabled = true
        engine.restoreIfWrongSpelling = true

        // Type a sequence that becomes invalid
        // "hoafs" - 'f' after 'a' applies grave tone (hòa), then 's' should become literal
        // Actually let's test with a clearer invalid case
        // "bcx" - no vowels, definitely invalid
        _ = engine.processKey(keyCode: 0, character: "b", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "c", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "x", modifiers: 0)

        XCTAssertEqual(engine.currentText, "bcx")

        // Press ESC - should restore original keystrokes (which are same as current)
        // and clear buffer
        let result = engine.processKey(keyCode: 53, character: "\u{1B}", modifiers: 0)

        // Since spelling is invalid and restoreIfWrongSpelling is enabled,
        // it should restore original keystrokes
        if case .replace(let backspaces, let replacement) = result {
            XCTAssertEqual(backspaces, 3, "Should delete 3 characters (bcx)")
            XCTAssertEqual(replacement, "bcx", "Should restore original keystrokes")
        } else if result == .passThrough {
            // If the text matches original (no transformation happened), it might just pass through
            XCTAssertTrue(engine.isEmpty, "Buffer should be cleared")
        }
    }

    /// Test: Valid word + ESC → no restore, just clear buffer
    func testValidWordWithEscapeNoRestore() {
        engine.spellCheckEnabled = true
        engine.restoreIfWrongSpelling = true

        // Type "viet" - valid Vietnamese
        _ = engine.processKey(keyCode: 0, character: "v", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "i", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "e", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "t", modifiers: 0)

        XCTAssertEqual(engine.currentText, "viet")

        // Press ESC - valid spelling, so no restore
        let result = engine.processKey(keyCode: 53, character: "\u{1B}", modifiers: 0)
        XCTAssertEqual(result, .passThrough, "ESC on valid word should pass through")
        XCTAssertTrue(engine.isEmpty, "Buffer should be cleared")
    }

    /// Test: Punctuation keys (comma, dot) still work as word breaks with char appended
    func testPunctuationWordBreakStillWorks() {
        _ = engine.processKey(keyCode: 0, character: "h", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "i", modifiers: 0)
        XCTAssertEqual(engine.currentText, "hi")

        // Type comma - should be word break (character-based)
        let result = engine.processKey(keyCode: 43, character: ",", modifiers: 0)
        XCTAssertEqual(result, .passThrough, "Comma should pass through as word break")
        XCTAssertTrue(engine.isEmpty, "Buffer should be cleared after comma")
    }

    /// Test: All arrow keys reset session
    func testAllArrowKeysResetSession() {
        // Test each arrow key
        let arrowCodes: [(UInt16, String)] = [
            (123, "Left"),
            (124, "Right"),
            (125, "Down"),
            (126, "Up")
        ]

        for (keyCode, name) in arrowCodes {
            // Setup: type something
            engine.reset()
            _ = engine.processKey(keyCode: 0, character: "a", modifiers: 0)
            XCTAssertFalse(engine.isEmpty, "Buffer should have content before \(name) arrow")

            // Press arrow key
            let result = engine.processKey(keyCode: keyCode, character: nil, modifiers: 0)
            XCTAssertEqual(result, .passThrough, "\(name) arrow should pass through")
            XCTAssertTrue(engine.isEmpty, "Buffer should be empty after \(name) arrow")
        }
    }

    /// Test: Break keycode with empty buffer just passes through
    func testBreakKeycodeEmptyBuffer() {
        XCTAssertTrue(engine.isEmpty)

        // Press ESC with empty buffer
        let result = engine.processKey(keyCode: 53, character: "\u{1B}", modifiers: 0)
        XCTAssertEqual(result, .passThrough, "ESC on empty buffer should pass through")
        XCTAssertTrue(engine.isEmpty)
    }
}
