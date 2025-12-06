# Change: Implement Core Vietnamese Engine

## Why

Spec `core-engine` đã được định nghĩa với 5 requirements, nhưng `DefaultVietnameseEngine` hiện chỉ là stub trả về `.passThrough`. Cần implement đầy đủ logic để có thể xử lý Vietnamese input.

## What Changes

- Implement `TypingBuffer` struct để lưu trữ word đang gõ với full metadata
- Implement `CharacterState` OptionSet cho bit-packed character state
- Implement core processing logic trong `DefaultVietnameseEngine`:
  - Buffer management (add/remove characters)
  - Mark positioning (modern orthography)
  - Word break detection
  - Delete key handling
- Implement `ProcessingResult` communication

## Impact

- **Affected specs**: `core-engine` (implementation only, no spec changes needed)
- **Affected code**:
  - `Sources/VnIme/Core/Engine/VietnameseEngine.swift` (modify)
  - `Sources/VnIme/Core/Engine/TypingBuffer.swift` (new)
  - `Sources/VnIme/Core/Engine/CharacterState.swift` (new)
  - `Tests/VnImeTests/EngineTests.swift` (expand)
  - `Tests/VnImeTests/TypingBufferTests.swift` (new)
  - `Tests/VnImeTests/CharacterStateTests.swift` (new)
