# Fix broken Library / desktop SQLite / Linux title

- **创建时间**：2026-07-05
- **负责人**：cursor-agent
- **状态**：active
- **关联 Issue / PR**：user report "Broken app Please fix"

---

## 1. 目标（Goal）

Restore a working Library tab and desktop database bootstrap after the Eara nav refactor and Lizunemu rebrand — gray Library screen, infinite Hot/Search loading symptoms traced to a Provider scope crash and Linux `libsqlite3.so` load failure.

## 2. 范围（Scope）

**包含：**
- Fix `LibraryTabContent` reading `LocalLibraryViewModel` above its `MultiProvider`
- Linux/desktop SQLite open override (`libsqlite3.so.0` fallback)
- Linux window title → Lizunemu
- Regression widget test for Library tab shell

**不包含：**
- API/VPN reliability changes beyond existing timeouts
- Full desktop packaging / CI for sqlite bundling

## 3. 验收标准（Acceptance）

- [ ] Library tab renders segment controls + empty local-library state (no Provider crash)
- [ ] Desktop SQLite opens on Linux (`libsqlite3.so.0` path)
- [ ] Linux window title shows Lizunemu
- [ ] `fvm flutter test` passes
- [ ] `fvm flutter analyze` passes (no new warnings)

## 4. 拆解步骤（Steps）

- [x] **Step 1**：Fix Provider scope in `library_tab_content.dart`
  - 验证：`flutter run -d linux` — no `ProviderNotFoundException`
- [x] **Step 2**：Harden `database_bootstrap.dart` for Linux sqlite soname
  - 验证：downloads/local library load without SqfliteFfiException
- [x] **Step 3**：Update `linux/my_application.cc` title
- [x] **Step 4**：Add widget test + run full test suite (185 tests)

## 5. 风险与回滚（Risks）

- **风险**：SQLite open override may differ per distro; fallback chain mitigates
- **回滚方案**：revert commit
