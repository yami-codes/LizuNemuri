# Fix Android + Web CI release builds

- **创建时间**：2026-07-05
- **负责人**：cursor-agent
- **状态**：active
- **关联**：v2.0.0-rc.2 CI failures (build-android, build-web)

---

## 1. 目标（Goal）

Restore passing `flutter build apk` and `flutter build web --release` in GitHub Actions after rc.2.

## 2. 范围（Scope）

**包含：**
- Split `database_bootstrap` (web stub vs io/desktop ffi init) — rc.2 regression
- Replace `dart:io` with `universal_io` across `lib/` for web compilation
- ProGuard keep rules for `moe.lizu.nemu` lyric overlay
- CI: explicit `flutter gen-l10n` before platform builds

**不包含：**
- Full offline-download / local-library web implementations (runtime stubs OK)
- iOS / Windows job fixes unless same root cause

## 3. 验收标准（Acceptance）

- [ ] `database_bootstrap` has no unconditional `dart:ffi` on web target
- [ ] No `import 'dart:io'` left under `lib/` (use `universal_io`)
- [ ] `fvm flutter test` passes
- [ ] Tag `v2.0.0-rc.3` triggers green android + web CI jobs

## 4. 拆解步骤（Steps）

- [ ] Split database bootstrap (stub / io)
- [ ] Add `universal_io`, migrate imports
- [ ] ProGuard + CI gen-l10n step
- [ ] Test + release rc.3
