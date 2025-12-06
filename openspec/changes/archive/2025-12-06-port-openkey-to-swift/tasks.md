# Tasks: Port OpenKey to Swift - Research Phase

## 1. Nghiên cứu kiến trúc OpenKey

- [x] 1.1 Tìm hiểu tổng quan kiến trúc hệ thống (Core Engine, Platform Layer)
- [x] 1.2 Phân tích cấu trúc dữ liệu TypingWord buffer và bit masks
- [x] 1.3 Nghiên cứu luồng xử lý event (CGEventTap → vKeyHandleEvent → Output)
- [x] 1.4 Tìm hiểu cơ chế backspace-and-replace

## 2. Nghiên cứu Core Engine

- [x] 2.1 Phân tích Engine.cpp - logic xử lý chính
- [x] 2.2 Phân tích Vietnamese.cpp - bảng ký tự Unicode
- [x] 2.3 Phân tích DataType.h - cấu trúc dữ liệu và hằng số
- [x] 2.4 Tài liệu hóa thuật toán mark positioning (modern orthography only)
- [x] 2.5 Tài liệu hóa thuật toán spell checking

## 3. Nghiên cứu Input Methods

- [x] 3.1 Tài liệu hóa quy tắc Telex (vowel transforms, tone marks)
- [x] 3.2 Tài liệu hóa Simple Telex variants
- [x] 3.3 Tài liệu hóa Quick Telex shortcuts

## 4. Nghiên cứu macOS Platform Integration

- [x] 4.1 Phân tích OpenKey.mm - CGEventTap implementation
- [x] 4.2 Tài liệu hóa cách xử lý compatibility với các app (browsers, editors)
- [x] 4.3 Phân tích Smart Switch mechanism

## 5. Thiết kế Swift Architecture

- [x] 5.1 Thiết kế project structure cho Swift
- [x] 5.2 Thiết kế Swift equivalents cho C++ data structures
- [x] 5.3 Thiết kế protocol-oriented architecture
- [x] 5.4 Xác định testing strategy

## 6. Tài liệu hóa

- [x] 6.1 Viết proposal.md
- [x] 6.2 Viết design.md với chi tiết kiến trúc
- [x] 6.3 Viết spec deltas cho tất cả capabilities
- [x] 6.4 Validate proposal với openspec
