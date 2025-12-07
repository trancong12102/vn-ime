# Change: Add Break Keycode Handling

## Why

ESC key và các navigation keys (arrows, Tab, Enter) hiện không được xử lý đúng cách. Khi user gõ "ho" rồi bấm ESC, engine không reset session mà thêm ESC character (`\u{1B}`) vào buffer, gây ra ký tự lạ khi gõ tiếp.

**Root cause:** LotusKey kiểm tra word break bằng character (`isWordBreak(char)`), trong khi OpenKey kiểm tra bằng keycode (`isWordBreak(keycode)`). ESC character (`\u{1B}`) không có trong `wordBreakChars` set.

## What Changes

- **ADDED** Break keycodes system theo OpenKey pattern:
  - Tạo danh sách break keycodes (ESC, Tab, Enter, arrows, etc.)
  - Kiểm tra keycode TRƯỚC khi kiểm tra character
  - Reset engine session khi break keycode được detect

- **MODIFIED** Event handling flow:
  - Thêm keycode-based break detection trong `processKey()`
  - Phân biệt character keys (punctuation) vs non-character keys (navigation)
  - Character break keys được pass-through sau reset
  - Non-character break keys suppress character output

- **ADDED** Platform-specific keycode constants:
  - macOS key codes cho navigation và punctuation keys
  - Extensible design cho future cross-platform support

## Impact

- **Affected specs**:
  - `specs/event-handling/spec.md` - keyboard event processing
  - `specs/core-engine/spec.md` - word break detection

- **Affected code**:
  - `Sources/LotusKey/Core/Engine/VietnameseEngine.swift` - processKey logic
  - `Sources/LotusKey/Core/Engine/TypedCharacter.swift` - keycode constants
  - `Sources/LotusKey/Utilities/Extensions.swift` - NSEvent.KeyCode enum

## Reference

OpenKey implementation:
- `OpenKey/Sources/OpenKey/engine/Engine.cpp` lines 21-28: `_breakCode` array
- `OpenKey/Sources/OpenKey/engine/Engine.cpp` lines 145-154: `isWordBreak()` function
- `OpenKey/Sources/OpenKey/engine/platforms/mac.h`: macOS key code definitions
