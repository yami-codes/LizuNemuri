import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:lizunemu/core/lore/lore_state_projector.dart';
import 'package:lizunemu/data/models/files/child.dart';

/// One audio leaf + optional subtitle pairing for lore/translate dedupe.
class LogicalTrackCandidate {
  final Child audio;
  final Child? matchedSubtitle;
  final String? subtitleText;
  final int index;

  const LogicalTrackCandidate({
    required this.audio,
    required this.index,
    this.matchedSubtitle,
    this.subtitleText,
  });

  String get title => audio.title ?? 'Track ${index + 1}';

  String get normalizedTitle =>
      LoreStateProjector.normalizeTrackTitle(title);

  String? get subtitleContentHash =>
      LogicalTrackDedupe.contentHash(subtitleText);
}

/// Deduped episode: one canonical audio + remaster aliases.
class LogicalTrackGroup {
  final String groupKey;
  final LogicalTrackCandidate canonical;
  final List<LogicalTrackCandidate> aliases;

  const LogicalTrackGroup({
    required this.groupKey,
    required this.canonical,
    this.aliases = const [],
  });

  List<LogicalTrackCandidate> get all => [canonical, ...aliases];
}

/// Collapse remasters (no-SFX / mp3 vs wav / same script) before LLM work.
class LogicalTrackDedupe {
  static const int minScriptCharsForContentMerge = 80;

  static String? contentHash(String? text) {
    final t = text?.trim();
    if (t == null || t.isEmpty) return null;
    return md5.convert(utf8.encode(t)).toString();
  }

  static bool looksLikeNoSfx(String title) {
    final t = title.toLowerCase();
    return RegExp(r'[（(]\s*无效果音\s*[）)]').hasMatch(title) ||
        RegExp(r'[（(]\s*no[\s\-]?sfx\s*[）)]', caseSensitive: false)
            .hasMatch(t);
  }

  /// Lower is better for canonical pick.
  static int formatRank(String title) {
    final lower = title.toLowerCase();
    if (lower.endsWith('.mp3') || lower.endsWith('.m4a')) return 0;
    if (lower.endsWith('.flac')) return 1;
    if (lower.endsWith('.ogg') || lower.endsWith('.aac')) return 2;
    if (lower.endsWith('.wav')) return 3;
    return 4;
  }

  static int compareCanonical(
    LogicalTrackCandidate a,
    LogicalTrackCandidate b,
  ) {
    final aHas = a.subtitleText != null && a.subtitleText!.trim().isNotEmpty;
    final bHas = b.subtitleText != null && b.subtitleText!.trim().isNotEmpty;
    if (aHas != bHas) return aHas ? -1 : 1;

    final aNo = looksLikeNoSfx(a.title);
    final bNo = looksLikeNoSfx(b.title);
    if (aNo != bNo) return aNo ? 1 : -1;

    final fmt = formatRank(a.title).compareTo(formatRank(b.title));
    if (fmt != 0) return fmt;

    return a.index.compareTo(b.index);
  }

  /// Group by normalized title, then merge groups that share the same
  /// long subtitle script (cross-folder remasters).
  static List<LogicalTrackGroup> group(List<LogicalTrackCandidate> items) {
    if (items.isEmpty) return const [];

    final byNorm = <String, List<LogicalTrackCandidate>>{};
    for (final item in items) {
      final key = item.normalizedTitle.isEmpty
          ? 'raw:${item.index}:${item.title}'
          : item.normalizedTitle;
      byNorm.putIfAbsent(key, () => []).add(item);
    }

    var groups = byNorm.entries.map((e) {
      final list = [...e.value]..sort(compareCanonical);
      return LogicalTrackGroup(
        groupKey: e.key,
        canonical: list.first,
        aliases: list.skip(1).toList(),
      );
    }).toList();

    // Secondary: merge groups with identical long subtitle payloads.
    final byHash = <String, List<LogicalTrackGroup>>{};
    final leftover = <LogicalTrackGroup>[];
    for (final g in groups) {
      final hash = g.canonical.subtitleContentHash;
      final len = g.canonical.subtitleText?.trim().length ?? 0;
      if (hash != null && len >= minScriptCharsForContentMerge) {
        byHash.putIfAbsent(hash, () => []).add(g);
      } else {
        leftover.add(g);
      }
    }

    final merged = <LogicalTrackGroup>[];
    for (final entry in byHash.entries) {
      final list = entry.value;
      if (list.length == 1) {
        merged.add(list.first);
        continue;
      }
      final candidates = <LogicalTrackCandidate>[
        for (final g in list) ...g.all,
      ]..sort(compareCanonical);
      merged.add(
        LogicalTrackGroup(
          groupKey: 'script:${entry.key}',
          canonical: candidates.first,
          aliases: candidates.skip(1).toList(),
        ),
      );
    }

    final out = [...merged, ...leftover];
    out.sort((a, b) => a.canonical.index.compareTo(b.canonical.index));
    return out;
  }
}
