import 'package:xuro/core/audio/models/playback_context.dart';
import 'package:xuro/core/audio/models/play_mode.dart';
import 'package:xuro/data/models/works/work.dart';
import 'package:xuro/utils/i18n_name_resolver.dart';

/// Builds rich playback context for LLM subtitle translation prompts.
class LlmTranslationContextBuilder {
  LlmTranslationContextBuilder._();

  static String build(PlaybackContext context, {required String targetLangCode}) {
    final work = context.work;
    final buffer = StringBuffer()
      ..writeln('Target translation language: $targetLangCode')
      ..writeln()
      ..writeln('=== Work / project ===')
      ..writeln(_formatWork(work))
      ..writeln()
      ..writeln('=== Current track ===')
      ..writeln('File: ${context.currentFile.title ?? 'unknown'}')
      ..writeln('Index in playlist: ${context.currentIndex + 1}/${context.playlist.length}')
      ..writeln()
      ..writeln('=== Playlist in this folder (${_playModeLabel(context.playMode)}) ===');

    for (var i = 0; i < context.playlist.length; i++) {
      final marker = i == context.currentIndex ? ' (current)' : '';
      buffer.writeln('${i + 1}. ${context.playlist[i].title ?? 'untitled'}$marker');
    }

    return buffer.toString().trim();
  }

  static String _formatWork(Work work) {
    final lines = <String>[
      if (work.sourceId != null) 'Catalog ID: ${work.sourceId}',
      if (work.title != null && work.title!.isNotEmpty) 'Title: ${work.title}',
      if (work.name != null && work.name!.isNotEmpty) 'Name: ${work.name}',
      if (work.circle?.name != null) 'Circle/studio: ${work.circle!.name}',
      if (work.duration != null) 'Duration (sec): ${work.duration}',
      if (work.nsfw == true) 'Content rating: adult/NSFW',
      if (work.translationInfo?.lang != null)
        'Work language tag: ${work.translationInfo!.lang}',
      if (work.translationInfo?.isOriginal == true) 'This edition: original',
      if (work.translationInfo?.isChild == true) 'This edition: translation child',
    ];

    final tags = work.tags
        ?.map((t) => I18nNameResolver.resolve(t.i18n, fallback: t.name ?? ''))
        .where((n) => n.isNotEmpty)
        .toList();
    if (tags != null && tags.isNotEmpty) {
      lines.add('Tags: ${tags.join(', ')}');
    }

    final vas = work.vas?.map((v) => v.toString()).where((s) => s.isNotEmpty).toList();
    if (vas != null && vas.isNotEmpty) {
      lines.add('Voice actors: ${vas.join(', ')}');
    }

    if (lines.isEmpty) return 'No detailed metadata available.';
    return lines.join('\n');
  }

  static String _playModeLabel(PlayMode mode) {
    switch (mode) {
      case PlayMode.sequence:
        return 'sequential';
      case PlayMode.loop:
        return 'loop playlist';
      case PlayMode.single:
        return 'single repeat';
    }
  }
}
