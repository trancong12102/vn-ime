import XCTest
@testable import LotusKey

final class TypingBufferSpellValidationTests: TypingBufferTestCase {

    // MARK: - Spell Validation

    func testValidVietnameseSyllable() {
        var buffer = TypingBuffer()
        buffer.append("b")
        buffer.append("a")
        buffer.append("n")

        XCTAssertTrue(buffer.isValidVietnameseSyllable())
    }

    func testInvalidToneWithSharpEnding() {
        // "bàc" is invalid - huyền (`) cannot be with 'c' ending
        var buffer = TypingBuffer()
        buffer.append("b")
        var typedA = TypedCharacter(character: "a")
        typedA.state.insert(.grave) // huyền
        buffer.append(typedA)
        buffer.append("c")

        XCTAssertFalse(buffer.isValidVietnameseSyllable())
    }

    func testValidToneWithSharpEnding() {
        // "bác" is valid - sắc (´) can be with 'c' ending
        var buffer = TypingBuffer()
        buffer.append("b")
        var typedA = TypedCharacter(character: "a")
        typedA.state.insert(.acute) // sắc
        buffer.append(typedA)
        buffer.append("c")

        XCTAssertTrue(buffer.isValidVietnameseSyllable())
    }
}
