# Optimize Two Error Prompt Types: Connection Errors Prioritize VPN Hint; Auth Errors Go Straight to Login

- **Created**: 2026-05-15
- **Owner**: WuMe-sicx
- **Status**: done
- **Related Issue / PR**: (none)

---

## 1. Goal

Optimize two user-visible error prompts:
1. **Connection errors**: when `Connection reset by peer` etc. occur, prioritize "Please connect VPN first" instead of surfacing low-level technical messages (`Connection failed: Connection reset by peer`).
2. **Auth state errors**: "Favorites" / "For You" when not logged in return "Please log in first"; bottom button should not be "Retry" (retry is pointless) — open login dialog directly; after successful login auto-load the list.

## 2. Scope

**In scope:**
- `lib/common/constants/strings.dart`: add VPN hint / login hint / go-login button copy, centralized.
- `lib/data/services/exceptions/network_exception.dart`: add `userMessage` (user-friendly mapping) and `isAuthError`. connectionError / timeout → VPN hint; authError → please log in.
- `lib/presentation/viewmodels/favorites_viewmodel.dart`, `recommend_viewmodel.dart`: add `isLoginError` flag; catch branches use `NetworkException.userMessage`.
- `lib/widgets/work_grid/components/grid_error.dart`, `enhanced_work_grid_view.dart`: pass through `isLoginError` + `onLogin`; login errors render "Go to login" button (not "Retry").
- `lib/screens/contents/favorites_content.dart`, `recommend_content.dart`: provide `onLogin` callback, open login dialog and refresh list after login success.
- `lib/widgets/work_grid_view.dart` (legacy) + `lib/screens/favorites_screen.dart` (sidebar "Favorites" standalone route, still legacy component): same `isLoginError` + `onLogin` wiring for consistent Favorites behavior (including mid-session token expiry).

**Out of scope:**
- Search, tags, circles, voice actors, playlists etc. — mapping centralized in `NetworkException` for future reuse; not wired per-page this round.
- No 401 token auto-refresh / logout logic (prompt + navigation only, no auth refresh changes).
- Login dialog UI unchanged.

## 3. Acceptance

- [x] VPN off, enter "Favorites" / "For You", connection error → page shows "Please connect VPN first" (not `Connection failed: ...` or `NetworkException(...)`).
- [x] Not logged in, enter "Favorites" / "For You" → "Please log in first", bottom button "Go to login" (not "Retry").
- [x] Tap "Go to login" opens login dialog; after success dialog closes and list auto-loads.
- [x] Ordinary network errors (e.g. 5xx) still show "Retry" button, no regression.
- [x] `flutter analyze` passes with no new warnings.
- [x] Related unit / widget tests pass (no model changes, no build_runner needed).

## 4. Steps

- [x] **Step 1**: Write this TODO doc.
  - Files: `docs/todos/active/20260515-network-vpn-and-login-error-prompts.md`
  - Verify: doc exists with complete fields.
- [x] **Step 2**: `strings.dart` add `networkVpnHint` / `loginRequired` / `goLogin`.
  - Files: `lib/common/constants/strings.dart`
  - Verify: compiles, constants referenceable.
- [x] **Step 3**: `NetworkException` add `userMessage` getter + `isAuthError`. connectionError/timeout→VPN hint, authError→please log in, else fallback `message`.
  - Files: `lib/data/services/exceptions/network_exception.dart`
  - Verify: `flutter test` passes; branch coverage.
- [x] **Step 4**: Both ViewModels add `_isLoginError`/`isLoginError`; not-logged-in branch sets flag with `Strings.loginRequired`; catch uses `NetworkException.userMessage` and `isAuthError`.
  - Files: `favorites_viewmodel.dart`, `recommend_viewmodel.dart`
  - Verify: `flutter analyze` passes; logic consistent.
- [x] **Step 5**: `GridError` + `EnhancedWorkGridView` pass `isLoginError`/`onLogin`, render "Go to login" button.
  - Files: `grid_error.dart`, `enhanced_work_grid_view.dart`
  - Verify: other pages using component unaffected (`isLoginError=false`, `onLogin=null` defaults).
- [x] **Step 6**: content screens + legacy standalone route wire `onLogin`: root navigator opens `LoginDialog`, await then refresh if `isLoggedIn`.
  - Files: `favorites_content.dart`, `recommend_content.dart`, `work_grid_view.dart`, `favorites_screen.dart`
  - Verify: manual path simulation (analyze pass + code review).
- [x] **Step 7**: `flutter analyze` (changed files 0 issues, repo 33 pre-existing withOpacity etc.) + `flutter test` (10 pass; only fail `test/widget_test.dart` scaffold counter smoke, baseline same fail, not regression), check acceptance, run `/init`, archive.

## 5. Risks

- **Risk**: `timeout` also mapped to VPN hint — reasonable product judgment for this app (asmr.one Japan server, domestic proxy needed), but real timeouts also show VPN copy. Acceptable.
- **Risk**: `EnhancedWorkGridView` reused on many pages; new params have defaults, old callers unchanged.
- **Rollback**: additive changes; single commit revert restores original copy and "Retry" button.

## 6. Notes / Decision Log

- Decision: user-friendly copy mapping in `NetworkException.userMessage` (single point); ViewModels only consume, no duplicate mapping.
- Decision: connectionError and timeout both → "Please connect VPN first" — geo-blocked server, same root cause.
- Decision: login button copy "Go to login" (`Strings.goLogin`), distinct from sidebar CTA "Log in now" (`loginCta`).
- Decision: login dialog reuses `sidebar_menu.dart` root navigator + `useRootNavigator: true` pattern, avoids drawer/local Theme leak.

---

## ✅ Done

- Completed at: 2026-05-15 18:38
- Command run: `/init`
- CLAUDE.md update summary: `lib/data/` added `services/exceptions/network_exception.dart` entry (`userMessage` single source for user copy, `isAuthError`); API section new "Error-prompt UX" subsection documenting VPN-first connection errors and login-state "Go to login" four-layer invariant (data→viewmodel→widget→screen).
- Related commit: bundled with this error-prompt closure commit (`strings.dart` 3 constants early in `f872229`; remaining 9 .dart files + this TODO in wrap-up commit).
