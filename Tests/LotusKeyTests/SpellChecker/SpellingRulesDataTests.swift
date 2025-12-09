import Testing
@testable import LotusKey

// MARK: - Data Table Tests

struct SpellingRulesDataTests {
    @Test("Initial consonants count")
    func testInitialConsonantsCount() {
        // Should have 26 patterns as per OpenKey
        #expect(VietnameseSpellingRules.initialConsonants.count == 26)
    }

    @Test("Final consonants count")
    func testFinalConsonantsCount() {
        // Should have 8 patterns as per OpenKey
        #expect(VietnameseSpellingRules.finalConsonants.count == 8)
    }

    @Test("Sharp ending consonants count")
    func testSharpEndingConsonantsCount() {
        // c, ch, p, t
        #expect(VietnameseSpellingRules.sharpEndConsonants.count == 4)
    }

    @Test("Base vowels count")
    func testBaseVowelsCount() {
        // a, e, i, o, u, y
        #expect(VietnameseSpellingRules.baseVowels.count == 6)
    }

    @Test("Vowel combinations no-ending set")
    func testVowelCombinationsNoEnding() {
        // These should NOT allow ending consonants
        let noEnding = VietnameseSpellingRules.vowelCombinationsNoEnding
        #expect(noEnding.contains("ai"))
        #expect(noEnding.contains("ao"))
        #expect(noEnding.contains("oi"))
        #expect(noEnding.contains("ui"))
    }

    @Test("Vowel combinations with-ending set")
    func testVowelCombinationsWithEnding() {
        // These SHOULD allow ending consonants
        let withEnding = VietnameseSpellingRules.vowelCombinationsWithEnding
        #expect(withEnding.contains("oa"))
        #expect(withEnding.contains("ua"))
        #expect(withEnding.contains("uy"))
    }
}
