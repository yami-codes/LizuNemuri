import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/lore/lore_generate_queue_models.dart';

/// Human labels for lore generate progress stages and job kinds.
class LoreProgressLabels {
  LoreProgressLabels._();

  static String forKind(LoreGenerateKind kind) {
    return switch (kind) {
      LoreGenerateKind.fullGenerate => Strings.loreQueueKindFullGenerate,
      LoreGenerateKind.secretsOnly => Strings.loreQueueKindSecretsOnly,
      LoreGenerateKind.regenerateWork => Strings.loreQueueKindRegenerateWork,
      LoreGenerateKind.regenerateTrack => Strings.loreQueueKindRegenerateTrack,
      LoreGenerateKind.regenerateCharacter =>
        Strings.loreQueueKindRegenerateCharacter,
    };
  }

  static String forStage(String progressStage) {
    if (progressStage.startsWith('cast')) {
      return Strings.loreProgressCast;
    }
    if (progressStage.startsWith('secrets')) {
      return Strings.loreProgressSecrets;
    }
    if (progressStage.startsWith('reconcile')) {
      return Strings.loreProgressReconcile;
    }
    if (progressStage == 'done') {
      return Strings.loreProgressDone;
    }
    if (progressStage.startsWith('subs:resolve') ||
        progressStage == 'subs') {
      return Strings.loreProgressSubsResolve;
    }
    if (progressStage.startsWith('subs:translate')) {
      return Strings.loreProgressSubsTranslate;
    }
    if (progressStage.startsWith('track')) {
      // Formats: track:key | track:i/N:title
      final parts = progressStage.split(':');
      if (parts.length >= 3) {
        final frac = parts[1].split('/');
        if (frac.length == 2) {
          final cur = int.tryParse(frac[0]);
          final tot = int.tryParse(frac[1]);
          if (cur != null && tot != null) {
            final title = parts.sublist(2).join(':').trim();
            final base = Strings.loreProgressTrackN(cur, tot);
            return title.isEmpty ? base : '$base · $title';
          }
        }
      }
      return Strings.loreProgressTrack;
    }
    if (progressStage == 'retry') {
      return Strings.loreQueueRetryFailed;
    }
    return Strings.loreGenerating;
  }
}
