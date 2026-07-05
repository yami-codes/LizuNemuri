# Downloads hub (Eara DownloadsScreen pattern)

- **创建时间**：2026-07-05
- **负责人**：cursor-agent
- **状态**：active
- **关联 Issue / PR**：

---

## 1. 目标（Goal）

在侧边栏提供「下载」入口，展示按作品分组的已完成本地下载列表；可进入作品详情或离线播放音频。

## 2. 范围（Scope）

**包含：**
- `DownloadsViewModel` + 分组纯函数 + 单元测试
- `DownloadsHubContent` / `DownloadsScreen` 全页包装
- 侧边栏导航项
- l10n + `Strings` 文案
- `DownloadService.localPathIfDownloaded` 标题回退（离线播放）

**不包含：**
- `main_screen.dart` 底部导航（另一 agent）
- DB schema 变更 / 进行中下载队列 UI

## 3. 验收标准（Acceptance）

- [x] 侧边栏「下载」可打开 Downloads 页
- [x] 列表按 workId 分组，显示 RJ/标题、文件数、总大小
- [x] 点击条目进入作品详情；有音频时可播放
- [x] 无下载时显示空状态
- [x] `flutter analyze` 无新增 warning
- [x] 分组逻辑单元测试通过

## 4. 拆解步骤（Steps）

- [x] **Step 1**：分组工具 + ViewModel
  - 涉及文件：`lib/core/download/utils/download_grouping.dart`, `lib/presentation/viewmodels/downloads_viewmodel.dart`
  - 验证：单元测试
- [x] **Step 2**：UI 内容 + 全页 Screen
  - 涉及文件：`lib/screens/contents/downloads_hub_content.dart`, `lib/screens/downloads_screen.dart`
  - 验证：analyze
- [x] **Step 3**：侧边栏 + l10n
  - 涉及文件：`sidebar_menu.dart`, `app_*.arb`, `strings.dart`
  - 验证：analyze
- [x] **Step 4**：离线播放回退 + 测试 + analyze
  - 验证：`fvm flutter test`, `fvm flutter analyze`

## 5. 风险与回滚（Risks）

- **风险**：同名文件标题回退匹配错误（极少见）
- **回滚方案**：revert commit

## 6. 备注 / 决策记录

- 复用 `IDownloadRepository.listAllOldestFirst()`，VM 内过滤失效文件并分组
- ViewModel 用局部 `ChangeNotifierProvider`，不注册 GetIt
