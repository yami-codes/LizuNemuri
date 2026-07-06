# Fix Android + Web CI release builds

- **Created**: 2026-07-05
- **Owner**: cursor-agent
- **Status**: done
- **Related Issue / PR**: PR #14 / v2.0.0-rc.3

---

## 1. Goal

Restore passing `flutter build apk` and `flutter build web --release` in GitHub Actions after rc.2.

## 2. Scope

**In scope:**
- `database_bootstrap` split (web stub / io desktop)
- `universal_io` migration (no `dart:io` in `lib/`)
- ProGuard + CI gen-l10n
- Tag `v2.0.0-rc.3`

**Out of scope:**
- (none listed)

## 3. Acceptance

- [x] `database_bootstrap` split (web stub / io desktop)
- [x] `universal_io` migration (no `dart:io` in `lib/`)
- [x] ProGuard + CI gen-l10n
- [x] Tagged `v2.0.0-rc.3`

---

## ✅ Done

- Completed at: 2026-07-05
- Related commit: `4bcbe99` / tag `v2.0.0-rc.3`
