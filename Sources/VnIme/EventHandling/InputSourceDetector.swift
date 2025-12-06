import Carbon
import Foundation

/// Protocol for detecting current input source language
public protocol InputSourceDetecting: AnyObject, Sendable {
    /// Get the current input source's primary language code
    /// - Returns: Language code (e.g., "en", "ja", "zh") or nil if unavailable
    func getCurrentInputLanguage() -> String?

    /// Check if the current input source is English
    /// - Returns: true if current input source is English or unknown
    func isEnglishInputSource() -> Bool

    /// Check if the current input source is a CJK input method
    /// - Returns: true if current input source is Chinese, Japanese, or Korean
    func isCJKInputSource() -> Bool
}

/// Detects current system input source using Text Input Services (TIS)
public final class InputSourceDetector: InputSourceDetecting, @unchecked Sendable {
    // MARK: - Language Prefixes

    /// English language prefixes
    private static let englishPrefixes = ["en"]

    /// CJK (Chinese, Japanese, Korean) language prefixes
    private static let cjkPrefixes = ["zh", "ja", "ko"]

    // MARK: - Initialization

    public init() {}

    // MARK: - Detection

    public func getCurrentInputLanguage() -> String? {
        // Get current keyboard input source
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return nil
        }

        // Get the languages property
        guard let languagesPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceLanguages) else {
            return nil
        }

        // Cast to array of strings
        let languages = Unmanaged<CFArray>.fromOpaque(languagesPtr).takeUnretainedValue() as? [String]
        return languages?.first
    }

    public func isEnglishInputSource() -> Bool {
        guard let language = getCurrentInputLanguage() else {
            // If we can't detect, assume English to avoid breaking input
            return true
        }

        // Check if language starts with any English prefix
        for prefix in Self.englishPrefixes {
            if language.hasPrefix(prefix) {
                return true
            }
        }

        return false
    }

    public func isCJKInputSource() -> Bool {
        guard let language = getCurrentInputLanguage() else {
            return false
        }

        // Check if language starts with any CJK prefix
        for prefix in Self.cjkPrefixes {
            if language.hasPrefix(prefix) {
                return true
            }
        }

        return false
    }
}

// MARK: - Additional Input Source Information

extension InputSourceDetector {
    /// Get the input source identifier (e.g., "com.apple.keylayout.US")
    public func getCurrentInputSourceIdentifier() -> String? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return nil
        }

        guard let idPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else {
            return nil
        }

        return Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String
    }

    /// Get the input source localized name
    public func getCurrentInputSourceName() -> String? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return nil
        }

        guard let namePtr = TISGetInputSourceProperty(source, kTISPropertyLocalizedName) else {
            return nil
        }

        return Unmanaged<CFString>.fromOpaque(namePtr).takeUnretainedValue() as String
    }

    /// Check if the current input source is a keyboard layout (not an IME)
    public func isKeyboardLayout() -> Bool {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return true
        }

        guard let categoryPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceCategory) else {
            return true
        }

        let category = Unmanaged<CFString>.fromOpaque(categoryPtr).takeUnretainedValue() as String
        return category == kTISCategoryKeyboardInputSource as String
    }
}
