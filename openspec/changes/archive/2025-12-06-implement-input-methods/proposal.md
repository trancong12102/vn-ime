# Change: Implement Complete Input Methods

## Why
Core engine is complete but input method layer lacks critical features: undo transformation (e.g., 'aaa' → 'aa'), Simple Telex variants, bracket key shortcuts, and proper Quick Telex integration. Without these, the IME cannot match OpenKey's user experience.

## What Changes
- **Telex Undo**: Typing same modifier twice undoes transformation (aaa → aa, www → ww, dd → d after đ)
- **Tone Undo**: Typing same tone key twice removes tone mark
- **Temp Disable After Undo**: After undo, same key is temporarily disabled to prevent re-transformation
- **Simple Telex 1 & 2**: Same as Telex but:
  - 'w' after 'o'/'u' does NOT convert to ơ/ư (e.g., 'ow' stays 'ow')
  - 'aw' → 'ă' still works (breve transformation preserved)
  - Standalone 'w' does NOT convert to 'ư' (unlike Telex)
- **Bracket Key Shortcuts**: `[` → 'ơ' and `]` → 'ư' as standalone characters
- **Quick Telex Integration**: Wire QuickTelex shortcuts into VietnameseEngine
- **Quick Start/End Consonants**: Support for f→ph, j→gi, w→qu (start) and g→ng, h→nh, k→ch (end) - **Deferred to future change**
- **Input Method Registry**: Centralized access to all available input methods

## Impact

- Affected specs: `input-methods`
- Affected code:
  - `Sources/LotusKey/Core/InputMethods/TelexInputMethod.swift`
  - `Sources/LotusKey/Core/InputMethods/InputMethod.swift`
  - `Sources/LotusKey/Core/Engine/VietnameseEngine.swift`
  - `Sources/LotusKey/Features/QuickTelex.swift` (integration)
- New files:
  - `Sources/LotusKey/Core/InputMethods/SimpleTelexInputMethod.swift`
  - `Sources/LotusKey/Core/InputMethods/InputMethodRegistry.swift`

## Non-Goals (Future Changes)

- **VNI Input Method**: Planned for separate change proposal
- **Quick Start/End Consonants**: f→ph, j→gi, etc. - Planned for separate change proposal
- **VIQR Input Method**: Low priority, may be added later
- **Custom key mapping configuration**: Not planned
