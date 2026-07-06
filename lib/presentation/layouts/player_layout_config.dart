/// Responsive breakpoints and sizing for the full-screen player.
class PlayerLayoutConfig {
  const PlayerLayoutConfig._();

  /// Side-by-side art + lyrics at or above this width.
  static const double wideBreakpoint = 900;

  static bool isWideLayout(double width) => width >= wideBreakpoint;

  /// Cover diameter — prevents full-width square on desktop.
  static double coverSizeForWidth(double width) {
    if (width >= wideBreakpoint) {
      return 280;
    }
    final padded = width - 48;
    return padded.clamp(240, 340);
  }
}
