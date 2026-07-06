import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/core/theme/app_animations.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/presentation/viewmodels/player_viewmodel.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:lizunemu/core/subtitle/i_subtitle_service.dart';
import 'package:lizunemu/core/audio/models/subtitle.dart';
import 'lyric_line.dart';

/// Proximity-based emphasis for kinetic centered lyrics (0 = dim, 1 = center).
@visibleForTesting
double lyricKineticEmphasis(
  ItemPosition position, {
  double viewportCenter = 0.5,
  double falloff = 0.14,
  double minEmphasis = 0.18,
}) {
  final itemCenter =
      (position.itemLeadingEdge + position.itemTrailingEdge) / 2;
  final distance = (itemCenter - viewportCenter).abs();
  final proximity = 1.0 - (distance / falloff).clamp(0.0, 1.0);
  return minEmphasis + (1.0 - minEmphasis) * proximity;
}

const _kMinEmphasis = 0.18;

@visibleForTesting
double lyricEmphasisForIndex({
  required int index,
  required bool isActive,
  required Iterable<ItemPosition> positions,
}) {
  for (final position in positions) {
    if (position.index == index) {
      final proximity = lyricKineticEmphasis(position);
      if (isActive) {
        // Only the centered playback line should read as fully active.
        return proximity.clamp(0.92, 1.0);
      }
      return (proximity * 0.55).clamp(_kMinEmphasis, 0.72);
    }
  }
  return isActive ? 0.92 : _kMinEmphasis;
}

class PlayerLyricView extends StatefulWidget {
  final bool immediateScroll;
  final Function(bool canSwitch) onScrollStateChanged;
  final bool lockParentViewSwitch;
  final bool compact;

  const PlayerLyricView({
    super.key,
    this.immediateScroll = false,
    required this.onScrollStateChanged,
    this.lockParentViewSwitch = true,
    this.compact = false,
  });

  @override
  State<PlayerLyricView> createState() => _PlayerLyricViewState();
}

class _PlayerLyricViewState extends State<PlayerLyricView> {
  final ISubtitleService _subtitleService = GetIt.I<ISubtitleService>();
  final PlayerViewModel _viewModel = GetIt.I<PlayerViewModel>();
  final AppSettingsService _settings = GetIt.I<AppSettingsService>();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  bool _isFirstBuild = true;
  Subtitle? _lastScrolledSubtitle;

  Timer? _scrollDebounceTimer;
  bool _allowAutoScroll = true;
  Timer? _autoScrollDebounceTimer;

  StreamSubscription? _subtitleSubscription;

  @override
  void initState() {
    super.initState();
    _subtitleSubscription =
        _subtitleService.currentSubtitleWithStateStream.listen((current) {
      if (current != null && _itemScrollController.isAttached) {
        _scrollToCurrentLyric(current);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = _subtitleService.currentSubtitleWithState;
      if (current != null && _itemScrollController.isAttached) {
        _scrollToCurrentLyric(current);
      }
    });
  }

  @override
  void dispose() {
    _subtitleSubscription?.cancel();
    _scrollDebounceTimer?.cancel();
    _autoScrollDebounceTimer?.cancel();
    super.dispose();
  }

  void _scrollToCurrentLyric(SubtitleWithState current) {
    if (!_itemScrollController.isAttached) return;
    if (!_allowAutoScroll) return;

    if (_lastScrolledSubtitle == current.subtitle) return;
    _lastScrolledSubtitle = current.subtitle;

    final index = current.subtitle.index;
    const alignment = 0.5;

    if (_isFirstBuild || widget.immediateScroll) {
      _isFirstBuild = false;
      _itemScrollController.jumpTo(
        index: index,
        alignment: alignment,
      );
      return;
    }

    _itemScrollController.scrollTo(
      index: index,
      duration: AppAnimations.long,
      curve: AppAnimations.smoothScroll,
      alignment: alignment,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final baseUnit = screenHeight * 0.04;

    return ListenableBuilder(
      listenable: Listenable.merge([_viewModel, _settings]),
      builder: (context, _) {
        return StreamBuilder<SubtitleWithState?>(
          stream: _subtitleService.currentSubtitleWithStateStream,
          initialData: _subtitleService.currentSubtitleWithState,
          builder: (context, snapshot) {
            final currentSubtitle = snapshot.data;
            final subtitleList = _subtitleService.subtitleList;

            if (subtitleList == null || subtitleList.subtitles.isEmpty) {
              return Center(
                child: Text(Strings.noLyrics),
              );
            }

            return NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollStartNotification &&
                    notification.dragDetails != null) {
                  if (widget.lockParentViewSwitch) {
                    widget.onScrollStateChanged(false);
                  }

                  _allowAutoScroll = false;
                  _scrollDebounceTimer?.cancel();
                  _autoScrollDebounceTimer?.cancel();
                } else if (notification is ScrollEndNotification) {
                  if (widget.lockParentViewSwitch) {
                    _scrollDebounceTimer?.cancel();
                    _scrollDebounceTimer =
                        Timer(const Duration(milliseconds: 1000), () {
                      if (mounted) {
                        widget.onScrollStateChanged(true);
                      }
                    });
                  }

                  _autoScrollDebounceTimer?.cancel();
                  _autoScrollDebounceTimer =
                      Timer(const Duration(milliseconds: 3000), () {
                    if (mounted) {
                      _allowAutoScroll = true;
                      _lastScrolledSubtitle = null;
                      final current =
                          _subtitleService.currentSubtitleWithState;
                      if (current != null) {
                        _scrollToCurrentLyric(current);
                      }
                    }
                  });
                }
                return false;
              },
              child: ValueListenableBuilder<Iterable<ItemPosition>>(
                valueListenable: _itemPositionsListener.itemPositions,
                builder: (context, positions, _) {
                  return ScrollablePositionedList.builder(
                    itemCount: subtitleList.subtitles.length,
                    itemScrollController: _itemScrollController,
                    itemPositionsListener: _itemPositionsListener,
                    padding: EdgeInsets.symmetric(
                      vertical: widget.compact
                          ? screenHeight * 0.1
                          : screenHeight * 0.34,
                      horizontal: baseUnit * 1.0,
                    ),
                    itemBuilder: (context, index) {
                      final subtitle = subtitleList.subtitles[index];
                      final isActive = currentSubtitle?.subtitle == subtitle;
                      final emphasis = lyricEmphasisForIndex(
                        index: index,
                        isActive: isActive,
                        positions: positions,
                      );

                      return Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: baseUnit * 0.5,
                        ),
                        child: LyricLine(
                          subtitle: subtitle,
                          secondaryText: isActive &&
                                  _viewModel.showDualSubtitles
                              ? _viewModel
                                  .originalSubtitleTextAt(subtitle.index)
                              : null,
                          emphasis: emphasis,
                          onTap: () async {
                            if (widget.lockParentViewSwitch) {
                              widget.onScrollStateChanged(false);
                            }

                            await _viewModel.seek(subtitle.start);

                            if (widget.lockParentViewSwitch) {
                              Future.delayed(
                                const Duration(milliseconds: 500),
                                () {
                                  if (mounted) {
                                    widget.onScrollStateChanged(true);
                                  }
                                },
                              );
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
