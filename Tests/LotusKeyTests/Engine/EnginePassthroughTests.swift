import XCTest
@testable import LotusKey

/// Tests for passthrough behavior and flicker prevention
final class EnginePassthroughTests: EngineTestCase {

    // MARK: - Passthrough Behavior Tests (Flicker Prevention)

    /// Normal consonant/vowel sequences should pass through without replacement
    func testPassthroughNormalSequence() {
        // First char always passes through
        let result1 = engine.processKey(keyCode: 0, character: "h", modifiers: 0)
        XCTAssertEqual(result1, .passThrough, "First char 'h' should pass through")

        // Second char (non-transformation) should also pass through
        let result2 = engine.processKey(keyCode: 0, character: "i", modifiers: 0)
        XCTAssertEqual(result2, .passThrough, "Second char 'i' should pass through (no transformation)")

        XCTAssertEqual(engine.currentText, "hi")
    }

    /// "hello" should passthrough all characters (no Vietnamese transformation)
    func testPassthroughHello() {
        let chars = Array("hello")
        var results: [EngineResult] = []

        for char in chars {
            let result = engine.processKey(keyCode: 0, character: char, modifiers: 0)
            results.append(result)
        }

        // All characters should pass through - no backspaces at all
        for (i, result) in results.enumerated() {
            XCTAssertEqual(
                result, .passThrough,
                "Character '\(chars[i])' at index \(i) should pass through, got \(result)"
            )
        }
        XCTAssertEqual(engine.currentText, "hello")
    }

    /// Multiple chars without transformation should all pass through
    func testPassthroughMultipleChars() {
        let result1 = engine.processKey(keyCode: 0, character: "c", modifiers: 0)
        let result2 = engine.processKey(keyCode: 0, character: "o", modifiers: 0)
        let result3 = engine.processKey(keyCode: 0, character: "n", modifiers: 0)

        XCTAssertEqual(result1, .passThrough, "'c' should pass through")
        XCTAssertEqual(result2, .passThrough, "'o' should pass through")
        XCTAssertEqual(result3, .passThrough, "'n' should pass through")
        XCTAssertEqual(engine.currentText, "con")
    }

    /// Tone mark transformation should trigger replace
    func testReplaceForToneMark() {
        _ = engine.processKey(keyCode: 0, character: "a", modifiers: 0)
        let result = engine.processKey(keyCode: 0, character: "s", modifiers: 0)  // tone mark

        if case .replace(let backspaces, let replacement) = result {
            XCTAssertEqual(backspaces, 1, "Should delete 'a'")
            XCTAssertEqual(replacement, "á", "Should produce 'á'")
        } else {
            XCTFail("Tone mark should trigger replace, got \(result)")
        }
    }

    /// Modifier (circumflex) should trigger replace
    func testReplaceForCircumflex() {
        _ = engine.processKey(keyCode: 0, character: "a", modifiers: 0)
        let result = engine.processKey(keyCode: 0, character: "a", modifiers: 0)  // circumflex

        if case .replace(let backspaces, let replacement) = result {
            XCTAssertEqual(backspaces, 1, "Should delete 'a'")
            XCTAssertEqual(replacement, "â", "Should produce 'â'")
        } else {
            XCTFail("Circumflex should trigger replace, got \(result)")
        }
    }

    /// Quick Telex should trigger replace
    func testReplaceForQuickTelex() {
        _ = engine.processKey(keyCode: 0, character: "c", modifiers: 0)
        let result = engine.processKey(keyCode: 0, character: "c", modifiers: 0)  // Quick Telex: cc -> ch

        if case .replace(let backspaces, let replacement) = result {
            XCTAssertEqual(backspaces, 1, "Should delete 'c'")
            XCTAssertEqual(replacement, "ch", "Should produce 'ch'")
        } else {
            XCTFail("Quick Telex should trigger replace, got \(result)")
        }
    }

