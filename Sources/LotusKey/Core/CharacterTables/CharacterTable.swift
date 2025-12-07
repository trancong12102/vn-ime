import Foundation

/// Protocol for character encoding tables
public protocol CharacterTable: Sendable {
    /// The name of the encoding
    var name: String { get }

    /// Convert a Vietnamese character to its encoded representation
    /// - Parameter character: The Unicode Vietnamese character
    /// - Returns: The encoded string representation
    func encode(_ character: Character) -> String

    /// Convert an encoded representation back to Unicode
    /// - Parameter encoded: The encoded string
    /// - Returns: The Unicode character, if valid
    func decode(_ encoded: String) -> Character?

    /// Check if this table supports a given character
    /// - Parameter character: The character to check
    /// - Returns: True if the character can be encoded
    func supports(_ character: Character) -> Bool
}

/// Unicode encoding (standard, no conversion needed)
public struct UnicodeCharacterTable: CharacterTable {
    public let name = "Unicode"

    public init() {}

    public func encode(_ character: Character) -> String {
        String(character)
    }

    public func decode(_ encoded: String) -> Character? {
        encoded.first
    }

    public func supports(_ character: Character) -> Bool {
        true
    }
}
