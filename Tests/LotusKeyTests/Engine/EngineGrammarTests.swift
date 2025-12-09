import XCTest
@testable import LotusKey

/// Tests for grammar auto-adjust (ưo → ươ, uơ → ươ)
final class EngineGrammarTests: EngineTestCase {

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
}
