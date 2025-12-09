import XCTest
@testable import LotusKey

final class TypingBufferVowelTests: TypingBufferTestCase {

    // MARK: - Vowel Analysis

    func testFindVowelPositions() {
        var buffer = TypingBuffer()
        buffer.append("h")
        buffer.append("o")
        buffer.append("a")

        let positions = buffer.findVowelPositions()
        XCTAssertEqual(positions, [1, 2]) // 'o' at 1, 'a' at 2
    }

    func testFindVowelPositionsNoVowels() {
        var buffer = TypingBuffer()
        buffer.append("b")
        buffer.append("c")

        let positions = buffer.findVowelPositions()
        XCTAssertTrue(positions.isEmpty)
    }

    // MARK: - qu-/gi- Consonant Cluster Handling

    func testQuConsonantCluster() {
        // In "qua", 'u' is part of 'qu' consonant, only 'a' is vowel
        var buffer = TypingBuffer()
        buffer.append("q")
        buffer.append("u")
        buffer.append("a")

        let positions = buffer.findVowelPositions()
        XCTAssertEqual(positions, [2]) // Only 'a' should be detected as vowel
    }

    func testQuConsonantClusterMarkPosition() {
        // "qua" -> mark should go on 'a' (the only real vowel)
        var buffer = TypingBuffer()
        buffer.append("q")
        buffer.append("u")
        buffer.append("a")

        let markPos = buffer.findMarkPosition()
        XCTAssertEqual(markPos, 2) // Position of 'a'
    }

    func testQuyMarkPosition() {
        // "quy" -> 'u' is part of 'qu', so only 'y' is vowel
        var buffer = TypingBuffer()
        buffer.append("q")
        buffer.append("u")
        buffer.append("y")

        let positions = buffer.findVowelPositions()
        XCTAssertEqual(positions, [2]) // Only 'y' should be vowel

        let markPos = buffer.findMarkPosition()
        XCTAssertEqual(markPos, 2) // Mark on 'y'
    }

    func testGiConsonantCluster() {
        // In "gia", 'i' is part of 'gi' consonant when followed by vowel
        var buffer = TypingBuffer()
        buffer.append("g")
        buffer.append("i")
        buffer.append("a")

        let positions = buffer.findVowelPositions()
        XCTAssertEqual(positions, [2]) // Only 'a' should be detected as vowel
    }

    func testGiConsonantClusterMarkPosition() {
        // "gia" -> mark should go on 'a'
        var buffer = TypingBuffer()
        buffer.append("g")
        buffer.append("i")
        buffer.append("a")

        let markPos = buffer.findMarkPosition()
        XCTAssertEqual(markPos, 2) // Position of 'a'
    }

    func testGiWithoutFollowingVowel() {
        // "gi" alone - 'i' should be treated as vowel (no following vowel)
        var buffer = TypingBuffer()
        buffer.append("g")
        buffer.append("i")

        let positions = buffer.findVowelPositions()
        XCTAssertEqual(positions, [1]) // 'i' is vowel when no following vowel
    }

    // MARK: - Triple Vowel Tests

    func testTripleVowelUoi() {
        // "uoi" -> mark on middle vowel
        var buffer = TypingBuffer()
        buffer.append("t")
        buffer.append("u")
        buffer.append("o")
        buffer.append("i")

        let markPos = buffer.findMarkPosition()
        XCTAssertEqual(markPos, 2) // Position of 'o' (middle)
    }

    func testTripleVowelOai() {
        // "oai" -> mark on middle vowel 'a'
        var buffer = TypingBuffer()
        buffer.append("o")
        buffer.append("a")
        buffer.append("i")

        let markPos = buffer.findMarkPosition()
        XCTAssertEqual(markPos, 1) // Position of 'a' (middle)
    }

    func testTripleVowelIeu() {
        // "ieu" -> mark on middle vowel 'e'
        var buffer = TypingBuffer()
        buffer.append("t")
        buffer.append("i")
        buffer.append("e")
        buffer.append("u")

        let markPos = buffer.findMarkPosition()
        XCTAssertEqual(markPos, 2) // Position of 'e' (middle)
    }

    func testTripleVowelUya() {
        // "khuya" -> mark on middle vowel 'y'
        var buffer = TypingBuffer()
        buffer.append("k")
        buffer.append("h")
        buffer.append("u")
        buffer.append("y")
        buffer.append("a")

        let markPos = buffer.findMarkPosition()
        XCTAssertEqual(markPos, 3) // Position of 'y' (middle of u-y-a)
    }
}
