#!/usr/bin/env python3
"""Safely localize internal Chinese string literals in lib/."""

from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / "lib"

# zh template -> (key, en, th)  ICU placeholders use {name} matching dart arg names.
CATALOG: dict[str, tuple[str, str, str]] = {
    "网络请求失败": ("logNetworkRequestFailed", "Network request failed", "คำขอเครือข่ายล้มเหลว"),
    "解析数据失败": ("logParseDataFailed", "Parse data failed", "แปลงข้อมูลล้มเหลว"),
    "解析认证数据失败": ("logParseAuthDataFailed", "Failed to parse auth data", "แปลงข้อมูลยืนยันตัวตนล้มเหลว"),
    "解析失败: {detail}": ("logParseFailedDetail", "Parse failed: {detail}", "แปลงล้มเหลว: {detail}"),
    "登录失败": ("logLoginFailed", "Login failed", "เข้าสู่ระบบล้มเหลว"),
    "登录失败: {detail}": ("logLoginFailedDetail", "Login failed: {detail}", "เข้าสู่ระบบล้มเหลว: {detail}"),
    "登录失败: {code}": ("logLoginFailedCode", "Login failed: {code}", "เข้าสู่ระบบล้มเหลว: {code}"),
    "登录请求失败": ("logLoginRequestFailed", "Login request failed", "คำขอเข้าสู่ระบบล้มเหลว"),
    "注册失败": ("logRegisterFailed", "Register failed", "สมัครล้มเหลว"),
    "注册失败: {detail}": ("logRegisterFailedDetail", "Register failed: {detail}", "สมัครล้มเหลว: {detail}"),
    "注册失败: {code}": ("logRegisterFailedCode", "Register failed: {code}", "สมัครล้มเหลว: {code}"),
    "注册请求失败": ("logRegisterRequestFailed", "Register request failed", "คำขอสมัครล้มเหลว"),
    "搜索失败": ("logSearchFailed", "Search failed", "ค้นหาล้มเหลว"),
    "搜索失败: {code}": ("logSearchFailedCode", "Search failed: {code}", "ค้นหาล้มเหลว: {code}"),
    "播放失败": ("logPlaybackFailed", "Playback failed", "เล่นล้มเหลว"),
    "标记失败: {code}": ("logMarkFailedCode", "Mark failed: {code}", "ทำเครื่องหมายล้มเหลว: {code}"),
    "加载文件失败": ("logLoadFilesFailed", "Failed to load files", "โหลดไฟล์ล้มเหลว"),
    "加载作品详情失败": ("logLoadWorkDetailFailed", "Failed to load work detail", "โหลดรายละเอียดผลงานล้มเหลว"),
    "加载标签列表失败": ("logLoadTagsFailed", "Failed to load tags", "โหลดแท็กล้มเหลว"),
    "加载社团列表失败": ("logLoadCirclesFailed", "Failed to load circles", "โหลดเซอร์เคิลล้มเหลว"),
    "加载声优列表失败": ("logLoadVoiceActorsFailed", "Failed to load voice actors", "โหลดนักพากย์ล้มเหลว"),
    "加载推荐列表失败": ("logLoadRecommendFailed", "Failed to load recommendations", "โหลดคำแนะนำล้มเหลว"),
    "加载相关推荐失败": ("logLoadSimilarFailed", "Failed to load similar works", "โหลดผลงานที่คล้ายกันล้มเหลว"),
    "加载收藏列表失败": ("logLoadFavoritesFailed", "Failed to load favorites", "โหลดรายการโปรดล้มเหลว"),
    "加载播放列表失败": ("logLoadPlaylistsFailed", "Failed to load playlists", "โหลดเพลย์ลิสต์ล้มเหลว"),
    "加载播放列表作品失败": ("logLoadPlaylistWorksFailed", "Failed to load playlist works", "โหลดผลงานในเพลย์ลิสต์ล้มเหลว"),
    "加载收藏夹列表失败": ("logLoadWorkPlaylistsFailed", "Failed to load work playlists", "โหลดเพลย์ลิสต์ของผลงานล้มเหลว"),
    "加载筛选状态失败": ("logLoadFilterStateFailed", "Failed to load filter state", "โหลดสถานะตัวกรองล้มเหลว"),
    "保存筛选状态失败": ("logSaveFilterStateFailed", "Failed to save filter state", "บันทึกสถานะตัวกรองล้มเหลว"),
    "加载缓存大小失败": ("logLoadCacheSizeFailed", "Failed to load cache size", "โหลดขนาดแคชล้มเหลว"),
    "清理缓存失败": ("logCleanCacheFailed", "Failed to clean cache", "ล้างแคชล้มเหลว"),
    "清理音频缓存失败": ("logCleanAudioCacheFailed", "Failed to clean audio cache", "ล้างแคชเสียงล้มเหลว"),
    "清理字幕缓存失败": ("logCleanSubtitleCacheFailed", "Failed to clean subtitle cache", "ล้างแคชคำบรรยายล้มเหลว"),
    "清理图片缓存失败": ("logCleanImageCacheFailed", "Failed to clean image cache", "ล้างแคชรูปภาพล้มเหลว"),
    "检查相关推荐失败": ("logCheckSimilarFailed", "Failed to check similar works", "ตรวจสอบผลงานที่คล้ายกันล้มเหลว"),
    "切换收藏状态失败": ("logToggleFavoriteFailed", "Failed to toggle favorite", "สลับรายการโปรดล้มเหลว"),
    "更新标记状态失败": ("logUpdateMarkFailed", "Failed to update mark status", "อัปเดตสถานะเครื่องหมายล้มเหลว"),
    "添加到收藏夹失败": ("logAddToPlaylistFailed", "Failed to add to playlist", "เพิ่มในเพลย์ลิสต์ล้มเหลว"),
    "从收藏夹移除失败": ("logRemoveFromPlaylistFailed", "Failed to remove from playlist", "นำออกจากเพลย์ลิสต์ล้มเหลว"),
    "添加到收藏夹失败: {detail}": ("logAddToPlaylistFailedDetail", "Failed to add to playlist: {detail}", "เพิ่มในเพลย์ลิสต์ล้มเหลว: {detail}"),
    "从收藏夹移除失败: {detail}": ("logRemoveFromPlaylistFailedDetail", "Failed to remove from playlist: {detail}", "นำออกจากเพลย์ลิสต์ล้มเหลว: {detail}"),
    "字幕预览加载失败": ("logSubtitlePreviewLoadFailed", "Failed to load subtitle preview", "โหลดตัวอย่างคำบรรยายล้มเหลว"),
    "字幕导入失败": ("logSubtitleImportFailed", "Subtitle import failed", "นำเข้าคำบรรยายล้มเหลว"),
    "字幕解析异常": ("logSubtitleParseException", "Subtitle parse exception", "ข้อยกเว้นการแปลงคำบรรยาย"),
    "不支持的字幕格式": ("logUnsupportedSubtitleFormat", "Unsupported subtitle format", "รูปแบบคำบรรยายไม่รองรับ"),
    "字幕地址为空": ("logSubtitleUrlEmpty", "Subtitle URL is empty", "URL คำบรรยายว่าง"),
    "字幕下载失败: {code}": ("logSubtitleDownloadFailedCode", "Subtitle download failed: {code}", "ดาวน์โหลดคำบรรยายล้มเหลว: {code}"),
    "无可用的音频源": ("logNoAudioSources", "No playable audio sources", "ไม่มีแหล่งเสียงที่เล่นได้"),
    "获取文件列表失败: {code}": ("logFetchFileListFailed", "Failed to fetch file list: {code}", "ดึงรายการไฟล์ล้มเหลว: {code}"),
    "获取作品列表失败: {code}": ("logFetchWorksFailed", "Failed to fetch works: {code}", "ดึงผลงานล้มเหลว: {code}"),
    "获取收藏列表失败: {code}": ("logFetchFavoritesFailed", "Failed to fetch favorites: {code}", "ดึงรายการโปรดล้มเหลว: {code}"),
    "获取推荐列表失败: {code}": ("logFetchRecommendFailed", "Failed to fetch recommendations: {code}", "ดึงคำแนะนำล้มเหลว: {code}"),
    "获取热门列表失败: {code}": ("logFetchPopularFailed", "Failed to fetch popular list: {code}", "ดึงรายการยอดนิยมล้มเหลว: {code}"),
    "获取相关推荐失败: {code}": ("logFetchSimilarFailed", "Failed to fetch similar works: {code}", "ดึงผลงานที่คล้ายกันล้มเหลว: {code}"),
    "获取收藏夹列表失败: {code}": ("logFetchPlaylistsFailed", "Failed to fetch playlists: {code}", "ดึงเพลย์ลิสต์ล้มเหลว: {code}"),
    "获取播放列表失败: {code}": ("logFetchMyPlaylistsFailed", "Failed to fetch my playlists: {code}", "ดึงเพลย์ลิสต์ของฉันล้มเหลว: {code}"),
    "获取标签列表失败: {code}": ("logFetchTagsFailed", "Failed to fetch tags: {code}", "ดึงแท็กล้มเหลว: {code}"),
    "获取社团列表失败: {code}": ("logFetchCirclesFailed", "Failed to fetch circles: {code}", "ดึงเซอร์เคิลล้มเหลว: {code}"),
    "获取声优列表失败: {code}": ("logFetchVoiceActorsFailed", "Failed to fetch voice actors: {code}", "ดึงนักพากย์ล้มเหลว: {code}"),
    "获取作品详情失败: {code}": ("logFetchWorkDetailFailed", "Failed to fetch work detail: {code}", "ดึงรายละเอียดผลงานล้มเหลว: {code}"),
    "获取播放列表作品失败: {code}": ("logFetchPlaylistWorksFailed", "Failed to fetch playlist works: {code}", "ดึงผลงานในเพลย์ลิสต์ล้มเหลว: {code}"),
    "获取默认标记目标收藏夹失败: {code}": ("logFetchDefaultMarkPlaylistFailed", "Failed to fetch default mark playlist: {code}", "ดึงเพลย์ลิสต์เครื่องหมายเริ่มต้นล้มเหลว: {code}"),
    "请求已取消": ("logRequestCancelled", "Request cancelled", "ยกเลิกคำขอแล้ว"),
    "请求超时: {detail}": ("logRequestTimeout", "Request timeout: {detail}", "คำขอหมดเวลา: {detail}"),
    "连接失败: {detail}": ("logConnectionFailed", "Connection failed: {detail}", "เชื่อมต่อล้มเหลว: {detail}"),
    "认证失败: {code}": ("logAuthFailedCode", "Auth failed: {code}", "ยืนยันตัวตนล้มเหลว: {code}"),
    "客户端错误: {code}": ("logClientErrorCode", "Client error: {code}", "ข้อผิดพลาดไคลเอนต์: {code}"),
    "服务器错误: {code}": ("logServerErrorCode", "Server error: {code}", "ข้อผิดพลาดเซิร์ฟเวอร์: {code}"),
    "未知响应错误: {code}": ("logUnknownResponseCode", "Unknown response error: {code}", "ข้อผิดพลาดการตอบกลับไม่ทราบ: {code}"),
    "证书验证失败: {detail}": ("logCertificateFailed", "Certificate validation failed: {detail}", "ตรวจสอบใบรับรองล้มเหลว: {detail}"),
    "未知网络错误: {detail}": ("logUnknownNetworkError", "Unknown network error: {detail}", "ข้อผิดพลาดเครือข่ายไม่ทราบ: {detail}"),
    "网络错误: {detail}": ("logNetworkErrorDetail", "Network error: {detail}", "ข้อผิดพลาดเครือข่าย: {detail}"),
    "GitHub 限流: {code}": ("logGithubRateLimited", "GitHub rate limited: {code}", "GitHub จำกัดอัตรา: {code}"),
    "未找到发布信息: 404": ("logReleaseNotFound404", "Release not found: 404", "ไม่พบข้อมูลเผยแพร่: 404"),
    "响应错误: {code}": ("logResponseErrorCode", "Response error: {code}", "ข้อผิดพลาดการตอบกลับ: {code}"),
    "GitHub release 缺少 tag_name 或 html_url": ("logGithubReleaseMissingFields", "GitHub release missing tag_name or html_url", "GitHub release ไม่มี tag_name หรือ html_url"),
    "无效的播放列表状态：播放列表为空": ("logPlaylistEmpty", "Invalid playlist state: playlist is empty", "สถานะเพลย์ลิสต์ไม่ถูกต้อง: ว่าง"),
    "无效的播放列表索引：{index}，列表长度：{length}": ("logPlaylistIndexInvalid", "Invalid playlist index: {index}, length: {length}", "ดัชนีเพลย์ลิสต์ไม่ถูกต้อง: {index}, ความยาว: {length}"),
    "当前文件不在播放列表中": ("logCurrentFileNotInPlaylist", "Current file is not in the playlist", "ไฟล์ปัจจุบันไม่ได้อยู่ในเพลย์ลิสต์"),
    "ASMR One 播放器": ("logNotificationChannelName", "ASMR One Player", "ASMR One Player"),
    "主页": ("logPageNameHome", "Home", "หน้าแรก"),
    "热门列表": ("logPageNamePopular", "Popular", "ยอดนิยม"),
    "移除": ("logActionRemove", "Remove", "นำออก"),
    "添加": ("logActionAdd", "Add", "เพิ่ม"),
    "展开": ("logExpand", "Expand", "ขยาย"),
    "折叠": ("logCollapse", "Collapse", "ยุบ"),
    "已加载": ("logLoaded", "loaded", "โหลดแล้ว"),
    "未加载": ("logNotLoaded", "not loaded", "ยังไม่โหลด"),
    "文件列表为空": ("logFileListEmpty", "File list is empty", "รายการไฟล์ว่าง"),
    "当前文件名为空": ("logCurrentFileNameEmpty", "Current file name is empty", "ชื่อไฟล์ปัจจุบันว่าง"),
    "未找到字幕文件，清除现有字幕": ("logSubtitleNotFoundClearing", "Subtitle not found, clearing current subtitle", "ไม่พบคำบรรยาย กำลังล้างคำบรรยายปัจจุบัน"),
    "注册成功但自动登录失败": ("logRegisterOkLoginFailed", "Registered but auto-login failed", "สมัครสำเร็จแต่เข้าสู่ระบบอัตโนมัติล้มเหลว"),
}

