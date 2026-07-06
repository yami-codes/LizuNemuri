import 'package:flutter/material.dart';
import 'package:lizunemu/data/models/works/work.dart';

class WorkTitle extends StatelessWidget {
  final Work work;
  final String? titleOverride;

  const WorkTitle({
    super.key,
    required this.work,
    this.titleOverride,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      titleOverride ?? work.title ?? '',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 14,
          ),
    );
  }
}
