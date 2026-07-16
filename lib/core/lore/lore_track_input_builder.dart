import 'package:lizunemu/core/lore/lore_json_utils.dart';
import 'package:lizunemu/core/lore/lore_state_projector.dart';
import 'package:lizunemu/core/lore/lore_subtitle_language_pipeline.dart';
import 'package:lizunemu/core/lore/lore_subtitle_resolver.dart';
import 'package:lizunemu/core/lore/models/lore_event.dart';
import 'package:lizunemu/core/lore/models/work_lore_pack.dart';
import 'package:lizunemu/core/lore/work_lore_service.dart';
import 'package:lizunemu/core/media/logical_track_dedupe.dart';
import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/data/models/files/files.dart';
import 'package:lizunemu/data/models/works/work.dart';

/// Shared prep for lore LLM: resolve → dedupe remasters → lore-language subs.
class LoreTrackInputBuilder {
  final LoreSubtitleResolver _resolver;
  final LoreSubtitleLanguagePipeline _languagePipeline;

  LoreTrackInputBuilder({
    required LoreSubtitleResolver resolver,
    required LoreSubtitleLanguagePipeline languagePipeline,
  })  : _resolver = resolver,
        _languagePipeline = languagePipeline;

  Future<List<LoreTrackInput>> build({
    required Work work,
    required String workId,
    required List<({Child audio, Child? subtitle})> pairs,
    Files? files,
    WorkLorePack? alignToPack,
    LoreProgressCallback? onProgress,
  }) async {
    final total = pairs.length;
    final resolved = <LogicalTrackCandidate>[];
    const batch = 6;
    for (var start = 0; start < pairs.length; start += batch) {
      final end = (start + batch).clamp(0, pairs.length);
      final slice = pairs.sublist(start, end);
      onProgress?.call(
        'subs:resolve:$end/$total',
        total == 0 ? 0.02 : 0.01 + 0.04 * (end / total),
      );
      final chunk = await Future.wait(
        List.generate(slice.length, (j) async {
          final i = start + j;
          final pair = slice[j];
          final text = await _resolver.resolveText(
            workId: workId,
            audio: pair.audio,
            matchedSubtitle: pair.subtitle,
            files: files,
          );
          return LogicalTrackCandidate(
            audio: pair.audio,
            matchedSubtitle: pair.subtitle,
            subtitleText: text,
            index: i,
          );
        }),
      );
      resolved.addAll(chunk);
    }

    final groups = LogicalTrackDedupe.group(resolved);
    final out = <LoreTrackInput>[];
    final gTotal = groups.length;
    for (var gi = 0; gi < groups.length; gi++) {
      final g = groups[gi];
      final c = g.canonical;
      onProgress?.call(
        'subs:translate:${gi + 1}/$gTotal',
        gTotal == 0 ? 0.05 : 0.05 + 0.03 * ((gi + 1) / gTotal),
      );
      final translated = await _languagePipeline.ensureForLore(
        raw: c.subtitleText,
        work: work,
        audio: c.audio,
        files: files,
      );
      out.add(
        LoreTrackInput(
          trackKey: LoreJsonUtils.trackKeyFor(
            index: gi,
            hash: c.audio.hash,
            mediaDownloadUrl: c.audio.mediaDownloadUrl,
            title: c.audio.title,
          ),
          title: c.title,
          index: gi,
          subtitleText: translated,
        ),
      );
    }
    if (alignToPack != null) {
      return alignTrackKeysToPack(out, alignToPack);
    }
    return out;
  }

  static List<LoreTrackInput> alignTrackKeysToPack(
    List<LoreTrackInput> inputs,
    WorkLorePack pack,
  ) {
    if (inputs.isEmpty || pack.trackSummaries.isEmpty) return inputs;
    final byNorm = <String, LoreTrackSummary>{};
    for (final s in pack.trackSummaries) {
      final n = LoreStateProjector.normalizeTrackTitle(s.trackTitle);
      if (n.isEmpty) continue;
      byNorm.putIfAbsent(n, () => s);
    }
    final out = <LoreTrackInput>[];
    for (final t in inputs) {
      final n = LoreStateProjector.normalizeTrackTitle(t.title);
      final hit = n.isEmpty ? null : byNorm[n];
      if (hit == null) {
        out.add(t);
        continue;
      }
      out.add(
        LoreTrackInput(
          trackKey: hit.trackKey,
          title: hit.trackTitle,
          index: hit.trackIndex,
          subtitleText: t.subtitleText,
        ),
      );
    }
    return out;
  }
}
