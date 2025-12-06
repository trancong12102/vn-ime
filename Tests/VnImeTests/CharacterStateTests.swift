import XCTest
@testable import VnIme

final class CharacterStateTests: XCTestCase {

    // MARK: - Basic Operations

    func testEmptyState() {
        let state = CharacterState()
        XCTAssertEqual(state.rawValue, 0)
        XCTAssertFalse(state.hasToneMark)
        XCTAssertFalse(state.hasModifier)
    }

    func testCapsFlag() {
        var state = CharacterState()
        state.insert(.caps)
        XCTAssertTrue(state.contains(.caps))
        XCTAssertEqual(state.rawValue, 1 << 16)
    }

    // MARK: - Tone Modifiers

    func testCircumflexModifier() {
        var state = CharacterState()
        state.insert(.circumflex)
        XCTAssertTrue(state.contains(.circumflex))
        XCTAssertTrue(state.hasModifier)
        XCTAssertEqual(state.rawValue, 1 << 17)
    }

    func testHornOrBreveModifier() {
        var state = CharacterState()
        state.insert(.hornOrBreve)
        XCTAssertTrue(state.contains(.hornOrBreve))
        XCTAssertTrue(state.hasModifier)
        XCTAssertEqual(state.rawValue, 1 << 18)
    }

    // MARK: - Tone Marks

    func testAcuteMark() {
        var state = CharacterState()
        state.insert(.acute)
        XCTAssertTrue(state.contains(.acute))
        XCTAssertTrue(state.hasToneMark)
        XCTAssertEqual(state.toneMark, .acute)
    }

    func testGraveMark() {
        var state = CharacterState()
        state.insert(.grave)
        XCTAssertTrue(state.contains(.grave))
        XCTAssertTrue(state.hasToneMark)
        XCTAssertEqual(state.toneMark, .grave)
    }

    func testHookMark() {
        var state = CharacterState()
        state.insert(.hook)
        XCTAssertTrue(state.contains(.hook))
        XCTAssertTrue(state.hasToneMark)
        XCTAssertEqual(state.toneMark, .hook)
    }

    func testTildeMark() {
        var state = CharacterState()
        state.insert(.tilde)
        XCTAssertTrue(state.contains(.tilde))
        XCTAssertTrue(state.hasToneMark)
        XCTAssertEqual(state.toneMark, .tilde)
    }

    func testDotBelowMark() {
        var state = CharacterState()
        state.insert(.dotBelow)
        XCTAssertTrue(state.contains(.dotBelow))
        XCTAssertTrue(state.hasToneMark)
        XCTAssertEqual(state.toneMark, .dotBelow)
    }

    // MARK: - Mutation Helpers

    func testClearToneMark() {
        var state: CharacterState = [.acute, .circumflex]
        state.clearToneMark()
        XCTAssertFalse(state.hasToneMark)
        XCTAssertTrue(state.hasModifier) // Modifier should remain
    }

    func testClearModifier() {
        var state: CharacterState = [.acute, .circumflex]
        state.clearModifier()
        XCTAssertTrue(state.hasToneMark) // Tone mark should remain
        XCTAssertFalse(state.hasModifier)
    }

    func testSetToneMark() {
        var state: CharacterState = [.acute]
        state.setToneMark(.grave)
        XCTAssertFalse(state.contains(.acute))
        XCTAssertTrue(state.contains(.grave))
    }

    func testSetModifier() {
        var state: CharacterState = [.circumflex]
        state.setModifier(.hornOrBreve)
        XCTAssertFalse(state.contains(.circumflex))
        XCTAssertTrue(state.contains(.hornOrBreve))
    }

    // MARK: - Combined States

    func testCombinedState() {
        let state: CharacterState = [.caps, .circumflex, .acute]
        XCTAssertTrue(state.contains(.caps))
        XCTAssertTrue(state.contains(.circumflex))
        XCTAssertTrue(state.contains(.acute))
        XCTAssertTrue(state.hasModifier)
        XCTAssertTrue(state.hasToneMark)
    }

    func testBitLayout() {
        // Verify exact bit positions match original OpenKey
        XCTAssertEqual(CharacterState.caps.rawValue, 0x10000)         // bit 16
        XCTAssertEqual(CharacterState.circumflex.rawValue, 0x20000)   // bit 17
        XCTAssertEqual(CharacterState.hornOrBreve.rawValue, 0x40000)  // bit 18
        XCTAssertEqual(CharacterState.acute.rawValue, 0x80000)        // bit 19
        XCTAssertEqual(CharacterState.grave.rawValue, 0x100000)       // bit 20
        XCTAssertEqual(CharacterState.hook.rawValue, 0x200000)        // bit 21
        XCTAssertEqual(CharacterState.tilde.rawValue, 0x400000)       // bit 22
        XCTAssertEqual(CharacterState.dotBelow.rawValue, 0x800000)    // bit 23
    }

    // MARK: - Description

    func testDescription() {
        let state: CharacterState = [.caps, .acute]
        let description = state.description
        XCTAssertTrue(description.contains("caps"))
        XCTAssertTrue(description.contains("sắc"))
    }
}
