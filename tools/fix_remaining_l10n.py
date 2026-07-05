#!/usr/bin/env python3
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / "lib"

replacements = [
    ("throw Exception('解析数据失败: $e')", "throw Exception(LogStrings.logParseFailedDetail(e.toString()))"),
    ("throw Exception('登录失败: $e')", "throw Exception(LogStrings.logLoginFailedDetail(e.toString()))"),
    ("throw Exception('注册失败: $e')", "throw Exception(LogStrings.logRegisterFailedDetail(e.toString()))"),
    ("throw Exception('添加到收藏夹失败: $e')", "throw Exception(LogStrings.logAddToPlaylistFailedDetail(e.toString()))"),
    ("throw Exception('从收藏夹移除失败: $e')", "throw Exception(LogStrings.logRemoveFromPlaylistFailedDetail(e.toString()))"),
    ("throw Exception('登录失败: ${response.statusCode}')", "throw Exception(LogStrings.logLoginFailedCode(response.statusCode.toString()))"),
    ("throw Exception('注册失败: ${response.statusCode}')", "throw Exception(LogStrings.logRegisterFailedCode(response.statusCode.toString()))"),
    ("throw Exception('搜索失败: ${response.statusCode}')", "throw Exception(LogStrings.logSearchFailedCode(response.statusCode.toString()))"),
    ("throw Exception('标记失败: ${response.statusCode}')", "throw Exception(LogStrings.logMarkFailedCode(response.statusCode.toString()))"),
    ("throw Exception('获取文件列表失败: ${response.statusCode}')", "throw Exception(LogStrings.logFetchFileListFailed(response.statusCode.toString()))"),
    ("throw Exception('获取作品列表失败: ${response.statusCode}')", "throw Exception(LogStrings.logFetchWorksFailed(response.statusCode.toString()))"),
    ("throw Exception('获取收藏列表失败: ${response.statusCode}')", "throw Exception(LogStrings.logFetchFavoritesFailed(response.statusCode.toString()))"),
    ("throw Exception('获取推荐列表失败: ${response.statusCode}')", "throw Exception(LogStrings.logFetchRecommendFailed(response.statusCode.toString()))"),
    ("throw Exception('获取热门列表失败: ${response.statusCode}')", "throw Exception(LogStrings.logFetchPopularFailed(response.statusCode.toString()))"),
    ("throw Exception('获取相关推荐失败: ${response.statusCode}')", "throw Exception(LogStrings.logFetchSimilarFailed(response.statusCode.toString()))"),
    ("throw Exception('获取收藏夹列表失败: ${response.statusCode}')", "throw Exception(LogStrings.logFetchPlaylistsFailed(response.statusCode.toString()))"),
    ("throw Exception('获取默认标记目标收藏夹失败: ${response.statusCode}')", "throw Exception(LogStrings.logFetchDefaultMarkPlaylistFailed(response.statusCode.toString()))"),
    ("throw Exception('获取播放列表失败: ${response.statusCode}')", "throw Exception(LogStrings.logFetchMyPlaylistsFailed(response.statusCode.toString()))"),
    ("throw Exception('获取标签列表失败: ${response.statusCode}')", "throw Exception(LogStrings.logFetchTagsFailed(response.statusCode.toString()))"),
    ("throw Exception('获取社团列表失败: ${response.statusCode}')", "throw Exception(LogStrings.logFetchCirclesFailed(response.statusCode.toString()))"),
    ("throw Exception('获取声优列表失败: ${response.statusCode}')", "throw Exception(LogStrings.logFetchVoiceActorsFailed(response.statusCode.toString()))"),
    ("throw Exception('获取作品详情失败: ${response.statusCode}')", "throw Exception(LogStrings.logFetchWorkDetailFailed(response.statusCode.toString()))"),
    ("throw Exception('获取播放列表作品失败: ${response.statusCode}')", "throw Exception(LogStrings.logFetchPlaylistWorksFailed(response.statusCode.toString()))"),
    ("throw Exception('字幕下载失败: ${response.statusCode}')", "throw Exception(LogStrings.logSubtitleDownloadFailedCode(response.statusCode.toString()))"),
    ("throw Exception('字幕地址为空')", "throw Exception(LogStrings.logSubtitleUrlEmpty)"),
    ("throw Exception('不支持的字幕格式')", "throw Exception(LogStrings.logUnsupportedSubtitleFormat)"),
    ("throw Exception('无可用的音频源')", "throw Exception(LogStrings.logNoAudioSources)"),
    ("throw Exception('部分缓存文件无法删除（$failed 个），可能正在播放中')", "throw Exception(LogStrings.logPartialCacheDeleteFailed(failed.toString()))"),
    ("AppLogger.error('错误详情: ${e.response?.data}')", "AppLogger.error(LogStrings.logErrorDetails(e.response?.data.toString() ?? ''))"),
    ("'切换下一曲'", "LogStrings.logOpSkipNext"),
    ("'切换上一曲'", "LogStrings.logOpSkipPrevious"),
    ("'设置播放上下文'", "LogStrings.logOpSetContext"),
    ("'音频播放器初始化'", "LogStrings.logOpAudioPlayerInit"),
    ("'恢复播放状态'", "LogStrings.logOpRestorePlaybackState"),
    ("'保存播放状态'", "LogStrings.logOpSavePlaybackState"),
    ("'清除播放状态'", "LogStrings.logOpClearPlaybackState"),
    ("'加载播放状态'", "LogStrings.logOpLoadPlaybackState"),
    ("'无效的播放列表状态：播放列表为空'", "LogStrings.logPlaylistEmpty"),
    ("'当前文件不在播放列表中'", "LogStrings.logCurrentFileNotInPlaylist"),
    ("return '播放操作失败: $operation'", "return LogStrings.logPlaybackOperationFailed(operation)"),
    ("return '播放列表操作失败: $operation'", "return LogStrings.logPlaylistOperationFailed(operation)"),
    ("return '状态操作失败: $operation'", "return LogStrings.logStateOperationFailed(operation)"),
    ("return '上下文操作失败: $operation'", "return LogStrings.logContextOperationFailed(operation)"),
    ("return '初始化失败: $operation'", "return LogStrings.logInitOperationFailed(operation)"),
]