    /// Grammar auto-correction should trigger replace
    func testReplaceForGrammarCorrection() {
        // Type "thuwon" - grammar corrects "uo" to "ươ" when 'n' is typed
        _ = engine.processKey(keyCode: 0, character: "t", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "h", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "u", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "w", modifiers: 0)  // thư
        _ = engine.processKey(keyCode: 0, character: "o", modifiers: 0)  // thưo

        let result = engine.processKey(keyCode: 0, character: "n", modifiers: 0)  // triggers grammar

        if case .replace(let backspaces, let replacement) = result {
            XCTAssertEqual(backspaces, 4, "Should delete 'thưo'")
            XCTAssertEqual(replacement, "thươn", "Should produce 'thươn'")
        } else {
            XCTFail("Grammar correction should trigger replace, got \(result)")
        }
    }

    /// Adding consonant after tone-marked vowel should pass through (no grammar trigger)
    func testPassthroughAfterToneMark() {
        _ = engine.processKey(keyCode: 0, character: "h", modifiers: 0)  // h
        _ = engine.processKey(keyCode: 0, character: "a", modifiers: 0)  // ha
        _ = engine.processKey(keyCode: 0, character: "f", modifiers: 0)  // hà (replace)

        // Add 'n' - should pass through (not a grammar trigger for this pattern)
        let result = engine.processKey(keyCode: 0, character: "n", modifiers: 0)
        XCTAssertEqual(result, .passThrough, "'n' after 'hà' should pass through")
        XCTAssertEqual(engine.currentText, "hàn")
    }

    /// Consonants that are not grammar triggers should pass through
    func testPassthroughNonGrammarTriggerConsonant() {
        // "thưo" + "b" -> "thưob" (passthrough, 'b' is not a grammar trigger)
        _ = engine.processKey(keyCode: 0, character: "t", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "h", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "u", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "w", modifiers: 0)
        _ = engine.processKey(keyCode: 0, character: "o", modifiers: 0)

        let result = engine.processKey(keyCode: 0, character: "b", modifiers: 0)
        XCTAssertEqual(result, .passThrough, "'b' is not a grammar trigger, should pass through")
    }

    /// Mixed input: verify correct passthrough vs replace sequence
    func testMixedPassthroughAndReplace() {
        // Type "vieets" -> should become "viết" (ê with acute = ế)
        let v = engine.processKey(keyCode: 0, character: "v", modifiers: 0)
        let i = engine.processKey(keyCode: 0, character: "i", modifiers: 0)
        let e = engine.processKey(keyCode: 0, character: "e", modifiers: 0)
        let e2 = engine.processKey(keyCode: 0, character: "e", modifiers: 0)  // circumflex
        let t = engine.processKey(keyCode: 0, character: "t", modifiers: 0)
        let s = engine.processKey(keyCode: 0, character: "s", modifiers: 0)  // tone

        XCTAssertEqual(v, .passThrough, "'v' should pass through")
        XCTAssertEqual(i, .passThrough, "'i' should pass through")
        XCTAssertEqual(e, .passThrough, "'e' should pass through")

        // 'e' (second) triggers circumflex -> replace
        if case .replace(_, let replacement) = e2 {
            XCTAssertEqual(replacement, "viê", "Second 'e' creates circumflex")
        } else {
            XCTFail("Second 'e' should replace, got \(e2)")
        }

        XCTAssertEqual(t, .passThrough, "'t' should pass through")

        // 's' triggers acute tone -> replace (ê + acute = ế)
        if case .replace(_, let replacement) = s {
            XCTAssertEqual(replacement, "viết", "'s' applies acute tone to ê")
        } else {
            XCTFail("'s' should replace with tone, got \(s)")
        }
    }

    /// Tone key without valid vowel should pass through as literal
    func testPassthroughToneKeyWithoutVowel() {
        _ = engine.processKey(keyCode: 0, character: "h", modifiers: 0)
        let result = engine.processKey(keyCode: 0, character: "s", modifiers: 0)

        // 's' has no vowel to apply tone to, so it's added as literal
        XCTAssertEqual(result, .passThrough, "Tone key without vowel should pass through")
        XCTAssertEqual(engine.currentText, "hs")
    }

    // MARK: - Flicker Prevention Integration Tests