EN_TERMS = [
    ("网络请求失败", "Network request failed"), ("解析数据失败", "Parse data failed"),
    ("解析数据失败", "Parse data failed"), ("解析失败", "Parse failed"),
    ("加载失败", "load failed"), ("加载", "Loading"), ("清理失败", "cleanup failed"),
    ("保存失败", "save failed"), ("播放失败", "Playback failed"), ("下载失败", "download failed"),
    ("搜索失败", "Search failed"), ("登录失败", "Login failed"), ("注册失败", "Register failed"),
    ("获取", "Fetch"), ("失败", "failed"), ("成功", "succeeded"), ("开始", "Start"),
    ("销毁", "Disposing"), ("刷新", "Refreshing"), ("预加载", "Preload"), ("检查", "Check"),
    ("更新", "Update"), ("移除", "Remove"), ("添加", "Add"), ("字幕", "Subtitle"),
    ("缓存", "Cache"), ("播放列表", "Playlist"), ("收藏夹", "Playlist"), ("作品", "work"),
    ("文件", "file"), ("音频", "audio"), ("标签", "Tag"), ("社团", "Circle"),
    ("声优", "Voice actor"), ("推荐", "Recommend"), ("收藏", "Favorites"),
    ("热门列表", "Popular"), ("主页", "Home"), ("个", ""), ("第", "Page "), ("页", ""),
    ("列表", " list"), ("详情", " detail"), ("初始化", "Init"), ("停止", "Stop"),
    ("恢复", "Restore"), ("设置", "Set"), ("找到", "Found"), ("未找到", "Not found"),
    ("无法", "Cannot"), ("跳过", "skip"), ("命令", "command"), ("权限", "permission"),
    ("数据库", "Database"), ("图片", "Image"), ("导入", "Import"), ("迁移", "Migration"),
    ("认证数据", "Auth data"), ("检查更新", "Update check"), ("限流", "rate limited"),
    ("发布", "release"), ("重试", "retry"), ("等待", "wait"), ("错误", "error"),
    ("状态", "state"), ("上下文", "context"), ("轨道", "track"), ("歌词", "lyric"),
    ("通知栏服务", "Notification service"), ("播放器", "player"), ("悬浮窗", "overlay"),
    ("配对", "Paired"), ("不影响音频", "audio unaffected"), ("预览", "preview"),
    ("匹配", "match"), ("精确", "exact"), ("前缀", "prefix"), ("相似度", "similarity"),
    ("过期", "expired"), ("有效", "valid"), ("无效", "invalid"), ("验证", "validate"),
    ("清空", "clear"), ("清除", "Clear"), ("所有", "All"), ("统一", "Unified"),
    ("自动", "Auto"), ("旧版", "legacy"), ("降级", "fallback"), ("切换", "Switch"),
    ("下一曲", "next track"), ("上一曲", "previous track"), ("播放源", "playback source"),
    ("播放状态", "playback state"), ("播放完成", "playback completed"),
    ("播放错误", "playback error"), ("播放操作", "playback operation"),
    ("播放上下文", "playback context"), ("播放列表", "playlist"),
    ("根目录", "root"), ("同级", "sibling"), ("父目录", "parent"), ("文件夹", "folder"),
    ("展开", "Expand"), ("折叠", "Collapse"), ("已加载", "loaded"), ("未加载", "not loaded"),
    ("文件列表为空", "file list is empty"), ("当前文件名为空", "current file name is empty"),
    ("使用", "Using"), ("从", "From"), ("到", "to"), ("完成", "done"), ("取消", "cancelled"),
    ("查询", "Query"), ("删除", "Delete"), ("创建", "Create"), ("读取", "Read"),
    ("保存", "Save"), ("关闭", "Close"), ("打开", "Open"), ("下载", "Download"),
    ("网络错误", "Network error"), ("服务器错误", "Server error"), ("客户端错误", "Client error"),
    ("请求已取消", "Request cancelled"), ("请求超时", "Request timeout"),
    ("连接失败", "Connection failed"), ("认证失败", "Auth failed"),
    ("证书验证失败", "Certificate validation failed"), ("未知网络错误", "Unknown network error"),
    ("未知响应错误", "Unknown response error"), ("响应错误", "Response error"),
    ("不支持的字幕格式", "Unsupported subtitle format"),
    ("不支持的文件类型", "Unsupported file type"), ("无可用的音频源", "No playable audio sources"),
    ("字幕地址为空", "Subtitle URL is empty"), ("注册成功但自动登录失败", "Registered but auto-login failed"),
    ("注册成功且已携带 token，跳过补充登录", "Registered with token, skip follow-up login"),
    ("注册成功但响应未携带 token/user，回退到 login 兜底", "Registered without token, fallback to login"),
    ("收到登录响应", "Login response received"), ("收到注册响应", "Register response received"),
    ("开始登录请求", "Start login request"), ("开始注册请求", "Start register request"),
    ("错误详情", "Error details"), ("执行搜索", "Run search"), ("搜索关键词", "Search keyword"),
    ("搜索成功", "Search succeeded"), ("点击标签", "Tag tapped"), ("点击文件", "File tapped"),
    ("更新标记状态成功", "Mark status updated"), ("切换收藏状态", "Toggle favorite"),
    ("收藏成功", "Favorite updated"), ("加载保存的认证数据", "Loaded saved auth data"),
    ("保存认证数据成功（安全存储）", "Auth data saved (secure storage)"),
    ("清除认证数据成功", "Auth data cleared"), ("认证数据已迁移到安全存储", "Auth data migrated to secure storage"),
    ("安全存储读取失败，回退检查 prefs 明文", "Secure storage read failed, fallback to prefs"),
    ("安全存储写入失败，降级写入 prefs", "Secure storage write failed, fallback to prefs"),
    ("迁移认证数据到安全存储失败，保留 prefs 明文（不登出用户）", "Auth migration failed, keep prefs plaintext"),
    ("降级写入 prefs 也失败", "Prefs fallback write also failed"),
    ("解析认证数据失败", "Failed to parse auth data"),
    ("API服务器已切换", "API server switched"), ("Auth API 服务器已切换", "Auth API server switched"),
    ("通知栏服务初始化成功", "Notification service initialized"),
    ("通知栏服务初始化失败", "Notification service init failed"),
    ("到点暂停失败", "Sleep timer pause failed"), ("切后台暂停失败", "Background pause failed"),
    ("配对字幕下载失败（不影响音频）", "Paired subtitle download failed (audio unaffected)"),
    ("未找到字幕文件，清除现有字幕", "Subtitle not found, clearing"),
    ("使用已下载本地字幕", "Using downloaded local subtitle"),
    ("字幕文件无可用 URL，清除现有字幕", "Subtitle URL unavailable, clearing"),
    ("无法查找字幕文件", "Cannot find subtitle file"),
    ("开始查找字幕文件", "Start finding subtitle file"),
    ("找到字幕文件", "Found subtitle file"),
    ("在当前目录中未找到字幕文件", "No subtitle in current directory"),
    ("从缓存加载字幕", "Load subtitle from cache"), ("从网络加载字幕", "Load subtitle from network"),
    ("使用字幕缓存", "Using subtitle cache"), ("字幕已缓存", "Subtitle cached"),
    ("字幕缓存已过期", "Subtitle cache expired"), ("字幕缓存已清空", "Subtitle cache cleared"),
    ("读取字幕缓存失败", "Read subtitle cache failed"), ("保存字幕缓存失败", "Save subtitle cache failed"),
    ("清理字幕缓存失败", "Clean subtitle cache failed"), ("获取字幕缓存大小失败", "Get subtitle cache size failed"),
    ("字幕加载失败", "Subtitle load failed"), ("字幕解析完成", "Subtitle parse complete"),
    ("字幕按时间轴解析失败，回退原文", "Timeline parse failed, fallback to raw"),
    ("字幕更新", "Subtitle update"), ("字幕状态已清除", "Subtitle state cleared"),
    ("没有找到匹配的字幕解析器", "No matching subtitle parser"),
    ("解析LRC时间标签失败", "LRC time tag parse failed"),
    ("LRC解析完成", "LRC parse complete"), ("字幕格式不支持", "Subtitle format unsupported"),
    ("字幕文件过大", "Subtitle file too large"), ("字幕内容解析失败", "Subtitle content parse failed"),
    ("字幕文件无有效内容", "Subtitle file has no valid content"), ("字幕解析异常", "Subtitle parse exception"),
    ("字幕导入成功", "Subtitle import succeeded"), ("字幕导入失败", "Subtitle import failed"),
    ("已移除导入字幕", "Removed imported subtitle"), ("用户字幕关联已保存", "User subtitle row saved"),
    ("用户字幕关联已删除", "User subtitle row deleted"), ("本地字幕文件不存在", "Local subtitle file missing"),
    ("加载本地字幕失败", "Load local subtitle failed"),
    ("移除字幕 DB 关联失败（一致性关键），保留本地文件以免产生指向缺失文件的失效行", "Remove subtitle DB row failed, keep file"),
    ("移除字幕本地文件失败（DB 关联已删，孤儿无害）", "Remove subtitle file failed (DB row deleted)"),
    ("删除旧的导入字幕文件", "Delete old imported subtitle file"),
    ("旧字幕文件清理失败（已成功导入新字幕，孤儿无害）", "Old subtitle cleanup failed (import ok)"),
    ("下载记录已保存", "Download row saved"), ("下载记录已删除", "Download row deleted"),
    ("下载完成", "Download complete"), ("下载失败", "Download failed"),
    ("下载已取消", "Download cancelled"), ("下载网络错误", "Download network error"),
    ("下载缺少 URL 或文件名", "Download missing URL or filename"),
    ("下载容量回收失败", "Download capacity reclaim failed"),
    ("查询待移除下载失败", "Query download to remove failed"),
    ("移除下载 DB 行失败（保留文件以免失效行）", "Remove download DB row failed, keep file"),
    ("移除下载文件失败（DB 行已删，孤儿无害）", "Remove download file failed (DB row deleted)"),
    ("下载记录指向缺失文件，清理失效行", "Stale download row cleaned"),
    ("清理失效下载行失败", "Clean stale download rows failed"),
    ("外部存储目录不可用，回退 App 内部目录", "External storage unavailable, fallback internal"),
    ("音频缓存已清空，共删除", "Audio cache cleared, deleted"), ("个文件", " files"),
    ("音频缓存部分清理: 成功", "Audio cache partial clean: ok"), ("失败", " failed"),
    ("无法删除缓存文件", "Cannot delete cache file"), ("可能正在使用中", "may be in use"),
    ("可能正在播放中", "may be playing"), ("部分缓存文件无法删除", "Some cache files could not be deleted"),
    ("缓存源创建异常", "Cache source creation error"),
    ("创建缓存音频源失败,降级为流式播放", "Cache audio source failed, streaming fallback"),
    ("创建音频源失败,跳过", "Create audio source failed, skip"),
    ("所有音频源创建失败,无法播放", "All audio sources failed"),
    ("命中缓存", "Cache hit"), ("添加缓存", "Cache add"), ("缓存已过期", "Cache expired"),
    ("移除作品缓存", "Remove work cache"), ("清除所有推荐缓存", "Clear all recommendation cache"),
    ("自动缓存清理完成", "Auto cache cleanup done"), ("自动缓存清理失败", "Auto cache cleanup failed"),
    ("开始统一缓存清理", "Start unified cache cleanup"), ("统一缓存清理完成", "Unified cache cleanup done"),
    ("清除所有缓存", "Clearing all cache"), ("所有缓存已清除", "All cache cleared"),
    ("图片缓存已清空", "Image cache cleared"), ("获取图片缓存大小失败", "Get image cache size failed"),
    ("清理图片缓存失败", "Clean image cache failed"), ("获取缓存大小失败", "Get cache size failed"),
    ("初始化数据库", "Init database"), ("数据库表创建完成", "Database tables created"),
    ("数据库升级", "Database upgrade"), ("应用数据库迁移", "Apply DB migration"),
    ("关闭数据库失败", "Close database failed"),
    ("播放状态已保存", "Playback state saved"), ("播放状态已清除", "Playback state cleared"),
    ("播放状态已加载", "Playback state loaded"), ("保存播放状态失败", "Save playback state failed"),
    ("清除播放状态失败", "Clear playback state failed"), ("加载播放状态失败", "Load playback state failed"),
    ("开始恢复播放状态", "Start restoring playback state"), ("播放状态恢复成功", "Playback state restored"),
    ("没有可恢复的播放状态", "No playback state to restore"), ("没有找到保存的播放状态", "No saved playback state"),
    ("已加载保存的状态", "Loaded saved state"), ("恢复的播放列表为空，跳过恢复", "Restored playlist empty, skip"),
    ("设置播放上下文失败，跳过状态恢复", "Set context failed, skip state restore"),
    ("无效的播放列表状态：播放列表为空", "Invalid playlist: empty"),
    ("无效的播放列表索引", "Invalid playlist index"), ("列表长度", "length"),
    ("当前文件不在播放列表中", "Current file not in playlist"),
    ("当前上下文为空，无法切换下一曲", "No context, cannot skip next"),
    ("当前上下文为空，无法切换上一曲", "No context, cannot skip previous"),
    ("没有下一曲可切换", "No next track"), ("没有上一曲可切换", "No previous track"),
    ("尝试切换下一曲", "Try skip next"), ("尝试切换上一曲", "Try skip previous"),
    ("执行切换到下一曲", "Switching to next track"), ("执行切换到上一曲", "Switching to previous track"),
    ("切换下一曲失败", "Skip next failed"), ("切换上一曲失败", "Skip previous failed"),
    ("设置播放源失败", "Set playback source failed"), ("设置播放上下文失败", "Set playback context failed"),
    ("设置播放上下文", "Set playback context"), ("播放上下文设置完成", "Playback context set"),
    ("播放上下文验证失败", "Playback context validation failed"),
    ("更新轨道信息", "Update track info"), ("更新轨道和上下文", "Update track and context"),
    ("停止当前播放", "Stop current playback"), ("加载播放状态", "Load playback state"),
    ("恢复播放状态", "Restore playback state"), ("开始获取播放列表", "Start building playlist"),
    ("找到", "Found"), ("个可播放文件", " playable files"),
    ("播放列表信息", "Playlist info"), ("长度", "length"), ("索引", "index"),
    ("播放列表状态", "Playlist state"), ("当前索引", "current index"),
    ("准备设置播放上下文", "Prepare playback context"), ("设置播放源", "Set playback source"),
    ("初始位置", "initial position"), ("原始索引", "Original index"), ("不可用,使用替代索引", "unavailable, use index"),
    ("当前文件", "Current file"), ("当前文件类型", "Current file type"), ("当前文件扩展名", "Current file extension"),
    ("开始查找文件路径", "Start resolving file path"), ("找到文件路径", "Found file path"),
    ("无法获取文件路径，返回空列表", "Cannot resolve file path, return empty"),
    ("未找到文件路径", "File path not found"), ("未找到父目录内容，返回空列表", "Parent dir empty, return empty"),
    ("父目录路径", "Parent dir path"), ("文件位于根目录，使用根目录文件列表", "File at root, use root file list"),
    ("开始获取同级文件", "Get sibling files"), ("找到同级文件数量", "Sibling file count"),
    ("AudioHandler", "AudioHandler"), ("播放命令", "play command"), ("暂停命令", "pause command"),
    ("停止命令", "stop command"), ("下一曲命令", "next command"), ("上一曲命令", "previous command"),
    ("跳转命令", "seek command"), ("AudioPlayerHandler 初始化", "AudioPlayerHandler init"),
    ("播放操作失败", "Playback operation failed"), ("状态操作失败", "State operation failed"),
    ("上下文操作失败", "Context operation failed"), ("播放列表操作失败", "Playlist operation failed"),
    ("初始化失败", "Init failed"), ("流错误", "stream error"),
    ("播放状态流错误", "player state stream error"), ("音轨变更流错误", "track change stream error"),
    ("播放进度流错误", "progress stream error"), ("字幕同步流错误", "subtitle sync stream error"),
    ("上下文流错误", "context stream error"), ("初始状态流错误", "initial state stream error"),
    ("错误事件流错误", "error event stream error"), ("清空状态流错误", "cleared state stream error"),
    ("播放完成流错误", "completed stream error"), ("字幕列表更新", "subtitle list update"),
    ("字幕流错误", "subtitle stream error"), ("当前字幕流错误", "current subtitle stream error"),
    ("播放错误事件", "playback error event"), ("检查更新失败", "Update check failed"),
    ("检查更新未知异常", "Update check unknown error"), ("打开下载地址失败", "Open download URL failed"),
    ("检查更新网络失败", "Update check network failed"), ("检查更新解析失败", "Update check parse failed"),
    ("检查更新", "Update check"), ("远端", "remote"), ("当前", "current"), ("有更新", "has update"),
    ("无合法发布（空列表或无 vX.Y.Z tag）", "No valid release (empty or no semver tag)"),
    ("releases 响应不是数组", "releases response is not an array"),
    ("获取默认标记目标收藏夹成功", "Default mark playlist fetched"),
    ("获取播放列表成功", "Playlists fetched"), ("个播放列表", " playlists"),
    ("个收藏夹", " playlists"), ("个标签", " tags"), ("个社团", " circles"),
    ("个声优", " voice actors"), ("个结果", " results"), ("个作品", " works"),
    ("标签列表加载成功", "Tags loaded"), ("社团列表加载成功", "Circles loaded"),
    ("声优列表加载成功", "Voice actors loaded"), ("收藏夹列表加载成功", "Work playlists loaded"),
    ("作品详情加载成功", "Work detail loaded"), ("开始加载作品文件", "Start loading work files"),
    ("文件加载成功", "Files loaded"), ("第", "Page "), ("页", " "), ("加载成功", " loaded"),
    ("加载", "Load "), ("失败", " failed"), ("刷新", "Refresh "), ("销毁", "Dispose "),
    ("ViewModel", "ViewModel"), ("使用预加载数据", "Using preloaded data"),
    ("预加载", "Preload "), ("完成", " done"), ("搜索返回数据", "Search response data"),
    ("网络请求重试", "Network retry"), ("AuthInterceptor: 处理请求失败", "AuthInterceptor: request failed"),
    ("AuthViewModel: 开始登录流程", "AuthViewModel: login start"),
    ("AuthViewModel: 开始注册流程", "AuthViewModel: register start"),
    ("AuthViewModel: 执行登出", "AuthViewModel: logout"),
    ("AuthViewModel: 登录失败", "AuthViewModel: login failed"),
    ("AuthViewModel: 注册失败", "AuthViewModel: register failed"),
    ("LoginDialog: 尝试登录", "LoginDialog: login attempt"),
    ("LoginDialog: 登录成功，关闭对话框", "LoginDialog: login ok, closing"),
    ("LoginDialog: 登录失败", "LoginDialog: login failed"),
    ("RegisterDialog: 尝试注册", "RegisterDialog: register attempt"),
    ("RegisterDialog: 注册成功，关闭对话框", "RegisterDialog: register ok, closing"),
    ("RegisterDialog: 注册失败", "RegisterDialog: register failed"),
    ("UpdateViewModel: 检查更新失败", "UpdateViewModel: update check failed"),
    ("UpdateViewModel: 检查更新未知异常", "UpdateViewModel: update check unknown"),
    ("UpdateViewModel: 打开下载地址失败", "UpdateViewModel: open download failed"),
    ("登录成功", "Login succeeded"), ("注册成功", "Register succeeded"),
    ("清理旧版缓存失败", "Legacy cache cleanup failed"), ("已清理旧版临时缓存目录", "Legacy temp cache cleaned"),
    ("[$_tag]", "[{_tag}]"), ("初始化", "init"), ("初始化失败", "init failed"),
    ("显示悬浮窗", "show overlay"), ("隐藏悬浮窗", "hide overlay"), ("更新歌词", "update lyric"),
    ("检查权限", "check permission"), ("请求权限", "request permission"),
    ("释放资源", "dispose"), ("释放失败", "dispose failed"), ("加载状态失败", "load state failed"),
    ("切换状态失败", "toggle state failed"),
]

