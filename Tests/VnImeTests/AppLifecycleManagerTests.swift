import AppKit
import XCTest
@testable import VnIme

@MainActor
final class AppLifecycleManagerTests: XCTestCase {
    // MARK: - Dock Icon Tests

    // Note: Dock icon tests require NSApp to be initialized, which only happens
    // in a real app context. These tests verify the code doesn't crash when
    // NSApp is nil (graceful degradation).

    func testDockIconManagerHandlesNilApp() {
        // Given - NSApp may be nil in test environment
        let manager = AppLifecycleManager.shared

        // When/Then - should not crash, returns false when NSApp is nil
        manager.setDockIconVisible(true)
        manager.setDockIconVisible(false)

        // isDockIconVisible returns false when NSApp is nil
        let isVisible = manager.isDockIconVisible
        if NSApp == nil {
            XCTAssertFalse(isVisible)
        }
    }

    func testDockIconManagerWithApp() throws {
        // Skip if NSApp is not available
        try XCTSkipIf(NSApp == nil, "Requires running application context")

        let manager = AppLifecycleManager.shared

        // Save original state
        let originalPolicy = NSApp.activationPolicy()

        // Test showing dock icon
        manager.setDockIconVisible(true)
        XCTAssertTrue(manager.isDockIconVisible)

        // Test hiding dock icon
        manager.setDockIconVisible(false)
        XCTAssertFalse(manager.isDockIconVisible)

        // Restore original state
        NSApp.setActivationPolicy(originalPolicy)
    }

    // MARK: - Launch at Login Tests

    // Note: SMAppService.mainApp requires a real app context and code signing
    // to function properly. These tests verify the API is accessible but may
    // fail in test environments. Full testing requires manual verification.

    func testLaunchAtLoginStatusAccessible() {
        // Given
        let manager = AppLifecycleManager.shared

        // When/Then - verify we can access the status without crashing
        let status = manager.launchAtLoginStatus
        // Status could be .notRegistered, .enabled, or .requiresApproval
        XCTAssertNotNil(status)
    }

    func testIsLaunchAtLoginEnabledProperty() {
        // Given
        let manager = AppLifecycleManager.shared

        // When/Then - verify the computed property works
        let isEnabled = manager.isLaunchAtLoginEnabled
        // In test context, this should return false (not registered)
        XCTAssertFalse(isEnabled)
    }

    func testLaunchAtLoginRequiresApprovalProperty() {
        // Given
        let manager = AppLifecycleManager.shared

        // When/Then - verify the computed property works
        _ = manager.launchAtLoginRequiresApproval
        // Just verify it doesn't crash - actual value depends on system state
    }
}
