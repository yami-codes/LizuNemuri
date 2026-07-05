# Player immersive clarity — live settings sync

- **创建时间**：2026-07-05
- **负责人**：cursor-agent
- **状态**：active
- **关联 Issue / PR**：PR #11

---

## 1. 目标（Goal）

`PlayerImmersiveColors` lyric contrast must follow `AppSettingsService.playerBackdropClarity` live (backdrop already does).

## 2. 范围（Scope）

**包含：**
- `player_screen.dart` ListenableBuilder + clarity pass-through
- Tests if needed

**不包含：**
- Milestone C global Monet theme

## 3. 验收标准（Acceptance）

- [x] Changing clarity slider updates lyric colors without leaving player
- [x] Existing immersive backdrop tests pass

## 4. 拆解步骤（Steps）

- [x] **Step 1**：Wire clarity in `PlayerImmersiveColors.resolve` call
- [x] **Step 2**：Run `immersive_player_backdrop_test.dart`
