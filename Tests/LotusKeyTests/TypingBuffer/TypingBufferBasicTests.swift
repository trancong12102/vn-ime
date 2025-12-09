import XCTest
@testable import LotusKey

final class TypingBufferBasicTests: TypingBufferTestCase {

    // MARK: - Basic Operations

    func testEmptyBuffer() {
        let buffer = TypingBuffer()
        XCTAssertTrue(buffer.isEmpty)
        XCTAssertEqual(buffer.count, 0)
        XCTAssertFalse(buffer.isFull)
    }

    func testAppendCharacter() {
        var buffer = TypingBuffer()
        let success = buffer.append("a")
        XCTAssertTrue(success)
        XCTAssertEqual(buffer.count, 1)
        XCTAssertFalse(buffer.isEmpty)
    }

    func testAppendTypedCharacter() {
        var buffer = TypingBuffer()
        let typed = TypedCharacter(character: "a", caps: true)
        buffer.append(typed)
        XCTAssertEqual(buffer.count, 1)
        XCTAssertTrue(buffer[0].isUppercase)
    }

    func testRemoveLast() {
        var buffer = TypingBuffer()
        buffer.append("a")
        buffer.append("b")

        let removed = buffer.removeLast()
        XCTAssertEqual(removed?.baseCharacter, "b")
        XCTAssertEqual(buffer.count, 1)
    }

    func testRemoveLastFromEmpty() {
        var buffer = TypingBuffer()
        let removed = buffer.removeLast()
        XCTAssertNil(removed)
    }

    func testClear() {
        var buffer = TypingBuffer()
        buffer.append("a")
        buffer.append("b")
        buffer.clear()
        XCTAssertTrue(buffer.isEmpty)
        XCTAssertEqual(buffer.count, 0)
    }

    func testMaxCapacity() {
        var buffer = TypingBuffer()
        for i in 0..<TypingBuffer.maxCapacity {
            let char = Character(UnicodeScalar(97 + (i % 26))!)
            buffer.append(char)
        }
        XCTAssertTrue(buffer.isFull)
        XCTAssertEqual(buffer.count, 64)

        // Should not add more
        let success = buffer.append("x")
        XCTAssertFalse(success)
        XCTAssertEqual(buffer.count, 64)
    }

    // MARK: - Collection Conformance

    func testSubscript() {
        var buffer = TypingBuffer()
        buffer.append("a")
        buffer.append("b")

        XCTAssertEqual(buffer[0].baseCharacter, "a")
        XCTAssertEqual(buffer[1].baseCharacter, "b")
    }

    func testIteration() {
        var buffer = TypingBuffer()
        buffer.append("a")
        buffer.append("b")
        buffer.append("c")

        var chars: [Character] = []
        for typed in buffer {
            if let char = typed.baseCharacter {
                chars.append(char)
            }
        }
        XCTAssertEqual(chars, ["a", "b", "c"])
    }
}