TH_TERMS = [
    ("网络请求失败", "คำขอเครือข่ายล้มเหลว"), ("解析数据失败", "แปลงข้อมูลล้มเหลว"),
    ("加载失败", "โหลดล้มเหลว"), ("清理失败", "ล้างล้มเหลว"), ("播放失败", "เล่นล้มเหลว"),
    ("下载失败", "ดาวน์โหลดล้มเหลว"), ("搜索失败", "ค้นหาล้มเหลว"), ("登录失败", "เข้าสู่ระบบล้มเหลว"),
    ("注册失败", "สมัครล้มเหลว"), ("字幕", "คำบรรยาย"), ("缓存", "แคช"), ("播放列表", "เพลย์ลิสต์"),
    ("作品", "ผลงาน"), ("文件", "ไฟล์"), ("音频", "เสียง"), ("标签", "แท็ก"), ("社团", "เซอร์เคิล"),
    ("声优", "นักพากย์"), ("推荐", "แนะนำ"), ("收藏", "รายการโปรด"), ("热门列表", "ยอดนิยม"),
    ("主页", "หน้าแรก"), ("成功", "สำเร็จ"), ("失败", "ล้มเหลว"), ("开始", "เริ่ม"), ("完成", "เสร็จ"),
    ("销毁", "ทำลาย"), ("刷新", "รีเฟรช"), ("加载", "โหลด"), ("清理", "ล้าง"), ("获取", "ดึง"),
    ("列表", "รายการ"), ("详情", "รายละเอียด"), ("错误", "ข้อผิดพลาด"), ("状态", "สถานะ"),
    ("网络错误", "ข้อผิดพลาดเครือข่าย"), ("请求已取消", "ยกเลิกคำขอแล้ว"),
    ("不支持的字幕格式", "รูปแบบคำบรรยายไม่รองรับ"), ("展开", "ขยาย"), ("折叠", "ยุบ"),
    ("文件夹", "โฟลเดอร์"), ("已加载", "โหลดแล้ว"), ("未加载", "ยังไม่โหลด"),
    ("文件列表为空", "รายการไฟล์ว่าง"), ("移除", "นำออก"), ("添加", "เพิ่ม"),
    ("想听", "อยากฟัง"), ("在听", "กำลังฟัง"), ("听过", "ฟังแล้ว"), ("重听", "ฟังซ้ำ"), ("搁置", "พักไว้"),
]

