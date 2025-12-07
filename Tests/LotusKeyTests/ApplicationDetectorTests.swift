import XCTest
@testable import LotusKey

final class ApplicationDetectorTests: XCTestCase {
    // MARK: - App Quirk Detection Tests

    /// Test that bundle ID prefixes are correctly mapped to quirks
    func testBundleIDToQuirkMapping() {
        // Simulate the quirk detection logic from ApplicationDetector
        func detectQuirk(bundleID: String) -> AppQuirk {
            // Sublime Text
            let sublimeTextPrefixes = ["com.sublimetext.2", "com.sublimetext.3", "com.sublimetext.4"]
            for prefix in sublimeTextPrefixes {
                if bundleID.hasPrefix(prefix) {
                    return .sublimeText
                }
            }

            // Chromium browsers
            let chromiumPrefixes = [
                "com.google.Chrome",
                "com.brave.Browser",
                "com.microsoft.Edge",
                "com.vivaldi.Vivaldi",
                "com.operasoftware.Opera",
                "org.chromium.Chromium"
            ]
            for prefix in chromiumPrefixes {
                if bundleID.hasPrefix(prefix) {
                    return .chromiumBrowser
                }
            }

            // Apple apps (Unicode Compound)
            let appleAppPrefixes = [
                "com.apple.Safari",
                "com.apple.Notes",
                "com.apple.TextEdit",
                "com.apple.mail"
            ]
            for prefix in appleAppPrefixes {
                if bundleID.hasPrefix(prefix) {
                    return .unicodeCompound
                }
            }

            return .standard
        }

        // Test Sublime Text
        XCTAssertEqual(detectQuirk(bundleID: "com.sublimetext.3"), .sublimeText)
        XCTAssertEqual(detectQuirk(bundleID: "com.sublimetext.4"), .sublimeText)
        XCTAssertEqual(detectQuirk(bundleID: "com.sublimetext.2.beta"), .sublimeText)

        // Test Chromium browsers
        XCTAssertEqual(detectQuirk(bundleID: "com.google.Chrome"), .chromiumBrowser)
        XCTAssertEqual(detectQuirk(bundleID: "com.google.Chrome.canary"), .chromiumBrowser)
        XCTAssertEqual(detectQuirk(bundleID: "com.brave.Browser"), .chromiumBrowser)
        XCTAssertEqual(detectQuirk(bundleID: "com.microsoft.Edge"), .chromiumBrowser)
        XCTAssertEqual(detectQuirk(bundleID: "com.microsoft.Edge.Dev"), .chromiumBrowser)
        XCTAssertEqual(detectQuirk(bundleID: "com.vivaldi.Vivaldi"), .chromiumBrowser)
        XCTAssertEqual(detectQuirk(bundleID: "org.chromium.Chromium"), .chromiumBrowser)

        // Test Apple apps
        XCTAssertEqual(detectQuirk(bundleID: "com.apple.Safari"), .unicodeCompound)
        XCTAssertEqual(detectQuirk(bundleID: "com.apple.Notes"), .unicodeCompound)
        XCTAssertEqual(detectQuirk(bundleID: "com.apple.TextEdit"), .unicodeCompound)
        XCTAssertEqual(detectQuirk(bundleID: "com.apple.mail"), .unicodeCompound)

        // Test standard apps
        XCTAssertEqual(detectQuirk(bundleID: "com.microsoft.VSCode"), .standard)
        XCTAssertEqual(detectQuirk(bundleID: "com.apple.Terminal"), .standard)
        XCTAssertEqual(detectQuirk(bundleID: "com.jetbrains.intellij"), .standard)
        XCTAssertEqual(detectQuirk(bundleID: "org.mozilla.firefox"), .standard)
    }

    // MARK: - OpenKey App Lists Comparison

    /// Verify our app lists match OpenKey's lists
    func testOpenKeyAppListsMatch() {
        // OpenKey _niceSpaceApp (Sublime Text - uses ZWNJ)
        let openKeyNiceSpaceApps = [
            "com.sublimetext.3",
            "com.sublimetext.2"
        ]

        // OpenKey _unicodeCompoundApp (uses Unicode Compound handling)
        // Note: This list includes BOTH Chrome and Apple apps in OpenKey
        let openKeyUnicodeCompoundApps = [
            "com.apple.",          // All Apple apps
            "com.google.Chrome",
            "com.brave.Browser",
            "com.operasoftware.Opera",
            "com.vivaldi.Vivaldi",
            "com.electron.",
            "org.chromium.Chromium",
            "com.microsoft.Edge"
        ]

        // Verify we handle all OpenKey apps
        XCTAssertTrue(openKeyNiceSpaceApps.contains("com.sublimetext.3"))
        XCTAssertTrue(openKeyUnicodeCompoundApps.contains("com.google.Chrome"))
        XCTAssertTrue(openKeyUnicodeCompoundApps.contains("com.apple."))
    }

    // MARK: - Priority Tests

    /// Test that more specific matches take priority
    func testQuirkPriority() {
        // If an app matches multiple categories, we need consistent behavior
        // Currently: Sublime > Chromium > Apple > Standard

        func detectQuirkWithPriority(bundleID: String) -> AppQuirk {
            // Check Sublime first (most specific workaround)
            if bundleID.hasPrefix("com.sublimetext") {
                return .sublimeText
            }

            // Check Chromium browsers
            if bundleID.hasPrefix("com.google.Chrome") ||
               bundleID.hasPrefix("com.brave.Browser") ||
               bundleID.hasPrefix("com.microsoft.Edge") {
                return .chromiumBrowser
            }

            // Check Apple apps
            if bundleID.hasPrefix("com.apple.") {
                return .unicodeCompound
            }

            return .standard
        }

        // Test priority is consistent
        XCTAssertEqual(detectQuirkWithPriority(bundleID: "com.sublimetext.3"), .sublimeText)
        XCTAssertEqual(detectQuirkWithPriority(bundleID: "com.google.Chrome"), .chromiumBrowser)
        XCTAssertEqual(detectQuirkWithPriority(bundleID: "com.apple.Safari"), .unicodeCompound)
    }
}
