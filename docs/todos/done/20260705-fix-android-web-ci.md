# Fix Android + Web CI release builds

- **创建时间**：2026-07-05
- **负责人**：cursor-agent
- **状态**：done
- **关联**：PR #14 / v2.0.0-rc.3

---

## 1. 目标（Goal）

Restore passing `flutter build apk` and `flutter build web --release` in GitHub Actions after rc.2.

## 3. 验收标准（Acceptance）

- [x] `database_bootstrap` split (web stub / io desktop)
- [x] `universal_io` migration (no `dart:io` in `lib/`)
- [x] ProGuard + CI gen-l10n
- [x] Tagged `v2.0.0-rc.3`

---

## ✅ 完成标记

- 完成时间：2026-07-05
- 关联 commit：`4bcbe99` / tag `v2.0.0-rc.3`
