# Fix Android RC build (desugar + compileSdk 36)

- **Created**: 2026-07-11
- **Owner**: mirai
- **Status**: done

## 1. Goal

> Unblock GitHub Actions `flutter build apk --release`: enable core library desugaring for flutter_local_notifications and compile against Android SDK 36 for media_kit.

## 2. Scope

**In scope:** `android/app/build.gradle`, rc.23 bump  
**Out of scope:** Flutter SDK upgrade

## 3. Acceptance

- [x] `compileSdk = 36`
- [x] Core library desugaring enabled with `desugar_jdk_libs:2.1.4` + `multiDexEnabled`
- [x] Bump + tag `v2.0.0-rc.23`

## 4. Steps

- [x] Patch `android/app/build.gradle`
- [x] Bump rc.23 + push tag

---

## ✅ Done

- Completed at: 2026-07-11 17:15
- Command run: `/init` (CLAUDE.md Environment note for compileSdk 36 + desugar)
- Related commit: (pending)
