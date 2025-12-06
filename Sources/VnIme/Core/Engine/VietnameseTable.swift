import Foundation

/// Lookup table for Vietnamese Unicode characters (NFC pre-composed form).
///
/// Provides efficient conversion from base vowel + modifier + tone mark
/// to the correct pre-composed Unicode character.
public enum VietnameseTable {
    // MARK: - Vowel Tables

    // Each vowel has 6 variants: base, sắc, huyền, hỏi, ngã, nặng
    // Index: 0=none, 1=acute, 2=grave, 3=hook, 4=tilde, 5=dotBelow

    // a variants (no modifier)
    private static let aTable: [Character] = ["a", "á", "à", "ả", "ã", "ạ"]
    // ă variants (breve modifier)
    private static let awTable: [Character] = ["ă", "ắ", "ằ", "ẳ", "ẵ", "ặ"]
    // â variants (circumflex modifier)
    private static let aaTable: [Character] = ["â", "ấ", "ầ", "ẩ", "ẫ", "ậ"]

    // e variants
    private static let eTable: [Character] = ["e", "é", "è", "ẻ", "ẽ", "ẹ"]
    // ê variants (circumflex)
    private static let eeTable: [Character] = ["ê", "ế", "ề", "ể", "ễ", "ệ"]

    // i variants
    private static let iTable: [Character] = ["i", "í", "ì", "ỉ", "ĩ", "ị"]

    // o variants
    private static let oTable: [Character] = ["o", "ó", "ò", "ỏ", "õ", "ọ"]
    // ô variants (circumflex)
    private static let ooTable: [Character] = ["ô", "ố", "ồ", "ổ", "ỗ", "ộ"]
    // ơ variants (horn)
    private static let owTable: [Character] = ["ơ", "ớ", "ờ", "ở", "ỡ", "ợ"]

    // u variants
    private static let uTable: [Character] = ["u", "ú", "ù", "ủ", "ũ", "ụ"]
    // ư variants (horn)
    private static let uwTable: [Character] = ["ư", "ứ", "ừ", "ử", "ữ", "ự"]

    // y variants
    private static let yTable: [Character] = ["y", "ý", "ỳ", "ỷ", "ỹ", "ỵ"]

    // đ (has no tone mark variants)
    private static let dTable: [Character] = ["đ"]

    // MARK: - Uppercase Tables

    private static let ATable: [Character] = ["A", "Á", "À", "Ả", "Ã", "Ạ"]
    private static let AwTable: [Character] = ["Ă", "Ắ", "Ằ", "Ẳ", "Ẵ", "Ặ"]
    private static let AaTable: [Character] = ["Â", "Ấ", "Ầ", "Ẩ", "Ẫ", "Ậ"]

    private static let ETable: [Character] = ["E", "É", "È", "Ẻ", "Ẽ", "Ẹ"]
    private static let EeTable: [Character] = ["Ê", "Ế", "Ề", "Ể", "Ễ", "Ệ"]

    private static let ITable: [Character] = ["I", "Í", "Ì", "Ỉ", "Ĩ", "Ị"]

    private static let OTable: [Character] = ["O", "Ó", "Ò", "Ỏ", "Õ", "Ọ"]
    private static let OoTable: [Character] = ["Ô", "Ố", "Ồ", "Ổ", "Ỗ", "Ộ"]
    private static let OwTable: [Character] = ["Ơ", "Ớ", "Ờ", "Ở", "Ỡ", "Ợ"]

    private static let UTable: [Character] = ["U", "Ú", "Ù", "Ủ", "Ũ", "Ụ"]
    private static let UwTable: [Character] = ["Ư", "Ứ", "Ừ", "Ử", "Ữ", "Ự"]

    private static let YTable: [Character] = ["Y", "Ý", "Ỳ", "Ỷ", "Ỹ", "Ỵ"]

    private static let DTable: [Character] = ["Đ"]

    // MARK: - Lookup

