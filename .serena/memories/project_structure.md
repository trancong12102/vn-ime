# Project Structure

## Directory Layout

```
lotus-key/
├── Package.swift           # Swift Package Manager manifest
├── CLAUDE.md               # AI assistant instructions
├── README.md               # Project documentation
├── LICENSE                 # GPLv3 License
├── .swiftlint.yml          # SwiftLint configuration
├── .gitmodules             # Git submodules (OpenKey reference)
│
├── Sources/
│   └── LotusKey/
│       ├── App/                    # Entry point, AppDelegate
│       │   ├── LotusKeyApp.swift   # @main SwiftUI App entry
│       │   ├── AppDelegate.swift   # NSApplicationDelegate
│       │   └── AppLifecycleManager.swift
│       │
│       ├── Core/                   # Vietnamese input engine
│       │   ├── Engine/             # Main processing logic
│       │   │   ├── VietnameseEngine.swift   # Engine protocol & implementation
│       │   │   ├── TypingBuffer.swift       # Word buffer management
│       │   │   ├── CharacterState.swift     # Character state encoding
│       │   │   ├── TypedCharacter.swift     # Typed character representation
│       │   │   └── VietnameseTable.swift    # Vietnamese character table
│       │   │
│       │   ├── InputMethods/       # Telex, Simple Telex handlers
│       │   ├── CharacterTables/    # Unicode encoding
│       │   └── Spelling/           # Spell checking rules
│       │
│       ├── EventHandling/          # CGEventTap, keyboard hook
│       ├── Features/               # Smart Switch, Quick Telex
│       ├── UI/                     # SwiftUI views, Menu bar
│       ├── Storage/                # UserDefaults, settings
│       ├── Utilities/              # Extensions, helpers
│       └── Resources/              # Assets, localization
│
├── Tests/
│   ├── LotusKeyTests/              # Unit tests
│   │   ├── EngineTests.swift
│   │   ├── InputMethodTests.swift
│   │   ├── SpellCheckerTests.swift
│   │   └── ...
│   └── LotusKeyUITests/            # UI tests
│
├── OpenKey/                        # Reference implementation (git submodule)
│
└── openspec/                       # OpenSpec specifications
    ├── project.md                  # Project conventions
    ├── AGENTS.md                   # AI agent instructions
    ├── specs/                      # Current specifications
    │   ├── core-engine/
    │   ├── event-handling/
    │   ├── input-methods/
    │   ├── smart-switch/
    │   ├── spell-checking/
    │   ├── ui-settings/
    │   └── project-structure/
    └── changes/                    # Change proposals
        └── archive/                # Completed changes
```

## Key Files

### Entry Points
- `Sources/LotusKey/App/LotusKeyApp.swift` - Main app entry (@main)
- `Sources/LotusKey/App/AppDelegate.swift` - App lifecycle management

### Core Engine
- `Sources/LotusKey/Core/Engine/VietnameseEngine.swift` - Main engine protocol and implementation
- `Sources/LotusKey/Core/Engine/TypingBuffer.swift` - Buffer for current word
- `Sources/LotusKey/Core/InputMethods/` - Input method implementations (Telex, etc.)

### Event Handling
- `Sources/LotusKey/EventHandling/` - CGEventTap keyboard hook

### UI
- `Sources/LotusKey/UI/` - SwiftUI settings views and menu bar

### Configuration
- `Package.swift` - SPM dependencies and targets
- `.swiftlint.yml` - Linting rules

## Module Architecture

```
LotusKey (executable target)
├── @main LotusKeyApp
├── AppDelegate
│   └── Sets up event tap, menu bar, lifecycle
│
├── VietnameseEngine (protocol)
│   └── DefaultVietnameseEngine (implementation)
│       ├── InputMethod (protocol) → TelexInputMethod, SimpleTelexInputMethod
│       ├── CharacterTable (protocol) → UnicodeCharacterTable
│       ├── SpellChecker (protocol) → DefaultSpellChecker
│       └── TypingBuffer
│
└── UI Layer
    ├── SettingsView (SwiftUI)
    └── MenuBarView (AppKit)
```
