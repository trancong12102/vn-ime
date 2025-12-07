import AppKit
import Combine
import Foundation

/// Protocol for detecting frontmost application
public protocol ApplicationDetecting: AnyObject, Sendable {
    /// Get the current frontmost application's bundle identifier
    var currentBundleIdentifier: String? { get }

    /// Get the quirk for the current application
    var currentAppQuirk: AppQuirk { get }

    /// Publisher for application changes
    var applicationChanged: AnyPublisher<String?, Never> { get }

    /// Start monitoring application changes
    func startMonitoring()

    /// Stop monitoring application changes
    func stopMonitoring()
}

/// Detects frontmost application and determines appropriate quirks
public final class ApplicationDetector: ApplicationDetecting, @unchecked Sendable {
    // MARK: - Known Application Bundle IDs

    /// Sublime Text bundle ID prefixes
    private static let sublimeTextPrefixes = [
        "com.sublimetext.2",
        "com.sublimetext.3",
        "com.sublimetext.4",
        "com.sublimetext",
    ]

    /// Chromium-based browser bundle IDs
    private static let chromiumBrowserPrefixes = [
        "com.google.Chrome",
        "com.google.Chrome.canary",
        "com.brave.Browser",
        "com.brave.Browser.beta",
        "com.brave.Browser.nightly",
        "com.microsoft.edgemac",
        "com.microsoft.Edge",
        "com.operasoftware.Opera",
        "com.vivaldi.Vivaldi",
        "org.chromium.Chromium",
        "com.electron",
    ]

    /// Apple apps that need Unicode Compound handling
    private static let appleAppPrefixes = [
        "com.apple.Safari",
        "com.apple.Notes",
        "com.apple.TextEdit",
        "com.apple.Pages",
        "com.apple.Numbers",
        "com.apple.Keynote",
    ]

    // MARK: - Properties

    private var cancellables = Set<AnyCancellable>()
    private let lock = NSLock()
    private var _currentBundleIdentifier: String?
    private var _currentAppQuirk: AppQuirk = .standard

    private let applicationChangedSubject = PassthroughSubject<String?, Never>()

    public var applicationChanged: AnyPublisher<String?, Never> {
        applicationChangedSubject.eraseToAnyPublisher()
    }

    public var currentBundleIdentifier: String? {
        lock.lock()
        defer { lock.unlock() }
        return _currentBundleIdentifier
    }

    public var currentAppQuirk: AppQuirk {
        lock.lock()
        defer { lock.unlock() }
        return _currentAppQuirk
    }

    // MARK: - Initialization

    public init() {
        // Get initial frontmost app
        updateCurrentApplication()
    }

    // MARK: - Monitoring

    public func startMonitoring() {
        // Subscribe to application activation notifications
        NSWorkspace.shared.notificationCenter.publisher(
            for: NSWorkspace.didActivateApplicationNotification
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] notification in
            self?.handleApplicationActivated(notification)
        }
        .store(in: &cancellables)
    }

    public func stopMonitoring() {
        cancellables.removeAll()
    }

    // MARK: - Private Methods

    private func handleApplicationActivated(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }

        let bundleIdentifier = app.bundleIdentifier
        updateCurrentApplication(bundleIdentifier: bundleIdentifier)
    }

    private func updateCurrentApplication(bundleIdentifier: String? = nil) {
        let bundleId = bundleIdentifier ?? NSWorkspace.shared.frontmostApplication?.bundleIdentifier

        lock.lock()
        _currentBundleIdentifier = bundleId
        _currentAppQuirk = determineQuirk(for: bundleId)
        lock.unlock()

        applicationChangedSubject.send(bundleId)
    }

    private func determineQuirk(for bundleIdentifier: String?) -> AppQuirk {
        guard let bundleId = bundleIdentifier else {
            return .standard
        }

        // Check for Sublime Text
        for prefix in Self.sublimeTextPrefixes {
            if bundleId.hasPrefix(prefix) {
                return .sublimeText
            }
        }

        // Check for Chromium browsers
        for prefix in Self.chromiumBrowserPrefixes {
            if bundleId.hasPrefix(prefix) {
                return .chromiumBrowser
            }
        }

        // Check for Apple apps
        for prefix in Self.appleAppPrefixes {
            if bundleId.hasPrefix(prefix) {
                return .unicodeCompound
            }
        }

        return .standard
    }
}

// MARK: - AppQuirk Extensions

extension AppQuirk: CustomStringConvertible {
    public var description: String {
        switch self {
        case .standard: return "Standard"
        case .sublimeText: return "Sublime Text"
        case .chromiumBrowser: return "Chromium Browser"
        case .unicodeCompound: return "Unicode Compound"
        }
    }
}
