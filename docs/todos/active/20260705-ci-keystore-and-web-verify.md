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

- [ ] Keystore step strips whitespace, validates output, prints actionable error
- [ ] Web build passes on CI (`workflow_dispatch` or tag)
- [ ] Android passes once `KEYSTORE_BASE64` secret is valid
- [ ] Tagged `v2.0.0-rc.4`

## 4. 步骤（Plan）

- [x] Update `build.yml` (keystore + concurrency + dispatch inputs)
- [ ] Bump version + CHANGELOG
- [ ] Push branch, open PR, merge, tag rc.4
- [ ] Confirm `build-web` green on Actions
