# Sleep timer fade-out + sleep mode dim

- **创建时间**：2026-07-05
- **负责人**：cursor-agent
- **状态**：active
- **关联 Issue / PR**：https://github.com/yami-codes/Xuro/pull/11

---

## 1. 目标（Goal）

Gradually fade audio volume before the sleep timer pauses playback, and dim the player screen while the timer is armed — ASMR bedtime UX.

## 2. 范围（Scope）

**包含：**
- Volume fade in last 30s before expiry (`persist: false` steps, restore on end/cancel)
- `SleepModeDimOverlay` on player (pass-through touches)
- Settings toggles: fade-out / dim screen (default on)
- Remaining time in settings value when active
- Unit tests (fade, restore, dim opacity)

**不包含：**
- System brightness API / new packages
- Dim outside player screen

## 3. 验收标准（Acceptance）

- [x] Last 30s: volume ramps to 0, then `pause()`; volume restored afterward
- [x] Cancel mid-fade restores pre-fade volume without clobbering saved preference
- [x] Player shows dim overlay when timer active; intensifies during fade window
- [x] Settings toggles persist; tests + analyze pass

## 4. 拆解步骤（Steps）

- [x] **Step 1**：Settings + `setVolume(persist:)` 
- [x] **Step 2**：`SleepTimerController` fade/tick/remaining/dimOpacity
- [x] **Step 3**：`SleepModeDimOverlay` + player/settings UI + l10n
- [x] **Step 4**：Tests

## 5. 风险与回滚（Risks）

- **风险**：Fade `setVolume` must not persist lowered volume to prefs — mitigated by `persist: false` + restore.
- **回滚**：Revert commit; toggles default on but can be disabled.
