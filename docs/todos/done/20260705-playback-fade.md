# Play/pause volume fade (Eara VolumeFader pattern)

- **创建时间**：2026-07-05
- **负责人**：cursor-agent
- **状态**：done

---

## 1. 目标（Goal）

Pause/resume 时线性淡入淡出音量（默认 ~300ms），贴近 Eara `VolumeFader` / `FadingPlayer` 的 ASMR 听感；可在设置中关闭或调节时长。

## 3. 验收标准（Acceptance）

- [x] 暂停：音量在 `playbackFadeMs` 内降至 0，再 `pause()`，播放器内部音量恢复为 `playbackVolume`
- [x] 恢复：从 0 开始 `play()`，再淡入至 `playbackVolume`
- [x] 设置关闭渐变时行为与改动前一致
- [x] 渐变过程不写 `playback_volume` SharedPreferences
- [x] `flutter analyze` 无新增 warning；单元测试通过

## 4. 拆解步骤（Steps）

- [x] **Step 1–6**：见关联 commit

---

## ✅ 完成标记

- 完成时间：2026-07-05 09:40
- 执行命令：`/init`（手动更新 CLAUDE.md）
- CLAUDE.md 更新摘要：补充 play/pause fade 设置与 `VolumeFader`/`AudioPlayerService` 不变量
- 关联 commit：`ef75351`
