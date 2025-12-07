# Change: Add 100% Test Coverage for Logic Components

## Why

Logic components của LotusKey là phần xử lý cốt lõi của Vietnamese input method - bất kỳ bug nào ở đây sẽ ảnh hưởng trực tiếp đến trải nghiệm gõ tiếng Việt của người dùng. Hiện tại test coverage của các logic components dao động từ 18% đến 96%, cần đạt 100% để đảm bảo:
- Mọi code path đều được kiểm tra
- Refactoring an toàn trong tương lai
- Phát hiện regression sớm

## What Changes

### Coverage Target: 100% cho Logic Components

| Component | Current | Target | Missing Lines |
|-----------|---------|--------|---------------|
| CharacterState.swift | 91.67% | 100% | 4 |
| TypedCharacter.swift | 66.97% | 100% | 36 |
| TypingBuffer.swift | 76.11% | 100% | 102 |
| VietnameseEngine.swift | 87.85% | 100% | 82 |
| VietnameseTable.swift | 69.47% | 100% | 40 |
| TelexInputMethod.swift | 95.52% | 100% | 9 |
| SimpleTelexInputMethod.swift | 91.89% | 100% | 6 |
| InputMethod.swift | 73.53% | 100% | 9 |
| InputMethodRegistry.swift | 50.00% | 100% | 11 |
| SpellChecker.swift | 94.09% | 100% | 25 |
| QuickTelex.swift | 96.30% | 100% | 1 |
| CharacterTable.swift | 18.18% | 100% | 9 |

### Non-Logic Components (NOT in scope - UI can skip coverage)
- App/ (AppDelegate, LotusKeyApp, AppLifecycleManager)
- EventHandling/ (CGEventTap, keyboard hooks)
- UI/ (SettingsView, MenuBarController)
- Storage/ (SettingsStore)
- Utilities/ (Extensions)

## Impact

- Affected specs: `core-engine`, `input-methods`, `spell-checking`
- Affected code: `Tests/LotusKeyTests/`
- New test files may be created for comprehensive coverage

## Approach

### Strategy 1: Test actual used code paths
- Focus on testing real scenarios users encounter
- Write integration-style tests that exercise multiple paths

### Strategy 2: Remove dead code where applicable
- Identify unused public APIs that can be removed
- Simplify codebase by removing unused functions

### Strategy 3: Mark intentionally uncovered code
- For defensive code paths that cannot be reached normally
- Document with `// LCOV_EXCL_LINE` if needed

## Risk Assessment

- **Low Risk**: Adding tests does not change production behavior
- **Medium Risk**: Removing dead code requires careful analysis
- **Mitigation**: Run full test suite after each change

## Success Criteria

1. `xcrun llvm-cov report` shows 100% line coverage for all logic components
2. All tests pass (`swift test`)
3. No reduction in existing test quality
