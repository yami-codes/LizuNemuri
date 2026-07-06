import 'package:flutter/material.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'work_title.dart';
import 'work_tags_panel.dart';
import 'work_footer.dart';

class WorkInfoSection extends StatelessWidget {
  final Work work;
  final String? titleOverride;
  final void Function(String apiTagName)? onTagInclude;
  final void Function(String apiTagName)? onTagExclude;

  const WorkInfoSection({
    super.key,
    required this.work,
    this.titleOverride,
    this.onTagInclude,
    this.onTagExclude,
  });

  @override
  Widget build(BuildContext context) {
    // Duration moved to cover badge; removed duplicate display and redundant SizedBox spacing.
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WorkTitle(work: work, titleOverride: titleOverride),
          const SizedBox(height: AppSpacing.space8),
          WorkTagsPanel(
            work: work,
            onTagInclude: onTagInclude,
            onTagExclude: onTagExclude,
          ),
          const SizedBox(height: AppSpacing.space12),
          WorkFooter(work: work),
        ],
      ),
    );
  }
}
