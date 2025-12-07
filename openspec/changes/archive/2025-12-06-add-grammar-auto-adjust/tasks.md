# Tasks: Add Grammar Auto-Adjust

## 1. Research & Analysis
- [x] 1.1 Analyze OpenKey `checkGrammar()` function (Engine.cpp:290-347)
- [x] 1.2 Analyze LotusKey current "uo" pattern handling (VietnameseEngine:451-456)
- [x] 1.3 Identify actual gap: non-standard typing orders (thuwon, nưoc)
- [x] 1.4 Document XOR logic for modifier auto-correction

## 2. Implementation - Grammar Auto-Adjust
- [x] 2.1 Add `checkGrammar()` method to `DefaultVietnameseEngine`
  ```swift
  /// Check for "uo" pattern with partial horn and auto-correct
  /// Called after adding characters that may trigger adjustment
  private func checkGrammar() -> Bool {
      // Find "uo" pattern where exactly one has horn (XOR)
      // If found, apply horn to both
  }
  ```

- [x] 2.2 Integrate into character processing flow
  - Call after `addCharacterToBuffer()` when character is trigger (n, c, i, m, p, t)
  - Only check if buffer.count >= 3
  - Generate correct output if adjustment made

- [x] 2.3 Handle output generation when grammar adjusts
  - Calculate correct backspace count (from vowel start)
  - Return adjusted characters

## 3. Testing - Focus on Non-Standard Orders
- [x] 3.1 Unit tests for "ưo" → "ươ" (u has horn, o doesn't)
  - `thuwon` → "thươn" ✓
  - `nuwoc` → "nươc" ✓
  - `dduwoc` → "đươc" ✓
  - `thuwongs` → "thướng" ✓
  - `nuwocs` → "nước" ✓
  - `dduwocj` → "được" ✓

- [x] 3.2 Unit tests for "uơ" → "ươ" (o has horn, u doesn't)
  - `u[n` → "ươn" (bracket key adds ơ) ✓
  - `thu[n` → "thươn" ✓

- [x] 3.3 Unit tests for no-change cases
  - `thuon` → "thuon" (neither has horn, no auto-apply) ✓
  - `thuwown` → "thươn" (both have horn, no double-apply) ✓
  - `nuwowc` → "nươc" (standard typing, no double-apply) ✓

- [x] 3.4 Integration tests with backspace
  - Type "thuwon", backspace, verify state ("thươ") ✓

## 4. Documentation
- [x] 4.1 Add inline comments explaining XOR logic
- [x] 4.2 Update spec if needed