extra_keys = {
    "logErrorDetails": ("错误详情: {detail}", "Error details: {detail}", "รายละเอียดข้อผิดพลาด: {detail}"),
    "logPartialCacheDeleteFailed": ("部分缓存文件无法删除（{count} 个），可能正在播放中", "Some cache files could not be deleted ({count}), may be playing", "ลบแคชบางไฟล์ไม่ได้ ({count}) อาจกำลังเล่น"),
    "logOpSkipNext": ("切换下一曲", "skip next", "ข้ามเพลงถัดไป"),
    "logOpSkipPrevious": ("切换上一曲", "skip previous", "ข้ามเพลงก่อนหน้า"),
    "logOpSetContext": ("设置播放上下文", "set playback context", "ตั้งค่าบริบทการเล่น"),
    "logOpAudioPlayerInit": ("音频播放器初始化", "audio player init", "เริ่มต้นเครื่องเล่นเสียง"),
    "logOpRestorePlaybackState": ("恢复播放状态", "restore playback state", "กู้คืนสถานะการเล่น"),
    "logOpSavePlaybackState": ("保存播放状态", "save playback state", "บันทึกสถานะการเล่น"),
    "logOpClearPlaybackState": ("清除播放状态", "clear playback state", "ล้างสถานะการเล่น"),
    "logOpLoadPlaybackState": ("加载播放状态", "load playback state", "โหลดสถานะการเล่น"),
    "logPlaybackOperationFailed": ("播放操作失败: {operation}", "Playback operation failed: {operation}", "การเล่นล้มเหลว: {operation}"),
    "logPlaylistOperationFailed": ("播放列表操作失败: {operation}", "Playlist operation failed: {operation}", "เพลย์ลิสต์ล้มเหลว: {operation}"),
    "logStateOperationFailed": ("状态操作失败: {operation}", "State operation failed: {operation}", "สถานะล้มเหลว: {operation}"),
    "logContextOperationFailed": ("上下文操作失败: {operation}", "Context operation failed: {operation}", "บริบทล้มเหลว: {operation}"),
    "logInitOperationFailed": ("初始化失败: {operation}", "Init failed: {operation}", "เริ่มต้นล้มเหลว: {operation}"),
    "logLoginSucceeded": ("登录成功: username={username}, group={group}", "Login succeeded: username={username}, group={group}", "เข้าสู่ระบบสำเร็จ: username={username}, group={group}"),
    "logRegisterSucceeded": ("注册成功: name={name}, group={group}", "Register succeeded: name={name}, group={group}", "สมัครสำเร็จ: name={name}, group={group}"),
    "logLoadedSavedAuth": ("加载保存的认证数据: {name}", "Loaded saved auth data: {name}", "โหลดข้อมูลยืนยันตัวตนที่บันทึก: {name}"),
    "logPlaylistsPageLoaded": ("第{page}页播放列表加载成功: {count}个播放列表", "Page {page} playlists loaded: {count}", "โหลดเพลย์ลิสต์หน้า {page}: {count}"),
    "logWorkPlaylistsLoaded": ("收藏夹列表加载成功: {count}个收藏夹", "Work playlists loaded: {count}", "โหลดเพลย์ลิสต์ผลงาน: {count}"),
    "logMyPlaylistsFetched": ("获取播放列表成功: {count}个播放列表", "Playlists fetched: {count}", "ดึงเพลย์ลิสต์สำเร็จ: {count}"),
    "logPlaylistIndexInvalid": ("无效的播放列表索引：{index}，列表长度：{length}", "Invalid playlist index: {index}, length: {length}", "ดัชนีเพลย์ลิสต์ไม่ถูกต้อง: {index}, ความยาว: {length}"),
    "logSubtitleContentPreview": ("字幕文件内容预览: {preview}...", "Subtitle content preview: {preview}...", "ตัวอย่างเนื้อหาคำบรรยาย: {preview}..."),
    "logLyricOverlayUpdate": ("[{tag}] 更新歌词: {text}", "[{tag}] update lyric: {text}", "[{tag}] อัปเดตเนื้อเพลง: {text}"),
    "logStartRegisterRequest": ("开始注册请求: name={name}, hasRecommender={hasRecommender}, baseUrl={baseUrl}", "Start register request: name={name}, hasRecommender={hasRecommender}, baseUrl={baseUrl}", "เริ่มคำขอสมัคร: name={name}, hasRecommender={hasRecommender}, baseUrl={baseUrl}"),
}


