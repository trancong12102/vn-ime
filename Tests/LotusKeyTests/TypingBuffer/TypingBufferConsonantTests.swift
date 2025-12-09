import XCTest
@testable import LotusKey

final class TypingBufferConsonantTests: TypingBufferTestCase {

    // MARK: - Ending Consonant Detection

    func testFindEndingConsonant() {
        var buffer = TypingBuffer()
        buffer.append("b")
        buffer.append("a")
        buffer.append("n")

        let ending = buffer.findEndingConsonant()
        XCTAssertNotNil(ending)
        XCTAssertEqual(ending?.pattern, "n")
        XCTAssertEqual(ending?.startIndex, 2)
    }

    func testFindEndingConsonantCH() {
        var buffer = TypingBuffer()
        buffer.append("b")
        buffer.append("a")
        buffer.append("c")
        buffer.append("h")

        let ending = buffer.findEndingConsonant()
        XCTAssertNotNil(ending)
        XCTAssertEqual(ending?.pattern, "ch")
    }

    func testFindEndingConsonantNG() {
        var buffer = TypingBuffer()
        buffer.append("b")
        buffer.append("a")
        buffer.append("n")
        buffer.append("g")

        let ending = buffer.findEndingConsonant()
        XCTAssertNotNil(ending)
        XCTAssertEqual(ending?.pattern, "ng")
    }

    func testNoEndingConsonant() {
        var buffer = TypingBuffer()
        buffer.append("b")
        buffer.append("a")

        let ending = buffer.findEndingConsonant()
        XCTAssertNil(ending)
    }

    func testHasSharpEnding() {
        var buffer = TypingBuffer()
        buffer.append("b")
        buffer.append("a")
        buffer.append("c") // Sharp ending

        XCTAssertTrue(buffer.hasSharpEnding)
    }

    func testHasNoSharpEnding() {
        var buffer = TypingBuffer()
        buffer.append("b")
        buffer.append("a")
        buffer.append("n") // Not a sharp ending

        XCTAssertFalse(buffer.hasSharpEnding)
    }
}
