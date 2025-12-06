import XCTest
@testable import VnIme

final class VietnameseTableTests: XCTestCase {

    // MARK: - Basic Vowels Without Marks

    func testBasicVowelsNoMark() {
        XCTAssertEqual(lookupChar("a", [], []), "a")
        XCTAssertEqual(lookupChar("e", [], []), "e")
        XCTAssertEqual(lookupChar("i", [], []), "i")
        XCTAssertEqual(lookupChar("o", [], []), "o")
        XCTAssertEqual(lookupChar("u", [], []), "u")
        XCTAssertEqual(lookupChar("y", [], []), "y")
    }

    // MARK: - Vowel 'a' Variants

    func testVowelA() {
        XCTAssertEqual(lookupChar("a", [], .acute), "á")
        XCTAssertEqual(lookupChar("a", [], .grave), "à")
        XCTAssertEqual(lookupChar("a", [], .hook), "ả")
        XCTAssertEqual(lookupChar("a", [], .tilde), "ã")
        XCTAssertEqual(lookupChar("a", [], .dotBelow), "ạ")
    }

    func testVowelACircumflex() {
        XCTAssertEqual(lookupChar("a", .circumflex, []), "â")
        XCTAssertEqual(lookupChar("a", .circumflex, .acute), "ấ")
        XCTAssertEqual(lookupChar("a", .circumflex, .grave), "ầ")
        XCTAssertEqual(lookupChar("a", .circumflex, .hook), "ẩ")
        XCTAssertEqual(lookupChar("a", .circumflex, .tilde), "ẫ")
        XCTAssertEqual(lookupChar("a", .circumflex, .dotBelow), "ậ")
    }

    func testVowelABreve() {
        XCTAssertEqual(lookupChar("a", .hornOrBreve, []), "ă")
        XCTAssertEqual(lookupChar("a", .hornOrBreve, .acute), "ắ")
        XCTAssertEqual(lookupChar("a", .hornOrBreve, .grave), "ằ")
        XCTAssertEqual(lookupChar("a", .hornOrBreve, .hook), "ẳ")
        XCTAssertEqual(lookupChar("a", .hornOrBreve, .tilde), "ẵ")
        XCTAssertEqual(lookupChar("a", .hornOrBreve, .dotBelow), "ặ")
    }

    // MARK: - Vowel 'e' Variants

    func testVowelE() {
        XCTAssertEqual(lookupChar("e", [], .acute), "é")
        XCTAssertEqual(lookupChar("e", [], .grave), "è")
        XCTAssertEqual(lookupChar("e", [], .hook), "ẻ")
        XCTAssertEqual(lookupChar("e", [], .tilde), "ẽ")
        XCTAssertEqual(lookupChar("e", [], .dotBelow), "ẹ")
    }

    func testVowelECircumflex() {
        XCTAssertEqual(lookupChar("e", .circumflex, []), "ê")
        XCTAssertEqual(lookupChar("e", .circumflex, .acute), "ế")
        XCTAssertEqual(lookupChar("e", .circumflex, .grave), "ề")
        XCTAssertEqual(lookupChar("e", .circumflex, .hook), "ể")
        XCTAssertEqual(lookupChar("e", .circumflex, .tilde), "ễ")
        XCTAssertEqual(lookupChar("e", .circumflex, .dotBelow), "ệ")
    }

    // MARK: - Vowel 'o' Variants

    func testVowelO() {
        XCTAssertEqual(lookupChar("o", [], .acute), "ó")
        XCTAssertEqual(lookupChar("o", [], .grave), "ò")
    }

    func testVowelOCircumflex() {
        XCTAssertEqual(lookupChar("o", .circumflex, []), "ô")
        XCTAssertEqual(lookupChar("o", .circumflex, .acute), "ố")
        XCTAssertEqual(lookupChar("o", .circumflex, .grave), "ồ")
    }

