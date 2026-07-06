import 'package:flutter/material.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/presentation/layouts/work_layout_config.dart';

/// Responsive layout tokens for the work detail screen.
class DetailLayoutConfig {
  DetailLayoutConfig._();

  static const double tabletBreakpoint = WorkLayoutConfig.tabletBreakpoint;
  static const double maxContentWidth = 1200;
  static const double coverWidth = 360;

  static bool isWideLayout(double width) => width >= tabletBreakpoint;

  static EdgeInsets pagePadding(bool wide) => wide
      ? const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageTabletDesktop,
          vertical: AppSpacing.space16,
        )
      : EdgeInsets.zero;
}
