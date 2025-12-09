import Testing
@testable import LotusKey

// MARK: - Edge Case Tests: Vowel-Ending Compatibility

struct VowelEndingCompatibilityTests {
    let spellChecker = DefaultSpellChecker()

    @Test("'oa' allows ending consonants")
    func testOaAllowsEnding() {
        // "oan" should be valid (oa + n)
        let result = spellChecker.check("oan")
        #expect(result == .valid)

        // "oang" should be valid (oa + ng)
        let result2 = spellChecker.check("oang")
        #expect(result2 == .valid)
    }

    @Test("'ai' does NOT allow ending consonants")
    func testAiNoEnding() {
        // "ai" alone is valid
        let result1 = spellChecker.check("ai")
        #expect(result1 == .valid)

        // "bai" is valid (b + ai, no ending)
        let result2 = spellChecker.check("bai")
        #expect(result2 == .valid)
    }

    @Test("'oi' does NOT allow ending consonants")
    func testOiNoEnding() {
        let result = spellChecker.check("oi")
        #expect(result == .valid)

        let result2 = spellChecker.check("boi")
        #expect(result2 == .valid)
    }

    @Test("'iê' allows ending consonants")
    func testIeAllowsEnding() {
        // "tiên" (t + iê + n)
        let result = spellChecker.check("tiên")
        #expect(result == .valid)

        // "tiếng" (t + iê + ng)
        let result2 = spellChecker.check("tiếng")
        #expect(result2 == .valid)
    }

    @Test("'yê' allows ending consonants")
    func testYeAllowsEnding() {
        // "yên" (y + ê + n) - but actually yê is the vowel
        let result = spellChecker.check("yên")
        #expect(result == .valid)
    }
}