def gloss(text: str, terms: list[tuple[str, str]]) -> str:
    out = text
    for zh, tr in sorted(terms, key=lambda x: -len(x[0])):
        out = out.replace(zh, tr)
    return re.sub(r"\s+", " ", out).strip()


def make_key(zh: str) -> str:
    base = re.sub(r"[^a-zA-Z0-9]+", "", gloss(zh, EN_TERMS)[:36].title())[:28] or "Msg"
    h = hashlib.md5(zh.encode()).hexdigest()[:5]
    return f"log{base}{h}"


def ensure_catalog(zh_raw: str) -> tuple[str, list[str]]:
    icu_zh, params = zh_template_to_icu(zh_raw)
    for cat_tpl, (key, en, th) in CATALOG.items():
        if zh_template_to_icu(cat_tpl)[0] == icu_zh:
            return key, params
    key = make_key(zh_raw)
    while any(v[0] == key for v in CATALOG.values()):
        key += "x"
    en_icu, _ = zh_template_to_icu(gloss(zh_raw, EN_TERMS))
    th_icu, _ = zh_template_to_icu(gloss(zh_raw, TH_TERMS))
    CATALOG[zh_raw] = (key, en_icu, th_icu)
    return key, params

SKIP_IF_CONTAINS = ("?", "\n", "//")

