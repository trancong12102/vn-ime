import XCTest
@testable import LotusKey

/// Tests for undo mechanism (double key to undo transformations)
final class EngineUndoTests: EngineTestCase {

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

    func testCircumflexUndoPreservesPrefix() {
        // Bug reproduction: "đa" + "aa" should produce "đâ", + "a" should produce "đaa"
        // NOT lose the "đ" prefix
        // Scenario: dd → đ, a → đa, a → đâ (circumflex), a → (undo) should give "đaa" NOT "aaa"
        let result = engine.processString("ddaaaa")
        XCTAssertEqual(result, "đaaa", "ddaaaa should produce 'đaaa', not 'aaa' - undo should preserve prefix")
    }

    func testCircumflexUndoPreservesPrefixTra() {
        // Similar test with "tr" prefix: tr + aa → trâ, + a → traa
        let result = engine.processString("traaaa")
        XCTAssertEqual(result, "traaa", "traaaa should produce 'traaa', not 'aaa' - undo should preserve prefix")
    }
}
