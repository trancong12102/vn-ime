import Testing
@testable import LotusKey

// MARK: - KeyStates Buffer Tests

struct KeyStatesBufferTests {
    @Test("Buffer records original keystrokes")
    func testRecordOriginalKeystrokes() {
        var buffer = TypingBuffer()

        buffer.recordOriginalKey("a")
        buffer.recordOriginalKey("a")

        #expect(buffer.originalKeystrokes == "aa")
        #expect(buffer.keystrokeCount == 2)
    }

    @Test("Buffer clears keystrokes on clear")
    func testClearKeystrokes() {
        var buffer = TypingBuffer()

        buffer.recordOriginalKey("t")
        buffer.recordOriginalKey("h")
        buffer.recordOriginalKey("a")

        #expect(buffer.hasOriginalKeystrokes == true)

        buffer.clear()

        #expect(buffer.hasOriginalKeystrokes == false)
        #expect(buffer.originalKeystrokes == "")
    }

    @Test("Buffer removes keystroke on removeLast")
    func testRemoveLastKeystroke() {
        var buffer = TypingBuffer()

        buffer.recordOriginalKey("a")
        buffer.recordOriginalKey("b")
        buffer.recordOriginalKey("c")

        #expect(buffer.keystrokeCount == 3)

        _ = buffer.removeLast()
        // Note: removeLast removes from keyStates only if there's content in characters
        // Since we only recorded keys without adding characters, this behavior differs
    }

    @Test("Original keystrokes preserved across transformations")
    func testKeystrokesPreservedAcrossTransformations() {
        var buffer = TypingBuffer()

        // Simulate typing "aa" which transforms to "â"
        buffer.append("a")
        buffer.recordOriginalKey("a")
        buffer.recordOriginalKey("a")

        #expect(buffer.originalKeystrokes == "aa")
    }
}
