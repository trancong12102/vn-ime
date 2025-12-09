import Testing
@testable import LotusKey

// MARK: - Edge Case Tests: Uppercase Handling

struct UppercaseHandlingTests {
    let spellChecker = DefaultSpellChecker()

    @Test("Uppercase syllables are validated correctly")
    func testUppercaseSyllables() {
        // Uppercase should work the same as lowercase
        let result1 = spellChecker.check("BAN")
        let result2 = spellChecker.check("ban")
        #expect(result1 == result2)
    }

    @Test("Mixed case syllables")
    func testMixedCase() {
        let result = spellChecker.check("Bán")
        #expect(result == .valid)

        let result2 = spellChecker.check("VIỆT")
        #expect(result2 == .valid)
    }

    @Test("Parse uppercase Vietnamese")
    func testParseUppercase() {
        let parts = SyllableParser.parse("TIẾNG")
        #expect(parts != nil)
        #expect(parts?.initialConsonant == "t")
        #expect(parts?.vowelNucleus == "ie")
        #expect(parts?.finalConsonant == "ng")
    }
}
