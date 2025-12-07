import Combine
import Foundation

/// Keys for UserDefaults storage
public enum SettingsKey: String {
    case inputMethod = "LotusKeyInputMethod"
    case spellCheckEnabled = "LotusKeySpellCheckEnabled"
    case smartSwitchEnabled = "LotusKeySmartSwitchEnabled"
    case quickTelexEnabled = "LotusKeyQuickTelexEnabled"
    case launchAtLogin = "LotusKeyLaunchAtLogin"
    case showDockIcon = "LotusKeyShowDockIcon"
    case autoCapitalize = "LotusKeyAutoCapitalize"
    case restoreIfWrongSpelling = "LotusKeyRestoreIfWrongSpelling"
    // Advanced settings
    case fixBrowserAutocomplete = "LotusKeyFixBrowserAutocomplete"
    case fixChromiumBrowser = "LotusKeyFixChromiumBrowser"
    case sendKeyStepByStep = "LotusKeySendKeyStepByStep"
}

/// Protocol for settings storage
public protocol SettingsStoring: AnyObject, Sendable {
    // Input settings
    var inputMethod: String { get set }
    var spellCheckEnabled: Bool { get set }
    var quickTelexEnabled: Bool { get set }
    var autoCapitalize: Bool { get set }
    var restoreIfWrongSpelling: Bool { get set }

    // App behavior
    var smartSwitchEnabled: Bool { get set }
    var launchAtLogin: Bool { get set }
    var showDockIcon: Bool { get set }

    // Advanced settings
    var fixBrowserAutocomplete: Bool { get set }
    var fixChromiumBrowser: Bool { get set }
    var sendKeyStepByStep: Bool { get set }

    // Publisher for settings changes
    var settingsChanged: AnyPublisher<SettingsKey, Never> { get }

    // Reset to defaults
    func resetToDefaults()
}

/// Default settings storage using UserDefaults
public final class SettingsStore: SettingsStoring, @unchecked Sendable {
    private let defaults: UserDefaults
    private let settingsChangedSubject = PassthroughSubject<SettingsKey, Never>()
    private let lock = NSLock()

    public var settingsChanged: AnyPublisher<SettingsKey, Never> {
        settingsChangedSubject.eraseToAnyPublisher()
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        registerDefaults()
    }

    private func registerDefaults() {
        defaults.register(defaults: [
            SettingsKey.inputMethod.rawValue: "Telex",
            SettingsKey.spellCheckEnabled.rawValue: true,
            SettingsKey.smartSwitchEnabled.rawValue: true,
            SettingsKey.quickTelexEnabled.rawValue: true,
            SettingsKey.launchAtLogin.rawValue: false,
            SettingsKey.showDockIcon.rawValue: false,
            SettingsKey.autoCapitalize.rawValue: true,
            SettingsKey.restoreIfWrongSpelling.rawValue: true,
            // Advanced settings
            SettingsKey.fixBrowserAutocomplete.rawValue: true,
            SettingsKey.fixChromiumBrowser.rawValue: true,
            SettingsKey.sendKeyStepByStep.rawValue: false,
        ])
    }

    // MARK: - Input Settings

    public var inputMethod: String {
        get {
            lock.lock()
            defer { lock.unlock() }
            return defaults.string(forKey: SettingsKey.inputMethod.rawValue) ?? "Telex"
        }
        set {
            lock.lock()
            defaults.set(newValue, forKey: SettingsKey.inputMethod.rawValue)
            lock.unlock()
            settingsChangedSubject.send(.inputMethod)
        }
    }

