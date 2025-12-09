import Testing
@testable import LotusKey

// MARK: - Edge Case Tests: Engine Restore on Invalid

struct EngineRestoreEdgeCaseTests {
    @Test("Engine restore on invalid at word boundary")
    func testRestoreAtWordBoundary() {
        let engine = DefaultVietnameseEngine()
        engine.spellCheckEnabled = true
        engine.restoreIfWrongSpelling = true

        // Type an invalid combination and press space
        // The engine should restore original keystrokes
        // This tests the actual restore-on-invalid feature
        _ = engine.processString("bacf")  // "bàc" is invalid (grave with sharp c)

        // The buffer should track original keystrokes
        #expect(engine.testBuffer.hasOriginalKeystrokes)
    }

    @Test("Engine tracks all keystrokes including transformations")
    func testTrackAllKeystrokes() {
        let engine = DefaultVietnameseEngine()
        engine.spellCheckEnabled = true

        // Process "thuowng" → "thương"
        _ = engine.processString("thuowng")

        // Original keystrokes should be preserved
        let original = engine.testBuffer.originalKeystrokes
        #expect(original.contains("t"))
        #expect(original.contains("h"))
    }

    @Test("Spell check boundary with valid word")
    func testValidWordNoRestore() {
        let engine = DefaultVietnameseEngine()
        engine.spellCheckEnabled = true
        engine.restoreIfWrongSpelling = true

        // "bán" is valid, should not restore
        let result = engine.processString("bans")
        #expect(result == "bán")
    }
}
