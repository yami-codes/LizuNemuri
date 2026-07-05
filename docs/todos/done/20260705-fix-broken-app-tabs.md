# Fix broken Library / desktop SQLite / Linux title

- **创建时间**：2026-07-05
- **负责人**：cursor-agent
- **状态**：done
- **关联 Issue / PR**：[#13](https://github.com/yami-codes/LizuNemu/pull/13) / v2.0.0-rc.2

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

- [x] Library tab renders segment controls + empty local-library state (no Provider crash)
- [x] Desktop SQLite opens on Linux (`libsqlite3.so.0` path)
- [x] Linux window title shows Lizunemu
- [x] `fvm flutter test` passes (185)
- [x] `fvm flutter analyze` passes (no new warnings)

## 4. 拆解步骤（Steps）

- [x] **Step 1**：Fix Provider scope in `library_tab_content.dart`
- [x] **Step 2**：Harden `database_bootstrap.dart` for Linux sqlite soname
- [x] **Step 3**：Update `linux/my_application.cc` title
- [x] **Step 4**：Add widget test + run full test suite

## 5. 风险与回滚（Risks）

- **风险**：SQLite open override may differ per distro; fallback chain mitigates
- **回滚方案**：revert commit

---

## ✅ 完成标记

- 完成时间：2026-07-05 10:31 UTC
- 执行命令：`/init`
- CLAUDE.md 更新摘要：无架构变更；桌面 SQLite soname 回退与 Library Provider 作用域为运行时修复。
- 关联 commit：`7da0b8d` (merge PR #13) / release tag `v2.0.0-rc.2`
