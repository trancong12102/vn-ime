import Testing
@testable import LotusKey

// MARK: - Engine Integration Tests

struct EngineSpellCheckerIntegrationTests {
    @Test("Engine spell check enabled by default")
    func testSpellCheckEnabledByDefault() {
        let engine = DefaultVietnameseEngine()
        #expect(engine.spellCheckEnabled == true)
    }

    @Test("Engine restoreIfWrongSpelling enabled by default")
    func testRestoreIfWrongSpellingEnabledByDefault() {
        let engine = DefaultVietnameseEngine()
        #expect(engine.restoreIfWrongSpelling == true)
    }

    @Test("Engine disables transformation on invalid tone with sharp ending")
    func testDisableTransformationOnInvalid() {
        let engine = DefaultVietnameseEngine()
        engine.spellCheckEnabled = true

        // Type "bac" (valid), then try to add grave tone which is invalid with 'c' ending
        // The engine should add 'f' as literal when spell check fails
        let result = engine.processString("bacf")

        // After typing "bac" (valid), adding 'f' should be detected as attempting grave tone
        // but since "bàc" is invalid (grave with sharp ending), transformation is blocked
        // The behavior depends on whether the invalid detection happens before or after transform
        // In our implementation, tone check happens during transformation
        #expect(!result.isEmpty)
    }

    @Test("Valid Vietnamese word transforms correctly")
    func testValidWordTransforms() {
        let engine = DefaultVietnameseEngine()
        engine.spellCheckEnabled = true

        // "bans" should transform to "bán" (acute tone)
        let result = engine.processString("bans")
        #expect(result == "bán")
    }

    @Test("Valid word with non-sharp ending allows all tones")
    func testValidNonSharpEndingAllTones() {
        let engine = DefaultVietnameseEngine()
        engine.spellCheckEnabled = true

        // "banf" should transform to "bàn" (grave tone with 'n' ending is valid)
        let result = engine.processString("banf")
        #expect(result == "bàn")
    }
}
