# Suggested Commands

## Build Commands

```bash
# Build debug
swift build

# Build release
swift build -c release

# Run the application (after building)
.build/release/LotusKey
```

## Testing Commands

```bash
# Run all tests
swift test

# Run specific test target
swift test --filter LotusKeyTests

# Run specific test class
swift test --filter EngineTests

# Run specific test method
swift test --filter "EngineTests/testEngineInitialization"
```

## Linting Commands

```bash
# Run SwiftLint
swiftlint lint

# Run SwiftLint with autocorrect
swiftlint --fix

# Check SwiftLint version
swiftlint version

# Install SwiftLint (if not installed)
brew install swiftlint
```

## Full Verification (Recommended Before Commit)

```bash
# Run build, tests, and lint in sequence
swift build && swift test && swiftlint lint
```

## Git Commands

```bash
# Check status
git status

# Create feature branch
git checkout -b feature/feature-name

# Create fix branch
git checkout -b fix/bug-description

# Commit (follow Conventional Commits format)
git commit -m "feat: add new feature"
git commit -m "fix: resolve bug"
git commit -m "refactor: restructure code"
git commit -m "test: add tests"
git commit -m "docs: update documentation"
```

## OpenSpec Commands

```bash
# List active changes
openspec list

# List specifications
openspec list --specs
# OR
openspec spec list --long

# Show change or spec details
openspec show [item]

# Validate change
openspec validate [change] --strict

# Archive completed change
openspec archive <change-id> --yes

# Initialize OpenSpec (if needed)
openspec init

# Full-text search in specs
rg -n "Requirement:|Scenario:" openspec/specs
```

## Utility Commands (macOS/Darwin)

```bash
# List files
ls -la

# Find files
find . -name "*.swift" -type f

# Search in files
rg "pattern" --type swift

# Directory structure
tree -L 2

# Check Xcode version
xcodebuild -version

# Check Swift version
swift --version
```

## Performance Considerations

- Event callback must return quickly (< 1ms) to avoid keyboard lag
- Avoid blocking operations in event handler
- Low memory footprint (runs continuously in background)
