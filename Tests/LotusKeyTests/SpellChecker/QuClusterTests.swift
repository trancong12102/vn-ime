import Testing
@testable import LotusKey

// MARK: - Edge Case Tests: qu- Cluster

struct QuClusterTests {
    let spellChecker = DefaultSpellChecker()

    @Test("Parse 'quốc' → qu + o + c")
    func testQuoc() {
        let parts = SyllableParser.parse("quốc")
        #expect(parts != nil)
        #expect(parts?.initialConsonant == "qu")
        #expect(parts?.vowelNucleus == "o")
        #expect(parts?.finalConsonant == "c")
        #expect(parts?.vowelModifiers[0] == .circumflex)
        #expect(parts?.tone == .acute)
    }

    @Test("Parse 'quyền' → qu + ye + n")
    func testQuyen() {
        let parts = SyllableParser.parse("quyền")
        #expect(parts != nil)
        #expect(parts?.initialConsonant == "qu")
        // After qu, "yề" = y + ê, so vowel nucleus is "ye"
        #expect(parts?.vowelNucleus == "ye")
        #expect(parts?.finalConsonant == "n")
    }

    @Test("Parse 'quý' → qu + y")
    func testQuy() {
        let parts = SyllableParser.parse("quý")
        #expect(parts != nil)
        #expect(parts?.initialConsonant == "qu")
        #expect(parts?.vowelNucleus == "y")
        #expect(parts?.tone == .acute)
    }

    @Test("Spell check 'quốc' is valid")
    func testQuocValid() {
        let result = spellChecker.check("quốc")
        #expect(result == .valid)
    }

    @Test("Spell check 'quyền' is valid")
    func testQuyenValid() {
        let result = spellChecker.check("quyền")
        #expect(result == .valid)
    }
}
