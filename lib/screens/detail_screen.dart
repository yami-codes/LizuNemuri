import 'package:lizunemu/core/theme/app_animations.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/widgets/mini_player/mini_player.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/widgets/detail/work_cover.dart';
import 'package:lizunemu/widgets/detail/work_info.dart';
import 'package:lizunemu/widgets/detail/work_files_list.dart';
import 'package:lizunemu/widgets/detail/work_files_skeleton.dart';
import 'package:lizunemu/presentation/viewmodels/detail_viewmodel.dart';
import 'package:lizunemu/presentation/viewmodels/work_lore_viewmodel.dart';
import 'package:lizunemu/presentation/layouts/detail_layout_config.dart';
import 'package:lizunemu/widgets/detail/work_action_buttons.dart';
import 'package:lizunemu/widgets/detail/media_download_dialog.dart';
import 'package:lizunemu/widgets/detail/batch_download_dialog.dart';
import 'package:lizunemu/widgets/detail/batch_translate_selection_dialog.dart';
import 'package:lizunemu/widgets/lore/work_lore_panel.dart';
import 'package:lizunemu/core/download/download_service.dart';
import 'package:lizunemu/core/llm/translation_queue_service.dart';
import 'package:lizunemu/screens/translation_queue_screen.dart';
import 'package:lizunemu/core/lore/ccv2_export_service.dart';
import 'package:lizunemu/core/lore/global_character_service.dart';
import 'package:lizunemu/core/lore/lore_track_input_builder.dart';
import 'package:lizunemu/core/lore/work_lore_service.dart';
import 'package:lizunemu/data/repositories/llm_api_key_repository.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/utils/user_facing_error.dart';
import 'package:lizunemu/screens/similar_works_screen.dart';
import 'package:lizunemu/screens/subtitle_preview_screen.dart';
import 'package:lizunemu/screens/image_preview_screen.dart';
import 'package:lizunemu/screens/video_player_screen.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/core/settings/metadata_translation_mode.dart';
import 'package:lizunemu/widgets/common/back_leading.dart';
import 'package:open_filex/open_filex.dart';

class DetailScreen extends StatelessWidget {
  final Work work;
  final bool fromPlayer;

  const DetailScreen({
    super.key,
    required this.work,
    this.fromPlayer = false,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DetailViewModel(work: work)..loadInitialData(),
        ),
        ChangeNotifierProvider(
          create: (_) => WorkLoreViewModel.create(
            work: work,
            lore: GetIt.instance<WorkLoreService>(),
            ccv2: GetIt.instance<Ccv2ExportService>(),
            global: GetIt.instance<GlobalCharacterService>(),
            trackBuilder: GetIt.instance<LoreTrackInputBuilder>(),
            apiKeyRepo: GetIt.instance<LlmApiKeyRepository>(),
          )..load(),
        ),
      ],
      child: Scaffold(
        appBar: PoppableAppBar(
          title: work.sourceId ?? '',
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final wide =
                DetailLayoutConfig.isWideLayout(constraints.maxWidth);
            return SingleChildScrollView(
              padding: DetailLayoutConfig.pagePadding(wide).copyWith(
                bottom: MiniPlayer.height,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: wide
                        ? DetailLayoutConfig.maxContentWidth
                        : constraints.maxWidth,
                  ),
                  child: wide
                      ? _WideDetailLayout(work: work)
                      : _NarrowDetailLayout(work: work),
                ),
              ),
            );
          },
        ),
        bottomSheet: const MiniPlayer(),
      ),
    );
  }
}

class _NarrowDetailLayout extends StatelessWidget {
  const _NarrowDetailLayout({required this.work});

  final Work work;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WorkCover(
          imageUrl: work.mainCoverUrl ?? '',
          workId: work.id ?? 0,
          sourceId: work.sourceId ?? '',
          releaseDate: work.release,
          heroTag: 'work-cover-${work.id}',
        ),
        _DetailMainContent(work: work),
      ],
    );
  }
}

class _WideDetailLayout extends StatelessWidget {
  const _WideDetailLayout({required this.work});

  final Work work;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: DetailLayoutConfig.coverWidth,
          child: WorkCover(
            imageUrl: work.mainCoverUrl ?? '',
            workId: work.id ?? 0,
            sourceId: work.sourceId ?? '',
            releaseDate: work.release,
            heroTag: 'work-cover-${work.id}',
          ),
        ),
        const SizedBox(width: AppSpacing.space24),
        Expanded(
          child: _DetailMainContent(work: work),
        ),
      ],
    );
  }
}

