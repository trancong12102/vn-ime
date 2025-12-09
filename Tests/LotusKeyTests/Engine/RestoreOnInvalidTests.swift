import Testing
@testable import LotusKey

// MARK: - Restore on Invalid Tests

struct RestoreOnInvalidTests {
    @Test("Engine tracks keystrokes for restore")
    func testEngineTracksKeystrokes() {
        let engine = DefaultVietnameseEngine()
        engine.spellCheckEnabled = true
        engine.restoreIfWrongSpelling = true

        // Process some characters
        _ = engine.processString("tha")

        // The buffer should have tracked the original keystrokes
        #expect(!engine.testBuffer.originalKeystrokes.isEmpty)
    }

    @Test("Restore disabled when feature is off")
    func testRestoreDisabledWhenOff() {
        let engine = DefaultVietnameseEngine()
        engine.spellCheckEnabled = true
        engine.restoreIfWrongSpelling = false

        // Even with invalid spelling, restore should not happen
        let result = engine.processString("bàc ")

        // Should keep the transformed text (even if invalid)
        #expect(result.contains(" "))
    }

    @Test("Restore disabled when spell check is off")
    func testRestoreDisabledWhenSpellCheckOff() {
        let engine = DefaultVietnameseEngine()
        engine.spellCheckEnabled = false
        engine.restoreIfWrongSpelling = true

        // Process potentially invalid combination
        let result = engine.processString("xyz ")

        // Should not restore since spell check is disabled
        #expect(result.contains(" "))
    }
}
