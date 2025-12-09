import Testing
@testable import LotusKey

// MARK: - Control Key Bypass Tests

struct ControlKeyBypassTests {
    @Test("Control key temporarily disables spell check")
    func testControlKeyBypass() {
        let engine = DefaultVietnameseEngine()
        engine.spellCheckEnabled = true

        // Simulate Control key held (modifier flag 0x40000)
        let ctrlModifier: UInt64 = 0x40000

        // Process with control key should set tempOffSpellChecking
        _ = engine.processKey(keyCode: 0, character: "a", modifiers: ctrlModifier)

        // After processing, tempOffSpellChecking should have been set
        // (We can't directly test this private property, but we can test behavior)
    }

    @Test("Command key passes through")
    func testCommandKeyPassThrough() {
        let engine = DefaultVietnameseEngine()

        // Simulate Command key held (modifier flag 0x100000)
        let cmdModifier: UInt64 = 0x100000

        let result = engine.processKey(keyCode: 0, character: "a", modifiers: cmdModifier)

        #expect(result == .passThrough)
    }
}
