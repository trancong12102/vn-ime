import Foundation

/// Protocol for Quick Telex shortcuts (cc=ch, gg=gi, etc.)
public protocol QuickTelexHandling: Sendable {
    /// Process a character and return expansion if applicable
    /// - Parameters:
    ///   - character: The input character
    ///   - previousCharacter: The previous character in the buffer
    /// - Returns: The expanded string if a shortcut matches, nil otherwise
    func processShortcut(_ character: Character, previousCharacter: Character?) -> String?

    /// Whether Quick Telex is enabled
    var isEnabled: Bool { get set }

    /// Get all available shortcuts
    var shortcuts: [String: String] { get }
}

/// Default Quick Telex implementation
public final class QuickTelex: QuickTelexHandling, @unchecked Sendable {
    public var isEnabled: Bool = true

    // Quick Telex shortcuts: doubled consonants expand to digraphs
    public let shortcuts: [String: String] = [
        "cc": "ch",
        "gg": "gi",
        "kk": "kh",
        "nn": "ng",
        "qq": "qu",
        "pp": "ph",
        "tt": "th",
    ]

    public init() {}

    public func processShortcut(_ character: Character, previousCharacter: Character?) -> String? {
        guard isEnabled,
              let prev = previousCharacter else {
            return nil
        }

        let pair = String([prev, character]).lowercased()

        // Check if the pair matches a shortcut
        if let expansion = shortcuts[pair] {
            // Return the expansion (caller should delete the previous character first)
            return expansion
        }

        return nil
    }
}
