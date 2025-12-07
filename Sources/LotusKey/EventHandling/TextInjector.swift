import Carbon
import Foundation

/// Protocol for text injection into applications
public protocol TextInjecting: AnyObject, Sendable {
    /// Inject backspace key presses
    /// - Parameters:
    ///   - count: Number of backspaces to inject
    ///   - proxy: Event tap proxy for posting events
    func injectBackspaces(count: Int, proxy: CGEventTapProxy)

    /// Inject a Unicode string
    /// - Parameters:
    ///   - string: The string to inject
    ///   - proxy: Event tap proxy for posting events
    func injectString(_ string: String, proxy: CGEventTapProxy)

    /// Inject an empty character (for browser autocomplete fixes)
    /// - Parameter proxy: Event tap proxy for posting events
    func injectEmptyCharacter(proxy: CGEventTapProxy)

    /// Inject Shift+LeftArrow key presses (for Chromium workaround)
    /// - Parameters:
    ///   - count: Number of Shift+LeftArrow presses
    ///   - proxy: Event tap proxy for posting events
    func injectShiftLeftArrow(count: Int, proxy: CGEventTapProxy)

    /// Configure the injector with application quirks
    /// - Parameter quirk: The application quirk to use
    func setAppQuirk(_ quirk: AppQuirk)

    /// Enable or disable step-by-step mode
    var sendKeyStepByStep: Bool { get set }

    /// Enable or disable browser autocomplete fix
    var fixBrowserAutocomplete: Bool { get set }

    /// Enable or disable Chromium browser workaround
    var fixChromiumBrowser: Bool { get set }
}

/// Application-specific quirks for text injection
public enum AppQuirk: Sendable, Equatable {
    /// Standard behavior (default)
    case standard
    /// Sublime Text - uses ZWNJ (0x200C) for empty character
    case sublimeText
    /// Chromium-based browsers - uses Shift+Arrow for backspace
    case chromiumBrowser
    /// Special Unicode Compound handling for Apple apps
    case unicodeCompound
}

/// Handles text injection with application-specific workarounds
public final class TextInjector: TextInjecting, @unchecked Sendable {
    // MARK: - Constants

    /// Narrow No-Break Space (NNBSP) - used as empty character for most apps
    private static let nnbsp: UniChar = 0x202F
    /// Zero-Width Non-Joiner (ZWNJ) - used for Sublime Text
    private static let zwnj: UniChar = 0x200C
    /// Maximum characters per batch event
    private static let maxBatchSize = 16
    /// Left Arrow key code
    private static let leftArrowKeyCode: UInt16 = 0x7B
    /// Backspace key code
    private static let backspaceKeyCode: UInt16 = 0x33

    // MARK: - Properties

    /// Private event source for own-event identification
    private let eventSource: CGEventSource

    /// Pre-created backspace events for performance
    private let backspaceKeyDown: CGEvent
    private let backspaceKeyUp: CGEvent

    /// Current application quirk
    private var currentQuirk: AppQuirk = .standard

    /// Configuration options
    public var sendKeyStepByStep: Bool = false
    public var fixBrowserAutocomplete: Bool = true
    public var fixChromiumBrowser: Bool = true

    // MARK: - Initialization

