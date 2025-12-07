# Proposal: Add Advanced Settings UI

## Change ID
`add-advanced-settings-ui`

## Summary
Expose existing TextInjector configuration options (browser autocomplete fix, Chromium fix, send key step-by-step) in the Settings UI, allowing users to toggle these features on/off.

## Why
Several features are already implemented in the codebase but have no UI controls:

| Feature | Implementation | UI Setting |
|---------|---------------|------------|
| Fix browser autocomplete | `TextInjector.fixBrowserAutocomplete` | Missing |
| Fix Chromium issues | `TextInjector.fixChromiumBrowser` | Missing |
| Send key step-by-step | `TextInjector.sendKeyStepByStep` | Missing |

Users cannot configure these features without modifying code. Exposing them in Settings UI enables:
1. **Troubleshooting**: Users can disable fixes if they cause issues in specific apps
2. **Performance**: Step-by-step mode can be enabled for compatibility with problematic apps
3. **Transparency**: Users see what workarounds are active

## Scope

### In Scope
- Add three new settings keys to `SettingsStore`
- Add UI toggles in a new "Advanced" GroupBox in Settings
- Wire settings to `TextInjector` via `AppDelegate`
- Add tests for new settings

### Out of Scope
- Per-application settings (future enhancement)
- New workaround implementations
- Hotkey configuration for these settings
- Localization (follows existing English UI pattern)

## Affected Specs
- `ui-settings` - Add new "Advanced Settings" requirement

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Users disable needed fixes | Medium | Low | Add help text explaining each option |
| Settings not persisted correctly | Low | Medium | Follow existing pattern, add tests |

## Success Criteria
1. All three settings appear in Settings UI under "Advanced" section
2. Settings persist across app restarts
3. Changes take effect immediately without restart
4. Unit tests pass for new settings keys
5. `openspec validate` passes
