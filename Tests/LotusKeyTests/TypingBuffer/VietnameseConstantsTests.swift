import XCTest
@testable import LotusKey

final class VietnameseConstantsTests: XCTestCase {

    // MARK: - VietnameseConstants Tests

    func testVietnameseConstantsIsVowel() {
        // Test static isVowel function
        XCTAssertTrue(VietnameseConstants.isVowel("a"))
        XCTAssertTrue(VietnameseConstants.isVowel("e"))
        XCTAssertTrue(VietnameseConstants.isVowel("i"))
        XCTAssertTrue(VietnameseConstants.isVowel("o"))
        XCTAssertTrue(VietnameseConstants.isVowel("u"))
        XCTAssertTrue(VietnameseConstants.isVowel("y"))
        XCTAssertTrue(VietnameseConstants.isVowel("A"))  // uppercase
        XCTAssertFalse(VietnameseConstants.isVowel("b"))
        XCTAssertFalse(VietnameseConstants.isVowel("x"))
    }

    func testVietnameseConstantsIsConsonant() {
        // Test static isConsonant function
        XCTAssertTrue(VietnameseConstants.isConsonant("b"))
        XCTAssertTrue(VietnameseConstants.isConsonant("c"))
        XCTAssertTrue(VietnameseConstants.isConsonant("d"))
        XCTAssertTrue(VietnameseConstants.isConsonant("B"))  // uppercase
        XCTAssertFalse(VietnameseConstants.isConsonant("a"))
        XCTAssertFalse(VietnameseConstants.isConsonant("e"))
    }

    func testVietnameseConstantsIsValidToneWithEndingNoTone() {
        // Test when tone is empty (no mark) - should return true
        let noTone: CharacterState = []
        XCTAssertTrue(VietnameseConstants.isValidToneWithEnding(tone: noTone, ending: "c"))
        XCTAssertTrue(VietnameseConstants.isValidToneWithEnding(tone: noTone, ending: "m"))
    }
}
