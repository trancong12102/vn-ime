# Change: Add Grammar Auto-Adjust Following OpenKey

## Why

OpenKey has a `checkGrammar()` function (Engine.cpp:290-347) that automatically adjusts vowel modifiers when syllable structure changes during typing. This handles edge cases where horn modifiers are applied in non-standard order.

**Current LotusKey behavior:**
- `thuowng` → "thương" ✅ (w after "o" triggers "uo" pattern detection)
- `thuwong` → "thưong" ❌ (w after "u" only applies horn to u, not auto-fixed later)

**OpenKey behavior:**
- Both inputs produce "thương" because `checkGrammar()` auto-fixes when ending consonant is typed

**Gap:** LotusKey doesn't auto-adjust modifiers after the initial W key press. If user types horn on "u" first, then "o", the XOR pattern (one has horn, other doesn't) is not corrected when ending consonant is added.

## What Changes

1. **Add grammar auto-adjust logic** - Implement OpenKey's `checkGrammar()` equivalent:
   - Triggers when N, C, I, M, P, T is typed after "uo" pattern
   - Uses XOR check: if exactly one of U/O has horn → apply horn to both
   - Prevents double-apply when both already have horn

2. **Integration points:**
   - After `addCharacterToBuffer()` when buffer has 3+ characters
   - After `handleBackspace()` to recalculate
   - Coordinate with `refreshTonePosition()` for correct tone placement

## Impact

- **Affected specs**: `core-engine`
- **Affected code**:
  - `VietnameseEngine.swift` - Add `checkGrammar()` method
- **Risk**: Low - additive change for edge cases, does not affect common typing patterns
- **Testing**: Focus on non-standard typing orders: "thuwon", "thưong", "nưoc", etc.
