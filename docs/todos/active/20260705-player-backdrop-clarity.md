# Player backdrop clarity slider

- **创建时间**：2026-07-05
- **负责人**：cursor-agent
- **状态**：active
- **关联 Issue / PR**：Eara player polish (Milestone A)

---

## 1. 目标（Goal）

让用户在设置中调节播放页封面背景清晰度（0–100%），持久化到 SharedPreferences；播放页 `CoverArtworkBackground` 监听 `AppSettingsService` 实时生效。

## 2. 范围（Scope）

**包含：**
- `AppSettingsService.playerBackdropClarity`（0.0–1.0，默认 0.35）
- `CoverArtworkBackground` 通过 `ListenableBuilder` 读取设置
- 设置 → 播放分区滑杆
- l10n（en/zh/th）+ `Strings`
- 单元 / widget 测试扩展

**不包含：**
- `player_screen.dart`、`mini_player/*`、`player_lyric_view.dart`
- `PlayerImmersiveScope` 歌词色估算（仍用常量，后续里程碑）

## 3. 验收标准（Acceptance）

- [x] 设置滑杆 0–100% 可调，重启后保持
- [x] 播放页背景随设置变更即时更新（无需重进页面）
- [x] `fvm flutter analyze` 无新增 warning
- [x] `immersive_player_backdrop_test` + settings 持久化测试通过

## 4. 拆解步骤（Steps）

- [x] **Step 1**：`AppSettingsService` 字段 + getter/setter
  - 涉及文件：`lib/core/settings/app_settings_service.dart`
  - 验证：默认 0.35，clamp 0–1
- [x] **Step 2**：`CoverArtworkBackground` 监听设置
  - 涉及文件：`lib/widgets/player/cover_artwork_background.dart`
  - 验证：ListenableBuilder 重建
- [x] **Step 3**：设置页滑杆 + l10n
  - 涉及文件：`settings_screen.dart`, `app_*.arb`, `strings.dart`
  - 验证：`gen-l10n` 成功
- [x] **Step 4**：测试 + analyze
  - 涉及文件：`test/widgets/player/immersive_player_backdrop_test.dart`
  - 验证：`fvm flutter test` / `analyze`

## 5. 风险与回滚（Risks）

- **风险**：`player_screen` 仍传 `kPlayerCoverBackdropClarity` 常量 — 组件内优先读设置，忽略入参
- **回滚方案**：revert 本分支 commit

## 6. 备注 / 决策记录

- 默认 0.35 与 `kPlayerCoverBackdropClarity` 一致，升级用户无视觉跳变。