def ensure_import(text: str) -> str:
    imp = "import 'package:xuro/common/constants/log_strings.dart';\n"
    if "LogStrings." in text and imp not in text:
        m = re.search(r"(import [^;]+;\n)+", text)
        if m:
            text = text[: m.end()] + imp + text[m.end() :]
    return text


def main() -> None:
    for name in ["app_zh.arb", "app_en.arb", "app_th.arb"]:
        p = ROOT / "lib/l10n" / name
        arb = json.loads(p.read_text(encoding="utf-8"))
        arb.pop("logStartRegisterRequestNameNamef7461", None)
        arb.pop("@logStartRegisterRequestNameNamef7461", None)
        p.write_text(json.dumps(arb, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    for f in LIB.rglob("*.dart"):
        if f.name == "log_strings.dart":
            continue
        text = f.read_text(encoding="utf-8")
        orig = text
        for old, new in replacements:
            text = text.replace(old, new)
        if text != orig:
            f.write_text(ensure_import(text), encoding="utf-8")

    auth = (LIB / "data/services/auth_service.dart").read_text(encoding="utf-8")
    auth = auth.replace(
        "AppLogger.info(\n          '登录成功: username=${authResp.user?.name}, group=${authResp.user?.group}',\n        );",
        "AppLogger.info(LogStrings.logLoginSucceeded(authResp.user?.name ?? '', authResp.user?.group ?? ''));",
    )
    auth = re.sub(
        r"AppLogger\.info\(\s*'开始注册请求: name=\$name, hasRecommender=\$\{body\.containsKey\('recommenderUuid'\)\}, baseUrl=\$\{_dio\.options\.baseUrl\}',\s*\);",
        "AppLogger.info(LogStrings.logStartRegisterRequest(name, body.containsKey('recommenderUuid').toString(), _dio.options.baseUrl));",
        auth,
    )
    (LIB / "data/services/auth_service.dart").write_text(ensure_import(auth), encoding="utf-8")

    patches = {
        "lib/presentation/viewmodels/auth_viewmodel.dart": [
            ("AppLogger.info('加载保存的认证数据: ${_authData?.user?.name}');", "AppLogger.info(LogStrings.logLoadedSavedAuth(_authData?.user?.name ?? ''));"),
            ("'注册成功: name=${_authData?.user?.name}, group=${_authData?.user?.group}',", "LogStrings.logRegisterSucceeded(_authData?.user?.name ?? '', _authData?.user?.group ?? ''),"),
        ],
        "lib/presentation/viewmodels/detail_viewmodel.dart": [
            ("AppLogger.info('收藏夹列表加载成功: ${_playlists?.length ?? 0}个收藏夹');", "AppLogger.info(LogStrings.logWorkPlaylistsLoaded((_playlists?.length ?? 0).toString()));"),
        ],
        "lib/presentation/viewmodels/playlists_viewmodel.dart": [
            ("AppLogger.info('第$page页播放列表加载成功: ${_playlists?.length ?? 0}个播放列表');", "AppLogger.info(LogStrings.logPlaylistsPageLoaded(page.toString(), (_playlists?.length ?? 0).toString()));"),
        ],
        "lib/data/services/api_service.dart": [
            ("AppLogger.info('获取播放列表成功: ${myPlaylists.playlists?.length ?? 0}个播放列表');", "AppLogger.info(LogStrings.logMyPlaylistsFetched((myPlaylists.playlists?.length ?? 0).toString()));"),
        ],
        "lib/core/audio/models/playback_context.dart": [
            ("'无效的播放列表索引：$currentIndex，列表长度：${playlist.length}',", "LogStrings.logPlaylistIndexInvalid(currentIndex.toString(), playlist.length.toString()),"),
        ],
        "lib/core/subtitle/subtitle_loader.dart": [
            ("AppLogger.debug('字幕文件内容预览: ${content.substring(0, content.length > 100 ? 100 : content.length)}...');", "AppLogger.debug(LogStrings.logSubtitleContentPreview(content.substring(0, content.length > 100 ? 100 : content.length)));"),
        ],
        "lib/core/platform/lyric_overlay_controller.dart": [
            ("AppLogger.debug('[$_tag] 更新歌词: ${text ?? '<空>'}');", "AppLogger.debug(LogStrings.logLyricOverlayUpdate(_tag, text ?? ''));"),
        ],
        "lib/core/audio/controllers/playback_controller.dart": [
            ("AppLogger.debug('设置播放源: 初始位置=${initialPosition?.inMilliseconds}ms');", "AppLogger.debug(LogStrings.logSetPlaybackSourceInitial(initialPosition?.inMilliseconds.toString() ?? '0'));"),
        ],
    }
    extra_keys["logSetPlaybackSourceInitial"] = (
        "设置播放源: 初始位置={ms}ms",
        "Set playback source: initial position={ms}ms",
        "ตั้งแหล่งเล่น: ตำแหน่งเริ่ม={ms}ms",
    )

    for rel, reps in patches.items():
        p = ROOT / rel
        text = p.read_text(encoding="utf-8")
        for old, new in reps:
            text = text.replace(old, new)
        p.write_text(ensure_import(text), encoding="utf-8")

    log_dart = (LIB / "common/constants/log_strings.dart").read_text(encoding="utf-8")
    arb_files = {
        n: json.loads((ROOT / "lib/l10n" / n).read_text(encoding="utf-8"))
        for n in ["app_zh.arb", "app_en.arb", "app_th.arb"]
    }
    for key, (zh, en, th) in extra_keys.items():
        params = re.findall(r"\{(\w+)\}", zh)
        if params:
            sig = ", ".join(f"String {p}" for p in params)
            call = ", ".join(params)
            method = f"  static String {key}({sig}) => _l10n.{key}({call});\n"
        else:
            method = f"  static String get {key} => _l10n.{key};\n"
        if key not in log_dart:
            log_dart = log_dart.replace("\n}", "\n" + method + "}")
        arb_files["app_zh.arb"][key] = zh
        arb_files["app_en.arb"][key] = en
        arb_files["app_th.arb"][key] = th
        if params:
            meta = {"placeholders": {p: {"type": "String"} for p in params}}
            for n in arb_files:
                arb_files[n][f"@{key}"] = meta
    (LIB / "common/constants/log_strings.dart").write_text(log_dart, encoding="utf-8")
    for n, data in arb_files.items():
        (ROOT / "lib/l10n" / n).write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("fix_remaining done")


if __name__ == "__main__":
    main()