    /// Convert a TypedCharacter to its Unicode representation
    public static func toUnicode(_ typed: TypedCharacter) -> Character? {
        guard let base = typed.baseCharacter else { return nil }

        let isUpper = typed.state.contains(.caps)
        let markIndex = toneMarkIndex(typed.state)

        // Handle đ/Đ separately (no tone marks)
        // Support both .stroke (new) and .hornOrBreve (legacy) for backwards compatibility
        if base == "d" && (typed.state.contains(.stroke) || typed.state.contains(.hornOrBreve)) {
            return isUpper ? "Đ" : "đ"
        }

        // Get the appropriate table
        guard let table = getTable(base: base, state: typed.state, uppercase: isUpper) else {
            // Not a Vietnamese vowel, return base character
            return isUpper ? Character(base.uppercased()) : base
        }

        // Return character with tone mark
        guard markIndex < table.count else { return table[0] }
        return table[markIndex]
    }

    /// Get tone mark index (0-5)
    private static func toneMarkIndex(_ state: CharacterState) -> Int {
        if state.contains(.acute) { return 1 }
        if state.contains(.grave) { return 2 }
        if state.contains(.hook) { return 3 }
        if state.contains(.tilde) { return 4 }
        if state.contains(.dotBelow) { return 5 }
        return 0
    }

    /// Get the character table for a base vowel
    private static func getTable(base: Character, state: CharacterState, uppercase: Bool) -> [Character]? {
        let hasCircumflex = state.contains(.circumflex)
        let hasHornOrBreve = state.contains(.hornOrBreve)

        switch base {
        case "a":
            if hasCircumflex {
                return uppercase ? AaTable : aaTable
            } else if hasHornOrBreve {
                return uppercase ? AwTable : awTable
            } else {
                return uppercase ? ATable : aTable
            }

        case "e":
            if hasCircumflex {
                return uppercase ? EeTable : eeTable
            } else {
                return uppercase ? ETable : eTable
            }

        case "i":
            return uppercase ? ITable : iTable

        case "o":
            if hasCircumflex {
                return uppercase ? OoTable : ooTable
            } else if hasHornOrBreve {
                return uppercase ? OwTable : owTable
            } else {
                return uppercase ? OTable : oTable
            }

        case "u":
            if hasHornOrBreve {
                return uppercase ? UwTable : uwTable
            } else {
                return uppercase ? UTable : uTable
            }

        case "y":
            return uppercase ? YTable : yTable

        default:
            return nil
        }
    }

    // MARK: - Reverse Lookup

    /// Parse a Vietnamese character back to base + state
    public static func parse(_ char: Character) -> (base: Character, state: CharacterState)? {
        let lowercased = char.lowercased().first ?? char
        let isUpper = char.isUppercase

        // Check all tables
        for (baseChar, tables) in allTables {
            for (modState, table) in tables {
                if let index = table.firstIndex(of: lowercased) {
                    var state = modState
                    if isUpper { state.insert(.caps) }
                    if index > 0 { state.insert(indexToMark(index)) }
                    return (baseChar, state)
                }
            }
        }

        // Not a Vietnamese character
        return nil
    }

    /// Convert tone mark index to CharacterState
    private static func indexToMark(_ index: Int) -> CharacterState {
        switch index {
        case 1:
            return .acute
        case 2:
            return .grave
        case 3:
            return .hook
        case 4:
            return .tilde
        case 5:
            return .dotBelow
        default:
            return []
        }
    }

    /// All tables organized by base character and modifier
    private static let allTables: [(Character, [(CharacterState, [Character])])] = [
        ("a", [([], aTable), (.circumflex, aaTable), (.hornOrBreve, awTable)]),
        ("e", [([], eTable), (.circumflex, eeTable)]),
        ("i", [([], iTable)]),
        ("o", [([], oTable), (.circumflex, ooTable), (.hornOrBreve, owTable)]),
        ("u", [([], uTable), (.hornOrBreve, uwTable)]),
        ("y", [([], yTable)]),
    ]
}

// MARK: - TypingBuffer Unicode Extension

public extension TypingBuffer {
    /// Convert the entire buffer to a Unicode string
    func toUnicodeString() -> String {
        var result = ""
        result.reserveCapacity(count)

        for typed in allCharacters {
            if let unicode = VietnameseTable.toUnicode(typed) {
                result.append(unicode)
            } else if let base = typed.baseCharacter {
                // Non-Vietnamese character, use base with caps
                let char = typed.isUppercase ? Character(base.uppercased()) : base
                result.append(char)
            }
        }

        return result
    }
}
