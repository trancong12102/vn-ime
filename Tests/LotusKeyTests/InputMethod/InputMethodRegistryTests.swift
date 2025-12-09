import XCTest
@testable import LotusKey

final class InputMethodRegistryTests: XCTestCase {
    // MARK: - Available IDs Tests

    func testRegistryAvailableIDs() {
        let ids = InputMethodRegistry.availableIDs
        XCTAssertEqual(ids.count, 2)
        XCTAssertTrue(ids.contains("telex"))
        XCTAssertTrue(ids.contains("simple-telex"))
    }

    // MARK: - Get by ID Tests

    func testRegistryGetTelex() {
        let method = InputMethodRegistry.get("telex")
        XCTAssertNotNil(method)
        XCTAssertEqual(method?.name, "Telex")
    }

    func testRegistryGetSimpleTelex() {
        let method = InputMethodRegistry.get("simple-telex")
        XCTAssertNotNil(method)
        XCTAssertEqual(method?.name, "Simple Telex")
    }

    func testRegistryGetUnknown() {
        let method = InputMethodRegistry.get("vni")
        XCTAssertNil(method)
    }

    // MARK: - Default Method Tests

    func testRegistryDefault() {
        let defaultMethod = InputMethodRegistry.default
        XCTAssertEqual(defaultMethod.name, "Telex")
    }

    // MARK: - All Methods Tests

    func testRegistryAllMethods() {
        let allMethods = InputMethodRegistry.allMethods
        XCTAssertEqual(allMethods.count, 2)

        let names = allMethods.map { $0.method.name }
        XCTAssertTrue(names.contains("Telex"))
        XCTAssertTrue(names.contains("Simple Telex"))
    }

    // MARK: - Get by Name Tests

    func testRegistryGetByName() {
        // Test getByName with exact name
        let telex = InputMethodRegistry.getByName("Telex")
        XCTAssertNotNil(telex)
        XCTAssertEqual(telex?.name, "Telex")

        let simpleTelex = InputMethodRegistry.getByName("Simple Telex")
        XCTAssertNotNil(simpleTelex)
        XCTAssertEqual(simpleTelex?.name, "Simple Telex")
    }

    func testRegistryGetByNameCaseInsensitive() {
        let telexLower = InputMethodRegistry.getByName("telex")
        XCTAssertNotNil(telexLower)

        let telexUpper = InputMethodRegistry.getByName("TELEX")
        XCTAssertNotNil(telexUpper)

        let simpleTelexMixed = InputMethodRegistry.getByName("simple telex")
        XCTAssertNotNil(simpleTelexMixed)
    }

    func testRegistryGetByNameInvalid() {
        let vni = InputMethodRegistry.getByName("VNI")
        XCTAssertNil(vni)

        let invalid = InputMethodRegistry.getByName("invalid")
        XCTAssertNil(invalid)
    }
}
