# Project Context

## Purpose
OpenKey Swift is a port of OpenKey to Swift - an open-source Vietnamese input method application for macOS. The application uses an advanced backspace technique to provide seamless Vietnamese text input, eliminating the underlining issues present in default system input methods.

### Key Features
- **Input Methods**: Telex, VNI, Simple Telex
- **Character Encodings**: Unicode, TCVN3 (ABC), VNI Windows, Unicode Compound, Vietnamese Locale CP 1258
- **Spell Checking**: Validates Vietnamese word combinations
- **Macro/Text Expansion**: Unlimited length text shortcuts
- **Smart Switch**: Remembers language preference per application
- **Quick Telex**: cc=ch, gg=gi, kk=kh, nn=ng, qq=qu, pp=ph, tt=th
- **Orthography Options**: Support both modern (oà, uý) and traditional (òa, úy) styles
- **Auto-capitalization**: Automatically capitalize first letter of sentences

## Tech Stack
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI (Settings), AppKit (Menu bar, CGEventTap)
- **Minimum macOS**: macOS 13.0 (Ventura)
- **Build System**: Swift Package Manager / Xcode
- **Core Engine**: Complete rewrite in Swift (no C++ wrapping)

## Project Conventions

### Code Style
- Use Swift naming conventions (camelCase for variables/functions, PascalCase for types)
- Prefer `let` over `var` when possible
- Use Swift concurrency (async/await) where appropriate
- Prefer value types (struct, enum) over reference types (class) when suitable
- Use strong typing, avoid `Any` and force unwrapping (`!`)
- Document public APIs with DocC comments
- Organize code with MARK comments and extensions

### Architecture Patterns
```
Sources/
├── OpenKeySwift/
│   ├── App/                    # Entry point, AppDelegate
│   ├── Core/                   # Vietnamese input engine
│   │   ├── Engine/             # Main processing logic
│   │   ├── InputMethods/       # Telex, VNI handlers
│   │   ├── CharacterTables/    # Unicode, TCVN3, VNI encodings
│   │   └── Spelling/           # Spell checking rules
│   ├── EventHandling/          # CGEventTap, keyboard hook
│   ├── Features/               # Macro, Smart Switch, Quick Telex
│   ├── UI/                     # SwiftUI views, Menu bar
│   ├── Storage/                # UserDefaults, settings
│   └── Utilities/              # Extensions, helpers
├── OpenKeySwiftTests/          # Unit tests
└── OpenKeySwiftUITests/        # UI tests
```

**Design Patterns**:
- **Protocol-Oriented**: Core engine components defined via protocols
- **Dependency Injection**: Easy testing and swappable implementations
- **Observer/Combine**: Settings changes propagation
- **State Machine**: Input processing states

### Testing Strategy
- **Unit Tests**:
  - Core engine logic (character conversion, spelling rules)
  - Input method rules (Telex, VNI transformations)
  - Macro expansion
- **Integration Tests**:
  - Event handling pipeline
  - Settings persistence
- **UI Tests**:
  - Settings panel interactions
  - Menu bar actions
- **Target Coverage**: 80%+ for core engine

### Git Workflow
- **Branch naming**: `feature/`, `fix/`, `refactor/`, `docs/`
- **Commit message format**: Conventional Commits
  - `feat:` new feature
  - `fix:` bug fix
  - `refactor:` code restructuring
  - `test:` adding tests
  - `docs:` documentation
- **PR flow**: Feature branch → main (squash merge)

## Domain Context

### Vietnamese Input Method Concepts
- **Tone marks (dấu thanh)**: acute (sắc), grave (huyền), hook (hỏi), tilde (ngã), dot below (nặng)
- **Modifier marks (dấu mũ)**: circumflex (â, ê, ô), breve (ă), horn (ơ, ư), stroke (đ)
- **Mark placement**: Rules for placing tone marks according to modern/traditional orthography
- **Spell checking**: Validate consonant clusters, vowel combinations, valid syllables

### Technical Concepts
- **CGEventTap**: macOS API to intercept keyboard events system-wide
- **Accessibility permissions**: Required to capture keyboard events
- **Backspace technique**: Delete old characters and send newly converted characters
- **Code tables**: Mapping from internal representation to various output encodings

### Data Structures from Original OpenKey
- **TypingWord buffer**: Stores current word being typed with metadata (caps, tone, marks)
- **Bit masks**: Encode character state in Uint32
  - bits 0-15: character code
  - bit 16: caps flag
  - bits 17-18: tone flags (^, w)
  - bits 19-23: mark flags (5 tone marks)
  - bit 24: standalone flag
  - bit 25: character code vs keycode flag

## Important Constraints

### System Requirements
- Accessibility permissions required (System Settings → Privacy & Security → Accessibility)
- Runs as background app (menu bar only) or with dock icon (optional)
- Sandbox: Cannot be sandboxed due to system-wide keyboard access requirement

### Performance
- Event callback must return quickly (< 1ms) to avoid keyboard lag
- Avoid blocking operations in event handler
- Low memory footprint (runs continuously in background)

### Compatibility
- Special handling required for some applications (browsers with autocomplete, editors)
- Support multiple keyboard layouts
- Handle Unicode Compound issues with Chrome-based browsers

### Localization
- Vietnamese UI is primary
- English UI support (optional)

## External Dependencies

### Apple Frameworks (Built-in)
- **Carbon.framework**: CGEventTap, keyboard event handling
- **AppKit**: NSStatusItem, NSMenu, application lifecycle
- **SwiftUI**: Settings UI
- **Combine**: Reactive settings updates

### No External Dependencies
- Avoid external dependencies to:
  - Reduce attack surface (security)
  - Easy maintenance
  - Small app size

## Reference Implementation
- Original OpenKey: https://github.com/tuyenvm/OpenKey
- Key engine files to reference:
  - `Sources/OpenKey/engine/Engine.cpp` - Main processing logic
  - `Sources/OpenKey/engine/Vietnamese.cpp` - Character tables & rules
  - `Sources/OpenKey/engine/DataType.h` - Data structures & constants
  - `Sources/OpenKey/macOS/ModernKey/OpenKey.mm` - macOS event handling
