# Design: Grammar Auto-Adjust

## Context

OpenKey implements `checkGrammar()` (Engine.cpp:290-347) that automatically adjusts vowel modifiers when syllable structure changes. This handles edge cases where users type horn modifiers in non-standard order.

**Important clarification:** LotusKey already handles the common case correctly:
- `thuowng` → "thương" ✅ (applyModifier(.horn) detects "uo" pattern at line 451-456)

**The gap is for non-standard typing orders:**
- `thuwong` → LotusKey: "thưong" ❌, OpenKey: "thương" ✅
- `nưoc` → LotusKey: "nưoc" ❌, OpenKey: "nước" ✅

**OpenKey's XOR logic (Engine.cpp:308):**
```cpp
// Only adjust if EXACTLY ONE vowel has horn (XOR = true)
// This handles: ưo → ươ, uơ → ươ
// But NOT: uo → ươ (both have no horn, XOR = false)
// And NOT: ươ → ươ (both have horn, XOR = false)
if ((TypingWord[i-1] & TONEW_MASK) ^ (TypingWord[i-2] & TONEW_MASK)) {
    TypingWord[i - 2] |= TONEW_MASK;  // U → Ư
    TypingWord[i - 1] |= TONEW_MASK;  // O → Ơ
}
```

## Goals / Non-Goals

**Goals:**
- Handle non-standard typing orders: "thuwon" → "thương"
- Match OpenKey's XOR-based auto-correction
- Minimal code change, focused on edge cases

**Non-Goals:**
- Changing standard typing flow (already works)
- Dictionary-based spell checking (future feature)
- Old orthography support (LotusKey only supports modern)

## Decisions

### Decision 1: Where to implement grammar checking

**Option A**: In `TypingBuffer` (data layer)
- Pro: Close to data, can be called from multiple places
- Con: Buffer shouldn't have business logic

**Option B**: In `DefaultVietnameseEngine` (chosen)
- Pro: Engine already has spell checking, keeps logic centralized
- Pro: Has access to both buffer and input method state
- Con: Slightly more complex method

**Chosen: Option B** - Keep grammar checking in engine alongside spell checking.

### Decision 2: When to trigger grammar checking

Trigger `checkGrammar()` after:
1. `addCharacterToBuffer()` - new character may complete pattern
2. `handleBackspace()` - removing character may break pattern
3. `applyModifier()` - modifier change may need adjustment

### Decision 3: XOR vs Always-Apply for modifiers

**OpenKey approach (chosen):**
```cpp
// Only adjust if exactly one vowel has horn (XOR)
if ((TypingWord[i-1] & TONEW_MASK) ^ (TypingWord[i-2] & TONEW_MASK))
```

This prevents double-applying when user explicitly typed "ươ" already.

## Algorithm

```swift
func checkGrammar() -> Bool {
    // 1. Find vowel positions
    let vowelPositions = buffer.findVowelPositions()
    guard vowelPositions.count >= 2 else { return false }

    // 2. Check for "uo" + ending pattern
    let chars = buffer.allCharacters
    for i in stride(from: buffer.count - 1, through: 2, by: -1) {
        let base = chars[i].baseCharacter

        // Check if current char is valid ending consonant
        guard isGrammarTriggerConsonant(base) else { continue }

        // Check for "uo" pattern before it
        let oIndex = i - 1
        let uIndex = i - 2

        guard chars[oIndex].baseCharacter == "o",
              chars[uIndex].baseCharacter == "u" else { continue }

        let oHasHorn = chars[oIndex].state.contains(.hornOrBreve)
        let uHasHorn = chars[uIndex].state.contains(.hornOrBreve)

        // XOR check: exactly one has horn → apply to both
        if oHasHorn != uHasHorn {
            buffer[uIndex].state.insert(.hornOrBreve)
            buffer[oIndex].state.insert(.hornOrBreve)
            return true
        }
    }
    return false
}

func isGrammarTriggerConsonant(_ char: Character?) -> Bool {
    guard let c = char else { return false }
    return ["n", "c", "i", "m", "p", "t"].contains(c)
}
```

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Performance overhead | Only check when buffer has 3+ chars |
| Breaking existing tests | Run full test suite before merge |
| Edge cases in "qu"/"gi" clusters | Vowel position finder already handles these |

## Migration Plan

1. Add feature behind internal flag initially
2. Run comprehensive testing
3. Enable by default
4. No user-facing migration needed (behavior improvement)

## Open Questions

1. Should grammar adjustment be reversible via undo?
   - **Current answer**: No, treat as automatic correction (matches OpenKey)

2. Should we show visual feedback when grammar adjusts?
   - **Current answer**: No, seamless adjustment (matches OpenKey)
