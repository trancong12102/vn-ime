import Foundation

/// Registry providing centralized access to all available input methods.
///
/// Use this enum to look up input methods by identifier or get the default method.
public enum InputMethodRegistry {
    /// Standard Telex input method
    public static let telex = TelexInputMethod()

    /// Simple Telex variant (no w→ư transformation)
    public static let simpleTelex = SimpleTelexInputMethod()

    /// List of all available input method identifiers
    public static let availableIDs: [String] = ["telex", "simple-telex"]

    /// Default input method (Telex)
    public static var `default`: any InputMethod { telex }

    /// Look up an input method by identifier
    /// - Parameter id: The input method identifier ("telex" or "simple-telex")
    /// - Returns: The input method, or nil if not found
    public static func get(_ id: String) -> (any InputMethod)? {
        switch id.lowercased() {
        case "telex":
            return telex
        case "simple-telex", "simpletelex", "simple_telex":
            return simpleTelex
        default:
            return nil
        }
    }

    /// Get all available input methods as (id, method) pairs
    public static var allMethods: [(id: String, method: any InputMethod)] {
        [
            ("telex", telex),
            ("simple-telex", simpleTelex),
        ]
    }

    /// Get input method by name (case-insensitive)
    /// - Parameter name: The display name (e.g., "Telex", "Simple Telex")
    /// - Returns: The input method, or nil if not found
    public static func getByName(_ name: String) -> (any InputMethod)? {
        let lower = name.lowercased()
        return allMethods.first { $0.method.name.lowercased() == lower }?.method
    }
}