    /// Helper to count backspace events in a sequence of engine results
    private func countBackspaces(_ results: [EngineResult]) -> Int {
        return results.reduce(0) { total, result in
            if case .replace(let backspaces, _) = result {
                return total + backspaces
            }
            return total
        }
    }

    /// Helper to process a string and collect all results
    private func processStringCollectingResults(_ input: String) -> [EngineResult] {
        engine.reset()
        return input.map { engine.processKey(keyCode: 0, character: $0, modifiers: 0) }
    }

    /// Typing "nước" should have minimal backspaces (only for transformations)
    func testFlickerPreventionNuoc() {
        // "nuwowcs" -> "nước" (uw = ư, ow = ơ, s = acute)
        // n: passthrough
        // u: passthrough
        // w: replace (horn on u -> ư)
        // o: passthrough
        // w: replace (horn on o -> ơ)
        // c: passthrough
        // s: replace (acute tone)
        let results = processStringCollectingResults("nuwowcs")
        let totalBackspaces = countBackspaces(results)

        XCTAssertEqual(engine.currentText, "nước")
        // Only 3 replace operations should happen (w for ư, w for ơ, s for tone)
        let replaceCount = results.filter { if case .replace = $0 { return true } else { return false } }.count
        XCTAssertEqual(replaceCount, 3, "Should have exactly 3 replace operations")
        XCTAssertLessThanOrEqual(totalBackspaces, 12, "Should have minimal backspaces")
    }

    /// Typing "việt" should have exactly 2 replace operations
    func testFlickerPreventionViet() {
        // "vieets" -> "viết"
        // v: passthrough
        // i: passthrough
        // e: passthrough
        // e: replace (circumflex)
        // t: passthrough
        // s: replace (tone)
        let results = processStringCollectingResults("vieets")

        XCTAssertEqual(engine.currentText, "viết")

        let replaceCount = results.filter { if case .replace = $0 { return true } else { return false } }.count
        XCTAssertEqual(replaceCount, 2, "Should have exactly 2 replace operations")

        let passthroughCount = results.filter { $0 == .passThrough }.count
        XCTAssertEqual(passthroughCount, 4, "Should have 4 passthrough operations (v, i, e, t)")
    }

    /// Typing "việt nam" should track expected backspaces
    func testFlickerPreventionVietNam() {
        // "vieets" -> "viết" (2 replaces)
        // " " -> word break (passthrough)
        // "nam" -> all passthrough (3 passthroughs)
        var results = processStringCollectingResults("vieets")

        // Process space
        let spaceResult = engine.processKey(keyCode: 0, character: " ", modifiers: 0)
        results.append(spaceResult)

        // Process "nam"
        for char in "nam" {
            let result = engine.processKey(keyCode: 0, character: char, modifiers: 0)
            results.append(result)
        }

        // Verify minimal replace operations
        let replaceOps = results.filter { if case .replace = $0 { return true } else { return false } }
        XCTAssertEqual(replaceOps.count, 2, "Should only have 2 replace operations for 'viết nam'")
    }

    /// Simple word "con" should have zero backspaces (all passthrough)
    func testFlickerPreventionSimpleWord() {
        let results = processStringCollectingResults("con")

        XCTAssertEqual(engine.currentText, "con")

        let totalBackspaces = countBackspaces(results)
        XCTAssertEqual(totalBackspaces, 0, "Simple word 'con' should have zero backspaces")

        XCTAssertTrue(results.allSatisfy { $0 == .passThrough }, "All chars should passthrough")
    }

    /// Compare backspace count for "thương" with grammar correction
    func testFlickerPreventionGrammarCorrection() {
        // "thuwong" -> "thương" with grammar auto-correct on 'n'
        let results = processStringCollectingResults("thuwong")

        XCTAssertEqual(engine.currentText, "thương")

        // Expected replaces:
        // w: horn on u (replace)
        // n: grammar correction uo->ươ (replace)
        // g: passthrough
        let replaceOps = results.filter { if case .replace = $0 { return true } else { return false } }
        XCTAssertEqual(replaceOps.count, 2, "Should have 2 replace operations (w for horn, n for grammar)")
    }
}
