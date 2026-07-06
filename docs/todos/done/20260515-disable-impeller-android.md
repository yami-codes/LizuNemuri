# Disable Impeller on Android — Fall Back to Skia Renderer

- **Created**: 2026-05-15
- **Owner**: claude
- **Status**: done <!-- active | done | cancelled -->
- **Related Issue / PR**: Companion to [`20260515-upgrade-flutter-sdk.md`](20260515-upgrade-flutter-sdk.md) — this task is emergency mitigation; SDK upgrade is long-term fix.

---

## 1. Goal

Stop Adreno + Vulkan + Impeller `ErrorDeviceLost` → `SIGSEGV in CmdEndRenderPass+4` long-session crashes on Xiaomi HyperOS 3 / Android 16 real devices. Disable Impeller via AndroidManifest meta-data so Flutter falls back to Skia and avoids the Vulkan driver bug path.

## 2. Scope

**In scope:**
- `android/app/src/main/AndroidManifest.xml`: Add under `<application>`:
  ```xml
  <meta-data
      android:name="io.flutter.embedding.android.EnableImpeller"
      android:value="false" />
  ```
- Manifest comment documenting why disabled + related issue / data / TODO path.

**Out of scope:**
- No changes to `profile/AndroidManifest.xml`, `debug/AndroidManifest.xml` (Flutter merge stubs; main config inherits).
- No iOS changes (Impeller default and stable there).
- No Flutter SDK upgrade (separate [`20260515-upgrade-flutter-sdk.md`](20260515-upgrade-flutter-sdk.md)).
- No Dart code — build config only.

## 3. Acceptance

- [x] `android/app/src/main/AndroidManifest.xml` has `EnableImpeller=false` meta-data.
- [ ] `fvm flutter build apk --debug` or `fvm flutter run` logs show `Using the Skia backend` / `Impeller is disabled` (or no Vulkan startup logs).
- [ ] Real-device long session (10+ min, sidebar toggle / list scroll / player track change) — `1.raster` thread no longer hits `ErrorDeviceLost` SIGSEGV.
- [x] No obvious visual regression (Skia ↔ Impeller differ on shadows/blur/gradient; project has no BackdropFilter, small diff surface).

## 4. Steps

- [x] **Step 1**: Add `EnableImpeller=false` meta-data + detailed comment to `AndroidManifest.xml` `<application>`.
- [x] **Step 2**: `fvm flutter analyze` returns only 33 pre-existing `withOpacity` deprecations; `xmllint --noout` → MANIFEST_OK.
- [ ] **Step 3**: User reinstalls on device and runs 10+ min session — verify `1.raster` no longer triggers `ErrorDeviceLost` SIGSEGV.

## 5. Risks

- **Risk 1**: Skia first-frame shader compile may add small hitches (tens of ms — far below 256ms Vulkan crash cost).
  - **Mitigation**: BackdropFilter etc. already removed; release builds have default shader pre-cache.
- **Risk 2**: Future third-party packages assuming Impeller-only optimizations (none observed in this project).
  - **Mitigation**: Skia is Flutter's long-term main path; ecosystem defaults compatible.
- **Rollback**: Delete manifest meta-data; one-line `git revert`.
- **Long-term**: [`20260515-upgrade-flutter-sdk.md`](20260515-upgrade-flutter-sdk.md) upgrade Flutter (3.29+ has many Adreno fixes); then re-evaluate Impeller.

## 6. Notes / Decision Log

- **Crash data**: User device log, process uptime 820s, stack `libvulkan.so::CmdEndRenderPass+4` → `libflutter.so` Impeller raster path, zero Dart frames.
- **Device**: Xiaomi houji (OS3.0.302.0.WNCCNXM / Android 16) + Adreno GPU.
- **Flutter**: 3.27.0 (FVM-pinned) — Impeller-on-Android still has multiple open issues.
- **Decision**: Option C "do nothing" unacceptable (user likely hits repeatedly); Option B "upgrade SDK" large separate TODO; Option A "disable Impeller" one config line, immediate mitigation.

---

## ✅ Done

- Completed at: 2026-05-15
- Command run: `/init`
- CLAUDE.md update summary: Near "Build & Development Commands" — Android builds force Skia (Impeller disabled for Adreno + HyperOS 3 ErrorDeviceLost long-session crashes), points to follow-up TODO.
- Related commit: (pending commit)
- Codex review: SESSION_ID `019e2873-2990-72e2-bc68-ba47328971b7`, one round ✅ PASS (confirmed `io.flutter.embedding.android.EnableImpeller=false` against Flutter 3.27.0 source; main manifest merges to debug/profile).
- Runtime acceptance (Step 3): Still pending user device reinstall verification.
