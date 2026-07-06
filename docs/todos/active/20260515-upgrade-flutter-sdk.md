# Upgrade Flutter SDK (3.27.0 → latest stable)

- **Created**: 2026-05-15
- **Owner**: (unassigned)
- **Status**: active (**not started** — placeholder for follow-up root fix; observe Plan A "disable Impeller" first)
- **Related Issue / PR**:
  - Prerequisite: [`docs/todos/done/20260515-disable-impeller-android.md`](../done/20260515-disable-impeller-android.md) (completed emergency mitigation)
  - Trigger: Adreno + Vulkan + Impeller `ErrorDeviceLost` crash on HyperOS 3 / Android 16 real devices

---

## 1. Goal

Upgrade project from Flutter 3.27.0 to current stable (check latest at execution time) to:
1. Pick up Flutter 3.29+ / 3.30+ Adreno Impeller compatibility fixes so Impeller can be re-evaluated.
2. Align Dart SDK / third-party deps to a maintainable baseline.
3. Fix 33 `withOpacity` deprecation warnings (newer SDK uses `.withValues(alpha:)`).

## 2. Scope

**In scope:**
- `.fvmrc`: bump `flutter` field to target version.
- `pubspec.yaml`: adjust `environment.sdk` and dependency constraints if needed.
- `pubspec.lock`: updated via `fvm flutter pub get`.
- Third-party compatibility: `just_audio`, `audio_service`, `dio`, `provider`, `get_it`, `freezed`, `json_serializable`, `rxdart`, `shared_preferences`, `flutter_lints`, etc.
- `android/` / `ios/`: possible Gradle / Kotlin / Pod / iOS deployment target bumps.
- Full `fvm flutter analyze` + `fvm flutter test` + real-device smoke (login, register, playback, subtitle import, floating lyrics, cache cleanup).

**Out of scope:**
- Do not fix all 33 `withOpacity` deprecations in one go — separate PR after upgrade.
- No architecture refactor.
- No state-management or renderer library swap.

## 3. Acceptance

- [ ] `.fvmrc` points to new version; `fvm install` succeeds.
- [ ] `fvm flutter pub get` without conflicts.
- [ ] `fvm dart run build_runner build --delete-conflicting-outputs` succeeds.
- [ ] `fvm flutter analyze` passes; new warnings listed and assessed.
- [ ] `fvm flutter build apk --release` and `fvm flutter build ios --no-codesign` succeed.
- [ ] Real-device smoke: login / register / list scroll / detail / playback / subtitles / floating lyrics / cache cleanup — no regressions.
- [ ] Re-evaluate enabling Impeller on Android (remove `EnableImpeller=false` meta-data, run 30+ min session, verify `ErrorDeviceLost` absent).

## 4. Steps

- [ ] **Step 1**: Research current Flutter stable + breaking changes (Material 3, Impeller, Android Gradle plugin matrix).
- [ ] **Step 2**: Local branch `chore/flutter-sdk-upgrade`, bump `.fvmrc` only, run `fvm flutter pub get` for dep conflicts.
- [ ] **Step 3**: Resolve dependency version warnings; bump `pubspec.yaml` constraints as needed.
- [ ] **Step 4**: Run `analyze` + `test` + Android/iOS release builds.
- [ ] **Step 5**: Real-device smoke matrix.
- [ ] **Step 6**: Impeller re-enable evaluation — if stable, remove manifest meta-data; if still crashing, keep disabled and open follow-up.

## 5. Risks

- **Risk 1**: Dependency breakage (especially `freezed` / `json_serializable` codegen).
  - Mitigation: tag before upgrade, resolve incrementally; revert if severe.
- **Risk 2**: Material 3 visual regressions on newer SDK.
  - Mitigation: screen recordings before/after on key pages.
- **Rollback**: SDK-level upgrade via feature branch + PR review; revert PR if needed.

## 6. Notes

- This TODO was created right after `disable-impeller-android` so both emergency mitigation and long-term fix are tracked.
- Start timing: after user runs Skia backend for ≥1 week daily use with no rendering regressions — avoids too many simultaneous changes.

---

## ✅ Done

- Completed at:
- Command run: `/init`
- CLAUDE.md update summary:
- Related commit:
