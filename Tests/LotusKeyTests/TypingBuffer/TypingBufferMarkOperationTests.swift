import XCTest
@testable import LotusKey

final class TypingBufferMarkOperationTests: TypingBufferTestCase {

    // MARK: - Mark Operations

    func testApplyMark() {
        var buffer = TypingBuffer()
        buffer.append("b")
        buffer.append("a")

        let success = buffer.applyMark(.acute)
        XCTAssertTrue(success)
        XCTAssertTrue(buffer[1].state.contains(.acute))
    }

    func testApplyMarkNoVowel() {
        var buffer = TypingBuffer()
        buffer.append("b")
        buffer.append("c")

        let success = buffer.applyMark(.acute)
        XCTAssertFalse(success)
    }

    func testApplyMarkReplacesExisting() {
        var buffer = TypingBuffer()
        buffer.append("b")
        buffer.append("a")
        buffer.applyMark(.acute)
        buffer.applyMark(.grave)

        XCTAssertFalse(buffer[1].state.contains(.acute))
        XCTAssertTrue(buffer[1].state.contains(.grave))
    }

    func testApplyModifier() {
        var buffer = TypingBuffer()
        buffer.append("a")

        let success = buffer.applyModifier(.circumflex, at: 0)
        XCTAssertTrue(success)
        XCTAssertTrue(buffer[0].state.contains(.circumflex))
    }

    func testRemoveMark() {
        var buffer = TypingBuffer()
        buffer.append("a")
        buffer.applyMark(.acute)

        let success = buffer.removeMark()
        XCTAssertTrue(success)
        XCTAssertFalse(buffer[0].state.hasToneMark)
    }
}
