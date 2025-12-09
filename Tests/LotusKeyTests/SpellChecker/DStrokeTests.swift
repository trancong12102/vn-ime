import Testing
@testable import LotusKey

// MARK: - Edge Case Tests: đ (d-stroke) Handling

struct DStrokeTests {
    let spellChecker = DefaultSpellChecker()

    @Test("Parse 'đi' → d + i")
    func testDi() {
        let parts = SyllableParser.parse("đi")
        #expect(parts != nil)
        // đ decomposes to 'd'
        #expect(parts?.initialConsonant == "d")
        #expect(parts?.vowelNucleus == "i")
    }

    @Test("Parse 'đường' → d + uo + ng")
    func testDuong() {
        let parts = SyllableParser.parse("đường")
        #expect(parts != nil)
        #expect(parts?.initialConsonant == "d")
        #expect(parts?.vowelNucleus == "uo")
        #expect(parts?.finalConsonant == "ng")
    }

    @Test("Parse 'đẹp' → d + e + p")
    func testDep() {
        let parts = SyllableParser.parse("đẹp")
        #expect(parts != nil)
        #expect(parts?.initialConsonant == "d")
        #expect(parts?.vowelNucleus == "e")
        #expect(parts?.finalConsonant == "p")
        #expect(parts?.tone == .dot)
    }

    @Test("Spell check 'đi' is valid")
    func testDiValid() {
        let result = spellChecker.check("đi")
        #expect(result == .valid)
    }

    @Test("Spell check 'đẹp' is valid")
    func testDepValid() {
        let result = spellChecker.check("đẹp")
        #expect(result == .valid)
    }
}
