import 'package:flutter/widgets.dart';

/// Radius tokens. Spec §1.4.
///
/// `*All` are const [BorderRadius] for zero-allocation theme/decoration.
/// Circular covers use `BoxShape.circle`, not these.
class AppRadius {
  AppRadius._();

  static const double sm = 8; // Chip / Tooltip
  static const double md = 12; // Work cards / list items
  static const double lg = 16; // Player sheet / bottom panel / dialogs
  static const double full = 999; // Pills / search field / avatar / AccentPill

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius fullAll = BorderRadius.all(Radius.circular(full));
}