    public init?() {
        guard let source = CGEventSource(stateID: .privateState) else {
            return nil
        }
        self.eventSource = source

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: Self.backspaceKeyCode, keyDown: true),
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: Self.backspaceKeyCode, keyDown: false)
        else {
            return nil
        }

        self.backspaceKeyDown = keyDown
        self.backspaceKeyUp = keyUp
    }

    /// Initialize with an existing event source (for sharing with KeyboardEventHandler)
    public init?(eventSource: CGEventSource) {
        self.eventSource = eventSource

        guard let keyDown = CGEvent(keyboardEventSource: eventSource, virtualKey: Self.backspaceKeyCode, keyDown: true),
            let keyUp = CGEvent(keyboardEventSource: eventSource, virtualKey: Self.backspaceKeyCode, keyDown: false)
        else {
            return nil
        }

        self.backspaceKeyDown = keyDown
        self.backspaceKeyUp = keyUp
    }

    // MARK: - Configuration

    public func setAppQuirk(_ quirk: AppQuirk) {
        currentQuirk = quirk
    }

    // MARK: - Text Injection

    public func injectBackspaces(count: Int, proxy: CGEventTapProxy) {
        guard count > 0 else { return }

        var remainingCount = count

        // For Chromium browsers with fix enabled, use Shift+LeftArrow workaround
        // OpenKey pattern (OpenKey.mm:721-725):
        //   if (backspaceCount > 0) {
        //       SendShiftAndLeftArrow();  // Always send once
        //       if (backspaceCount == 1) backspaceCount--;  // Only decrement if == 1
        //   }
        //   // Then loop sends backspaceCount backspaces
        //
        // This means:
        //   count=1: Shift+Arrow, then 0 backspaces (new text replaces selection)
        //   count=2: Shift+Arrow, then 2 backspaces
        //   count=3: Shift+Arrow, then 3 backspaces
        if currentQuirk == .chromiumBrowser && fixChromiumBrowser {
            // Select 1 character with Shift+LeftArrow
            injectShiftLeftArrow(count: 1, proxy: proxy)

            // Only decrement if count == 1 (selection replaces the char)
            // If count > 1, we still need all backspaces after selection
            if remainingCount == 1 {
                remainingCount = 0
            }
            // Otherwise remainingCount stays the same - we send all backspaces
        } else if fixBrowserAutocomplete && currentQuirk != .sublimeText {
            // For non-Chromium apps: inject empty character first to fix autocomplete
            // Note: Sublime Text uses ZWNJ which doesn't need extra backspace
            injectEmptyCharacter(proxy: proxy)
            // Increase count to delete the empty char we just injected
            remainingCount += 1
        }

        // Standard backspace injection for remaining count
        for _ in 0..<remainingCount {
            injectSingleBackspace(proxy: proxy)
        }
    }

    public func injectString(_ string: String, proxy: CGEventTapProxy) {
        guard !string.isEmpty else { return }

        if sendKeyStepByStep {
            // Step-by-step mode: inject each character separately
            for char in string {
                injectSingleCharacter(char, proxy: proxy)
            }
        } else {
            // Batch mode: inject up to 16 characters at a time
            injectBatchCharacters(string, proxy: proxy)
        }
    }

    public func injectEmptyCharacter(proxy: CGEventTapProxy) {
        let emptyChar: UniChar = (currentQuirk == .sublimeText) ? Self.zwnj : Self.nnbsp

        guard let keyDown = CGEvent(keyboardEventSource: eventSource, virtualKey: 0, keyDown: true),
            let keyUp = CGEvent(keyboardEventSource: eventSource, virtualKey: 0, keyDown: false)
        else { return }

        var chars: [UniChar] = [emptyChar]
        keyDown.keyboardSetUnicodeString(stringLength: 1, unicodeString: &chars)
        keyUp.keyboardSetUnicodeString(stringLength: 1, unicodeString: &chars)

        keyDown.tapPostEvent(proxy)
        keyUp.tapPostEvent(proxy)
    }

    public func injectShiftLeftArrow(count: Int, proxy: CGEventTapProxy) {
        guard count > 0 else { return }

        guard
            let keyDown = CGEvent(
                keyboardEventSource: eventSource, virtualKey: Self.leftArrowKeyCode, keyDown: true),
            let keyUp = CGEvent(
                keyboardEventSource: eventSource, virtualKey: Self.leftArrowKeyCode, keyDown: false)
        else { return }

        // Add Shift modifier
        keyDown.flags = .maskShift
        keyUp.flags = .maskShift

        for _ in 0..<count {
            keyDown.tapPostEvent(proxy)
            keyUp.tapPostEvent(proxy)
        }
    }

    // MARK: - Private Methods

    private func injectSingleBackspace(proxy: CGEventTapProxy) {
        backspaceKeyDown.tapPostEvent(proxy)
        backspaceKeyUp.tapPostEvent(proxy)
    }

    private func injectSingleCharacter(_ char: Character, proxy: CGEventTapProxy) {
        guard !char.unicodeScalars.isEmpty else { return }

        let utf16 = Array(char.utf16)
        guard !utf16.isEmpty else { return }

        guard let keyDown = CGEvent(keyboardEventSource: eventSource, virtualKey: 0, keyDown: true),
            let keyUp = CGEvent(keyboardEventSource: eventSource, virtualKey: 0, keyDown: false)
        else { return }

        var chars = utf16.map { UniChar($0) }
        keyDown.keyboardSetUnicodeString(stringLength: chars.count, unicodeString: &chars)
        keyUp.keyboardSetUnicodeString(stringLength: chars.count, unicodeString: &chars)

        keyDown.tapPostEvent(proxy)
        keyUp.tapPostEvent(proxy)
    }

    private func injectBatchCharacters(_ string: String, proxy: CGEventTapProxy) {
        let utf16 = Array(string.utf16)

        // Process in batches of up to maxBatchSize
        var offset = 0
        while offset < utf16.count {
            let batchSize = min(Self.maxBatchSize, utf16.count - offset)
            var batch = Array(utf16[offset..<(offset + batchSize)]).map { UniChar($0) }

            guard let keyDown = CGEvent(keyboardEventSource: eventSource, virtualKey: 0, keyDown: true),
                let keyUp = CGEvent(keyboardEventSource: eventSource, virtualKey: 0, keyDown: false)
            else {
                offset += batchSize
                continue
            }

            keyDown.keyboardSetUnicodeString(stringLength: batch.count, unicodeString: &batch)
            keyUp.keyboardSetUnicodeString(stringLength: batch.count, unicodeString: &batch)

            keyDown.tapPostEvent(proxy)
            keyUp.tapPostEvent(proxy)

            offset += batchSize
        }
    }
}
