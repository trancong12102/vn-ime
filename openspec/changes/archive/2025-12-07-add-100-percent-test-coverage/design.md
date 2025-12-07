# Design: 100% Test Coverage Implementation

## Context

LotusKey là Vietnamese input method cho macOS với yêu cầu nghiêm ngặt về chất lượng code. Logic components xử lý việc chuyển đổi keystroke thành Vietnamese text - bất kỳ bug nào đều ảnh hưởng trực tiếp đến người dùng.

### Stakeholders
- Developers: Cần confidence khi refactoring
- Users: Cần input method hoạt động chính xác
- Maintainers: Cần regression tests cho future changes

## Goals / Non-Goals

### Goals
- Đạt 100% line coverage cho tất cả logic components
- Tạo comprehensive test suite cho Vietnamese input processing
- Identify và remove dead code nếu có
- Document any intentionally uncovered paths

### Non-Goals
- Coverage cho UI components (SwiftUI views, menu bar)
- Coverage cho system integration code (CGEventTap, Accessibility APIs)
- Branch coverage (chỉ focus line coverage)
- Performance testing

## Decisions

### Decision 1: Focus on Line Coverage
**What:** Target 100% line coverage thay vì branch coverage
**Why:** Line coverage đủ để đảm bảo mọi code path được execute ít nhất một lần. Branch coverage phức tạp hơn và diminishing returns cho project này.
**Alternatives:**
- Branch coverage (rejected: quá phức tạp cho một số conditional logic)
- Statement coverage (rejected: quá basic, có thể miss quan trọng paths)

### Decision 2: Test via Integration over Unit
**What:** Prefer integration-style tests qua engine.processString() over isolated unit tests
**Why:**
- Tests sát với real user behavior hơn
- Cover nhiều code paths trong một test
- Easier to maintain
**Alternatives:**
- Pure unit tests cho mỗi function (rejected: nhiều mocking, fragile tests)
- End-to-end tests (rejected: quá slow, khó setup)

### Decision 3: Remove Unused Code
**What:** Xóa public APIs không được sử dụng thay vì viết tests cho chúng
**Why:**
- Less code = less maintenance
- Dead code có thể confuse future developers
- Nếu cần lại, có thể khôi phục từ git history
**Candidates for removal:**
- `TypingBuffer.fromEnd(_:)` - không có caller
- `TypingBuffer.findVowelStartIndex()` - không có caller
- `VietnameseTable.parse(_:)` - reverse lookup không được sử dụng

### Decision 4: Test Organization
**What:** Thêm tests vào existing test files thay vì tạo files mới
**Why:**
- Consistent với current structure
- Related tests ở cùng một nơi
- Không phân tán test knowledge

## Implementation Approach

### Phase 1: Low-Hanging Fruit (91%+ coverage files)
1. CharacterState.swift - add 1 test cho `modifier` property
2. QuickTelex.swift - add 1 test cho disabled state
3. TelexInputMethod.swift - add edge case tests
4. SimpleTelexInputMethod.swift - add edge case tests
5. SpellChecker.swift - add edge case tests

### Phase 2: Medium Effort (70-90% coverage files)
1. TypedCharacter.swift - test constructors và static functions
2. TypingBuffer.swift - test unused methods or remove them
3. VietnameseEngine.swift - comprehensive transformation tests
4. InputMethod.swift - test default implementation

### Phase 3: Higher Effort (50% or below)
1. InputMethodRegistry.swift - test all lookup methods
2. CharacterTable.swift - test UnicodeCharacterTable
3. VietnameseTable.swift - test parse() or remove if unused

### Phase 4: Cleanup & Verification
1. Remove dead code identified during testing
2. Run full coverage report
3. Document any intentionally uncovered paths
4. Update specs if behavior changed

## Risks / Trade-offs

### Risk: Removing code that's actually needed
**Mitigation:**
- Search codebase for all usages before removal
- Keep code in git history
- Add TODO comment if uncertain

### Risk: Tests that pass but don't test real behavior
**Mitigation:**
- Write tests that match real user scenarios
- Review test quality, not just coverage numbers
- Use mutation testing if needed

### Risk: Over-testing defensive code
**Mitigation:**
- Document defensive paths that cannot be reached
- Use LCOV exclusion comments sparingly
- Focus on paths that can actually fail

## Testing Strategy

### Test Categories

```
┌─────────────────────────────────────────────┐
│         Integration Tests (Primary)         │
│  engine.processString("viet") → "việt"      │
├─────────────────────────────────────────────┤
│           Unit Tests (Secondary)            │
│  CharacterState, TypedCharacter, etc.       │
├─────────────────────────────────────────────┤
│         Edge Case Tests (Tertiary)          │
│  Empty buffers, invalid inputs, limits      │
└─────────────────────────────────────────────┘
```

### Test Naming Convention
```swift
func test[Component][Behavior][Condition]() {
    // Given
    // When
    // Then
}

// Examples:
func testCharacterStateModifierReturnsCircumflex()
func testTypingBufferFromEndReturnsNilForInvalidOffset()
func testEngineProcessStringWithStandaloneVowel()
```

## Open Questions

1. **Should VietnameseTable.parse() be kept?**
   - Currently unused but could be useful for clipboard/paste handling
   - Decision: Keep and test, as it's part of the character processing API

2. **Should fromEnd() and findVowelStartIndex() be removed?**
   - These appear unused but may have been added for future features
   - Decision: Remove if no planned usage, document in commit message

3. **How to test paths that require nil character input?**
   - Some paths require CGEvent to produce nil character
   - Decision: Use testable helpers or mark as integration-only paths
