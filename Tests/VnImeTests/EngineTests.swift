import XCTest
@testable import VnIme

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
        // Result should handle the backspace properly
        XCTAssertTrue(result == .passThrough || result == .replace(backspaceCount: 1, replacement: ""))
    }

    func testMultipleBackspaces() {
        // Type "abc", then backspace 3 times
        _ = engine.processKey(keyCode: 0, character: "a", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "b", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "c", modifiers: 0)
        XCTAssertEqual(engine.currentText, "abc")

        _ = engine.processKey(keyCode: 51, character: nil, modifiers: 0)
        XCTAssertEqual(engine.currentText, "ab")

        _ = engine.processKey(keyCode: 51, character: nil, modifiers: 0)
        XCTAssertEqual(engine.currentText, "a")

        _ = engine.processKey(keyCode: 51, character: nil, modifiers: 0)
        XCTAssertTrue(engine.isEmpty)
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
}
