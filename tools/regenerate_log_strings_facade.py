#!/usr/bin/env python3
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
L10N = ROOT / ".dart_tool/flutter_gen/gen_l10n/app_localizations.dart"
OUT = ROOT / "lib/common/constants/log_strings.dart"

EXTRA = {
    "logFavoriteUpdated": {
        "zh": "{action} 收藏成功: {name}",
        "en": "{action} favorite updated: {name}",
        "th": "{action} อัปเดตรายการโปรด: {name}",
        "params": ["action", "name"],
    },
}

REMOVE_KEYS = {"logActionfavoriteUpdatedPlaylis0b2d0", "@logActionfavoriteUpdatedPlaylis0b2d0"}


def main() -> None:
    text = L10N.read_text(encoding="utf-8")
    getters = re.findall(r"  String get (log\w+);", text)
    methods = re.findall(r"  String (log\w+)\(([^)]*)\);", text)

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
    for name in sorted(getters):
        if name in REMOVE_KEYS:
            continue
        lines.append(f"  static String get {name} => _l10n.{name};")
    for name, params in sorted(methods, key=lambda x: x[0]):
        if name in REMOVE_KEYS:
            continue
        if not params.strip():
            lines.append(f"  static String get {name} => _l10n.{name};")
            continue
        parts = [p.strip() for p in params.split(",")]
        dart_params = []
        call_args = []
        for p in parts:
            typ, pname = p.split()
            dart_params.append(f"dynamic {pname}")
            call_args.append(f"{pname}.toString()")
        sig = ", ".join(dart_params)
        call = ", ".join(call_args)
        lines.append(f"  static String {name}({sig}) => _l10n.{name}({call});")
    existing = set(getters) | {m[0] for m in methods}
    for key, meta in EXTRA.items():
        if key in existing:
            continue
        sig = ", ".join(f"dynamic {p}" for p in meta["params"])
        call = ", ".join(f"{p}.toString()" for p in meta["params"])
        lines.append(f"  static String {key}({sig}) => _l10n.{key}({call});")
    lines.append("}")
    lines.append("")
    OUT.write_text("\n".join(lines), encoding="utf-8")

    for name in ["app_zh.arb", "app_en.arb", "app_th.arb"]:
        p = ROOT / "lib/l10n" / name
        arb = json.loads(p.read_text(encoding="utf-8"))
        for k in list(REMOVE_KEYS):
            arb.pop(k, None)
        field = {"app_zh.arb": "zh", "app_en.arb": "en", "app_th.arb": "th"}[name]
        for key, meta in EXTRA.items():
            arb[key] = meta[field]
            arb[f"@{key}"] = {
                "placeholders": {p: {"type": "String"} for p in meta["params"]}
            }
        p.write_text(json.dumps(arb, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"getters={len(getters)} methods={len(methods)}")


if __name__ == "__main__":
    main()
