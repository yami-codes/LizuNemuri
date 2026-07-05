# App UI 文案多语言（中文 / English / ไทย）

- **创建时间**：2026-07-05
- **负责人**：cursor-agent
- **状态**：active

---

## 1. 目标（Goal）

为 `Strings` 全量 UI 文案增加 zh / en / th 三语支持，Settings 可选语言（含跟随系统），`MaterialApp` 接入 gen-l10n。

## 2. 范围（Scope）

**包含：**
- ARB + `flutter gen-l10n` + `Strings` 门面保留现有调用点
- `AppLanguage` 持久化 + Settings 语言分区
- 去除 `const Text(Strings.*)` 编译冲突
- 测试 + APK

**不包含：**
- 非 UI 诊断字符串迁移

## 3. 验收标准（Acceptance）

- [ ] Settings → 语言 可切换 system/zh/en/th，即时生效
- [ ] 英文/泰文下主导航、设置、错误提示为对应语言
- [ ] `flutter analyze` + 测试通过
- [ ] release APK 构建成功

## 4. 拆解步骤（Steps）

- [x] ARB 三语 + pubspec l10n
- [x] Strings 门面 + AppSettingsService
- [x] main.dart + settings UI
- [ ] 测试 / analyze / APK
