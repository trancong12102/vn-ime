import XCTest
@testable import LotusKey

/// Integration tests for full Telex sequences and common Vietnamese words
final class EngineIntegrationTests: EngineTestCase {

    // MARK: - Integration Tests (Full Telex Sequences)

    func testProcessStringViet() {
        // "Vieejt" -> "Việt" (Telex: ee = ê, j = nặng)
        let result = engine.processString("Vieejt")
        XCTAssertEqual(result, "Việt")
    }

    func testProcessStringNam() {
        // "Nam" -> "Nam" (no transformation needed)
        let result = engine.processString("Nam")
        XCTAssertEqual(result, "Nam")
    }

    func testProcessStringXinChao() {
        // "xin chaof" -> "xin chào" (f = huyền)
        let result = engine.processString("xin chaof")
        XCTAssertEqual(result, "xin chào")
    }

    func testProcessStringToi() {
        // "tooi" -> "tôi" (oo = ô)
        let result = engine.processString("tooi")
        XCTAssertEqual(result, "tôi")
    }

    func testProcessStringDi() {
        // "ddi" -> "đi" (dd = đ)
        let result = engine.processString("ddi")
        XCTAssertEqual(result, "đi")
    }

    func testProcessStringUong() {
        // "uoongs" -> "uống" (oo = ô, s = sắc)
        let result = engine.processString("uoongs")
        XCTAssertEqual(result, "uống")
    }

    func testProcessStringNuoc() {
        // "nuwowcs" -> "nước" (uw = ư, ow = ơ, s = sắc)
        // For "ươ" combination, mark goes on ơ (second vowel) per modern orthography
        let result = engine.processString("nuwowcs")
        XCTAssertEqual(result, "nước")
    }

    func testProcessStringHoa() {
        // "hoaf" -> "hoà" (mark on 'a' for oa combination)
        let result = engine.processString("hoaf")
        XCTAssertEqual(result, "hoà")
    }

    func testProcessStringQuy() {
        // "quys" -> "quý" (mark on 'y' for uy combination)
        let result = engine.processString("quys")
        XCTAssertEqual(result, "quý")
    }

    // MARK: - Uppercase Tests

    func testUppercaseTelex() {
        // "AS" -> should produce "Á" or "AS" depending on implementation
        let result = engine.processString("AS")
        // The first 'A' should be uppercase, second 'S' applies tone
        XCTAssertTrue(result == "Á" || result == "AS")
    }

    func testUppercaseCircumflex() {
        // "AA" -> "Â"
        let result = engine.processString("AA")
        XCTAssertEqual(result, "Â")
    }

    func testUppercaseDD() {
        // "DD" -> "Đ"
        let result = engine.processString("DD")
        XCTAssertEqual(result, "Đ")
    }
}
