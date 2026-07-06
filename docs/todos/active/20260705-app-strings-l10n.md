# App UI copy localization (Chinese / English / Thai)

- **Created**: 2026-07-05
- **Owner**: cursor-agent
- **Status**: active
- **Related Issue / PR**:

---

## 1. Goal

Add zh / en / th support for all `Strings` UI copy, Settings language picker (including follow system), `MaterialApp` wired to gen-l10n.

## 2. Scope

**In scope:**
- ARB + `flutter gen-l10n` + `Strings` facade keeping existing call sites
- `AppLanguage` persistence + Settings language section
- Remove `const Text(Strings.*)` compile conflicts
- Tests + APK

**Out of scope:**
- Non-UI diagnostic string migration

## 3. Acceptance

- [ ] Settings → Language: switch system/zh/en/th with immediate effect
- [ ] English/Thai: main nav, settings, error prompts in target language
- [ ] `flutter analyze` + tests pass
- [ ] Release APK build succeeds

## 4. Steps

- [x] ARB three locales + pubspec l10n
- [x] Strings facade + AppSettingsService
- [x] main.dart + settings UI
- [ ] Tests / analyze / APK