CONTEXT_RES = [
    re.compile(r"(AppLogger\.(?:debug|info|warning|error)\(\s*)'((?:[^'\\]|\\.)*)'"),
    re.compile(r"(debugPrint\(\s*)'((?:[^'\\]|\\.)*)'"),
    re.compile(r"(throw (?:const )?\w+Exception\()'((?:[^'\\]|\\.)*)'"),
    re.compile(r"(message: )'((?:[^'\\]|\\.)*)'"),
    re.compile(r"(androidNotificationChannelName: )'((?:[^'\\]|\\.)*)'"),
    re.compile(r"(pageName => )'((?:[^'\\]|\\.)*)'"),
]


def zh_template_to_icu(zh: str) -> tuple[str, list[str]]:
    params: list[str] = []
    used: set[str] = set()

    def pname(expr: str) -> str:
        base = re.sub(r"[^a-zA-Z0-9_]", "_", expr.split(".")[0].split("?")[0]) or "value"
        n, i = base, 2
        while n in used:
            n = f"{base}{i}"
            i += 1
        used.add(n)
        params.append(n)
        return n

    def br(m: re.Match) -> str:
        return "{" + pname(m.group(1)) + "}"

    def dol(m: re.Match) -> str:
        return "{" + pname(m.group(1)) + "}"

    s = re.sub(r"\$\{([^}]+)\}", br, zh)
    s = re.sub(r"\$([a-zA-Z_][a-zA-Z0-9_.]*)", dol, s)
    return s, params


