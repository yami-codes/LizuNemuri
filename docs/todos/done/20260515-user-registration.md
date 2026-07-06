# User Registration (/api/auth/reg)

- **Created**: 2026-05-15
- **Owner**: claude
- **Status**: done
- **Related Issue / PR**: N/A

---

## 1. Goal

Integrate ASMR.ONE `POST /api/auth/reg` so the app completes "register account → auto-login → sync favorites and history" in-app; currently only login exists, unfriendly to new users.

## 2. Scope

**In scope:**
- `AuthService.register(name, password, {recommenderUuid})`: implement POST `/auth/reg`, reuse existing `AuthService` Dio instance and exception wrapping.
- `AuthViewModel.register(...)`: align with existing `login()` — on success write `AuthRepository`, flip `isLoggedIn`, expose errors in `error`.
- `RegisterDialog` (new): `AlertDialog` matching `LoginDialog` style, with username, password, confirm password, recommender UUID (optional); client validation `name.length >= 5 && password.length >= 5 && password == confirmPassword`.
- `LoginDialog` bottom add "No account? Register" TextButton, close LoginDialog → open RegisterDialog (same root navigator).
- `Strings`: add `register / noAccountCta / nameMinLength / passwordMinLength / passwordMismatch / recommenderUuid / recommenderUuidOptional / registerSuccess` and related copy.

**Out of scope:**
- No email verification, captcha, password strength meter, password recovery, or third-party login.
- No new node-switch UI (already in Settings).
- No multi-node auto fallback / retry (user can manually switch nodes in Settings).
- Do not remove/rename `AuthService.login` or existing `AuthRepository` fields.

## 3. Acceptance

- [ ] `AuthService.register('abcde', 'abcde')` against real API returns same `AuthResp` as `login` (with `token` and `user`).
- [ ] Client validation: username < 5 / password < 5 / password mismatch → button disabled, hint under corresponding field.
- [ ] After successful registration: `authVM.isLoggedIn == true`, `authVM.username` shows new username, drawer profile card refreshes, `AuthRepository` persisted, SnackBar "Registration successful".
- [ ] Server error (e.g. username taken): keep dialog open, show `authVM.error`, button retryable.
- [ ] `recommenderUuid` optional: omit from request body when empty; when non-empty validate 8-4-4-4-12 UUID format.
- [x] `flutter analyze` passes with no new warnings. Verified: `fvm flutter analyze` on changed files → `No issues found!`.
- [~] `fvm flutter test` status: only `test/widget_test.dart` exists — Flutter starter Counter smoke test expecting counter UI; project replaced with `MainScreen` audio UI, **test fails on HEAD** (verified with `git stash`), unrelated to this change. Should clean up or rewrite later; out of scope for this task.

## 4. Steps

- [x] **Step 1**: Extend `Strings` with registration copy constants.
  - Output: `lib/common/constants/strings.dart` (14 new registration constants)
- [x] **Step 2a**: `AuthService` refactor — inject `AppSettingsService`, Dio baseUrl reads `_settings.serverUrl`, listen to `_settings` changes to update baseUrl.
  - Output: `lib/data/services/auth_service.dart`, `lib/core/di/service_locator.dart`
- [x] **Step 2b**: `AuthService.register(name, password, {recommenderUuid})`: POST `/auth/reg`, include UUID only when non-empty; accept HTTP 200/201; if response missing `token`/`user` fallback to `login`.
  - Output: `lib/data/services/auth_service.dart`
- [x] **Step 3**: `AuthViewModel.register(...)` mirrors `login` state machine.
  - Output: `lib/presentation/viewmodels/auth_viewmodel.dart`
- [x] **Step 4**: New `RegisterDialog`, 4 TextFields + live validation + submit enabled by `_isFormValid`.
  - Output: `lib/presentation/widgets/auth/register_dialog.dart`
- [x] **Step 5**: `LoginDialog` add "No account? Register" TextButton via root navigator; RegisterDialog has reciprocal "Already have an account? Log in".
  - Output: `lib/presentation/widgets/auth/login_dialog.dart`
- [x] **Step 6**: `fvm flutter analyze` passes; `fvm flutter test` pre-existing scaffold smoke fail (see acceptance).
- [ ] **Step 7**: Manual verification (user side): register with `abcde` / `abcde` + empty recommenderUuid, confirm drawer profile refreshes, logout and login with same account works.

## 5. Risks

- **Risk 1**: `/api/auth/reg` behavior on `api.asmr.one` vs curl's `api.asmr-200.com` unknown (may be mirrors).
  - **Mitigation**: reuse `AuthService` `api.asmr.one` baseUrl, same origin as `login`; if device test fails, evaluate second baseUrl or `AppSettingsService.serverUrl`.
- **Risk 2**: Registration response may differ from `/auth/me` (e.g. success flag only, no token).
  - **Mitigation**: `AuthService.register` fallback — if `AuthResp.token == null && user == null`, sync call `login(name, password)` and return, transparent to ViewModel.
- **Risk 3**: Using a real recommender UUID binds all future registrations to that UUID — ethical/product risk.
  - **Mitigation**: default empty, **do not** hardcode curl's `ec2abb35-4010-4a81-98da-8b4cfb2e3a6b`; only send when user fills it in.
- **Rollback**: all changes additive or in-file append; `AuthService.register` / `AuthViewModel.register` / `RegisterDialog` independently revertible without affecting login path.

## 6. Notes / Decision Log

- **Decision A (revised): `AuthService` uses `AppSettingsService.serverUrl`**. `AppSettingsService.serverOptions` supports 4 nodes (main + nodes 1/2/3 including curl's `asmr-200.com`), but existing `AuthService.login` hardcoded `asmr.one` — legacy bug, fixed here. Register + login both read `_settings.serverUrl` and listen for node changes, aligned with `ApiService`.
- **Decision B: `recommenderUuid` optional + default empty**. Do not hardcode curl's `ec2abb35-…` — that recorder's personal invite code; hardcoding binds all new users.
- **Decision C: auto-login immediately after registration**. `AuthService.register` guarantees `AuthResp` with token (fallback `login` if needed); ViewModel reuses persistence logic.
- **Decision D: UI entry in `LoginDialog` not standalone `RegisterScreen`**. Registration is low-frequency; dialog sufficient; full-screen page is over-engineering.

---

## ✅ Done

- Completed at: 2026-05-15
- Command run: `/init`
- CLAUDE.md update summary: added auth flow section — `AuthService` now reads `AppSettingsService.serverUrl` and listens for node switch; new `register()` + custom `RegisteredButNotLoggedInException`; `AuthViewModel` adds `register()` / `clearError()`; `presentation/widgets/auth/` has both LoginDialog and RegisterDialog.
- Related commit: (pending commit; message should reference archived path)
- Codex review: SESSION_ID `019e2873-2990-72e2-bc68-ba47328971b7`, two rounds ⚠️→✅ PASS.
- Runtime verification (Step 7): still pending user device test.

---

## 7. Review

- **Round 1** (⚠️ OPTIMIZE):
  - Registration success but fallback login failure wrapped as generic "registration failed", misrepresenting server state → added `RegisteredButNotLoggedInException` to distinguish;
  - login ⇄ register switch leaked stale `authVM.error` → added `AuthViewModel.clearError()` called in both `_switchToXxx`.
- **Round 2** (✅ PASS): exception catch order correct, `_authData == null` semantics preserved; `clearError()` short-circuits on `_error == null`, no extra rebuild.
