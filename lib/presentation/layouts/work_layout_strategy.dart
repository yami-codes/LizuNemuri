import 'package:flutter/material.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'package:lizunemu/presentation/layouts/work_layout_config.dart';

/// Work grid layout strategy.
class WorkLayoutStrategy {
  const WorkLayoutStrategy();

  /// Device type from context.
  DeviceType _getDeviceType(BuildContext context) {
    return DeviceType.fromWidth(MediaQuery.of(context).size.width);
  }

  /// Column count per row (responsive; more columns on wide screens).
  int getColumnsCount(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return WorkLayoutConfig.columnsForWidth(width);
  }

  /// Row spacing.
  double getRowSpacing(BuildContext context) {
    return WorkLayoutConfig.getSpacing(_getDeviceType(context));
  }

  /// Column spacing.
  double getColumnSpacing(BuildContext context) {
    return WorkLayoutConfig.getSpacing(_getDeviceType(context));
  }

  /// Page padding.
  EdgeInsets getPadding(BuildContext context) {
    return WorkLayoutConfig.getPadding(_getDeviceType(context));
  }

  // Last input+output memo (spec §7.3). Key = works identity + column count.
  // WorkLayoutStrategy is const — class-level single-slot cache: reuse same works + columns; recompute on page/rotation change.
  static List<Work>? _memoWorks;
  static int? _memoCols;
  static List<List<Work>>? _memoRows;

  /// Group works into grid rows.
  List<List<Work>> groupWorksIntoRows(List<Work> works, int columnsCount) {
    if (identical(_memoWorks, works) &&
        _memoCols == columnsCount &&
        _memoRows != null) {
      return _memoRows!;
    }
    final List<List<Work>> rows = [];
    for (var i = 0; i < works.length; i += columnsCount) {
      final end = i + columnsCount;
      rows.add(works.sublist(i, end > works.length ? works.length : end));
    }
    _memoWorks = works;
    _memoCols = columnsCount;
    _memoRows = rows;
    return rows;
  }
}
