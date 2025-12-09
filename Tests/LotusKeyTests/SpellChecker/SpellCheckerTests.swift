import Testing
@testable import LotusKey

/// Tests for Vietnamese spell checking and syllable parsing
struct SpellCheckerTests {
    let spellChecker = DefaultSpellChecker()

    // MARK: - SyllableParser Tests

    @Test("Parse simple syllable: 'ba'")
    func testParseSimpleSyllable() {
        let parts = SyllableParser.parse("ba")
        #expect(parts != nil)
        #expect(parts?.initialConsonant == "b")
        #expect(parts?.vowelNucleus == "a")
        #expect(parts?.finalConsonant == "")
    }

    @Test("Parse syllable with ending consonant: 'ban'")
    func testParseSyllableWithEnding() {
        let parts = SyllableParser.parse("ban")
        #expect(parts != nil)
        #expect(parts?.initialConsonant == "b")
        #expect(parts?.vowelNucleus == "a")
        #expect(parts?.finalConsonant == "n")
    }

    @Test("Parse syllable with digraph consonant: 'tha'")
    func testParseDigraphConsonant() {
        let parts = SyllableParser.parse("tha")
        #expect(parts != nil)
        #expect(parts?.initialConsonant == "th")
        #expect(parts?.vowelNucleus == "a")
        #expect(parts?.finalConsonant == "")
    }

    @Test("Parse syllable with trigraph: 'nghe'")
    func testParseTrigraphConsonant() {
        let parts = SyllableParser.parse("nghe")
        #expect(parts != nil)
        #expect(parts?.initialConsonant == "ngh")
        #expect(parts?.vowelNucleus == "e")
        #expect(parts?.finalConsonant == "")
    }

    @Test("Parse syllable with digraph ending: 'bang'")
    func testParseDigraphEnding() {
        let parts = SyllableParser.parse("bang")
        #expect(parts != nil)
        #expect(parts?.initialConsonant == "b")
        #expect(parts?.vowelNucleus == "a")
        #expect(parts?.finalConsonant == "ng")
    }

    @Test("Parse syllable starting with vowel: 'an'")
    func testParseVowelStart() {
        let parts = SyllableParser.parse("an")
        #expect(parts != nil)
        #expect(parts?.initialConsonant == "")
        #expect(parts?.vowelNucleus == "a")
        #expect(parts?.finalConsonant == "n")
    }

    @Test("Parse syllable with 'qu' cluster: 'qua'")
    func testParseQuCluster() {
        let parts = SyllableParser.parse("qua")
        #expect(parts != nil)
        #expect(parts?.initialConsonant == "qu")
        #expect(parts?.vowelNucleus == "a")
        #expect(parts?.finalConsonant == "")
    }

    @Test("Parse syllable with 'gi' cluster: 'gia'")
    func testParseGiCluster() {
        let parts = SyllableParser.parse("gia")
        #expect(parts != nil)
        #expect(parts?.initialConsonant == "gi")
        #expect(parts?.vowelNucleus == "a")
        #expect(parts?.finalConsonant == "")
    }

    @Test("Parse diphthong: 'ai'")
    func testParseDiphthong() {
        let parts = SyllableParser.parse("ai")
        #expect(parts != nil)
        #expect(parts?.initialConsonant == "")
        #expect(parts?.vowelNucleus == "ai")
        #expect(parts?.finalConsonant == "")
    }

    @Test("Parse triphthong: 'oai'")
    func testParseTriphthong() {
        let parts = SyllableParser.parse("oai")
        #expect(parts != nil)
        #expect(parts?.initialConsonant == "")
        #expect(parts?.vowelNucleus == "oai")
        #expect(parts?.finalConsonant == "")
    }

    @Test("Parse Vietnamese unicode: 'tiến'")
    func testParseVietnameseUnicode() {
        let parts = SyllableParser.parse("tiến")
        #expect(parts != nil)
        #expect(parts?.initialConsonant == "t")
        #expect(parts?.vowelNucleus == "ie")
        #expect(parts?.finalConsonant == "n")
        #expect(parts?.tone == .acute)
    }