def catalog_icu(zh_tpl: str) -> tuple[str, list[str]]:
    return ensure_catalog(zh_tpl)


def dart_expr(key: str, zh: str, params: list[str]) -> str:
    args = []
    for m in re.finditer(r"\$\{([^}]+)\}", zh):
        args.append(m.group(1))
    for m in re.finditer(r"\$([a-zA-Z_][a-zA-Z0-9_.]*)", zh):
        if m.group(0) not in [f"${a}" for a in args]:
            args.append(m.group(1))
    if not args:
        return f"LogStrings.{key}"
    if len(args) == len(params):
        return f"LogStrings.{key}({', '.join(args)})"
    return f"LogStrings.{key}({', '.join(args)})"


def build_log_strings_dart(entries: dict[str, dict]) -> str:
    lines = [
        "import 'dart:ui' show Locale;",
        "",
        "import 'package:flutter_gen/gen_l10n/app_localizations.dart';",
        "import 'package:xuro/core/di/service_locator.dart';",
        "import 'package:xuro/core/settings/app_settings_service.dart';",
        "",
        "/// Localized logs, diagnostics, and internal exception copy.",
        "class LogStrings {",
        "  LogStrings._();",
        "",
        "  static AppLocalizations get _l10n {",
        "    try {",
        "      return lookupAppLocalizations(getIt<AppSettingsService>().stringsLocale);",
        "    } catch (_) {",
        "      return lookupAppLocalizations(const Locale('zh'));",
        "    }",
        "  }",
        "",
    ]
    for key in sorted(entries):
        e = entries[key]
        if not e["params"]:
            lines.append(f"  static String get {key} => _l10n.{key};")
        else:
            sig = ", ".join(f"String {p}" for p in e["params"])
            call = ", ".join(e["params"])
            lines.append(f"  static String {key}({sig}) => _l10n.{key}({call});")
    lines.append("}")
    lines.append("")
    return "\n".join(lines)


