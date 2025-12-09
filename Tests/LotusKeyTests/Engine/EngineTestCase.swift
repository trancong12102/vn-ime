import XCTest
@testable import LotusKey

/// Base test class providing common setup for Vietnamese engine tests
class EngineTestCase: XCTestCase {
    var engine: DefaultVietnameseEngine!

    override func setUp() {
        super.setUp()
        engine = DefaultVietnameseEngine()
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }
}
