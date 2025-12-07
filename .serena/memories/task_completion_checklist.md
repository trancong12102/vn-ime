# Task Completion Checklist

When completing a task in LotusKey, follow this checklist:

## Before Committing

### 1. Full Verification (Recommended)
```bash
# Run all checks in one command
swift build && swift test && swiftlint lint
```

Or run individually:

### 2. Build Check
```bash
swift build
```
Ensure the project builds without errors.

### 3. Run Tests
```bash
swift test
```
All tests should pass. If adding new functionality, add corresponding tests.

### 4. Linting
```bash
swiftlint lint
```
Fix any style violations. Current acceptable thresholds:
- Warnings: OK to commit (but fix when possible)
- Errors: Must fix before committing (except test file length)

### 5. Code Review Checklist
- [ ] Follows naming conventions (camelCase, PascalCase)
- [ ] Uses `let` over `var` where possible
- [ ] No force unwrapping (`!`) unless justified
- [ ] No use of `Any` type unless necessary
- [ ] Public APIs have DocC documentation
- [ ] MARK comments organize code sections
- [ ] Functions are under 50 lines (warning threshold)
- [ ] Files are under 500 lines (warning threshold)

## Committing

### Commit Message Format (Conventional Commits)
```bash
git commit -m "feat: description"   # New feature
git commit -m "fix: description"    # Bug fix
git commit -m "refactor: description"  # Restructuring
git commit -m "test: description"   # Adding tests
git commit -m "docs: description"   # Documentation
```

### Scope Examples
```bash
git commit -m "feat(engine): add tone placement logic"
git commit -m "fix(spelling): correct consonant validation"
git commit -m "refactor(ui): simplify settings view"
```

## OpenSpec Workflow

### For Feature Changes
If the task involves:
- New features or functionality
- Breaking changes (API, schema)
- Architecture changes
- Performance optimizations (that change behavior)
- Security pattern updates

Then:
1. Create change proposal with `openspec`
2. Get approval before implementing
3. After deployment, archive the change

### For Simple Changes
Skip OpenSpec for:
- Bug fixes (restore intended behavior)
- Typos, formatting, comments
- Dependency updates (non-breaking)
- Configuration changes
- Tests for existing behavior

## Performance Considerations

For code in event handling path:
- [ ] Event callback returns quickly (< 1ms)
- [ ] No blocking operations in event handler
- [ ] Memory footprint kept low

## Testing Guidelines

### Target Coverage
- Core engine: 80%+ coverage
- Unit tests for character conversion, spelling rules
- Integration tests for event handling, settings persistence
- UI tests for settings panel, menu bar actions

### Test File Locations
- Unit tests: `Tests/LotusKeyTests/`
- UI tests: `Tests/LotusKeyUITests/`
