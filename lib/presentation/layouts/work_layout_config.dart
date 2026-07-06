import 'package:flutter/material.dart';

/// Device type.
enum DeviceType {
  mobile,
  tablet,
  desktop;

  /// Device type from screen width.
  static DeviceType fromWidth(double width) {
    if (width >= WorkLayoutConfig.desktopBreakpoint) return DeviceType.desktop;
    if (width >= WorkLayoutConfig.tabletBreakpoint) return DeviceType.tablet;
    return DeviceType.mobile;
  }
}

/// Work grid layout configuration.
class WorkLayoutConfig {
  // Breakpoints
  static const double desktopBreakpoint = 1200;
  static const double tabletBreakpoint = 800;

  // Column counts (legacy; [columnsForWidth] is authoritative)
  static const int desktopColumns = 4;
  static const int tabletColumns = 3;
  static const int mobileColumns = 2;

  /// Target max card width (px); wide screens derive column count from this.
  static const double maxCardWidth = 180;

  static const int minColumns = 2;
  static const int maxColumns = 10;

  // Spacing
  static const double desktopSpacing = 16;
  static const double tabletSpacing = 12;
  static const double mobileSpacing = 8;

  // Padding
  static const EdgeInsets desktopPadding = EdgeInsets.all(16);
  static const EdgeInsets tabletPadding = EdgeInsets.all(12);
  static const EdgeInsets mobilePadding = EdgeInsets.all(8);

  const WorkLayoutConfig._();

  /// Column count by device type (narrow-screen fallback).
  static int getColumnsCount(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.desktop:
        return desktopColumns;
      case DeviceType.tablet:
        return tabletColumns;
      case DeviceType.mobile:
        return mobileColumns;
    }
  }

  /// Column count from available width so card width ≤ [maxCardWidth].
  static int columnsForWidth(double width) {
    final deviceType = DeviceType.fromWidth(width);
    final horizontalPadding = getPadding(deviceType).horizontal;
    final spacing = getSpacing(deviceType);
    final usable = width - horizontalPadding;
    if (usable <= 0) return minColumns;

    final cols = ((usable + spacing) / (maxCardWidth + spacing)).floor();
    return cols.clamp(minColumns, maxColumns);
  }

  /// Spacing by device type.
  static double getSpacing(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.desktop:
        return desktopSpacing;
      case DeviceType.tablet:
        return tabletSpacing;
      case DeviceType.mobile:
        return mobileSpacing;
    }
  }

  /// Padding by device type.
  static EdgeInsets getPadding(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.desktop:
        return desktopPadding;
      case DeviceType.tablet:
        return tabletPadding;
      case DeviceType.mobile:
        return mobilePadding;
    }
  }
}
