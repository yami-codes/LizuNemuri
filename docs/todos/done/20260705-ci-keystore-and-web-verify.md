# Harden CI keystore decode + verify Web build

- **创建时间**：2026-07-05
- **负责人**：cursor-agent
- **状态**：active
- **关联 Issue / PR**：follow-up to PR #14 / v2.0.0-rc.3

---

## 1. 目标（Goal）

Android release CI still fails on `KEYSTORE_BASE64` decode; Web fix from rc.3 was never verified green because the workflow cancelled mid-build. Harden signing setup and re-release.

## 2. 范围（Scope）

**包含：**
- Robust base64 keystore decode in `.github/workflows/build.yml`
- `concurrency: cancel-in-progress: false` so parallel jobs finish
- `workflow_dispatch` platform toggles for manual verification
- Tag `v2.0.0-rc.4`

**不包含：**
- Rotating or re-uploading GitHub secrets (repo owner action)
- Unsigned Android fallback builds

## 3. 验收标准（Acceptance）

- [x] Keystore step strips whitespace, validates output, prints actionable error
- [x] Web build passes on CI (`v2.0.0-rc.4` run 28749094915 — `build-web: success`)
- [ ] Android passes once `KEYSTORE_BASE64` secret is valid (still fails at Create keystore file)
- [x] Tagged `v2.0.0-rc.4`

## 4. 步骤（Plan）

- [x] Update `build.yml` (keystore + concurrency + dispatch inputs)
- [x] Bump version + CHANGELOG
- [x] Push branch, open PR, merge, tag rc.4
- [x] Confirm `build-web` green on Actions (run 28749094915)

---

## ✅ 完成标记

- 完成时间：2026-07-05
- 关联 commit：`850f3e4` / tag `v2.0.0-rc.3` → `v2.0.0-rc.4`
- CI: Web/iOS/Windows green on run 28749094915; Android blocked on invalid `KEYSTORE_BASE64` secret
