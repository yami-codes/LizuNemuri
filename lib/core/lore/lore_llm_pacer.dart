/// Reactive pacing between serial lore LLM calls.
///
/// Default gap is **0** (premium / BYOK). Fixed gap only when
/// [AppSettingsService.loreLlmPaceMs] is 1–5000. After a 429, cool off
/// using Retry-After-style seconds then resume.
class LoreLlmPacer {
  LoreLlmPacer({int paceMs = 0}) : _paceMs = paceMs.clamp(0, 5000);

  int _paceMs;
  DateTime? _cooloffUntil;
  DateTime? _lastCallEnded;

  int get paceMs => _paceMs;

  void updatePaceMs(int ms) {
    _paceMs = ms.clamp(0, 5000);
  }

  /// Note a rate-limit cooloff. [seconds] clamped to 1–60.
  void noteRateLimited({int seconds = 5}) {
    final cool = seconds.clamp(1, 60);
    _cooloffUntil = DateTime.now().add(Duration(seconds: cool));
  }

  /// Await fixed gap and/or pending cooloff before the next LLM call.
  Future<void> beforeNextCall() async {
    final now = DateTime.now();
    Duration wait = Duration.zero;

    if (_cooloffUntil != null && _cooloffUntil!.isAfter(now)) {
      wait = _cooloffUntil!.difference(now);
    } else if (_paceMs > 0 && _lastCallEnded != null) {
      final elapsed = now.difference(_lastCallEnded!);
      final gap = Duration(milliseconds: _paceMs);
      if (elapsed < gap) wait = gap - elapsed;
    }

    if (wait > Duration.zero) {
      await Future<void>.delayed(wait);
    }
  }

  void markCallEnded() {
    _lastCallEnded = DateTime.now();
  }
}
