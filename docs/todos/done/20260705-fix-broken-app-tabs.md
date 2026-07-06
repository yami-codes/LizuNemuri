# Fix broken Library / desktop SQLite / Linux title

- **Created**: 2026-07-05
- **Owner**: cursor-agent
- **Status**: done
- **Related Issue / PR**: [#13](https://github.com/yami-codes/LizuNemu/pull/13) / v2.0.0-rc.2

---

## 1. Goal

Restore a working Library tab and desktop database bootstrap after the Eara nav refactor and Lizunemu rebrand — gray Library screen, infinite Hot/Search loading symptoms traced to a Provider scope crash and Linux `libsqlite3.so` load failure.

## 2. Scope

**In scope:**
- Fix `LibraryTabContent` reading `LocalLibraryViewModel` above its `MultiProvider`
- Linux/desktop SQLite open override (`libsqlite3.so.0` fallback)
- Linux window title → Lizunemu
- Regression widget test for Library tab shell

**Out of scope:**
- API/VPN reliability changes beyond existing timeouts
- Full desktop packaging / CI for sqlite bundling

## 3. Acceptance

- [x] Library tab renders segment controls + empty local-library state (no Provider crash)
- [x] Desktop SQLite opens on Linux (`libsqlite3.so.0` path)
- [x] Linux window title shows Lizunemu
- [x] `fvm flutter test` passes (185)
- [x] `fvm flutter analyze` passes (no new warnings)

## 4. Steps

- [x] **Step 1**: Fix Provider scope in `library_tab_content.dart`
- [x] **Step 2**: Harden `database_bootstrap.dart` for Linux sqlite soname
- [x] **Step 3**: Update `linux/my_application.cc` title
- [x] **Step 4**: Add widget test + run full test suite

## 5. Risks

- **Risk**: SQLite open override may differ per distro; fallback chain mitigates
- **Rollback**: Revert commit

---

## ✅ Done

- Completed at: 2026-07-05 10:31 UTC
- Command run: `/init`
- CLAUDE.md update summary: No architecture change; desktop SQLite soname fallback and Library Provider scope are runtime fixes.
- Related commit: `7da0b8d` (merge PR #13) / release tag `v2.0.0-rc.2`
