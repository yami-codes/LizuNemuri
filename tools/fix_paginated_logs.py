#!/usr/bin/env python3
"""Fix paginated log call sites and a few broken ARB placeholder entries."""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

CLEAN = {
    "logUsingPreloadedData": (
        "使用预加载数据: 第{page}页 {pageName}",
        "Using preloaded data: page {page} {pageName}",
        "ใช้ข้อมูลโหลดล่วงหน้า: หน้า {page} {pageName}",
        ["page", "pageName"],
    ),
    "logLoadingPageName": (
        "加载{pageName}: 第{page}页",
        "Loading {pageName}: page {page}",
        "โหลด {pageName}: หน้า {page}",
        ["pageName", "page"],
    ),
    "logPageWorksLoaded": (
        "第{page}页{pageName}加载成功: {count}个作品",
        "Page {page} {pageName} loaded: {count} works",
        "โหลดหน้า {page} {pageName} สำเร็จ: {count} ผลงาน",
        ["page", "pageName", "count"],
    ),
    "logPageLoadFailed": (
        "加载{pageName}失败",
        "Failed to load {pageName}",
        "โหลด {pageName} ล้มเหลว",
        ["pageName"],
    ),
    "logPreloadDone": (
        "预加载{pageName}第{nextPage}页完成",
        "Preload {pageName} page {nextPage} done",
        "โหลดล่วงหน้า {pageName} หน้า {nextPage} เสร็จ",
        ["pageName", "nextPage"],
    ),
    "logPreloadFailed": (
        "预加载{pageName}第{nextPage}页失败: {error}",
        "Preload {pageName} page {nextPage} failed: {error}",
        "โหลดล่วงหน้า {pageName} หน้า {nextPage} ล้มเหลว: {error}",
        ["pageName", "nextPage", "error"],
    ),
    "logPageListLoaded": (
        "第{page}页{listName}加载成功: {count}个作品",
        "Page {page} {listName} loaded: {count} works",
        "โหลดหน้า {page} {listName} สำเร็จ: {count} ผลงาน",
        ["page", "listName", "count"],
    ),
    "logPageNamePlaylistWorks": (
        "播放列表作品",
        "playlist works",
        "ผลงานในเพลย์ลิสต์",
        [],
    ),
    "logMarkStatusUpdated": (
        "更新标记状态成功: {label}",
        "Mark status updated: {label}",
        "อัปเดตสถานะเครื่องหมายสำเร็จ: {label}",
        ["label"],
    ),
}

REMOVE_PREFIXES = (
    "logUsingPreloadedDataPagePagePa",
    "logLoadingPagenamePagePage",
    "logPagePagePagenameLoadedRespon",
    "logLoadingPagenamefailed",
    "logPreloadPagenamepageNextpage",
    "logPagePagefavoritesListLoadedR",
    "logPagePageplaylistworkLoadedRe",
    "logMarkStatusUpdatedStatusLabel",
    "logStartRegisterRequestNameName",
    "logActionfavoriteUpdatedPlaylis",
)

PATCHES = {
    "lib/presentation/viewmodels/base/paginated_works_viewmodel.dart": [
        ("LogStrings.logUsingPreloadedDataPagePagePa97478(page, pageName)", "LogStrings.logUsingPreloadedData(page.toString(), pageName)"),
        ("LogStrings.logLoadingPagenamePagePagecaf65(pageName, page)", "LogStrings.logLoadingPageName(pageName, page.toString())"),
        ("LogStrings.logPagePagePagenameLoadedRespon60b03(response.works.length, page, pageName)", "LogStrings.logPageWorksLoaded(page.toString(), pageName, response.works.length.toString())"),
        ("LogStrings.logLoadingPagenamefailed2cfc9(pageName)", "LogStrings.logPageLoadFailed(pageName)"),
        ("LogStrings.logPreloadPagenamepageNextpaged818c3(pageName, nextPage)", "LogStrings.logPreloadDone(pageName, nextPage.toString())"),
        ("LogStrings.logPreloadPagenamepageNextpagef6035e(pageName, nextPage, e)", "LogStrings.logPreloadFailed(pageName, nextPage.toString(), e.toString())"),
    ],
    "lib/presentation/viewmodels/favorites_viewmodel.dart": [
        ("LogStrings.logPagePagefavoritesListLoadedR61ad0(page, response.works.length)", "LogStrings.logPageListLoaded(page.toString(), pageName, response.works.length.toString())"),
    ],
    "lib/presentation/viewmodels/recommend_viewmodel.dart": [
        ("LogStrings.logPagePagefavoritesListLoadedR61ad0(page, response.works.length)", "LogStrings.logPageListLoaded(page.toString(), pageName, response.works.length.toString())"),
    ],
    "lib/presentation/viewmodels/similar_works_viewmodel.dart": [
        ("LogStrings.logPagePagefavoritesListLoadedR61ad0(page, response.works.length)", "LogStrings.logPageListLoaded(page.toString(), pageName, response.works.length.toString())"),
    ],
    "lib/presentation/viewmodels/playlist_works_viewmodel.dart": [
        ("LogStrings.logPagePageplaylistworkLoadedRe62070(page, response.works.length)", "LogStrings.logPageListLoaded(page.toString(), LogStrings.logPageNamePlaylistWorks, response.works.length.toString())"),
    ],
    "lib/presentation/viewmodels/playlists_viewmodel.dart": [
        ("LogStrings.logPagePageplaylistworkLoadedRe62070(page, response.works.length)", "LogStrings.logPageListLoaded(page.toString(), LogStrings.logPageNamePlaylistWorks, response.works.length.toString())"),
    ],
}


def main() -> None:
    for rel, reps in PATCHES.items():
        p = ROOT / rel
        text = p.read_text(encoding="utf-8")
        for old, new in reps:
            text = text.replace(old, new)
        p.write_text(text, encoding="utf-8")

    for name in ["app_zh.arb", "app_en.arb", "app_th.arb"]:
        p = ROOT / "lib/l10n" / name
        arb = json.loads(p.read_text(encoding="utf-8"))
        field = {"app_zh.arb": 0, "app_en.arb": 1, "app_th.arb": 2}[name]
        for k in list(arb):
            if any(k.startswith(pref) for pref in REMOVE_PREFIXES):
                arb.pop(k, None)
            if any(k.startswith("@" + pref) for pref in REMOVE_PREFIXES):
                arb.pop(k, None)
        for key, vals in CLEAN.items():
            zh, en, th, params = vals
            arb[key] = [zh, en, th][field]
            if params:
                arb[f"@{key}"] = {"placeholders": {p: {"type": "String"} for p in params}}
        p.write_text(json.dumps(arb, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    log_dart = (ROOT / "lib/common/constants/log_strings.dart").read_text(encoding="utf-8")
    for key, vals in CLEAN.items():
        _, _, _, params = vals
        if key in log_dart:
            continue
        if params:
            sig = ", ".join(f"dynamic {p}" for p in params)
            call = ", ".join(f"{p}.toString()" for p in params)
            method = f"  static String {key}({sig}) => _l10n.{key}({call});\n"
        else:
            method = f"  static String get {key} => _l10n.{key};\n"
        log_dart = log_dart.replace("\n}", "\n" + method + "}")
    (ROOT / "lib/common/constants/log_strings.dart").write_text(log_dart, encoding="utf-8")
    print("paginated log fixes applied")


if __name__ == "__main__":
    main()
