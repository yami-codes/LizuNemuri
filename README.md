# Xuro

[English](README_en.md)

一个使用 Flutter 构建的 [ASMR.ONE](https://asmr.one) 第三方客户端。

## 项目概述

Xuro 旨在通过精美的动画和现代化的用户界面，提供流畅愉悦的 ASMR 聆听体验。播放器沉浸感、睡前定时与若干交互模式参考了 **[EaraAsmrPlayer](https://github.com/moyucc/EaraAsmrPlayer)**（见下方 [设计灵感](#设计灵感)）。

## 特性

- 🎵 稳定的后台播放，再也不用担心杀后台了
- 🎨 精美的动画效果与简洁的 UI 设计
- 📝 字幕/歌词显示，支持 VTT/LRC 格式导入
- 📋 播放列表管理
- 🔍 多维度探索：标签、社团、声优浏览
- ❤️ 收藏功能
- 🔔 Android 13+ 通知权限适配
- 🖥️ 悬浮歌词窗口（Android）
- ⚙️ 完善的设置系统
  - 外观主题（浅色/深色/跟随系统）
  - 音频格式偏好
  - 屏幕常亮
  - 智能路径展开
- 💾 全方位的智能缓存机制
  - 图片智能缓存：优化封面加载速度，告别重复加载
  - 字幕本地缓存：实现快速字幕匹配与加载
  - 音频文件缓存：减少重复下载，节省流量开销
  - 统一缓存管理：一键查看和清理所有缓存
- 🌐 为服务器减轻压力
  - 智能的缓存策略确保资源高效利用
  - 懒加载机制避免无效请求
  - 合理的缓存清理机制平衡本地存储
- 🎧 **Eara 启发（持续移植中）**
  - 封面莫奈取色 + 沉浸式播放背景
  - 睡眠定时淡出与睡眠模式暗屏
  - 播放速度预设
  - 双语字幕（原文 + LLM 译文）

## 设计灵感

Xuro 的沉浸式播放器、睡前定时与耳机向交互，主要参考 **[EaraAsmrPlayer](https://github.com/moyucc/EaraAsmrPlayer)** — 一款专为 ASMR 打造的 Android 客户端（Jetpack Compose + Media3）。Eara 展示了如何用**封面驱动取色**、**可读歌词**、**左右耳向音频调节**与**进度条切片循环**，让长时间双耳内容听起来「为此而生」，而不是套在通用音乐播放器上的皮肤。

我们已在 Flutter 跨平台架构下移植并改造了其中一部分：

- 模糊封面背景 + 从封面提取的动态强调色（播放器画布内）
- LLM 双语字幕（原文叠译文 — Xuro 独有）
- 睡眠定时：到期前音量淡出 + 播放器暗屏
- 播放速度预设（0.75×–1.5×）

完整对照与后续移植清单见 [`docs/inspiration_eara.md`](docs/inspiration_eara.md)；**产品方向（grill-me 锁定）** 见 [`docs/eara_ui_north_star.md`](docs/eara_ui_north_star.md)。

- **A–B 片段循环**（进度条标记、拖拽微调）
- **双声道频谱**与立体声平衡（双耳向内容）
- **图形均衡器 / 场景混响**（独立音频面板）
- **搜索筛选 Chips**、热门发现、统一下载管理页

Xuro 的差异化在于：**原生 asmr.one API**、**LLM 字幕翻译**、**iOS / 多语言界面**与用户字幕导入。若你喜欢 Xuro 的播放器氛围，也请支持原项目：[github.com/moyucc/EaraAsmrPlayer](https://github.com/moyucc/EaraAsmrPlayer)。**Xuro 与 Eara 作者、asmr.one、DLsite 无隶属关系。**

## 环境要求

- Flutter 3.27.0+
- Dart SDK >=3.2.3 <4.0.0
- Android: minSdk 21 / targetSdk 33
- Java 17

## 安装与运行

```bash
# 克隆仓库
git clone https://github.com/WuMe-sicx/Xuro.git
cd Xuro

# 安装依赖
flutter pub get

# 代码生成（freezed + json_serializable）
dart run build_runner build --delete-conflicting-outputs

# 运行应用（调试模式）
flutter run

# 构建 Release APK
flutter build apk --release
```

## 项目结构

```
lib/
├── core/                 # 核心功能（音频、字幕、主题、缓存、平台服务）
├── data/                 # 数据层（API 服务、数据模型、仓储）
├── presentation/         # 表现层（ViewModel）
├── screens/              # 页面
├── widgets/              # 可复用 UI 组件
└── common/               # 通用功能（常量、工具）
```

## 开发准则

我们维护了一套完整的开发准则以确保代码质量和一致性：
- [开发工作流（强制）](docs/dev_workflow.md) —— 任何功能开发前先写 TODO，完成时执行 `/init`
- [开发准则](docs/guidelines_zh.md) —— 架构、代码风格、UI/UX 规范
- [TODO 文档目录](docs/todos/) —— 任务跟踪与模板

## 贡献指南

在提交贡献之前，请按 [开发工作流](docs/dev_workflow.md) 建立 TODO 文档，并遵循 [开发准则](docs/guidelines_zh.md)。

## 许可证

本项目采用 Creative Commons 非商业性使用-相同方式共享许可证 (CC BY-NC-SA) - 查看 [LICENSE](LICENSE) 文件了解详细信息。

原项目作者：[asmroneapp](https://github.com/asmroneapp) | 原始仓库：[Yuro](https://github.com/asmroneapp/Yuro)
