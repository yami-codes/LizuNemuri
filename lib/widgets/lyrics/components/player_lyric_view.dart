import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:get_it/get_it.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/audio/models/subtitle.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/core/subtitle/i_subtitle_service.dart';
import 'package:lizunemu/core/theme/app_animations.dart';
import 'package:lizunemu/presentation/viewmodels/player_viewmodel.dart';
import 'package:lizunemu/widgets/common/accent_pill.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
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
        return proximity.clamp(0.92, 1.0);
      }
      return (proximity * 0.55).clamp(_kMinEmphasis, 0.72);
    }
  }
  return isActive ? 0.92 : _kMinEmphasis;
}

/// Whether the active cue sits near the viewport center (visible + centered).
@visibleForTesting
bool lyricActiveLineIsCentered({
  required int? activeIndex,
  required Iterable<ItemPosition> positions,
  double centerTolerance = 0.15,
}) {
  if (activeIndex == null) return true;
  for (final position in positions) {
    if (position.index != activeIndex) continue;
    final itemCenter =
        (position.itemLeadingEdge + position.itemTrailingEdge) / 2;
    return (itemCenter - 0.5).abs() <= centerTolerance;
  }
  return false;
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
  int? _lastScrolledSubtitleIndex;
  bool _allowAutoScroll = true;

  Timer? _scrollDebounceTimer;
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

  void _enterManualScrollMode() {
    _allowAutoScroll = false;
    _scrollDebounceTimer?.cancel();
    _autoScrollDebounceTimer?.cancel();
  }

  void _scheduleAutoScrollResume() {
    _autoScrollDebounceTimer?.cancel();
    final seconds = _settings.lyricAutoScrollResumeSec;
    _autoScrollDebounceTimer = Timer(Duration(seconds: seconds), () {
      if (!mounted) return;
      _resumeAutoScroll();
    });
  }

  void _resumeAutoScroll({bool forceScroll = true}) {
    _allowAutoScroll = true;
    _lastScrolledSubtitleIndex = null;
    if (!forceScroll) return;
    final current = _subtitleService.currentSubtitleWithState;
    if (current != null) {
      _scrollToCurrentLyric(current);
    }
  }

  void _jumpToCurrentLine() {
    _autoScrollDebounceTimer?.cancel();
    _resumeAutoScroll();
  }

  void _scrollToCurrentLyric(SubtitleWithState current) {
    if (!_itemScrollController.isAttached) return;
    if (!_allowAutoScroll) return;

    if (_lastScrolledSubtitleIndex == current.subtitle.index) return;
    _lastScrolledSubtitleIndex = current.subtitle.index;

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

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is UserScrollNotification &&
        notification.direction != ScrollDirection.idle) {
      if (widget.lockParentViewSwitch) {
        widget.onScrollStateChanged(false);
      }
      _enterManualScrollMode();
    } else if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      if (widget.lockParentViewSwitch) {
        widget.onScrollStateChanged(false);
      }
      _enterManualScrollMode();
    } else if (notification is ScrollEndNotification) {
      if (widget.lockParentViewSwitch) {
        _scrollDebounceTimer?.cancel();
        _scrollDebounceTimer = Timer(const Duration(milliseconds: 1000), () {
          if (mounted) {
            widget.onScrollStateChanged(true);
          }
        });
      }
      _scheduleAutoScrollResume();
    }
    return false;
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

            final activeIndex = currentSubtitle?.subtitle.index;

            return NotificationListener<ScrollNotification>(
              onNotification: _handleScrollNotification,
              child: ValueListenableBuilder<Iterable<ItemPosition>>(
                valueListenable: _itemPositionsListener.itemPositions,
                builder: (context, positions, _) {
                  final showJumpChip = !lyricActiveLineIsCentered(
                    activeIndex: activeIndex,
                    positions: positions,
                  );

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      ScrollablePositionedList.builder(
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
                          final isActive = activeIndex == subtitle.index;
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
                                _enterManualScrollMode();
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
                                _scheduleAutoScrollResume();
                              },
                            ),
                          );
                        },
                      ),
                      if (showJumpChip)
                        Positioned(
                          bottom: widget.compact ? 8 : 16,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: AccentPill(
                              label: Strings.lyricJumpToCurrent,
                              icon: Icons.my_location_outlined,
                              dense: true,
                              onTap: _jumpToCurrentLine,
                            ),
                          ),
                        ),
                    ],
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
