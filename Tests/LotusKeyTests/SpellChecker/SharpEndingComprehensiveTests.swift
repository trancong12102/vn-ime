import Testing
@testable import LotusKey

// MARK: - Edge Case Tests: All Sharp Endings with All Tones

struct SharpEndingComprehensiveTests {
    let spellChecker = DefaultSpellChecker()

    @Test("Sharp ending 'c' with all tones")
    func testSharpC() {
        // Valid: no tone, acute, dot
        #expect(spellChecker.check("bac") == .valid)   // no tone
        #expect(spellChecker.check("bác") == .valid)   // acute
        #expect(spellChecker.check("bạc") == .valid)   // dot

        // Invalid: grave, hook, tilde
        #expect(spellChecker.check("bàc") != .valid)   // grave
        #expect(spellChecker.check("bảc") != .valid)   // hook
        #expect(spellChecker.check("bãc") != .valid)   // tilde
    }

    @Test("Sharp ending 'ch' with all tones")
    func testSharpCh() {
        // Valid: no tone, acute, dot
        #expect(spellChecker.check("bach") == .valid)  // no tone
        #expect(spellChecker.check("bách") == .valid)  // acute
        #expect(spellChecker.check("bạch") == .valid)  // dot

        // Invalid: grave, hook, tilde
        #expect(spellChecker.check("bàch") != .valid)  // grave
        #expect(spellChecker.check("bảch") != .valid)  // hook
        #expect(spellChecker.check("bãch") != .valid)  // tilde
    }

    @Test("Sharp ending 'p' with all tones")
    func testSharpP() {
        // Valid: no tone, acute, dot
        #expect(spellChecker.check("tap") == .valid)   // no tone
        #expect(spellChecker.check("táp") == .valid)   // acute
        #expect(spellChecker.check("tạp") == .valid)   // dot

        // Invalid: grave, hook, tilde
        #expect(spellChecker.check("tàp") != .valid)   // grave
        #expect(spellChecker.check("tảp") != .valid)   // hook
        #expect(spellChecker.check("tãp") != .valid)   // tilde
    }

    @Test("Sharp ending 't' with all tones")
    func testSharpT() {
        // Valid: no tone, acute, dot
        #expect(spellChecker.check("bat") == .valid)   // no tone
        #expect(spellChecker.check("bát") == .valid)   // acute
        #expect(spellChecker.check("bạt") == .valid)   // dot

        // Invalid: grave, hook, tilde
        #expect(spellChecker.check("bàt") != .valid)   // grave
        #expect(spellChecker.check("bảt") != .valid)   // hook
        #expect(spellChecker.check("bãt") != .valid)   // tilde
    }
}
