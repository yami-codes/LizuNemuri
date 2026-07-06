import 'package:lizunemu/core/theme/app_animations.dart';
import 'package:flutter/material.dart';

class GridConfig {
  final ScrollPhysics? physics;
  final bool enablePagination;
  final bool showLoadingOnEmpty;
  final Duration scrollDuration;
  final Curve scrollCurve;
  final EdgeInsets? padding;
  final void Function(String apiTagName)? onTagInclude;
  final void Function(String apiTagName)? onTagExclude;

  const GridConfig({
    this.physics,
    this.enablePagination = true,
    this.showLoadingOnEmpty = true,
    this.scrollDuration = AppAnimations.medium,
    this.scrollCurve = AppAnimations.enter,
    this.padding,
    this.onTagInclude,
    this.onTagExclude,
  });

  static const GridConfig defaultConfig = GridConfig();
} 