class _DetailMainContent extends StatefulWidget {
  const _DetailMainContent({required this.work});

  final Work work;

  @override
  State<_DetailMainContent> createState() => _DetailMainContentState();
}

class _DetailMainContentState extends State<_DetailMainContent> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final work = widget.work;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Consumer<DetailViewModel>(
          builder: (context, viewModel, _) => WorkInfo(
            work: work,
            workInfo: viewModel.workInfo,
            displayTitle: viewModel.displayTitle,
            isTitleTranslated: viewModel.isTitleTranslated,
            isTitleTranslating: viewModel.isTitleTranslating,
            canRestoreOriginalTitle: viewModel.canRestoreOriginalTitle,
            canShowTranslatedTitle: viewModel.canShowTranslatedTitle,
            onTranslateTitle: () async {
              final msg = await viewModel.translateWorkTitle();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    msg ?? Strings.llmTitleTranslationDone,
                  ),
                ),
              );
            },
            onShowOriginalTitle: viewModel.showOriginalTitle,
            onShowTranslatedTitle: viewModel.showTranslatedTitle,
          ),
        ),
        Consumer<DetailViewModel>(
          builder: (context, viewModel, _) => WorkActionButtons(
            hasRecommendations: viewModel.hasRecommendations,
            checkingRecommendations: viewModel.checkingRecommendations,
            onRecommendationsTap: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      SimilarWorksScreen(work: work),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = AppAnimations.standard;
                    var tween = Tween(begin: begin, end: end).chain(
                      CurveTween(curve: curve),
                    );
                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
                ),
              );
            },
            onFavoriteTap: () => viewModel.showPlaylistsDialog(context),
            loadingFavorite: viewModel.loadingFavorite,
            onMarkTap: () => viewModel.showMarkDialog(context),
            currentMarkStatus: viewModel.currentMarkStatus,
            loadingMark: viewModel.loadingMark,
          ),
        ),
        const SizedBox(height: AppSpacing.space12),
        SegmentedButton<int>(
          segments: [
            ButtonSegment(value: 0, label: Text(Strings.loreFilesTab)),
            ButtonSegment(value: 1, label: Text(Strings.loreTab)),
          ],
          selected: {_tab},
          onSelectionChanged: (s) => setState(() => _tab = s.first),
        ),
        const SizedBox(height: AppSpacing.space12),
        if (_tab == 0)
          _DetailFilesSection(work: work)
        else
          Consumer<DetailViewModel>(
            builder: (context, detail, _) {
              final pairs = DetailViewModel.collectAudioWithSubtitles(
                detail.files?.children,
              );
              return WorkLorePanel(
                pairs: pairs,
                files: detail.files,
              );
            },
          ),
      ],
    );
  }
}

class _DetailFilesSection extends StatelessWidget {
  const _DetailFilesSection({required this.work});

  final Work work;

  @override
  Widget build(BuildContext context) {
    return Consumer<DetailViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLoading) {
          return const WorkFilesSkeleton();
        }