    func testVowelOHorn() {
        XCTAssertEqual(lookupChar("o", .hornOrBreve, []), "ơ")
        XCTAssertEqual(lookupChar("o", .hornOrBreve, .acute), "ớ")
        XCTAssertEqual(lookupChar("o", .hornOrBreve, .grave), "ờ")
        XCTAssertEqual(lookupChar("o", .hornOrBreve, .hook), "ở")
        XCTAssertEqual(lookupChar("o", .hornOrBreve, .tilde), "ỡ")
        XCTAssertEqual(lookupChar("o", .hornOrBreve, .dotBelow), "ợ")
    }

    // MARK: - Vowel 'u' Variants

    func testVowelU() {
        XCTAssertEqual(lookupChar("u", [], .acute), "ú")
        XCTAssertEqual(lookupChar("u", [], .grave), "ù")
    }

    func testVowelUHorn() {
        XCTAssertEqual(lookupChar("u", .hornOrBreve, []), "ư")
        XCTAssertEqual(lookupChar("u", .hornOrBreve, .acute), "ứ")
        XCTAssertEqual(lookupChar("u", .hornOrBreve, .grave), "ừ")
        XCTAssertEqual(lookupChar("u", .hornOrBreve, .hook), "ử")
        XCTAssertEqual(lookupChar("u", .hornOrBreve, .tilde), "ữ")
        XCTAssertEqual(lookupChar("u", .hornOrBreve, .dotBelow), "ự")
    }

    // MARK: - Vowel 'i' and 'y'

    func testVowelI() {
        XCTAssertEqual(lookupChar("i", [], .acute), "í")
        XCTAssertEqual(lookupChar("i", [], .grave), "ì")
        XCTAssertEqual(lookupChar("i", [], .hook), "ỉ")
        XCTAssertEqual(lookupChar("i", [], .tilde), "ĩ")
        XCTAssertEqual(lookupChar("i", [], .dotBelow), "ị")
    }

    func testVowelY() {
        XCTAssertEqual(lookupChar("y", [], .acute), "ý")
        XCTAssertEqual(lookupChar("y", [], .grave), "ỳ")
        XCTAssertEqual(lookupChar("y", [], .hook), "ỷ")
        XCTAssertEqual(lookupChar("y", [], .tilde), "ỹ")
        XCTAssertEqual(lookupChar("y", [], .dotBelow), "ỵ")
    }

    // MARK: - Uppercase

    func testUppercaseVowels() {
        XCTAssertEqual(lookupCharCaps("a", [], .acute), "Á")
        XCTAssertEqual(lookupCharCaps("e", .circumflex, .grave), "Ề")
        XCTAssertEqual(lookupCharCaps("o", .hornOrBreve, .tilde), "Ỡ")
        XCTAssertEqual(lookupCharCaps("u", .hornOrBreve, .dotBelow), "Ự")
    }

    // MARK: - Consonant đ

    func testConsonantD() {
        var typed = TypedCharacter(character: "d")
        typed.state.insert(.hornOrBreve)
        XCTAssertEqual(VietnameseTable.toUnicode(typed), "đ")
    }

    func testConsonantDUppercase() {
        var typed = TypedCharacter(character: "D")
        typed.state.insert(.hornOrBreve)
        XCTAssertEqual(VietnameseTable.toUnicode(typed), "Đ")
    }

    // MARK: - Non-Vietnamese Characters

    func testNonVietnameseCharacter() {
        let typed = TypedCharacter(character: "b")
        XCTAssertEqual(VietnameseTable.toUnicode(typed), "b")
    }

    func testNonVietnameseCharacterUppercase() {
        let typed = TypedCharacter(character: "B")
        XCTAssertEqual(VietnameseTable.toUnicode(typed), "B")
    }

    // MARK: - Helpers

    private func lookupChar(_ base: Character, _ modifier: CharacterState, _ mark: CharacterState) -> Character? {
        var typed = TypedCharacter(character: base)
        typed.state.insert(modifier)
        typed.state.insert(mark)
        return VietnameseTable.toUnicode(typed)
    }

    private func lookupCharCaps(_ base: Character, _ modifier: CharacterState, _ mark: CharacterState) -> Character? {
        var typed = TypedCharacter(character: base)
        typed.state.insert(.caps)
        typed.state.insert(modifier)
        typed.state.insert(mark)
        return VietnameseTable.toUnicode(typed)
    }
}
