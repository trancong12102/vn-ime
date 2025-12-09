import XCTest
@testable import LotusKey

final class TypingBufferUnicodeTests: TypingBufferTestCase {

    // MARK: - Unicode Output

    func testToUnicodeStringBasic() {
        var buffer = TypingBuffer()
        buffer.append("a")
        buffer.append("b")
        buffer.append("c")

        XCTAssertEqual(buffer.toUnicodeString(), "abc")
    }

    func testToUnicodeStringWithMark() {
        var buffer = TypingBuffer()
        buffer.append("a")
        buffer.applyMark(.acute)

        XCTAssertEqual(buffer.toUnicodeString(), "á")
    }

    func testToUnicodeStringWithModifier() {
        var buffer = TypingBuffer()
        buffer.append("a")
        buffer.applyModifier(.circumflex, at: 0)

        XCTAssertEqual(buffer.toUnicodeString(), "â")
    }

    func testToUnicodeStringWithModifierAndMark() {
        var buffer = TypingBuffer()
        buffer.append("a")
        buffer.applyModifier(.circumflex, at: 0)
        buffer.applyMark(.acute)

        XCTAssertEqual(buffer.toUnicodeString(), "ấ")
    }

    func testToUnicodeStringCaps() {
        var buffer = TypingBuffer()
        let typed = TypedCharacter(character: "A")
        buffer.append(typed)

        XCTAssertEqual(buffer.toUnicodeString(), "A")
    }

    func testToUnicodeStringCapsWithMark() {
        var buffer = TypingBuffer()
        var typed = TypedCharacter(character: "A")
        typed.state.insert(.acute)
        buffer.append(typed)

        XCTAssertEqual(buffer.toUnicodeString(), "Á")
    }
}