def process_file(path: Path, entries: dict[str, dict]) -> bool:
    text = path.read_text(encoding="utf-8")
    orig = text

    def sub_literal(m: re.Match) -> str:
        prefix, content = m.group(1), m.group(2)
        if not re.search(r"[\u4e00-\u9fff]", content):
            return m.group(0)
        if any(x in content for x in SKIP_IF_CONTAINS):
            return m.group(0)
        key, params2 = ensure_catalog(content)
        return prefix + dart_expr(key, content, params2)

    for cre in CONTEXT_RES:
        text = cre.sub(sub_literal, text)

    if text != orig:
        if "LogStrings." in text and "log_strings.dart" not in text:
            imp = "import 'package:xuro/common/constants/log_strings.dart';\n"
            if imp not in text:
                m = re.search(r"(import [^;]+;\n)+", text)
                if m:
                    text = text[: m.end()] + imp + text[m.end() :]
        path.write_text(text, encoding="utf-8")
        return True
    return False


def apply_manual_fixes() -> None:
    fixes = [
        (
            LIB / "data/models/mark_status.dart",
            """enum MarkStatus {
  wantToListen('想听'),
  listening('在听'),
  listened('听过'),
  relistening('重听'),
  onHold('搁置');

  final String label;
  const MarkStatus(this.label);
}""",
            """enum MarkStatus {
  wantToListen,
  listening,
  listened,
  relistening,
  onHold;
}""",
        ),
        (
            LIB / "presentation/viewmodels/detail_viewmodel.dart",
            "final action = (playlist.exist ?? false) ? '移除' : '添加';",
            "final action = (playlist.exist ?? false) ? LogStrings.logActionRemove : LogStrings.logActionAdd;",
        ),
        (
            LIB / "presentation/viewmodels/detail_viewmodel.dart",
            "AppLogger.info('更新标记状态成功: ${status.label}');",
            "AppLogger.info(LogStrings.logMarkStatusUpdated(status.localizedLabel));",
        ),
        (
            LIB / "widgets/detail/work_folder_item.dart",
            """AppLogger.debug(
              '${expanded ? "展开" : "折叠"}文件夹: ${folder.title}',
            );""",
            """AppLogger.debug(
              LogStrings.logFolderToggled(
                expanded ? LogStrings.logExpand : LogStrings.logCollapse,
                folder.title ?? '',
              ),
            );""",
        ),
        (
            LIB / "presentation/viewmodels/player_viewmodel.dart",
            """debugPrint('$_tag - 字幕列表更新: ${subtitleList != null ? '已加载' : '未加载'}');""",
            """debugPrint('$_tag - ${LogStrings.logSubtitleListUpdated(subtitleList != null ? LogStrings.logLoaded : LogStrings.logNotLoaded)}');""",
        ),
        (
            LIB / "core/subtitle/subtitle_loader.dart",
            """AppLogger.debug('无法查找字幕文件: ${files.children == null ? '文件列表为空' : '当前文件名为空'}');""",
            """AppLogger.debug(LogStrings.logCannotFindSubtitleReason(files.children == null ? LogStrings.logFileListEmpty : LogStrings.logCurrentFileNameEmpty));""",
        ),
        (
            LIB / "core/subtitle/managers/subtitle_state_manager.dart",
            """AppLogger.debug('字幕更新: ${_currentSubtitle?.text ?? '无字幕'} (${newSubtitleWithState?.state})');""",
            """AppLogger.debug(LogStrings.logSubtitleStateUpdated(_currentSubtitle?.text ?? LogStrings.logNoSubtitle, newSubtitleWithState?.state.toString() ?? ''));""",
        ),
    ]
    extra_catalog = {
        "更新标记状态成功: {label}": ("logMarkStatusUpdated", "Mark status updated: {label}", "อัปเดตสถานะเครื่องหมาย: {label}"),
        "{action}文件夹: {title}": ("logFolderToggled", "{action} folder: {title}", "{action} โฟลเดอร์: {title}"),
        "字幕列表更新: {status}": ("logSubtitleListUpdated", "Subtitle list updated: {status}", "อัปเดตรายการคำบรรยาย: {status}"),
        "无法查找字幕文件: {reason}": ("logCannotFindSubtitleReason", "Cannot find subtitle file: {reason}", "ไม่พบไฟล์คำบรรยาย: {reason}"),
        "字幕更新: {text} ({state})": ("logSubtitleStateUpdated", "Subtitle update: {text} ({state})", "อัปเดตคำบรรยาย: {text} ({state})"),
        "无字幕": ("logNoSubtitle", "No subtitle", "ไม่มีคำบรรยาย"),
    }
    CATALOG.update(extra_catalog)
    for path, old, new in fixes:
        text = path.read_text(encoding="utf-8")
        if old in text:
            path.write_text(text.replace(old, new), encoding="utf-8")