        if (viewModel.error != null) {
          return Center(
            child: Text(
              viewModel.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        }

        if (viewModel.files == null) {
          return const SizedBox.shrink();
        }

        Future<void> runDownload(
          Child file, {
          required bool openOnDone,
          required String title,
          required String prompt,
        }) async {
          final result = await showDialog<DownloadResult>(
            context: context,
            barrierDismissible: false,
            builder: (_) => MediaDownloadDialog(
              fileName: file.title ?? '',
              titleText: title,
              promptText: prompt,
              download: (ct, onP) => viewModel.downloadFile(
                file,
                cancelToken: ct,
                onProgress: onP,
              ),
            ),
          );
          if (result == null || !context.mounted) return;
          final messenger = ScaffoldMessenger.of(context);
          if (result.isPlayable && result.localPath != null) {
            if (openOnDone) {
              final open = await OpenFilex.open(result.localPath!);
              if (open.type != ResultType.done) {
                messenger.showSnackBar(SnackBar(
                  content: Text(Strings.downloadOpenFailed),
                ));
              }
            } else {
              messenger.showSnackBar(SnackBar(
                content: Text(Strings.downloadSuccess),
              ));
            }
          } else if (result.status == DownloadStatus.cancelled) {
            messenger.showSnackBar(SnackBar(
              content: Text(Strings.downloadCancelled),
            ));
          } else if (result.status == DownloadStatus.networkError) {
            messenger.showSnackBar(SnackBar(
              content: Text(Strings.downloadNetworkError),
            ));
          } else {
            messenger.showSnackBar(SnackBar(
              content: Text(Strings.downloadIoError),
            ));
          }
        }

        Future<void> runBatch(Child? folderNode) async {
          final outcome = await showDialog<BatchDownloadOutcome>(
            context: context,
            barrierDismissible: false,
            builder: (_) => BatchDownloadDialog(
              audioCount: viewModel.batchAudioCount(folderNode),
              download: (ct, onP) => viewModel.downloadFolder(
                folder: folderNode,
                onProgress: onP,
                cancelToken: ct,
              ),
            ),
          );
          if (outcome == null || !context.mounted) return;
          final messenger = ScaffoldMessenger.of(context);
          messenger.showSnackBar(SnackBar(
            content: Text(outcome.cancelled
                ? Strings.batchDownloadCancelled
                : Strings.batchDownloadSummary(
                    outcome.ok,
                    outcome.skipped,
                    outcome.failed,
                  )),
          ));
        }

        Future<void> runBulkTranslate(Child? folderNode) async {
          final selection =
              await showDialog<BatchTranslateSelectionResult>(
            context: context,
            barrierDismissible: false,
            builder: (_) => BatchTranslateSelectionDialog(
              loadItems: () =>
                  viewModel.prepareTranslateSelection(folderNode),
              cachedCount: viewModel.cachedTranslationCount,
              workTitle: work.title,
              isTitleCached: viewModel.isWorkTitleCached,
            ),
          );
          if (selection == null || !context.mounted) return;
          if (selection.translateTitle) {
            await viewModel.translateWorkTitle();
          }
          if (selection.pairs.isEmpty) {
            if (selection.translateTitle && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(Strings.llmTitleTranslationDone),
                ),
              );
            }
            return;
          }

          final files = viewModel.files;
          if (files == null) return;
          final pairs = selection.pairs
              .where((p) => p.subtitle != null)
              .map((p) => (audio: p.audio, subtitle: p.subtitle!))
              .toList();
          final queued = await GetIt.I<TranslationQueueService>().enqueue(
            work: work,
            files: files,
            pairs: pairs,
          );
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(Strings.translationQueueEnqueued(queued)),
              action: SnackBarAction(
                label: Strings.translationQueueTitle,
                onPressed: () => openTranslationQueueScreen(context),
              ),
            ),
          );
        }

        final metadataSettings = GetIt.I<AppSettingsService>();
        final showManualTrackTranslate =
            metadataSettings.metadataTranslationEnabled &&
                metadataSettings.metadataTranslationMode ==
                    MetadataTranslationMode.manual;

        return WorkFilesList(
          files: viewModel.files!,
          onFolderDownload: runBatch,
          onFolderTranslate: runBulkTranslate,
          titleFor: viewModel.displayTreeTitle,
          isTranslatingTrackNames: viewModel.isTranslatingTracks,
          onTranslateTrackNames: showManualTrackTranslate
              ? () async {
                  final msg = await viewModel.translateTrackNames(force: true);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        msg ?? Strings.metadataTrackTranslationDone,
                      ),
                    ),
                  );
                }
              : null,
          onFileTap: (file) async {
            if (viewModel.isVideoFile(file)) {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VideoPlayerScreen(
                    workId: work.id?.toString(),
                    file: file,
                    subtitleFile: viewModel.subtitleForFile(file),
                  ),
                ),
              );
              return;
            }
            if (viewModel.isAudioFile(file)) {
              try {
                await viewModel.playFile(file, context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(localizedPlayFailed(e))),
                  );
                }
              }
              return;
            }
            if (viewModel.isSubtitleFile(file)) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SubtitlePreviewScreen(
                    workId: work.id?.toString(),
                    file: file,
                  ),
                ),
              );
              return;
            }
            if (viewModel.isImageFile(file)) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ImagePreviewScreen(
                    workId: work.id?.toString(),
                    file: file,
                  ),
                ),
              );
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(Strings.unsupportedFileType),
              ),
            );
          },
          onFileDownload: (file) => runDownload(
            file,
            openOnDone: false,
            title: Strings.audioDownloadTitle,
            prompt: Strings.audioDownloadPrompt,
          ),
        );
      },
    );
  }
}
