import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/presentation/viewmodels/downloads_viewmodel.dart';
import 'package:lizunemu/presentation/viewmodels/home_viewmodel.dart';
import 'package:lizunemu/presentation/viewmodels/local_library_viewmodel.dart';
import 'package:lizunemu/screens/contents/downloads_hub_content.dart';
import 'package:lizunemu/screens/contents/home_content.dart';
import 'package:lizunemu/screens/contents/local_library_content.dart';

enum _LibrarySegment { local, downloads, browse }

/// Library shell: **Local | Downloads | Browse** (Eara Milestone F + interim).
class LibraryTabContent extends StatefulWidget {
  const LibraryTabContent({super.key});

  @override
  State<LibraryTabContent> createState() => _LibraryTabContentState();
}

class _LibraryTabContentState extends State<LibraryTabContent>
    with AutomaticKeepAliveClientMixin {
  _LibrarySegment _segment = _LibrarySegment.local;
  late final DownloadsViewModel _downloadsViewModel;
  late final LocalLibraryViewModel _localLibraryViewModel;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _downloadsViewModel = DownloadsViewModel();
    _localLibraryViewModel = LocalLibraryViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _downloadsViewModel.load();
      _localLibraryViewModel.load();
    });
  }

  @override
  void dispose() {
    _downloadsViewModel.dispose();
    _localLibraryViewModel.dispose();
    super.dispose();
  }

  String _title(BuildContext context) {
    switch (_segment) {
      case _LibrarySegment.local:
        final count = context.select<LocalLibraryViewModel, int>(
          (vm) => vm.albums.length,
        );
        if (count <= 0) return Strings.librarySegmentLocal;
        return '${Strings.librarySegmentLocal} ($count)';
      case _LibrarySegment.downloads:
        final count = context.select<DownloadsViewModel, int>(
          (vm) => vm.groups.length,
        );
        if (count <= 0) return Strings.downloadsTitle;
        return '${Strings.downloadsTitle} ($count)';
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _downloadsViewModel),
        ChangeNotifierProvider.value(value: _localLibraryViewModel),
      ],
      // Providers are scoped to [child]; AppBar title must read them from a
      // descendant context, not the outer build context (ProviderNotFound).
      child: Builder(
        builder: (scopedContext) {
          return Scaffold(
            appBar: AppBar(
              title: Text(_title(scopedContext)),
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
                        value: _LibrarySegment.local,
                        label: Text(Strings.librarySegmentLocal),
                        icon: const Icon(Icons.folder_outlined),
                      ),
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
                      LocalLibraryContent(),
                      DownloadsHubContent(),
                      HomeContent(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
