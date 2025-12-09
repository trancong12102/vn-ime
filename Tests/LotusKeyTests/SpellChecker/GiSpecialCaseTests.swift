import Testing
@testable import LotusKey

// MARK: - Edge Case Tests: gi- Special Cases

struct GiSpecialCaseTests {
    let spellChecker = DefaultSpellChecker()

    @Test("Parse 'gi' + vowel only: 'già' → gi + a")
    func testGiVowelOnly() {
        // "già" should parse as: gi (consonant) + a (vowel)
        let parts = SyllableParser.parse("già")
        #expect(parts != nil)
        #expect(parts?.initialConsonant == "gi")
        #expect(parts?.vowelNucleus == "a")
        #expect(parts?.finalConsonant == "")
        #expect(parts?.tone == .grave)
    }

    @Test("Parse 'giếng' - current implementation parses as gi + e + ng")
    func testGiIeConsonant() {
        // NOTE: Ideally "giếng" should parse as: g + iê + ng (where "i" joins the vowel)
        // However, current implementation parses it as: gi + ê + ng
        // This is a known limitation documented in design.md
        // The spell check still passes because both parses result in valid syllables
        let parts = SyllableParser.parse("giếng")
        #expect(parts != nil)
        // Current implementation behavior:
        #expect(parts?.initialConsonant == "gi")
        #expect(parts?.vowelNucleus == "e")
        #expect(parts?.finalConsonant == "ng")
        #expect(parts?.tone == .acute)
    }

    @Test("Parse 'giết' - current implementation parses as gi + e + t")
    func testGiet() {
        // NOTE: Similar to "giếng" - ideally g + iê + t, currently gi + ê + t
        let parts = SyllableParser.parse("giết")
        #expect(parts != nil)
        #expect(parts?.initialConsonant == "gi")
        #expect(parts?.vowelNucleus == "e")
        #expect(parts?.finalConsonant == "t")
        #expect(parts?.tone == .acute)
    }

    @Test("Parse 'giếc' - current implementation parses as gi + e + c")
    func testGiec() {
        // NOTE: Similar to above - known limitation
        let parts = SyllableParser.parse("giếc")
        #expect(parts != nil)
        #expect(parts?.initialConsonant == "gi")
        #expect(parts?.vowelNucleus == "e")
        #expect(parts?.finalConsonant == "c")
    }

    @Test("Spell check 'già' is valid")
    func testGiaValid() {
        let result = spellChecker.check("già")
        #expect(result == .valid)
    }

    @Test("Spell check 'giếng' is valid")
    func testGiengValid() {
        // The word should be valid even with current parsing approach
        let result = spellChecker.check("giếng")
        #expect(result == .valid)
    }

    @Test("Spell check 'giết' is valid")
    func testGietValid() {
        let result = spellChecker.check("giết")
        #expect(result == .valid)
    }

    @Test("Parse 'giờ' → gi + o (with horn)")
    func testGio() {
        let parts = SyllableParser.parse("giờ")
        #expect(parts != nil)
        #expect(parts?.initialConsonant == "gi")
        #expect(parts?.vowelNucleus == "o")
        #expect(parts?.vowelModifiers[0] == .horn)
        #expect(parts?.tone == .grave)
    }

    @Test("Parse 'giữa' → gi + ua (with horn on u)")
    func testGiua() {
        // "giữa" parses as gi + ưa
        let parts = SyllableParser.parse("giữa")
        #expect(parts != nil)
        #expect(parts?.initialConsonant == "gi")
        // The parser handles this as gi + ua (with horn on u)
        #expect(parts?.vowelNucleus == "ua")
    }
}