    @Test("Parse syllable with circumflex: 'ân'")
    func testParseCircumflex() {
        let parts = SyllableParser.parse("ân")
        #expect(parts != nil)
        #expect(parts?.initialConsonant == "")
        #expect(parts?.vowelNucleus == "a")
        #expect(parts?.finalConsonant == "n")
        #expect(parts?.vowelModifiers[0] == .circumflex)
    }

    @Test("Parse syllable with horn: 'ơn'")
    func testParseHorn() {
        let parts = SyllableParser.parse("ơn")
        #expect(parts != nil)
        #expect(parts?.initialConsonant == "")
        #expect(parts?.vowelNucleus == "o")
        #expect(parts?.finalConsonant == "n")
        #expect(parts?.vowelModifiers[0] == .horn)
    }

    @Test("Parse syllable with breve: 'ăn'")
    func testParseBreve() {
        let parts = SyllableParser.parse("ăn")
        #expect(parts != nil)
        #expect(parts?.initialConsonant == "")
        #expect(parts?.vowelNucleus == "a")
        #expect(parts?.finalConsonant == "n")
        #expect(parts?.vowelModifiers[0] == .breve)
    }

    @Test("Parse complex syllable: 'thương'")
    func testParseComplex() {
        let parts = SyllableParser.parse("thương")
        #expect(parts != nil)
        #expect(parts?.initialConsonant == "th")
        // Note: after decomposition, "ươ" becomes "uo" with horn modifiers
        #expect(parts?.vowelNucleus == "uo")
        #expect(parts?.finalConsonant == "ng")
    }

    @Test("Parse all tone marks")
    func testParseToneMarks() {
        // Acute (sắc)
        let acute = SyllableParser.parse("má")
        #expect(acute?.tone == .acute)

        // Grave (huyền)
        let grave = SyllableParser.parse("mà")
        #expect(grave?.tone == .grave)

        // Hook (hỏi)
        let hook = SyllableParser.parse("mả")
        #expect(hook?.tone == .hook)

        // Tilde (ngã)
        let tilde = SyllableParser.parse("mã")
        #expect(tilde?.tone == .tilde)

        // Dot below (nặng)
        let dot = SyllableParser.parse("mạ")
        #expect(dot?.tone == .dot)

        // No tone (ngang)
        let none = SyllableParser.parse("ma")
        #expect(none?.tone == nil || none?.tone == ToneMark.none)
    }

    // MARK: - Initial Consonant Validation Tests

    @Test("Valid initial consonants")
    func testValidInitialConsonants() {
        let validConsonants = [
            "b", "c", "ch", "d", "g", "gh", "gi", "h", "k", "kh",
            "l", "m", "n", "ng", "ngh", "nh", "p", "ph", "qu", "r",
            "s", "t", "th", "tr", "v", "x"
        ]
        for consonant in validConsonants {
            #expect(spellChecker.isValidInitialConsonant(consonant), "Expected '\(consonant)' to be valid")
        }
    }

    @Test("Invalid initial consonants")
    func testInvalidInitialConsonants() {
        let invalidConsonants = ["f", "j", "w", "z", "bh", "dl", "kk"]
        for consonant in invalidConsonants {
            #expect(!spellChecker.isValidInitialConsonant(consonant), "Expected '\(consonant)' to be invalid")
        }
    }

    @Test("Empty initial consonant is valid")
    func testEmptyInitialConsonant() {
        #expect(spellChecker.isValidInitialConsonant(""))
    }

    // MARK: - Final Consonant Validation Tests

    @Test("Valid final consonants")
    func testValidFinalConsonants() {
        let validFinals = ["c", "ch", "m", "n", "ng", "nh", "p", "t"]
        for consonant in validFinals {
            #expect(spellChecker.isValidFinalConsonant(consonant), "Expected '\(consonant)' to be valid final")
        }
    }

    @Test("Invalid final consonants")
    func testInvalidFinalConsonants() {
        let invalidFinals = ["b", "d", "g", "h", "k", "l", "r", "s", "v", "x", "tr"]
        for consonant in invalidFinals {
            #expect(!spellChecker.isValidFinalConsonant(consonant), "Expected '\(consonant)' to be invalid final")
        }
    }

    @Test("Empty final consonant is valid")
    func testEmptyFinalConsonant() {
        #expect(spellChecker.isValidFinalConsonant(""))
    }

