/// Linear volume interpolation for play/pause fades (Eara VolumeFader pattern).
class VolumeFader {
  VolumeFader._();

  static const int defaultStepMs = 16;

  /// Linear blend: progress 0 → [from], 1 → [to].
  static double interpolate(double from, double to, double progress) {
    final t = progress.clamp(0.0, 1.0);
    return from + (to - from) * t;
  }

  /// Number of fade steps for [durationMs] at [stepMs] intervals (at least 1).
  static int stepCount(int durationMs, {int stepMs = defaultStepMs}) {
    if (durationMs <= 0) return 0;
    return (durationMs / stepMs).ceil().clamp(1, 1000);
  }

  /// Volume at discrete step [step] of [totalSteps] (0 = start, totalSteps = end).
  static double volumeAtStep({
    required double from,
    required double to,
    required int step,
    required int totalSteps,
  }) {
    if (totalSteps <= 0) return to;
    final progress = step / totalSteps;
    return interpolate(from, to, progress);
  }

  /// All intermediate volumes including endpoints (length = totalSteps + 1).
  static List<double> fadeSteps({
    required double from,
    required double to,
    required int durationMs,
    int stepMs = defaultStepMs,
  }) {
    final total = stepCount(durationMs, stepMs: stepMs);
    if (total == 0) return [to];
    return [
      for (var i = 0; i <= total; i++)
        volumeAtStep(from: from, to: to, step: i, totalSteps: total),
    ];
  }

  /// After an interrupted fade, restore volume if playback is active but still
  /// near-muted (common when rapid play/pause cancels mid-fade).
  static bool shouldRestoreVolume({
    required bool isPlaying,
    required double currentVolume,
    required double targetVolume,
  }) {
    if (!isPlaying || targetVolume <= 0) return false;
    return currentVolume < targetVolume * 0.5;
  }
}
