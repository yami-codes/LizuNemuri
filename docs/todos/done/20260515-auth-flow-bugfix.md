# Auth Flow Bugfix + Remove Recommender Field from Registration

- **Created**: 2026-05-15
- **Owner**: claude
- **Status**: done <!-- active | done | cancelled -->
- **Related Issue / PR**: N/A (runtime regression found via manual testing)

---

## 1. Goal

Fix drawer profile-card logout flow (tap sometimes fails to show dialog / occasional crash), and per product decision remove the "recommender UUID" input from `RegisterDialog` to lighten registration.

## 2. Scope

**In scope:**
- `lib/widgets/sidebar/sidebar_header.dart`: Rewrite `_closeDrawerThenShowDialog` — push `showDialog` to next frame to avoid same-frame drawer pop + dialog on same navigator; logout button `onPressed` uses `NavigatorState.mounted` guard to avoid dialogContext deactivated after await.
- `lib/presentation/widgets/auth/register_dialog.dart`: Remove recommender UUID TextField + controller + validation; `_isFormValid` drops that branch; `_handleRegister` passes `recommenderUuid: null`.
- `lib/common/constants/strings.dart`: Remove two constants bound to that field (`recommenderUuidLabel`, `recommenderUuidInvalid`).
- Keep optional `recommenderUuid` on `AuthService.register` and `AuthViewModel.register` (future UI can reuse without service changes).

**Out of scope:**
- No changes to `LoginDialog` flow (user did not report login issues).
- No `Drawer` / `Navigator` refactor.
- No change to `AuthService.register` interface signature.

## 3. Acceptance

- [x] Logged-in: tap drawer profile card → **always** shows logout confirm dialog, no crash.
- [x] Tap 「退出登录」 in confirm dialog → dialog closes, `AuthViewModel.isLoggedIn == false`, reopen drawer shows 「立即登录」.
- [x] Logged-out: tap profile card → `LoginDialog` opens reliably (same race fix applies).
- [x] `RegisterDialog` UI has only 3 TextFields (username / password / confirm password).
- [x] Registration still succeeds (request body omits `recommenderUuid`).
- [x] `fvm flutter analyze` on changed files → `No issues found!`.

## 4. Steps

- [x] **Step 1**: `sidebar_header.dart` — `_closeDrawerThenShowDialog` captures root navigator → `Navigator.maybePop` → `addPostFrameCallback` → `showDialog`; logout `onPressed` uses `final navigator = Navigator.of(dialogContext); ... if (navigator.mounted) navigator.pop();`.
- [x] **Step 2**: `register_dialog.dart` — remove `_recommenderController` / `_recommenderError` / `_uuidPattern` / 4th TextField; `_isFormValid` drops recommender branch; `_handleRegister` calls `authVM.register(name, password)` without recommenderUuid.
- [x] **Step 3**: `strings.dart` — remove `recommenderUuidLabel`, `recommenderUuidInvalid`.
- [x] **Step 4**: `fvm flutter analyze lib/widgets/sidebar/sidebar_header.dart lib/presentation/widgets/auth/ lib/common/constants/strings.dart` → `No issues found!`.

## 5. Risks

- **Risk**: `addPostFrameCallback` delays dialog ~16ms vs tap; acceptable vs current intermittent no-show / crash.
- **Rollback**: Three small independent files; `git revert`.

## 6. Notes / Decision Log

- Recommender UUID service path kept: `AuthService.register(..., recommenderUuid: ...)` available for future callers (e.g. deep link from invite). Default UI no longer asks user to type it.
- No full `Theme` override refactor (drawer still wraps dark Theme); dialogs use root navigator and bypass that Theme.

### Review

- **Round 1** (❌ CHANGE):
  - High: `NavigatorState.mounted` on logout does not prove dialog still on stack; user closing via barrier/back during await could pop underlying page → reverted to `dialogContext.mounted`.
  - Medium: `addPostFrameCallback` lacked reentrancy guard; fast double-tap stacked dialogs → `SidebarHeader` StatefulWidget + `_dialogScheduled` + `showDialog<void>(...).whenComplete(reset)`.
- **Round 2** (✅ PASS): All enter/exit paths reset flag; `mounted` guards async after unmount; `_dialogScheduled` not in render tree so no `setState`.

---

## ✅ Done

- Completed at: 2026-05-15
- Command run: `/init`
- CLAUDE.md update summary: `widgets/auth/` dialog root navigator + `clearError()` already documented; `widgets/sidebar/` notes `SidebarHeader` StatefulWidget with `_dialogScheduled` + `addPostFrameCallback` anti double-tap race.
- Related commit: (pending commit)
- Codex review: SESSION_ID `019e2873-2990-72e2-bc68-ba47328971b7`, two rounds ❌ CHANGE → ✅ PASS.
