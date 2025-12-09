import XCTest
@testable import LotusKey

/// Tests for Quick Telex shortcuts (cc=ch, gg=gi, nn=ng, tt=th)
final class EngineQuickTelexTests: EngineTestCase {

    // MARK: - Quick Telex Integration Tests

    func testQuickTelexCC() {
        engine.quickTelex.isEnabled = true
        let result = engine.processString("cc")
        XCTAssertEqual(result, "ch", "cc with Quick Telex enabled should produce 'ch'")
    }

    func testQuickTelexGG() {
        engine.quickTelex.isEnabled = true
        let result = engine.processString("gg")
        XCTAssertEqual(result, "gi", "gg with Quick Telex enabled should produce 'gi'")
    }

    func testQuickTelexNN() {
        engine.quickTelex.isEnabled = true
        let result = engine.processString("nn")
        XCTAssertEqual(result, "ng", "nn with Quick Telex enabled should produce 'ng'")
    }

    func testQuickTelexTT() {
        engine.quickTelex.isEnabled = true
        let result = engine.processString("tt")
        XCTAssertEqual(result, "th", "tt with Quick Telex enabled should produce 'th'")
    }

    func testQuickTelexDisabled() {
        engine.quickTelex.isEnabled = false
        let result = engine.processString("cc")
        XCTAssertEqual(result, "cc", "cc with Quick Telex disabled should stay 'cc'")
    }

    func testQuickTelexProcessShortcutDirectlyWhenDisabled() {
        // Test processShortcut directly to cover the guard else branch
        engine.quickTelex.isEnabled = false
        let result = engine.quickTelex.processShortcut("c", previousCharacter: "c")
        XCTAssertNil(result, "processShortcut should return nil when disabled")
    }

    func testQuickTelexProcessShortcutWithNilPreviousCharacter() {
        // Test processShortcut with nil previousCharacter to cover the guard else branch
        engine.quickTelex.isEnabled = true
        let result = engine.quickTelex.processShortcut("c", previousCharacter: nil)
        XCTAssertNil(result, "processShortcut should return nil when previousCharacter is nil")
    }

    func testQuickTelexInWord() {
        engine.quickTelex.isEnabled = true
        let result = engine.processString("cca")
        XCTAssertEqual(result, "cha", "cca with Quick Telex should produce 'cha'")
    }
}
