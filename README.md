# Lizunemu

[English](README_en.md)

一个使用 Flutter 构建的 [ASMR.ONE](https://asmr.one) 第三方客户端（原 **Xuro** 2.0 重品牌）。

## 项目概述

Lizunemu 旨在通过精美的动画和现代化的用户界面，提供流畅愉悦的 ASMR 聆听体验。播放器沉浸感、睡前定时与若干交互模式参考了 **[EaraAsmrPlayer](https://github.com/moyucc/EaraAsmrPlayer)**（见下方 [设计灵感](#设计灵感)）。

## 特性

- 🎵 稳定的后台播放，再也不用担心杀后台了
- 🎨 精美的动画效果与简洁的 UI 设计
- 📝 字幕/歌词显示，支持 VTT/LRC 格式导入
- 🤖 LLM 双语字幕翻译（原文 + 译文叠显）
- 📥 离线下载、本地曲库扫描
- 🎧 DLsite Play 曲库（Cookie 登录）
- 🌐 多语言界面（中文 / English / ไทย）
- 📱 Android / iOS / Web / Windows 桌面

## 设计灵感

Lizunemu 的沉浸式播放器、睡前定时与耳机向交互，主要参考 **[EaraAsmrPlayer](https://github.com/moyucc/EaraAsmrPlayer)** — 一款专为 ASMR 打造的 Android 客户端（Jetpack Compose + Media3）。Eara 展示了如何用**封面驱动取色**、**可读歌词**、**左右耳向音频调节**与**进度条切片循环**，让长时间双耳内容听起来「为此而生」，而不是套在通用音乐播放器上的皮肤。

已移植或对齐的 Eara 模式包括：

- 封面驱动 Monet 动态主题
- 动能居中歌词
- 播放/暂停音量淡入淡出
- 睡前定时 + 睡眠模式暗屏
- 本地曲库 + DLsite Play 集成

Lizunemu 的差异化在于：**原生 asmr.one API**、**LLM 字幕翻译**、**iOS / 多语言界面**与用户字幕导入。若你喜欢 Lizunemu 的播放器氛围，也请支持原项目：[github.com/moyucc/EaraAsmrPlayer](https://github.com/moyucc/EaraAsmrPlayer)。**Lizunemu 与 Eara 作者、asmr.one、DLsite 无隶属关系。**

## 快速开始

```bash
git clone https://github.com/yami-codes/LizuNemu.git
cd LizuNemu
fvm flutter pub get
fvm flutter run
```

## 许可证

本项目基于 [CC BY-NC-SA 4.0](LICENSE) 开源。
