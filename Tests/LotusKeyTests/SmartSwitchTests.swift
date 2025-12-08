import XCTest
@testable import LotusKey

final class SmartSwitchTests: XCTestCase {
    private var smartSwitch: SmartSwitch!
    private let testStorageKey = "LotusKeySmartSwitch"

    override func setUp() {
        super.setUp()
        // Clear any existing preferences
        UserDefaults.standard.removeObject(forKey: testStorageKey)
        smartSwitch = SmartSwitch()
    }

    override func tearDown() {
        smartSwitch = nil
        UserDefaults.standard.removeObject(forKey: testStorageKey)
        super.tearDown()
    }

    // MARK: - hasPreference Tests

    func testHasPreferenceReturnsFalseForNewApp() {
        // Given a bundle ID that was never set
        let bundleId = "com.test.newapp"

        // Then hasPreference should return false
        XCTAssertFalse(smartSwitch.hasPreference(for: bundleId))
    }

    func testHasPreferenceReturnsTrueAfterSettingPreference() {
        // Given
        let bundleId = "com.test.app"

        // When we set a preference
        smartSwitch.setVietnameseEnabled(true, for: bundleId)

        // Then hasPreference should return true
        XCTAssertTrue(smartSwitch.hasPreference(for: bundleId))
    }

    func testHasPreferenceReturnsTrueForFalsePreference() {
        // Given
        let bundleId = "com.test.app"

        // When we set preference to false (English mode)
        smartSwitch.setVietnameseEnabled(false, for: bundleId)

        // Then hasPreference should still return true (preference exists)
        XCTAssertTrue(smartSwitch.hasPreference(for: bundleId))
    }

    // MARK: - shouldEnableVietnamese Tests

    func testShouldEnableVietnameseDefaultsToTrue() {
        // Given a bundle ID with no preference
        let bundleId = "com.test.unknown"

        // Then should default to Vietnamese enabled
        XCTAssertTrue(smartSwitch.shouldEnableVietnamese(for: bundleId))
    }

    func testShouldEnableVietnameseReturnsSavedValue() {
        // Given
        let bundleId = "com.test.app"

        // When we set to false
        smartSwitch.setVietnameseEnabled(false, for: bundleId)

        // Then should return false
        XCTAssertFalse(smartSwitch.shouldEnableVietnamese(for: bundleId))
    }

    func testShouldEnableVietnameseReturnsTrueWhenSet() {
        // Given
        let bundleId = "com.test.app"

        // When we explicitly set to true
        smartSwitch.setVietnameseEnabled(true, for: bundleId)

        // Then should return true
        XCTAssertTrue(smartSwitch.shouldEnableVietnamese(for: bundleId))
    }

    // MARK: - Persistence Tests

    func testPreferencesPersistedAcrossInstances() {
        // Given
        let bundleId = "com.test.persistent"
        smartSwitch.setVietnameseEnabled(false, for: bundleId)

        // When we create a new instance
        let newSmartSwitch = SmartSwitch()

        // Then preference should be loaded
        XCTAssertTrue(newSmartSwitch.hasPreference(for: bundleId))
        XCTAssertFalse(newSmartSwitch.shouldEnableVietnamese(for: bundleId))
    }

    func testMultipleAppsPreferencesIndependent() {
        // Given multiple apps with different preferences
        let app1 = "com.test.app1"
        let app2 = "com.test.app2"
        let app3 = "com.test.app3"

        // When we set different preferences
        smartSwitch.setVietnameseEnabled(true, for: app1)
        smartSwitch.setVietnameseEnabled(false, for: app2)
        // app3 has no preference

        // Then each app should have correct preference
        XCTAssertTrue(smartSwitch.hasPreference(for: app1))
        XCTAssertTrue(smartSwitch.shouldEnableVietnamese(for: app1))

        XCTAssertTrue(smartSwitch.hasPreference(for: app2))
        XCTAssertFalse(smartSwitch.shouldEnableVietnamese(for: app2))

        XCTAssertFalse(smartSwitch.hasPreference(for: app3))
        XCTAssertTrue(smartSwitch.shouldEnableVietnamese(for: app3)) // default
    }

    // MARK: - Update Preference Tests

    func testPreferenceCanBeUpdated() {
        // Given
        let bundleId = "com.test.update"
        smartSwitch.setVietnameseEnabled(true, for: bundleId)
        XCTAssertTrue(smartSwitch.shouldEnableVietnamese(for: bundleId))

        // When we update the preference
        smartSwitch.setVietnameseEnabled(false, for: bundleId)

        // Then should reflect new value
        XCTAssertFalse(smartSwitch.shouldEnableVietnamese(for: bundleId))
    }

    func testPreferenceUpdatePersisted() {
        // Given
        let bundleId = "com.test.updatepersist"
        smartSwitch.setVietnameseEnabled(true, for: bundleId)
        smartSwitch.setVietnameseEnabled(false, for: bundleId)

        // When we create new instance
        let newSmartSwitch = SmartSwitch()

        // Then should have updated value
        XCTAssertFalse(newSmartSwitch.shouldEnableVietnamese(for: bundleId))
    }
}
