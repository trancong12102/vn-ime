import XCTest
@testable import LotusKey

final class TypedCharacterTests: XCTestCase {

    // MARK: - TypedCharacter Tests

    func testTypedCharacterInitWithBaseCodeAndState() {
        // Test init(baseCode:state:)
        let state: CharacterState = [.caps, .acute]
        let typed = TypedCharacter(baseCode: 97, state: state)  // 'a' = 97
        XCTAssertEqual(typed.baseCode, 97)
        XCTAssertEqual(typed.state, state)
        XCTAssertEqual(typed.baseCharacter, "a")
        XCTAssertTrue(typed.isUppercase)
    }

    func testTypedCharacterRawValueRoundTrip() {
        // Test init(rawValue:) and rawValue computed property
        let original = TypedCharacter(baseCode: 97, state: [.caps, .acute])
        let rawValue = original.rawValue

        // Verify raw value packing
        XCTAssertEqual(rawValue & 0xFFFF, 97)  // Base code in lower 16 bits

        // Verify round-trip
        let unpacked = TypedCharacter(rawValue: rawValue)
        XCTAssertEqual(unpacked.baseCode, original.baseCode)
        XCTAssertEqual(unpacked.state, original.state)
    }

    func testTypedCharacterDescription() {
        let typed = TypedCharacter(character: "a", caps: true)
        let description = typed.description
        XCTAssertTrue(description.contains("TypedCharacter"))
        XCTAssertTrue(description.contains("a"))
        XCTAssertTrue(description.contains("caps"))
    }

    func testTypedCharacterDescriptionWithUnknownChar() {
        // Test description when baseCode is 0 (no valid character)
        let typed = TypedCharacter(baseCode: 0, state: [])
        let description = typed.description
        XCTAssertTrue(description.contains("?"))
    }
}
