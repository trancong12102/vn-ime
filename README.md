# LotusKey

Bộ gõ tiếng Việt cho macOS, được viết hoàn toàn bằng Swift. Lấy cảm hứng từ [OpenKey](https://github.com/tuyenvm/OpenKey).

## Tính năng

- **Kiểu gõ**: Telex, Simple Telex
- **Quick Telex**: cc=ch, gg=gi, kk=kh, nn=ng, qq=qu, pp=ph, tt=th
- **Kiểm tra chính tả**: Xác thực các tổ hợp từ tiếng Việt
- **Smart Switch**: Nhớ ngôn ngữ theo từng ứng dụng
- **Tự động viết hoa**: Tự động viết hoa chữ cái đầu câu

## Yêu cầu hệ thống

- macOS 15.0 (Sequoia) trở lên
- Quyền truy cập Accessibility (System Settings → Privacy & Security → Accessibility)

## Thiết lập quyền Accessibility

LotusKey cần quyền Accessibility để hoạt động. Khi chạy lần đầu:

1. LotusKey sẽ hiển thị dialog yêu cầu quyền
2. Click **"Open System Settings"**
3. Trong System Settings → Privacy & Security → Accessibility:
   - Tìm LotusKey trong danh sách
   - Bật toggle để cấp quyền
4. Quay lại LotusKey, click **"Check Permission Status"** hoặc **"Continue"**

> **Lưu ý**: Nếu LotusKey không xuất hiện trong danh sách, hãy thử kéo ứng dụng LotusKey vào list hoặc restart ứng dụng.

## Cài đặt

### Từ source

```bash
# Clone repository
git clone https://github.com/lotus-key/lotus-key.git
cd lotus-key

# Build
swift build -c release

# Chạy ứng dụng
.build/release/LotusKey
```

### Từ Release

Tải xuống file `.dmg` từ [Releases](https://github.com/lotus-key/lotus-key/releases) và kéo LotusKey vào thư mục Applications.

## Sử dụng

1. Khởi động LotusKey
2. Cấp quyền Accessibility khi được yêu cầu
3. Icon LotusKey sẽ xuất hiện trên menu bar
4. Click vào icon để chuyển đổi giữa tiếng Việt và tiếng Anh

### Phím tắt

| Phím tắt | Chức năng |
|----------|-----------|
| `Ctrl + Space` | Chuyển đổi Tiếng Việt / Tiếng Anh |
| `Command` (giữ) | Tạm tắt bộ gõ (dùng cho shortcuts) |
| `Control` (giữ) | Tạm tắt kiểm tra chính tả |

> **Mẹo**: Giữ Command khi gõ shortcuts (Cmd+C, Cmd+V) để tránh LotusKey xử lý sai.

### Ứng dụng được hỗ trợ

LotusKey hoạt động với hầu hết các ứng dụng macOS. Một số ứng dụng có workaround đặc biệt:

| Ứng dụng | Ghi chú |
|----------|---------|
| Safari, Notes, TextEdit | Hỗ trợ đầy đủ (Unicode Compound) |
| Chrome, Edge, Brave | Workaround cho địa chỉ bar |
| Sublime Text | Sử dụng ZWNJ thay vì NNBSP |
| Terminal, iTerm2 | Hoạt động bình thường |
| VSCode | Hoạt động bình thường |

### Tương thích bàn phím

LotusKey hỗ trợ các layout bàn phím không phải QWERTY (Dvorak, Colemak, v.v.) thông qua tùy chọn **Layout Compatibility** trong Settings.

### Tương thích với IME khác

LotusKey tự động bypass khi phát hiện IME tiếng Nhật, Trung, Hàn đang hoạt động để tránh xung đột.

### Kiểu gõ Telex

| Phím | Kết quả |
|------|---------|
| aa | â |
| ee | ê |
| oo | ô |
| aw | ă |
| ow | ơ |
| uw | ư |
| dd | đ |
| s | dấu sắc |
| f | dấu huyền |
| r | dấu hỏi |
| x | dấu ngã |
| j | dấu nặng |
| z | xóa dấu |

## Phát triển

### Yêu cầu

- Xcode 26+ hoặc Swift 6.2+
- macOS 15.0+

### Build

```bash
# Build debug
swift build

# Build release
swift build -c release

# Chạy tests
swift test
```

### Cấu trúc dự án

```text
Sources/LotusKey/
├── App/                    # Entry point, AppDelegate
├── Core/                   # Vietnamese input engine
│   ├── Engine/             # Main processing logic
│   ├── InputMethods/       # Telex, Simple Telex handlers
│   ├── CharacterTables/    # Unicode encoding
│   └── Spelling/           # Spell checking rules
├── EventHandling/          # CGEventTap, keyboard hook
├── Features/               # Smart Switch, Quick Telex
├── UI/                     # SwiftUI views, Menu bar
├── Storage/                # UserDefaults, settings
└── Utilities/              # Extensions, helpers
```

## Đóng góp

Mọi đóng góp đều được hoan nghênh! Vui lòng:

1. Fork repository
2. Tạo branch mới (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Tạo Pull Request

## Giấy phép

Dự án này được phân phối theo giấy phép [GNU General Public License v3.0](LICENSE).

## Lời cảm ơn

- [OpenKey](https://github.com/tuyenvm/OpenKey) - Nguồn cảm hứng cho ý tưởng xử lý tiếng Việt trên macOS
- [ibus-bamboo](https://github.com/BambooEngine/ibus-bamboo) - Tham khảo thuật toán spell checking và tone repositioning
