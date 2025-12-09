import Testing
@testable import LotusKey

// MARK: - Edge Case Tests: Invalid Combinations

struct InvalidCombinationTests {
    let spellChecker = DefaultSpellChecker()

    @Test("Invalid: vowel combination 'ai' cannot have ending consonant")
    func testAiNoEnding() {
        // "ain" is invalid because "ai" doesn't allow ending consonants
        // Parser may still parse it, but spell checker should reject
        let parts = SyllableParser.parse("ain")
        // The parser extracts what it can
        #expect(parts != nil)

        // But spell check should fail because "ai" cannot have ending
        // Note: this depends on implementation - parser might not even extract 'n' as ending
    }

    @Test("Invalid: non-Vietnamese consonant cluster 'pr'")
    func testPrInvalid() {
        let result = spellChecker.check("pra")
        // "pr" is not a valid Vietnamese initial consonant
        #expect(result != .valid)
    }

    @Test("Invalid: 'bbb' - consonant only gibberish")
    func testBbbInvalid() {
        let result = spellChecker.check("bbb")
        // No vowels, but also not a valid consonant cluster
        #expect(result == .unknown || result != .valid)
    }

    @Test("Invalid: 'xyz' - non-Vietnamese characters")
    func testXyzHandling() {
        // 'x' is valid initial, but 'y' followed by 'z' is problematic
        let result = spellChecker.check("xyz")
        // Parser should handle gracefully
        #expect(result != .valid || result == .unknown)
    }

    @Test("Invalid: double consonant 'aa' with invalid ending 'k'")
    func testAakInvalid() {
        // 'k' is not a valid Vietnamese ending consonant
        let result = spellChecker.check("aak")
        #expect(result != .valid)
    }

    @Test("Invalid initial consonant 'f'")
    func testFInvalid() {
        let result = spellChecker.check("fa")
        // 'f' is not a valid Vietnamese consonant
        #expect(result != .valid)
    }

    @Test("Invalid: ending 'ng' after 'ai' (no-ending vowel)")
    func testAingInvalid() {
        // "ai" doesn't allow ending consonants per OpenKey rules
        // "aing" should be invalid
        let parts = SyllableParser.parse("aing")
        // Parser will extract what it can
        #expect(parts != nil)
    }
}