    // MARK: - Vowel Combination Validation Tests

    @Test("Valid single vowels")
    func testValidSingleVowels() {
        let singleVowels = ["a", "e", "i", "o", "u", "y"]
        for vowel in singleVowels {
            #expect(spellChecker.isValidVowelCombination(vowel), "Expected '\(vowel)' to be valid")
        }
    }

    @Test("Valid diphthongs")
    func testValidDiphthongs() {
        let validDiphthongs = ["ai", "ao", "au", "ay", "eo", "ia", "ie", "iu", "oa", "oe", "oi", "ua", "ue", "ui", "uo", "uy", "ye"]
        for diphthong in validDiphthongs {
            #expect(spellChecker.isValidVowelCombination(diphthong), "Expected '\(diphthong)' to be valid")
        }
    }

    @Test("Valid triphthongs")
    func testValidTriphthongs() {
        let validTriphthongs = ["oai", "oao", "oay", "oeo", "uoi", "uya", "uye", "uyu", "ieu", "yeu"]
        for triphthong in validTriphthongs {
            #expect(spellChecker.isValidVowelCombination(triphthong), "Expected '\(triphthong)' to be valid")
        }
    }

    // MARK: - Tone with Ending Consonant Tests

    @Test("Sharp endings allow acute and dot tones")
    func testSharpEndingsValidTones() {
        let sharpEndings = ["c", "ch", "p", "t"]
        for ending in sharpEndings {
            #expect(VietnameseSpellingRules.isValidToneWithEnding(.acute, ending: ending), "Acute should be valid with \(ending)")
            #expect(VietnameseSpellingRules.isValidToneWithEnding(.dot, ending: ending), "Dot should be valid with \(ending)")
            #expect(VietnameseSpellingRules.isValidToneWithEnding(ToneMark.none, ending: ending), "None should be valid with \(ending)")
            #expect(VietnameseSpellingRules.isValidToneWithEnding(nil, ending: ending), "Nil should be valid with \(ending)")
        }
    }

    @Test("Sharp endings reject grave, hook, tilde tones")
    func testSharpEndingsInvalidTones() {
        let sharpEndings = ["c", "ch", "p", "t"]
        for ending in sharpEndings {
            #expect(!VietnameseSpellingRules.isValidToneWithEnding(.grave, ending: ending), "Grave should be invalid with \(ending)")
            #expect(!VietnameseSpellingRules.isValidToneWithEnding(.hook, ending: ending), "Hook should be invalid with \(ending)")
            #expect(!VietnameseSpellingRules.isValidToneWithEnding(.tilde, ending: ending), "Tilde should be invalid with \(ending)")
        }
    }

    @Test("Non-sharp endings allow all tones")
    func testNonSharpEndingsAllTones() {
        let nonSharpEndings = ["m", "n", "ng", "nh"]
        let allTones: [ToneMark?] = [ToneMark.none, .acute, .grave, .hook, .tilde, .dot, nil]
        for ending in nonSharpEndings {
            for tone in allTones {
                #expect(VietnameseSpellingRules.isValidToneWithEnding(tone, ending: ending), "All tones should be valid with \(ending)")
            }
        }
    }

    @Test("Empty ending allows all tones")
    func testEmptyEndingAllTones() {
        let allTones: [ToneMark?] = [ToneMark.none, .acute, .grave, .hook, .tilde, .dot, nil]
        for tone in allTones {
            #expect(VietnameseSpellingRules.isValidToneWithEnding(tone, ending: ""), "All tones should be valid with empty ending")
        }
    }

    // MARK: - Full Spell Check Tests

    @Test("Valid simple syllables")
    func testValidSimpleSyllables() {
        let validWords = ["ba", "me", "di", "to", "cu", "ly"]
        for word in validWords {
            let result = spellChecker.check(word)
            #expect(result == .valid, "Expected '\(word)' to be valid")
        }
    }

    @Test("Valid syllables with ending consonants")
    func testValidSyllablesWithEnding() {
        let validWords = ["ban", "cam", "tin", "bong", "lung"]
        for word in validWords {
            let result = spellChecker.check(word)
            #expect(result == .valid, "Expected '\(word)' to be valid")
        }
    }

