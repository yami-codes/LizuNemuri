import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xuro/common/constants/strings.dart';
import 'package:xuro/core/theme/app_spacing.dart';
import 'package:xuro/presentation/viewmodels/downloads_viewmodel.dart';
import 'package:xuro/presentation/viewmodels/home_viewmodel.dart';
import 'package:xuro/screens/contents/downloads_hub_content.dart';
import 'package:xuro/screens/contents/home_content.dart';

enum _LibrarySegment { downloads, browse }

/// Interim library shell: **Downloads** (offline) + **Browse** (asmr.one grid).
///
/// Replaces the old Home-only stub. Milestone F local scan will add a third
/// segment or replace Browse — see `docs/eara_ui_north_star.md`.
class LibraryTabContent extends StatefulWidget {
  const LibraryTabContent({super.key});

  @override
  State<LibraryTabContent> createState() => _LibraryTabContentState();
}

class _LibraryTabContentState extends State<LibraryTabContent>
    with AutomaticKeepAliveClientMixin {
  _LibrarySegment _segment = _LibrarySegment.downloads;
  late final DownloadsViewModel _downloadsViewModel;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _downloadsViewModel = DownloadsViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _downloadsViewModel.load();
    });
  }

  @override
  void dispose() {
    _downloadsViewModel.dispose();
    super.dispose();
  }

  String _title(BuildContext context) {
    switch (_segment) {
      case _LibrarySegment.downloads:
        final count = context.select<DownloadsViewModel, int>(
          (vm) => vm.groups.length,
        );
        if (count <= 0) return Strings.tabLibrary;
        return '${Strings.tabLibrary} ($count)';
      case _LibrarySegment.browse:
        final total = context.select<HomeViewModel, int?>(
          (vm) => vm.pagination?.totalCount,
        );
        if (total == null) return Strings.librarySegmentBrowse;
        return '${Strings.librarySegmentBrowse} ($total)';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ChangeNotifierProvider.value(
      value: _downloadsViewModel,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_title(context)),
          actions: [
            if (_segment == _LibrarySegment.browse)
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () =>
                    context.read<HomeViewModel>().toggleFilterPanel(),
              ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageMobile,
                AppSpacing.space8,
                AppSpacing.pageMobile,
                AppSpacing.space8,
              ),
              child: SegmentedButton<_LibrarySegment>(
                segments: [
                  ButtonSegment(
                    value: _LibrarySegment.downloads,
                    label: Text(Strings.downloadsTitle),
                    icon: const Icon(Icons.download_outlined),
                  ),
                  ButtonSegment(
                    value: _LibrarySegment.browse,
                    label: Text(Strings.librarySegmentBrowse),
                    icon: const Icon(Icons.explore_outlined),
                  ),
                ],
                selected: {_segment},
                onSelectionChanged: (selection) {
                  setState(() => _segment = selection.first);
                },
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _segment.index,
                children: const [
                  DownloadsHubContent(),
                  HomeContent(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
