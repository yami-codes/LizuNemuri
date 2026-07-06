import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/data/models/my_lists/my_playlists/playlist.dart';
import 'package:lizunemu/presentation/viewmodels/playlist_works_viewmodel.dart';
import 'package:lizunemu/presentation/viewmodels/playlists_viewmodel.dart';
import 'package:lizunemu/widgets/translation/metadata_translate_page_bar.dart';
import 'package:lizunemu/widgets/work_grid/enhanced_work_grid_view.dart';
import 'package:lizunemu/presentation/layouts/work_layout_strategy.dart';

class PlaylistWorksView extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onBack;
  final WorkLayoutStrategy _layoutStrategy = const WorkLayoutStrategy();

  const PlaylistWorksView({
    super.key,
    required this.playlist,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final playlistsViewModel = context.read<PlaylistsViewModel>();
    
    return ChangeNotifierProvider(
      create: (_) => PlaylistWorksViewModel(playlist)..loadWorks(),
      child: Consumer<PlaylistWorksViewModel>(
        builder: (context, viewModel, child) {
          return Column(
            children: [
              Material(
                elevation: 2,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: onBack,
                      ),
                      Expanded(
                        child: Text(
                          playlistsViewModel.getDisplayName(playlist.name),
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              MetadataTranslatePageBar(
                isTranslating: viewModel.isTranslatingWorkTitles,
                onTranslate: () =>
                    viewModel.translateWorksManual(viewModel.works),
              ),
              Expanded(
                child: EnhancedWorkGridView(
                  works: viewModel.works,
                  isLoading: viewModel.isLoading,
                  error: viewModel.error,
                  onRetry: () => viewModel.refresh(),
                  onRefresh: () => viewModel.refresh(),
                  currentPage: viewModel.currentPage,
                  totalPages: viewModel.totalPages,
                  onPageChanged: (page) => viewModel.loadWorks(page: page),
                  layoutStrategy: _layoutStrategy,
                  emptyMessage: Strings.noWorks,
                  translatedTitles: viewModel.translatedWorkTitles,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
} 