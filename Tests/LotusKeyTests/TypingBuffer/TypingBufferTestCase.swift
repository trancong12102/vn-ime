import XCTest
@testable import LotusKey

/// Base test case for TypingBuffer tests
class TypingBufferTestCase: XCTestCase {
    var buffer: TypingBuffer!

    override func setUp() {
        super.setUp()
        buffer = TypingBuffer()
    }

    override func tearDown() {
        buffer = nil
        super.tearDown()
    }
}
