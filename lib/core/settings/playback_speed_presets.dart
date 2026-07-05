/// Preset playback speeds exposed in the player UI.
abstract final class PlaybackSpeedPresets {
  static const double min = 0.5;
  static const double max = 2.0;
  static const double defaultSpeed = 1.0;

  static const List<double> values = [
    0.75,
    0.85,
    1.0,
    1.1,
    1.25,
    1.5,
  ];

  static double clamp(double speed) => speed.clamp(min, max);

  /// Picks the nearest preset for display highlighting.
  static bool isSelected(double current, double preset) {
    return (current - preset).abs() < 0.01;
  }
}
