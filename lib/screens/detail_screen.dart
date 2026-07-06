import 'package:lizunemu/core/theme/app_animations.dart';
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
import 'package:lizunemu/widgets/detail/work_action_buttons.dart';
import 'package:lizunemu/widgets/detail/media_download_dialog.dart';
import 'package:lizunemu/widgets/detail/batch_download_dialog.dart';
import 'package:lizunemu/widgets/detail/batch_translate_dialog.dart';
import 'package:lizunemu/widgets/detail/batch_translate_selection_dialog.dart';
import 'package:lizunemu/core/download/download_service.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/utils/user_facing_error.dart';
import 'package:lizunemu/screens/similar_works_screen.dart';
import 'package:lizunemu/screens/subtitle_preview_screen.dart';
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
    return ChangeNotifierProvider(
      create: (_) => DetailViewModel(
        work: work,
      )..loadInitialData(),
      child: Scaffold(
        appBar: PoppableAppBar(
          title: work.sourceId ?? '',
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: MiniPlayer.height),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WorkCover(
                imageUrl: work.mainCoverUrl ?? '',
                workId: work.id ?? 0,
                sourceId: work.sourceId ?? '',
                releaseDate: work.release,
                heroTag: 'work-cover-${work.id}',
              ),
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
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
              Consumer<DetailViewModel>(
                builder: (context, viewModel, _) {
                  if (viewModel.isLoading) {
                    return const WorkFilesSkeleton();
                  }

                  if (viewModel.error != null) {
                    return Center(
                      child: Text(
                        viewModel.error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                    );
                  }

                  if (viewModel.files != null) {
                    // Confirm → download (progress/cancel) → result snackbar.
                    // [openOnDone]=true opens externally for video; false for offline audio.
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
                      // Dismiss at confirm stage → no-op
                      if (result == null || !context.mounted) return;
                      final messenger = ScaffoldMessenger.of(context);
                      if (result.isPlayable && result.localPath != null) {
                        if (openOnDone) {
                          final open =
                              await OpenFilex.open(result.localPath!);
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
                      } else if (result.status ==
                          DownloadStatus.networkError) {
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

                      final outcome =
                          await showDialog<BatchTranslateOutcome>(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => BatchTranslateDialog(
                          trackCount: selection.pairs.length,
                          skipConfirm: true,
                          translate: (ct, onP) => viewModel.translatePairs(
                            items: selection.pairs,
                            onProgress: onP,
                            cancelToken: ct,
                          ),
                        ),
                      );
                      if (outcome == null || !context.mounted) return;
                      final messenger = ScaffoldMessenger.of(context);
                      messenger.showSnackBar(SnackBar(
                        content: Text(outcome.cancelled
                            ? Strings.batchTranslateCancelled
                            : Strings.batchTranslateSummary(
                                outcome.translated,
                                outcome.cached,
                                outcome.failed,
                              )),
                      ));
                    }

                    return WorkFilesList(
                      files: viewModel.files!,
                      onFolderDownload: runBatch,
                      onFolderTranslate: runBulkTranslate,
                      trackTitleFor: viewModel.displayTrackTitle,
                      isTranslatingTrackNames: viewModel.isTranslatingTracks,
                      onTranslateTrackNames: () async {
                        final msg = await viewModel.translateTrackNames(force: true);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              msg ?? Strings.metadataTrackTranslationDone,
                            ),
                          ),
                        );
                      },
                      onFileTap: (file) async {
                        // Video check first: extension over unreliable API `type`.
                        // Video → download + external player, never audio pipeline.
                        if (viewModel.isVideoFile(file)) {
                          await runDownload(
                            file,
                            openOnDone: true,
                            title: Strings.videoNeedsDownloadTitle,
                            prompt: Strings.videoNeedsDownloadPrompt,
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
                  }

                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
        bottomSheet: const MiniPlayer(),
      ),
    );
  }
}
