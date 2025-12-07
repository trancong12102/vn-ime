# Change: Cải thiện GUI Settings - Expose các tính năng đã implement

## Why

LotusKey đã implement nhiều tính năng trong engine nhưng chưa expose hết trong GUI Settings. User cần có thể cấu hình các tính năng đã có, đặc biệt là "Restore if wrong spelling" - một tính năng hữu ích khi gõ sai từ.

## What Changes

### 1. **BUG FIX** - Sửa @AppStorage keys không khớp với SettingsKey
- **FIXED** `SettingsView.swift` sử dụng keys ngắn (`"launchAtLogin"`) trong khi `SettingsStore` sử dụng keys với prefix (`"LotusKeyLaunchAtLogin"`)
- Điều này khiến UI và engine sử dụng **2 UserDefaults keys khác nhau**
- Cần thống nhất tất cả về sử dụng `SettingsKey.rawValue`

### 2. Expose "Restore if wrong spelling" setting
- **ADDED** Toggle "Khôi phục phím gốc khi từ không hợp lệ" trong Spelling settings
- Setting này đã implement trong engine (`restoreIfWrongSpelling`) nhưng chưa có UI

### 3. Thêm mô tả cho Ctrl bypass
- **ADDED** Help text giải thích rằng giữ Ctrl sẽ tạm thời tắt spell checking
- Tính năng này đã hoạt động (engine checks `tempOffSpellChecking` when Ctrl pressed)

### 4. Cải thiện tổ chức Settings UI
- **MODIFIED** Thêm GroupBox "Spelling" riêng biệt để nhóm các spelling options
- **MODIFIED** Cải thiện layout với dependent toggles (sub-options disabled khi master toggle off)

## Impact

- **Affected specs**: `ui-settings`
- **Affected code**:
  - `Sources/LotusKey/Storage/SettingsStore.swift` - Thêm 1 settings key mới
  - `Sources/LotusKey/UI/SettingsView.swift` - **Fix @AppStorage keys**, thêm toggle và cải thiện layout
  - `Sources/LotusKey/App/AppDelegate.swift` - Wire setting mới vào engine

## Out of Scope

Các tính năng sau KHÔNG trong phạm vi change này vì **chưa implement trong engine**:
- Modern orthography (oà, uý vs òa, úy) - Engine chưa support
- Allow ZWJF consonants - Engine chưa support
- Quick Start Consonant (f→ph, j→gi, w→qu) - Engine chưa support
- Quick End Consonant (g→ng, h→nh, k→ch) - Engine chưa support
- Custom hotkey configuration - HotkeyDetector chưa support custom keys
- Gray menu bar icon - Cần implementation riêng
- Browser fixes - Cần investigation riêng
