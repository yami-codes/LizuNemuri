# Auth Token Migration to Secure Storage + AuthRepository In-Memory Cache (Defensive Degradation)

- **Created**: 2026-05-15
- **Owner**: WuMe-sicx
- **Status**: done
- **Related Issue / PR**: Local persistence optimization checklist item 6 (Codex SESSION 019e2c0c…2962 analysis C7)

---

## 1. Goal

`AuthRepository` stores `AuthResp` containing bearer `token` as **plaintext JSON** in SharedPreferences (`auth_data`), and `AuthInterceptor.onRequest` calls `getAuthData()` on **every HTTP request** (prefs read + `json.decode` + `AuthResp.fromJson`). This task: (1) migrate token to `flutter_secure_storage` (Android EncryptedSharedPrefs / iOS Keychain), (2) add `AuthRepository` in-memory cache so interceptor has zero storage overhead, (3) one-time migration of existing plaintext `auth_data`, (4) **defensive degradation**: on secure storage read/write failure fall back to prefs, never log user out due to Keystore failure.

> User acknowledged and accepted: new native dependency, this environment cannot verify Android Keystore on device, so defensive degradation is mandatory.

## 2. Scope

**In scope:**
- `pubspec.yaml` add `flutter_secure_storage` (`pub get` resolves).
- Rewrite `AuthRepository`: inject `SharedPreferences` + `FlutterSecureStorage` (latter optional named param, default `const FlutterSecureStorage()`, zero DI call-site changes); `_cached`/`_loaded` in-memory cache + concurrent dedup `_loadFuture` (`??=`, same atomic pattern as DatabaseService).
- `getAuthData()`: if loaded → return memory; else secure first → empty then migrate old prefs (clear plaintext only on migration success, on failure keep plaintext + no logout) → empty then null.
- `saveAuthData()`: secure write success → clear residual plaintext; secure failure → degrade to prefs (preserve login state).
- `clearAuthData()`: clear secure + prefs + memory (each swallows errors, does not block the other).
- Entire `AuthResp` JSON blob in secure (token is sensitive; blob is small; no model split — avoids model knowledge leak and split complexity; prefs leave no sensitive data).

**Out of scope:**
- Do not split `AuthResp` into sensitive/non-sensitive storage (whole blob in secure is simpler and safer).
- Do not change `AuthInterceptor` / `AuthViewModel` / `AuthService` call contracts (`getAuthData/saveAuthData/clearAuthData` signatures unchanged; interceptor benefits from cache automatically).
- No platform-specific hardening config (default Android EncryptedSharedPreferences / iOS Keychain), no biometrics.
- Cannot verify Keystore on device — defensive degradation covers faulty devices (project sensitive to Xiaomi HyperOS etc. native issues).

## 3. Acceptance

- [x] `flutter_secure_storage: ^9.2.2` in `pubspec.yaml`, `fvm flutter pub get` success (Changed 7 deps).
- [x] `AuthInterceptor` via memory cache: after first load `getAuthData()` uses `_cached`, no prefs/secure read, no `json.decode`.
- [x] Existing plaintext `auth_data` migrates to secure and clears plaintext after upgrade; migration failure keeps plaintext and does not logout (defensive degradation, Codex confirmed).
- [x] New login token writes secure; secure write failure degrades to prefs, login state preserved.
- [x] Logout clears secure+prefs+memory, each swallows errors independently.
- [x] Concurrent first `getAuthData()` triggers only one load/migrate (`_loadFuture ??=` no await suspension point, Codex confirmed).
- [x] `flutter analyze lib/data/repositories/` = No issues found; tests 31 pass (1 pre-existing stale unrelated).
- [x] Codex review ✅ PASS (SESSION 019e2c0c…2962; round 1 ✅ → self-review found concurrent guard → round 2 ❌ secure old value resurrection → serialization fix → round 3 PASS).

## 4. Steps

- [x] **Step 1**: `pubspec.yaml` add `flutter_secure_storage: ^9.2.2`; `fvm flutter pub get` success
- [x] **Step 2**: Rewrite `AuthRepository` (secure+prefs dual backend, `_cached`/`_loaded` cache, `_loadFuture ??=` dedup, one-time migration, defensive degrade)
- [x] **Step 2b**: Self-review add concurrent guards (`if(_loaded)return _cached` at each commit point) + persistence serialization `_writeLock`/`_serialize` (migration/save/clear ordered, no secure old value resurrection)
- [x] **Step 3**: `flutter analyze` (No issues found) + `flutter test` (31 pass, 1 pre-existing stale) full regression
- [x] **Step 4**: Codex review — round 1 ✅ → self-review concurrent window guards → round 2 ❌ (secure old token platform reorder resurrection) → serialization fix → round 3 ✅ PASS

## 5. Risks

- **Risk**: new native dep `pub get` resolve/build not verified in this environment (user accepted). Android Keystore failures on some OEM ROMs — defensive degradation (read/write fail → prefs fallback, migration fail keep plaintext no logout) worst case equals current plaintext prefs, no logout or crash. Memory cache multi-instance inconsistency — `AuthRepository` DI singleton, single write entry, cache and storage written together, safe.
- **Rollback**: revert commit + `pubspec.yaml`/`pubspec.lock` rollback then `pub get`.

## 6. Notes / Decision Log

- Defensive degradation is hard constraint: security gain must not cost logout/crash on faulty devices. Clear plaintext only after migration success is key invariant (clear plaintext + migration fail = logout).
- Concurrent dedup reuses DatabaseService "cache Future, no await between `??=`" pattern; parallel interceptor requests load once.
- Codex round 2 deep concurrency: memory `_loaded` guard alone cannot prevent「legacy migrate `_secure.write(legacy)` vs concurrent save/clear secure writes completing out of order on platform ⇒ old token resurrects in secure」. Fix = persistence serialization `_serialize` (each migration/save/clear secure+prefs write is one serialized action, issue order == persist order, last writer wins) + `if(_loaded)return` guard before chain (migration only enqueued when no save/clear). Reuses optimization-1 chain pattern.

---

## ✅ Done

- Completed at: 2026-05-15 21:10
- Command run: `/init`
- CLAUDE.md update summary: added `AuthRepository` security/concurrency invariants — token blob in flutter_secure_storage, `_cached`/`_loaded` cache zero per-request interceptor overhead, `_loadFuture ??=` concurrent dedup, one-time plaintext migration (clear only on success), defensive prefs fallback (Keystore failure no logout/crash), all secure/prefs writes via `_serialize` serialization preventing old value resurrection.
- Related commit: not committed (user did not request commit; pending unified commit timing)