    public var spellCheckEnabled: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return defaults.bool(forKey: SettingsKey.spellCheckEnabled.rawValue)
        }
        set {
            lock.lock()
            defaults.set(newValue, forKey: SettingsKey.spellCheckEnabled.rawValue)
            lock.unlock()
            settingsChangedSubject.send(.spellCheckEnabled)
        }
    }

    public var quickTelexEnabled: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return defaults.bool(forKey: SettingsKey.quickTelexEnabled.rawValue)
        }
        set {
            lock.lock()
            defaults.set(newValue, forKey: SettingsKey.quickTelexEnabled.rawValue)
            lock.unlock()
            settingsChangedSubject.send(.quickTelexEnabled)
        }
    }

    public var autoCapitalize: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return defaults.bool(forKey: SettingsKey.autoCapitalize.rawValue)
        }
        set {
            lock.lock()
            defaults.set(newValue, forKey: SettingsKey.autoCapitalize.rawValue)
            lock.unlock()
            settingsChangedSubject.send(.autoCapitalize)
        }
    }

    public var restoreIfWrongSpelling: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return defaults.bool(forKey: SettingsKey.restoreIfWrongSpelling.rawValue)
        }
        set {
            lock.lock()
            defaults.set(newValue, forKey: SettingsKey.restoreIfWrongSpelling.rawValue)
            lock.unlock()
            settingsChangedSubject.send(.restoreIfWrongSpelling)
        }
    }

    // MARK: - App Behavior

    public var smartSwitchEnabled: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return defaults.bool(forKey: SettingsKey.smartSwitchEnabled.rawValue)
        }
        set {
            lock.lock()
            defaults.set(newValue, forKey: SettingsKey.smartSwitchEnabled.rawValue)
            lock.unlock()
            settingsChangedSubject.send(.smartSwitchEnabled)
        }
    }

    public var launchAtLogin: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return defaults.bool(forKey: SettingsKey.launchAtLogin.rawValue)
        }
        set {
            lock.lock()
            defaults.set(newValue, forKey: SettingsKey.launchAtLogin.rawValue)
            lock.unlock()
            settingsChangedSubject.send(.launchAtLogin)

            // Register/unregister login item on main thread
            // Note: SMAppService requires proper code signing, skip in debug builds
            #if !DEBUG
            Task { @MainActor in
                do {
                    try AppLifecycleManager.shared.setLaunchAtLogin(newValue)
                } catch {
                    print("Failed to update launch at login: \(error.localizedDescription)")
                }
            }
            #else
            print("Launch at login is disabled in debug builds (requires code signing)")
            #endif
        }
    }

    public var showDockIcon: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return defaults.bool(forKey: SettingsKey.showDockIcon.rawValue)
        }
        set {
            lock.lock()
            defaults.set(newValue, forKey: SettingsKey.showDockIcon.rawValue)
            lock.unlock()
            settingsChangedSubject.send(.showDockIcon)

            // Update dock icon visibility on main thread
            Task { @MainActor in
                AppLifecycleManager.shared.setDockIconVisible(newValue)
            }
        }
    }

    // MARK: - Advanced Settings

    public var fixBrowserAutocomplete: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return defaults.bool(forKey: SettingsKey.fixBrowserAutocomplete.rawValue)
        }
        set {
            lock.lock()
            defaults.set(newValue, forKey: SettingsKey.fixBrowserAutocomplete.rawValue)
            lock.unlock()
            settingsChangedSubject.send(.fixBrowserAutocomplete)
        }
    }

    public var fixChromiumBrowser: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return defaults.bool(forKey: SettingsKey.fixChromiumBrowser.rawValue)
        }
        set {
            lock.lock()
            defaults.set(newValue, forKey: SettingsKey.fixChromiumBrowser.rawValue)
            lock.unlock()
            settingsChangedSubject.send(.fixChromiumBrowser)
        }
    }

    public var sendKeyStepByStep: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return defaults.bool(forKey: SettingsKey.sendKeyStepByStep.rawValue)
        }
        set {
            lock.lock()
            defaults.set(newValue, forKey: SettingsKey.sendKeyStepByStep.rawValue)
            lock.unlock()
            settingsChangedSubject.send(.sendKeyStepByStep)
        }
    }

    // MARK: - Reset

    public func resetToDefaults() {
        let keys: [SettingsKey] = [
            .inputMethod, .spellCheckEnabled,
            .smartSwitchEnabled, .quickTelexEnabled,
            .launchAtLogin, .showDockIcon, .autoCapitalize,
            .restoreIfWrongSpelling,
            // Advanced settings
            .fixBrowserAutocomplete, .fixChromiumBrowser,
            .sendKeyStepByStep,
        ]

        lock.lock()
        for key in keys {
            defaults.removeObject(forKey: key.rawValue)
        }
        lock.unlock()

        registerDefaults()

        for key in keys {
            settingsChangedSubject.send(key)
        }
    }
}
