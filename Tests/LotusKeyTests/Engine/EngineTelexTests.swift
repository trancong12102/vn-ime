import XCTest
@testable import LotusKey

/// Tests for Telex-specific features including bracket keys, standalone W, and Simple Telex
final class EngineTelexTests: EngineTestCase {

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

    func testStandaloneWUndo() {
        // w → ư, ww → w (undo standaloneHorn)
        let result = engine.processString("ww")
        XCTAssertEqual(result, "w", "ww should undo standalone to produce 'w'")
    }

    func testStandaloneWUndoAfterConsonant() {
        // bw → bư, bww → bw (undo standaloneHorn after consonant)
        let result = engine.processString("bww")
        XCTAssertEqual(result, "bw", "bww should undo standalone to produce 'bw'")
    }

    func testStandaloneBracketOpenUndo() {
        // [ → ơ, [[ → [ (undo standaloneHorn)
        let result = engine.processString("[[")
        XCTAssertEqual(result, "[", "[[ should undo standalone to produce '['")
    }

    func testStandaloneBracketCloseUndo() {
        // ] → ư, ]] → ] (undo standaloneHorn)
        let result = engine.processString("]]")
        XCTAssertEqual(result, "]", "]] should undo standalone to produce ']'")
    }

    func testStandaloneUndoWithTempDisable() {
        // www → ww (tempDisableKey prevents re-transformation after undo)
        let result = engine.processString("www")
        XCTAssertEqual(result, "ww", "www should produce 'ww' (tempDisableKey)")
    }

    // MARK: - Simple Telex Engine Tests

    func testSimpleTelexOWHorn() {
        let simpleTelex = SimpleTelexInputMethod()
        let simpleEngine = DefaultVietnameseEngine(inputMethod: simpleTelex)

        // ow → ơ in Simple Telex (horn WORKS - pattern matching runs regardless)
        let result = simpleEngine.processString("ow")
        XCTAssertEqual(result, "ơ", "ow in Simple Telex should produce 'ơ'")
    }

    func testSimpleTelexUWHorn() {
        let simpleTelex = SimpleTelexInputMethod()
        let simpleEngine = DefaultVietnameseEngine(inputMethod: simpleTelex)

        // uw → ư in Simple Telex (horn WORKS - pattern matching runs regardless)
        let result = simpleEngine.processString("uw")
        XCTAssertEqual(result, "ư", "uw in Simple Telex should produce 'ư'")
    }

    func testSimpleTelexCow() {
        let simpleTelex = SimpleTelexInputMethod()
        let simpleEngine = DefaultVietnameseEngine(inputMethod: simpleTelex)

        // cow → cơ in Simple Telex
        let result = simpleEngine.processString("cow")
        XCTAssertEqual(result, "cơ", "cow in Simple Telex should produce 'cơ'")
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

    func testSimpleTelexBracketPassthrough() {
        let simpleTelex = SimpleTelexInputMethod()
        let simpleEngine = DefaultVietnameseEngine(inputMethod: simpleTelex)

        // [ at start → [ in Simple Telex (bracket passes through as literal)
        // Reference: OpenKey Engine.cpp:1541 - bracket keys cause word break
        let openResult = simpleEngine.processString("[")
        XCTAssertEqual(openResult, "[", "[ in Simple Telex should pass through as literal")

        // ] at start → ] in Simple Telex
        simpleEngine.reset()
        let closeResult = simpleEngine.processString("]")
        XCTAssertEqual(closeResult, "]", "] in Simple Telex should pass through as literal")
    }

    func testSimpleTelexUOPatternTransformation() {
        let simpleTelex = SimpleTelexInputMethod()
        let simpleEngine = DefaultVietnameseEngine(inputMethod: simpleTelex)

        // uow → ươ in Simple Telex (horn transformation for "uo" pattern)
        // Reference: OpenKey Engine.cpp:899-910 - insertW handles "uo" specially
        let result = simpleEngine.processString("uow")
        XCTAssertEqual(result, "ươ", "uow in Simple Telex should produce 'ươ'")
    }

    func testSimpleTelexThuong() {
        let simpleTelex = SimpleTelexInputMethod()
        let simpleEngine = DefaultVietnameseEngine(inputMethod: simpleTelex)

        // thuowng → thương in Simple Telex
        let result = simpleEngine.processString("thuowng")
        XCTAssertEqual(result, "thương", "thuowng in Simple Telex should produce 'thương'")
    }

    func testSimpleTelexDuong() {
        let simpleTelex = SimpleTelexInputMethod()
        let simpleEngine = DefaultVietnameseEngine(inputMethod: simpleTelex)

        // duowng → dương in Simple Telex
        let result = simpleEngine.processString("duowng")
        XCTAssertEqual(result, "dương", "duowng in Simple Telex should produce 'dương'")
    }

    func testSimpleTelexAWWUndo() {
        let simpleTelex = SimpleTelexInputMethod()
        let simpleEngine = DefaultVietnameseEngine(inputMethod: simpleTelex)

        // aww → aw in Simple Telex (undo breve)
        let result = simpleEngine.processString("aww")
        XCTAssertEqual(result, "aw", "aww in Simple Telex should undo breve to produce 'aw'")
    }

    func testSimpleTelexOWWUndo() {
        let simpleTelex = SimpleTelexInputMethod()
        let simpleEngine = DefaultVietnameseEngine(inputMethod: simpleTelex)

        // oww → ow in Simple Telex (undo horn)
        let result = simpleEngine.processString("oww")
        XCTAssertEqual(result, "ow", "oww in Simple Telex should undo horn to produce 'ow'")
    }

    func testSimpleTelexUWWUndo() {
        let simpleTelex = SimpleTelexInputMethod()
        let simpleEngine = DefaultVietnameseEngine(inputMethod: simpleTelex)

        // uww → uw in Simple Telex (undo horn)
        let result = simpleEngine.processString("uww")
        XCTAssertEqual(result, "uw", "uww in Simple Telex should undo horn to produce 'uw'")
    }

    func testSimpleTelexAWWWTempDisable() {
        let simpleTelex = SimpleTelexInputMethod()
        let simpleEngine = DefaultVietnameseEngine(inputMethod: simpleTelex)

        // awww → aww in Simple Telex (tempDisableKey after undo)
        let result = simpleEngine.processString("awww")
        XCTAssertEqual(result, "aww", "awww in Simple Telex should produce 'aww' (tempDisableKey)")
    }
}
