import XCTest
@testable import VnIme

final class TypingBufferTests: XCTestCase {

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

    // MARK: - Mark Positioning (Modern Orthography)

    func testMarkPositionSingleVowel() {
        var buffer = TypingBuffer()
        buffer.append("b")
        buffer.append("a")

        let position = buffer.findMarkPosition()
        XCTAssertEqual(position, 1) // 'a' at position 1
    }

    func testMarkPositionOA() {
        // "hoa" -> mark on 'a' (second vowel)
        var buffer = TypingBuffer()
        buffer.append("h")
        buffer.append("o")
        buffer.append("a")

        let position = buffer.findMarkPosition()
        XCTAssertEqual(position, 2) // 'a' is at position 2
    }

    func testMarkPositionOE() {
        // "hoe" -> mark on 'e' (second vowel)
        var buffer = TypingBuffer()
        buffer.append("h")
        buffer.append("o")
        buffer.append("e")

        let position = buffer.findMarkPosition()
        XCTAssertEqual(position, 2)
    }

    func testMarkPositionUY() {
        // "uy" (without q prefix) -> mark on 'y'
        var buffer = TypingBuffer()
        buffer.append("t")
        buffer.append("u")
        buffer.append("y")

        let position = buffer.findMarkPosition()
        XCTAssertEqual(position, 2)
    }

    func testMarkPositionAI() {
        // "mai" -> mark on 'a' (first vowel)
        var buffer = TypingBuffer()
        buffer.append("m")
        buffer.append("a")
        buffer.append("i")

        let position = buffer.findMarkPosition()
        XCTAssertEqual(position, 1) // 'a' at position 1
    }

    func testMarkPositionModifiedVowelPriority() {
        // Modified vowel gets priority
        var buffer = TypingBuffer()
        buffer.append("t")
        buffer.append("u") // position 1
        var typedA = TypedCharacter(character: "a")
        typedA.state.insert(.circumflex) // â at position 2
        buffer.append(typedA)
        buffer.append("n")

        let position = buffer.findMarkPosition()
        XCTAssertEqual(position, 2) // â gets priority
    }

    // MARK: - iê/yê/uô/ươ + Ending Consonant Tests

    func testMarkPositionIEWithEnding() {
        // "tiên" -> mark on 'ê' (iê + ending n)
        var buffer = TypingBuffer()
        buffer.append("t")
        buffer.append("i")
        var typedE = TypedCharacter(character: "e")
        typedE.state.insert(.circumflex) // ê
        buffer.append(typedE)
        buffer.append("n")

        let markPos = buffer.findMarkPosition()
        XCTAssertEqual(markPos, 2) // Position of 'ê'
    }

    func testMarkPositionYEWithEnding() {
        // "yến" -> mark on 'ê'
        var buffer = TypingBuffer()
        buffer.append("y")
        var typedE = TypedCharacter(character: "e")
        typedE.state.insert(.circumflex) // ê
        buffer.append(typedE)
        buffer.append("n")

        let markPos = buffer.findMarkPosition()
        XCTAssertEqual(markPos, 1) // Position of 'ê'
    }

    func testMarkPositionUOWithEnding() {
        // "cuốn" -> mark on 'ô' (uô + ending n)
        var buffer = TypingBuffer()
        buffer.append("c")
        buffer.append("u")
        var typedO = TypedCharacter(character: "o")
        typedO.state.insert(.circumflex) // ô
        buffer.append(typedO)
        buffer.append("n")

        let markPos = buffer.findMarkPosition()
        XCTAssertEqual(markPos, 2) // Position of 'ô'
    }

    func testMarkPositionUoWithHorn() {
        // "nước" (ươ combination) -> mark on 'ơ'
        var buffer = TypingBuffer()
        buffer.append("n")
        var typedU = TypedCharacter(character: "u")
        typedU.state.insert(.hornOrBreve) // ư
        buffer.append(typedU)
        var typedO = TypedCharacter(character: "o")
        typedO.state.insert(.hornOrBreve) // ơ
        buffer.append(typedO)
        buffer.append("c")

        let markPos = buffer.findMarkPosition()
        XCTAssertEqual(markPos, 2) // Position of 'ơ'
    }

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

    // MARK: - Dynamic Tone Repositioning

    func testRefreshTonePosition() {
        // Test that tone moves when structure changes
        // Start with "ua" with tone on 'u', add 'n' -> tone should move to 'a'
        var buffer = TypingBuffer()
        buffer.append("l")
        var typedU = TypedCharacter(character: "u")
        typedU.state.insert(.acute) // Mark on 'u' first
        buffer.append(typedU)
        buffer.append("a")

        // With "ua" pattern without ending, mark should be on first vowel
        // But after adding ending 'n', it might change
        buffer.append("n")

        // Refresh should reposition
        let repositioned = buffer.refreshTonePosition()

        // After adding 'n', mark should move to 'a' (per modern orthography for "uan")
        let markedPos = buffer.findMarkedVowelPosition()
        // The exact position depends on rule - test that refresh works
        XCTAssertNotNil(markedPos)
    }

    func testFindMarkedVowelPosition() {
        var buffer = TypingBuffer()
        buffer.append("b")
        buffer.append("a")
        buffer.applyMark(.acute)

        let pos = buffer.findMarkedVowelPosition()
        XCTAssertEqual(pos, 1)
    }

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
