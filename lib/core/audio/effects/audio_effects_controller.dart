import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Android graphic EQ via [just_audio] [AndroidEqualizer] (Milestone H).
class AudioEffectsController extends ChangeNotifier {
  AndroidEqualizer? _equalizer;
  bool _enabled = false;

  bool get isSupported => _equalizer != null;
  bool get enabled => _enabled;
  AndroidEqualizer? get equalizer => _equalizer;

  void bind(AndroidEqualizer equalizer) {
    _equalizer = equalizer;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    final eq = _equalizer;
    if (eq == null) return;
    _enabled = value;
    await eq.setEnabled(value);
    notifyListeners();
  }

  Future<AndroidEqualizerParameters?> loadParameters() async {
    final eq = _equalizer;
    if (eq == null) return null;
    return eq.parameters;
  }
}
