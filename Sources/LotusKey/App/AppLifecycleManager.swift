import AppKit
import ServiceManagement

/// Errors that can occur during app lifecycle management
public enum AppLifecycleError: LocalizedError {
    case registrationFailed(underlying: Error)
    case unregistrationFailed(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .registrationFailed(let error):
            return "Failed to enable launch at login: \(error.localizedDescription)"
        case .unregistrationFailed(let error):
            return "Failed to disable launch at login: \(error.localizedDescription)"
        }
    }
}

/// Manages app lifecycle features: launch at login and dock icon visibility
@MainActor
public final class AppLifecycleManager {
    public static let shared = AppLifecycleManager()

    private init() {}

    // MARK: - Launch at Login

    /// Sets whether the app should launch at login
    /// - Parameter enabled: true to enable launch at login, false to disable
    /// - Throws: AppLifecycleError if registration/unregistration fails
    public func setLaunchAtLogin(_ enabled: Bool) throws {
        let service = SMAppService.mainApp
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
        } catch {
            if enabled {
                throw AppLifecycleError.registrationFailed(underlying: error)
            } else {
                throw AppLifecycleError.unregistrationFailed(underlying: error)
            }
        }
    }

    /// The current status of launch at login (returns .notRegistered if unavailable)
    public var launchAtLoginStatus: SMAppService.Status {
        SMAppService.mainApp.status
    }

    /// Whether launch at login is currently enabled
    public var isLaunchAtLoginEnabled: Bool {
        launchAtLoginStatus == .enabled
    }

    /// Whether launch at login requires user approval in System Settings
    public var launchAtLoginRequiresApproval: Bool {
        launchAtLoginStatus == .requiresApproval
    }

    // MARK: - Dock Icon

    /// Sets whether the dock icon should be visible
    /// - Parameter visible: true to show in Dock, false for menu bar only
    public func setDockIconVisible(_ visible: Bool) {
        guard let app = NSApp else { return }

        let policy: NSApplication.ActivationPolicy = visible ? .regular : .accessory
        app.setActivationPolicy(policy)

        // Activate the app to ensure the change takes effect
        if visible {
            app.activate(ignoringOtherApps: false)
        }
    }

    /// Whether the dock icon is currently visible
    public var isDockIconVisible: Bool {
        guard let app = NSApp else { return false }
        return app.activationPolicy() == .regular
    }
}
