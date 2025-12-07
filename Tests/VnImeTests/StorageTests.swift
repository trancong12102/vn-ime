import Combine
import XCTest
@testable import VnIme

@MainActor
final class StorageTests: XCTestCase {
    private var settings: SettingsStore!
    private var testDefaults: UserDefaults!
    private var testSuiteName: String!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        // Create isolated UserDefaults for testing
        testSuiteName = "com.vn-ime.tests.\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: testSuiteName)!
        settings = SettingsStore(defaults: testDefaults)
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        settings = nil
        // Clean up test defaults
        UserDefaults.standard.removePersistentDomain(forName: testSuiteName)
        testDefaults = nil
        testSuiteName = nil
        super.tearDown()
    }

    // MARK: - Advanced Settings Default Values

    func testFixBrowserAutocompleteDefaultValue() {
        XCTAssertTrue(settings.fixBrowserAutocomplete, "fixBrowserAutocomplete should default to true")
    }

    func testFixChromiumBrowserDefaultValue() {
        XCTAssertTrue(settings.fixChromiumBrowser, "fixChromiumBrowser should default to true")
    }

    func testSendKeyStepByStepDefaultValue() {
        XCTAssertFalse(settings.sendKeyStepByStep, "sendKeyStepByStep should default to false")
    }

    // MARK: - Advanced Settings Persistence

    func testFixBrowserAutocompletePersistence() {
        // Given
        XCTAssertTrue(settings.fixBrowserAutocomplete)

        // When
        settings.fixBrowserAutocomplete = false

        // Then
        XCTAssertFalse(settings.fixBrowserAutocomplete)
        XCTAssertFalse(testDefaults.bool(forKey: SettingsKey.fixBrowserAutocomplete.rawValue))
    }

    func testFixChromiumBrowserPersistence() {
        // Given
        XCTAssertTrue(settings.fixChromiumBrowser)

        // When
        settings.fixChromiumBrowser = false

        // Then
        XCTAssertFalse(settings.fixChromiumBrowser)
        XCTAssertFalse(testDefaults.bool(forKey: SettingsKey.fixChromiumBrowser.rawValue))
    }

    func testSendKeyStepByStepPersistence() {
        // Given
        XCTAssertFalse(settings.sendKeyStepByStep)

        // When
        settings.sendKeyStepByStep = true

        // Then
        XCTAssertTrue(settings.sendKeyStepByStep)
        XCTAssertTrue(testDefaults.bool(forKey: SettingsKey.sendKeyStepByStep.rawValue))
    }

    // MARK: - Settings Changed Publisher

    func testFixBrowserAutocompletePublisher() {
        let expectation = expectation(description: "Publisher fires for fixBrowserAutocomplete")

        settings.settingsChanged
            .sink { key in
                if key == .fixBrowserAutocomplete {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        settings.fixBrowserAutocomplete = false

        waitForExpectations(timeout: 1.0)
    }

    func testFixChromiumBrowserPublisher() {
        let expectation = expectation(description: "Publisher fires for fixChromiumBrowser")

        settings.settingsChanged
            .sink { key in
                if key == .fixChromiumBrowser {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        settings.fixChromiumBrowser = false

        waitForExpectations(timeout: 1.0)
    }

    func testSendKeyStepByStepPublisher() {
        let expectation = expectation(description: "Publisher fires for sendKeyStepByStep")

        settings.settingsChanged
            .sink { key in
                if key == .sendKeyStepByStep {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        settings.sendKeyStepByStep = true

        waitForExpectations(timeout: 1.0)
    }

    // MARK: - Reset to Defaults

    func testResetToDefaultsResetsAdvancedSettings() {
        // Given - Change all advanced settings from defaults
        settings.fixBrowserAutocomplete = false
        settings.fixChromiumBrowser = false
        settings.sendKeyStepByStep = true

        // When
        settings.resetToDefaults()

        // Then - All should be back to defaults
        XCTAssertTrue(settings.fixBrowserAutocomplete, "fixBrowserAutocomplete should reset to true")
        XCTAssertTrue(settings.fixChromiumBrowser, "fixChromiumBrowser should reset to true")
        XCTAssertFalse(settings.sendKeyStepByStep, "sendKeyStepByStep should reset to false")
    }

    func testResetToDefaultsFiresPublisherForAdvancedSettings() {
        var receivedKeys: Set<SettingsKey> = []
        let expectation = expectation(description: "Publisher fires for all advanced settings")
        expectation.expectedFulfillmentCount = 3

        settings.settingsChanged
            .sink { key in
                if [.fixBrowserAutocomplete, .fixChromiumBrowser, .sendKeyStepByStep].contains(key) {
                    receivedKeys.insert(key)
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        settings.resetToDefaults()

        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(receivedKeys.contains(.fixBrowserAutocomplete))
        XCTAssertTrue(receivedKeys.contains(.fixChromiumBrowser))
        XCTAssertTrue(receivedKeys.contains(.sendKeyStepByStep))
    }

    // MARK: - Settings Keys

    func testAdvancedSettingsKeyRawValues() {
        XCTAssertEqual(SettingsKey.fixBrowserAutocomplete.rawValue, "VnImeFixBrowserAutocomplete")
        XCTAssertEqual(SettingsKey.fixChromiumBrowser.rawValue, "VnImeFixChromiumBrowser")
        XCTAssertEqual(SettingsKey.sendKeyStepByStep.rawValue, "VnImeSendKeyStepByStep")
    }
}