def main() -> None:
    entries: dict[str, dict] = {}
    changed = 0
    for f in sorted(LIB.rglob("*.dart")):
        if f.name == "log_strings.dart":
            continue
        if process_file(f, entries):
            changed += 1

    apply_manual_fixes()

    # rebuild entries metadata from CATALOG for all keys
    final: dict[str, dict] = {}
    for tpl, (key, en, th) in CATALOG.items():
        zh_icu, params = zh_template_to_icu(tpl)
        final[key] = {"params": params, "zh_icu": zh_icu, "en_icu": en, "th_icu": th}

    (LIB / "common/constants/log_strings.dart").write_text(
        build_log_strings_dart(final), encoding="utf-8"
    )

    for name, field in [("app_zh.arb", "zh_icu"), ("app_en.arb", "en_icu"), ("app_th.arb", "th_icu")]:
        p = ROOT / "lib/l10n" / name
        arb = json.loads(p.read_text(encoding="utf-8"))
        for k in list(arb):
            if re.match(r"^log[A-Z]", k):
                del arb[k]
            if re.match(r"^@log[A-Z]", k):
                del arb[k]
        for key, meta in final.items():
            arb[key] = meta[field if field != "en_icu" else "en_icu"]
            # fix en/th - use catalog
            tpl_match = next((t for t, v in CATALOG.items() if v[0] == key), None)
            if tpl_match:
                _, en, th = CATALOG[tpl_match]
                if name == "app_zh.arb":
                    arb[key] = zh_template_to_icu(tpl_match)[0]
                elif name == "app_en.arb":
                    arb[key] = en
                else:
                    arb[key] = th
            if meta["params"]:
                arb[f"@{key}"] = {"placeholders": {p: {"type": "String"} for p in meta["params"]}}
        p.write_text(json.dumps(arb, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    print(f"files={changed} keys={len(final)}")


if __name__ == "__main__":
    main()
