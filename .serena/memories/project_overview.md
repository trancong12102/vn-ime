# LotusKey Project Overview

## Purpose
LotusKey is a Vietnamese input method for macOS, rewritten in Swift from [OpenKey](https://github.com/tuyenvm/OpenKey). It uses an advanced backspace technique to provide seamless Vietnamese text input, avoiding underlining issues present in default system input methods.

## Key Features
- **Input Methods**: Telex, Simple Telex
- **Character Encoding**: Unicode only
- **Spell Checking**: Validates Vietnamese word combinations
- **Smart Switch**: Remembers language preference per application
- **Quick Telex**: cc=ch, gg=gi, kk=kh, nn=ng, qq=qu, pp=ph, tt=th
- **Auto-capitalization**: Automatically capitalizes first letter of sentences

## Tech Stack
- **Language**: Swift 6.2+
- **UI Framework**: SwiftUI (Settings), AppKit (Menu bar, CGEventTap)
- **Minimum macOS**: macOS 15.0 (Sequoia)
- **Build System**: Swift Package Manager / Xcode 26+
- **Core Engine**: Complete rewrite in Swift (no C++ wrapping)

## System Requirements
- macOS 15.0+ (Sequoia)
- Accessibility permissions (System Settings → Privacy & Security → Accessibility)
- Cannot be sandboxed due to system-wide keyboard access requirement

## External Dependencies
None - uses only Apple built-in frameworks:
- Carbon.framework (CGEventTap, keyboard event handling)
- AppKit (NSStatusItem, NSMenu, application lifecycle)
- SwiftUI (Settings UI)
- Combine (Reactive settings updates)

## Reference Implementation
- Original OpenKey: https://github.com/tuyenvm/OpenKey
- Key files to reference:
  - `Sources/OpenKey/engine/Engine.cpp` - Main processing logic
  - `Sources/OpenKey/engine/Vietnamese.cpp` - Character tables & rules
  - `Sources/OpenKey/engine/DataType.h` - Data structures & constants
  - `Sources/OpenKey/macOS/ModernKey/OpenKey.mm` - macOS event handling

## Domain Concepts

### Vietnamese Input Method Concepts
- **Tone marks (dấu thanh)**: acute (sắc), grave (huyền), hook (hỏi), tilde (ngã), dot below (nặng)
- **Modifier marks (dấu mũ)**: circumflex (â, ê, ô), breve (ă), horn (ơ, ư), stroke (đ)
- **Mark placement**: Rules for placing tone marks (modern style)
- **Spell checking**: Validate consonant clusters, vowel combinations, valid syllables

### Technical Concepts
- **CGEventTap**: macOS API to intercept keyboard events system-wide
- **Accessibility permissions**: Required to capture keyboard events
- **Backspace technique**: Delete old characters and send newly converted characters

### Data Structures (from Original OpenKey)
- **TypingWord buffer**: Stores current word being typed with metadata (caps, tone, marks)
- **Bit masks**: Encode character state in UInt32:
  - bits 0-15: character code
  - bit 16: caps flag
  - bits 17-18: tone flags (^, w)
  - bits 19-23: mark flags (5 tone marks)
  - bit 24: standalone flag
  - bit 25: character code vs keycode flag
