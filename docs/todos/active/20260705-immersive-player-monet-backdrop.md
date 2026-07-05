# Immersive player + Monet cover backdrop

- **创建时间**：2026-07-05
- **负责人**：cursor-agent
- **状态**：active
- **关联 Issue / PR**：

---

## 1. 目标（Goal）

为播放页增加 Eara 风格的沉浸式壳层：封面图模糊铺底 + 从封面提取 Monet 色调，透明 AppBar，歌词/封面共用同一氛围背景。

## 2. 范围（Scope）

**包含：**
- `CoverArtworkBackground` 模糊封面 + clarity 分层
- 封面主色提取 → 播放页 backdrop tint / accent
- `PlayerScreen` 全屏 Stack 布局、透明 chrome
- 歌词行在沉浸背景下可读色（`PlayerImmersiveScope`）
- 单元测试（backdrop style + hue derivation）

**不包含：**
- 设置页 clarity 滑杆（默认 0.35，后续可加）
- 双字幕、睡眠淡出、频谱、A–B 切片
- 全局 Theme 动态色（仅播放页 canvas）

## 3. 验收标准（Acceptance）

- [ ] 播放页封面 URL 存在时显示模糊动态背景，切歌时色调过渡
- [ ] 无封面时回退 `colorScheme` 中性底
- [ ] AppBar / 控件仍可读，三 variant 切换时 chrome 仍走 `colorScheme`
- [ ] 窄屏封面↔字幕切换、宽屏分栏均正常
- [ ] `fvm flutter analyze` 无新增 warning
- [x] 相关单元测试通过

## 4. 拆解步骤（Steps）

- [x] **Step 1**：`palette_generator` + hue/backdrop 纯函数
  - 涉及文件：`pubspec.yaml`, `lib/core/theme/player_hue_derivation.dart`, `lib/widgets/player/cover_artwork_backdrop_style.dart`
  - 验证：单元测试
- [x] **Step 2**：`CoverArtworkBackground` + palette loader
  - 涉及文件：`lib/widgets/player/cover_artwork_background.dart`, `player_cover_palette_loader.dart`, `player_immersive_scope.dart`
  - 验证：analyze
- [x] **Step 3**：接入 `PlayerScreen` + 歌词可读色
  - 涉及文件：`lib/screens/player_screen.dart`, `lib/widgets/lyrics/components/lyric_line.dart`
  - 验证：analyze + test
- [ ] **Step 4**：提交并开 PR
  - 验证：CI 本地 analyze/test

## 5. 风险与回滚（Risks）

- **风险**：palette 提取增加首帧异步；低端机 blur 成本
- **回滚方案**：revert 分支或 `enabled: false` 常量

## 6. 备注 / 决策记录

- 参考 Eara `CoverArtworkBackground.kt` + `HueDerivation.kt` + `LyricReadableColors.kt`
- 动态色仅限播放页，不破坏三 variant 全局 invariant

---

## ✅ 完成标记

- 完成时间：
- 执行命令：`/init`
- CLAUDE.md 更新摘要：
- 关联 commit：
