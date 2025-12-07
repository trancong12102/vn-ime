import AppKit
import Foundation

/// Protocol for smart language switching based on application
public protocol SmartSwitching: Sendable {
    /// Get the preferred language setting for an application
    /// - Parameter bundleIdentifier: The application bundle identifier
    /// - Returns: True if Vietnamese should be enabled, false for English
    func shouldEnableVietnamese(for bundleIdentifier: String) -> Bool

    /// Remember the language preference for an application
    /// - Parameters:
    ///   - enabled: Whether Vietnamese is enabled
    ///   - bundleIdentifier: The application bundle identifier
    func setVietnameseEnabled(_ enabled: Bool, for bundleIdentifier: String)

    /// Start monitoring for application changes
    func startMonitoring()

    /// Stop monitoring for application changes
    func stopMonitoring()

    /// Callback when active application changes
    var onApplicationChange: ((String?) -> Void)? { get set }
}

/// Default smart switch implementation
public final class SmartSwitch: SmartSwitching, @unchecked Sendable {
    private var preferences: [String: Bool] = [:]
    private let storageKey = "LotusKeySmartSwitch"
    private var observer: NSObjectProtocol?
    private let lock = NSLock()

    public var onApplicationChange: ((String?) -> Void)?

    public init() {
        loadPreferences()
    }

    deinit {
        stopMonitoring()
    }

    public func shouldEnableVietnamese(for bundleIdentifier: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        // Default to Vietnamese enabled if no preference stored
        return preferences[bundleIdentifier] ?? true
    }

    public func setVietnameseEnabled(_ enabled: Bool, for bundleIdentifier: String) {
        lock.lock()
        preferences[bundleIdentifier] = enabled
        lock.unlock()
        savePreferences()
    }

    public func startMonitoring() {
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  let bundleId = app.bundleIdentifier else {
                return
            }
            self?.onApplicationChange?(bundleId)
        }
    }

    public func stopMonitoring() {
        if let observer = observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            self.observer = nil
        }
    }

    private func loadPreferences() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String: Bool].self, from: data) {
            lock.lock()
            preferences = decoded
            lock.unlock()
        }
    }

    private func savePreferences() {
        lock.lock()
        let currentPrefs = preferences
        lock.unlock()

        if let encoded = try? JSONEncoder().encode(currentPrefs) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
}
