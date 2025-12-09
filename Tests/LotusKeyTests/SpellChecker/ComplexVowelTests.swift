import Testing
@testable import LotusKey

// MARK: - Edge Case Tests: Complex Vowel Combinations

struct ComplexVowelTests {
    let spellChecker = DefaultSpellChecker()

    @Test("Parse 'khuya' → kh + uya")
    func testKhuya() {
        let parts = SyllableParser.parse("khuya")
        #expect(parts != nil)
        #expect(parts?.initialConsonant == "kh")
        #expect(parts?.vowelNucleus == "uya")
        #expect(parts?.finalConsonant == "")
    }

    @Test("Parse 'khuấy' → kh + uay")
    func testKhuay() {
        let parts = SyllableParser.parse("khuấy")
        #expect(parts != nil)
        #expect(parts?.initialConsonant == "kh")
        // "uấy" = u + â + y = uay with circumflex on a
        #expect(parts?.vowelNucleus == "uay")
    }

    @Test("Parse 'ngoài' → ng + oai")
    func testNgoai() {
        let parts = SyllableParser.parse("ngoài")
        #expect(parts != nil)
        #expect(parts?.initialConsonant == "ng")
        #expect(parts?.vowelNucleus == "oai")
        #expect(parts?.tone == .grave)
    }

    @Test("Parse 'xoáy' → x + oay")
    func testXoay() {
        let parts = SyllableParser.parse("xoáy")
        #expect(parts != nil)
        #expect(parts?.initialConsonant == "x")
        #expect(parts?.vowelNucleus == "oay")
        #expect(parts?.tone == .acute)
    }

    @Test("Parse 'thoong' (loan word) → th + oo + ng")
    func testThoong() {
        let parts = SyllableParser.parse("thoong")
        #expect(parts != nil)
        #expect(parts?.initialConsonant == "th")
        #expect(parts?.vowelNucleus == "oo")
        #expect(parts?.finalConsonant == "ng")
    }

    @Test("Spell check 'khuya' is valid")
    func testKhuyaValid() {
        let result = spellChecker.check("khuya")
        #expect(result == .valid)
    }

    @Test("Spell check 'ngoài' is valid")
    func testNgoaiValid() {
        let result = spellChecker.check("ngoài")
        #expect(result == .valid)
    }

    @Test("Parse 'ươi' (standalone triphthong)")
    func testUoi() {
        let parts = SyllableParser.parse("ươi")
        #expect(parts != nil)
        #expect(parts?.initialConsonant == "")
        #expect(parts?.vowelNucleus == "uoi")
        // Both u and o should have horn modifiers
    }

    @Test("Parse 'được' → d + uo + c")
    func testDuoc() {
        let parts = SyllableParser.parse("được")
        #expect(parts != nil)
        #expect(parts?.initialConsonant == "d")
        #expect(parts?.vowelNucleus == "uo")
        #expect(parts?.finalConsonant == "c")
        #expect(parts?.tone == .dot)
    }

    @Test("Parse 'người' → ng + uoi")
    func testNguoi() {
        let parts = SyllableParser.parse("người")
        #expect(parts != nil)
        #expect(parts?.initialConsonant == "ng")
        #expect(parts?.vowelNucleus == "uoi")
    }
}