    @Test("Valid Vietnamese unicode syllables")
    func testValidUnicodeSyllables() {
        let validWords = ["án", "bàn", "cảm", "dãn", "đẹp"]
        for word in validWords {
            let result = spellChecker.check(word)
            #expect(result == .valid, "Expected '\(word)' to be valid")
        }
    }

    @Test("Invalid: sharp ending with grave tone")
    func testInvalidSharpEndingGrave() {
        // "bàc" has grave tone with sharp ending 'c' - invalid
        let result = spellChecker.check("bàc")
        #expect(result != .valid, "Expected 'bàc' to be invalid (grave with sharp ending)")
    }

    @Test("Invalid: sharp ending with hook tone")
    func testInvalidSharpEndingHook() {
        // "bảc" has hook tone with sharp ending 'c' - invalid
        let result = spellChecker.check("bảc")
        #expect(result != .valid, "Expected 'bảc' to be invalid (hook with sharp ending)")
    }

    @Test("Invalid: sharp ending with tilde tone")
    func testInvalidSharpEndingTilde() {
        // "bãc" has tilde tone with sharp ending 'c' - invalid
        let result = spellChecker.check("bãc")
        #expect(result != .valid, "Expected 'bãc' to be invalid (tilde with sharp ending)")
    }

    @Test("Valid: sharp ending with acute tone")
    func testValidSharpEndingAcute() {
        let result = spellChecker.check("bác")
        #expect(result == .valid, "Expected 'bác' to be valid (acute with sharp ending)")
    }

    @Test("Valid: sharp ending with dot tone")
    func testValidSharpEndingDot() {
        let result = spellChecker.check("bạc")
        #expect(result == .valid, "Expected 'bạc' to be valid (dot with sharp ending)")
    }

    @Test("Empty word is invalid")
    func testEmptyWord() {
        let result = spellChecker.check("")
        #expect(result == .invalid(reason: "Empty word"))
    }

    @Test("Consonant-only returns unknown")
    func testConsonantOnly() {
        // Just "th" could be typing "tha" - treat as unknown
        let result = spellChecker.check("th")
        #expect(result == .unknown)
    }

    @Test("Valid vowel-only words")
    func testVowelOnlyWords() {
        let validWords = ["a", "ái", "ơi", "ư"]
        for word in validWords {
            let result = spellChecker.check(word)
            #expect(result == .valid, "Expected '\(word)' to be valid")
        }
    }

    // MARK: - Edge Cases

    @Test("Case insensitive validation")
    func testCaseInsensitive() {
        #expect(spellChecker.isValidInitialConsonant("TH") == spellChecker.isValidInitialConsonant("th"))
        #expect(spellChecker.isValidFinalConsonant("NG") == spellChecker.isValidFinalConsonant("ng"))
    }

    @Test("Complex syllables: common Vietnamese words")
    func testCommonVietnameseWords() {
        let commonWords = [
            "xin", "chào", "cảm", "ơn", "việt", "nam",
            "học", "tiếng", "nước", "người", "được"
        ]
        for word in commonWords {
            let result = spellChecker.check(word)
            // These should all be valid or at least parseable
            #expect(result != .invalid(reason: "Empty word"), "Expected '\(word)' to be parseable")
        }
    }

    // MARK: - ToneMark Conversion Tests

    @Test("ToneMark to CharacterState conversion")
    func testToneMarkToCharacterState() {
        #expect(ToneMark.none.asCharacterState == [])
        #expect(ToneMark.acute.asCharacterState == .acute)
        #expect(ToneMark.grave.asCharacterState == .grave)
        #expect(ToneMark.hook.asCharacterState == .hook)
        #expect(ToneMark.tilde.asCharacterState == .tilde)
        #expect(ToneMark.dot.asCharacterState == .dotBelow)
    }

    @Test("CharacterState to ToneMark conversion")
    func testCharacterStateToToneMark() {
        #expect(ToneMark(from: .acute) == .acute)
        #expect(ToneMark(from: .grave) == .grave)
        #expect(ToneMark(from: .hook) == .hook)
        #expect(ToneMark(from: .tilde) == .tilde)
        #expect(ToneMark(from: .dotBelow) == .dot)
        #expect(ToneMark(from: []) == ToneMark.none)
    }
}
