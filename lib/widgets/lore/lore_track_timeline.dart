import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/lore/lore_state_projector.dart';
import 'package:lizunemu/core/theme/app_animations.dart';
import 'package:lizunemu/core/theme/app_radius.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/core/theme/app_text_styles.dart';
import 'package:lizunemu/presentation/viewmodels/player_viewmodel.dart';

/// Video-editor style per-track lore timeline with playhead + seekable clips.
class LoreTrackTimeline extends StatefulWidget {
  final LorePlaybackSnapshot snapshot;
  final PlayerViewModel player;

  /// Pixels per second of audio. Higher = more zoom.
  final double pxPerSecond;

  const LoreTrackTimeline({
    super.key,
    required this.snapshot,
    required this.player,
    this.pxPerSecond = 36,
  });

  static const double labelWidth = 96;
  static const double laneHeight = 34;
  static const double rulerHeight = 24;

  @override
  State<LoreTrackTimeline> createState() => _LoreTrackTimelineState();
}

class _LoreTrackTimelineState extends State<LoreTrackTimeline> {
  final ScrollController _hCtrl = ScrollController();
  final ScrollController _vCtrl = ScrollController();
  DateTime _userScrollUntil = DateTime.fromMillisecondsSinceEpoch(0);
  int? _lastFollowMs;
  String? _lastTrackKey;

  LorePlaybackSnapshot get snapshot => widget.snapshot;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _followPlayheadIfNeeded(force: true);
    });
  }

  @override
  void didUpdateWidget(covariant LoreTrackTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    final trackChanged =
        oldWidget.snapshot.resolvedTrackKey != snapshot.resolvedTrackKey;
    final posChanged = oldWidget.snapshot.positionMs != snapshot.positionMs;
    if (trackChanged || posChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _followPlayheadIfNeeded(force: trackChanged);
      });
    }
  }

  @override
  void dispose() {
    _hCtrl.dispose();
    _vCtrl.dispose();
    super.dispose();
  }

  void _onUserScroll() {
    _userScrollUntil = DateTime.now().add(const Duration(seconds: 3));
  }

  void _followPlayheadIfNeeded({bool force = false}) {
    if (!_hCtrl.hasClients) return;
    if (!force && DateTime.now().isBefore(_userScrollUntil)) return;

    final positionMs = snapshot.positionMs;
    final trackKey = snapshot.resolvedTrackKey;
    if (!force &&
        trackKey == _lastTrackKey &&
        _lastFollowMs != null &&
        (positionMs - _lastFollowMs!).abs() < 400) {
      return;
    }
    _lastFollowMs = positionMs;
    _lastTrackKey = trackKey;

    final playX = (positionMs / 1000) * widget.pxPerSecond;
    final viewW = _hCtrl.position.viewportDimension;
    if (viewW <= 0) return;
    final max = _hCtrl.position.maxScrollExtent;
    if (max <= 0) return;

    final leftEdge = _hCtrl.offset;
    final rightEdge = leftEdge + viewW;
    // Re-center when playhead leaves the middle 50% band (or force).
    final inComfort =
        playX >= leftEdge + viewW * 0.25 && playX <= rightEdge - viewW * 0.25;
    if (!force && inComfort) return;

    final target = (playX - viewW * 0.35).clamp(0.0, max);
    if ((target - _hCtrl.offset).abs() < 4) return;

    if (force || (target - _hCtrl.offset).abs() > viewW * 0.6) {
      _hCtrl.jumpTo(target);
    } else {
      _hCtrl.animateTo(
        target,
        duration: AppAnimations.short,
        curve: AppAnimations.smoothScroll,
      );
    }
  }

  void _onPointerScroll(PointerScrollEvent event) {
    if (!_hCtrl.hasClients) return;
    // Trackpad/horizontal delta → pan timeline. Mouse wheel (dy) also pans
    // horizontally when the track is wider than the viewport; otherwise leave
    // dy for the outer vertical scroller (many lanes).
    final hasHOverflow = _hCtrl.position.maxScrollExtent > 0;
    final double? delta;
    if (event.scrollDelta.dx != 0) {
      delta = event.scrollDelta.dx;
    } else if (hasHOverflow && event.scrollDelta.dy != 0) {
      delta = event.scrollDelta.dy;
    } else {
      delta = null;
    }
    if (delta == null) return;
    _onUserScroll();
    final next =
        (_hCtrl.offset + delta).clamp(0.0, _hCtrl.position.maxScrollExtent);
    _hCtrl.jumpTo(next);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final spans = snapshot.trackSpans;
    if (spans.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space8),
        child: Text(
          Strings.loreNoEventsYet,
          style: AppTextStyles.caption.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final endMs = snapshot.trackTimelineEndMs.clamp(1000, 1 << 30);
    final trackWidth = (endMs / 1000) * widget.pxPerSecond;
    final lanes = _laneKeys(spans);
    final playX = (snapshot.positionMs / 1000) * widget.pxPerSecond;
    final contentHeight = LoreTrackTimeline.rulerHeight +
        lanes.length * LoreTrackTimeline.laneHeight +
        AppSpacing.space8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                snapshot.trackTitle ?? Strings.lorePlayerTimeline,
                style: AppTextStyles.labelMedium.copyWith(
                  color: scheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _fmt(snapshot.positionMs),
              style: AppTextStyles.caption.copyWith(
                color: scheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space8),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: AppRadius.mdAll,
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: ClipRRect(
              borderRadius: AppRadius.mdAll,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bodyH = math.max(contentHeight, constraints.maxHeight);
                  return NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n is ScrollStartNotification &&
                          n.dragDetails != null) {
                        _onUserScroll();
                      }
                      if (n is UserScrollNotification) {
                        _onUserScroll();
                      }
                      return false;
                    },
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        scrollbars: true,
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                          PointerDeviceKind.trackpad,
                          PointerDeviceKind.stylus,
                        },
                      ),
                      child: Scrollbar(
                        controller: _vCtrl,
                        thumbVisibility: !kIsWeb,
                        child: SingleChildScrollView(
                          controller: _vCtrl,
                          primary: false,
                          child: SizedBox(
                            height: bodyH,
                            child: Listener(
                              onPointerSignal: (signal) {
                                if (signal is PointerScrollEvent) {
                                  _onPointerScroll(signal);
                                }
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: LoreTrackTimeline.labelWidth,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        SizedBox(
                                          height:
                                              LoreTrackTimeline.rulerHeight,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                left: AppSpacing.space8,
                                              ),
                                              child: Text(
                                                Strings.lorePlayerParamsTitle,
                                                style: AppTextStyles.caption
                                                    .copyWith(
                                                  color: scheme
                                                      .onSurfaceVariant,
                                                  fontSize: 10,
                                                ),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        ),
                                        for (final key in lanes)
                                          SizedBox(
                                            height:
                                                LoreTrackTimeline.laneHeight,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: AppSpacing.space8,
                                              ),
                                              child: Align(
                                                alignment:
                                                    Alignment.centerLeft,
                                                child: Text(
                                                  spans
                                                      .firstWhere(
                                                          (s) => s.key == key)
                                                      .label,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: AppTextStyles.caption
                                                      .copyWith(
                                                    color: snapshot.activeSpans
                                                            .any((s) =>
                                                                s.key == key)
                                                        ? scheme.primary
                                                        : scheme.onSurface,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  VerticalDivider(
                                    width: 1,
                                    color: scheme.outlineVariant
                                        .withValues(alpha: 0.4),
                                  ),
                                  Expanded(
                                    child: Scrollbar(
                                      controller: _hCtrl,
                                      thumbVisibility: !kIsWeb,
                                      notificationPredicate: (n) =>
                                          n.depth == 0,
                                      child: SingleChildScrollView(
                                        controller: _hCtrl,
                                        scrollDirection: Axis.horizontal,
                                        primary: false,
                                        physics:
                                            const ClampingScrollPhysics(),
                                        child: SizedBox(
                                          width: math.max(
                                            trackWidth + AppSpacing.space24,
                                            constraints.maxWidth -
                                                LoreTrackTimeline.labelWidth,
                                          ),
                                          height: bodyH,
                                          child: Stack(
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  _Ruler(
                                                    width: trackWidth,
                                                    endMs: endMs,
                                                    pxPerSecond:
                                                        widget.pxPerSecond,
                                                  ),
                                                  ...lanes.map((key) {
                                                    final laneSpans = spans
                                                        .where((s) =>
                                                            s.key == key)
                                                        .toList();
                                                    return _Lane(
                                                      width: trackWidth,
                                                      spans: laneSpans,
                                                      pxPerSecond:
                                                          widget.pxPerSecond,
                                                      activeIds: snapshot
                                                          .activeSpans
                                                          .where((s) =>
                                                              s.key == key)
                                                          .map((s) =>
                                                              s.eventId)
                                                          .toSet(),
                                                      onSeek: (ms) => widget
                                                          .player
                                                          .seek(Duration(
                                                              milliseconds:
                                                                  ms)),
                                                    );
                                                  }),
                                                ],
                                              ),
                                              Positioned(
                                                left: playX,
                                                top: 0,
                                                bottom: 0,
                                                child: IgnorePointer(
                                                  child: Container(
                                                    width: 2,
                                                    color: scheme.primary,
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                left: playX - 5,
                                                top: 0,
                                                child: IgnorePointer(
                                                  child: CustomPaint(
                                                    size: const Size(12, 10),
                                                    painter:
                                                        _PlayheadCapPainter(
                                                      color: scheme.primary,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<String> _laneKeys(List<LoreParamSpan> spans) {
    final seen = <String>{};
    final out = <String>[];
    for (final s in spans) {
      if (seen.add(s.key)) out.add(s.key);
    }
    // Lore tab should list every param lane (secrets included) — no hard cap.
    return out;
  }

  String _fmt(int ms) {
    final m = ms ~/ 60000;
    final s = (ms % 60000) ~/ 1000;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _PlayheadCapPainter extends CustomPainter {
  final Color color;
  _PlayheadCapPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PlayheadCapPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _Ruler extends StatelessWidget {
  final double width;
  final int endMs;
  final double pxPerSecond;

  const _Ruler({
    required this.width,
    required this.endMs,
    required this.pxPerSecond,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final marks = <Widget>[];
    final stepSec = endMs > 600000 ? 60 : (endMs > 180000 ? 30 : 10);
    for (var s = 0; s * 1000 <= endMs; s += stepSec) {
      final x = s * pxPerSecond;
      marks.add(
        Positioned(
          left: x,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 1,
                height: 6,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              Text(
                _fmt(s * 1000),
                style: AppTextStyles.caption.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      height: LoreTrackTimeline.rulerHeight,
      width: width,
      child: Stack(children: marks),
    );
  }

  String _fmt(int ms) {
    final m = ms ~/ 60000;
    final s = (ms % 60000) ~/ 1000;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _Lane extends StatelessWidget {
  final double width;
  final List<LoreParamSpan> spans;
  final double pxPerSecond;
  final Set<String> activeIds;
  final ValueChanged<int> onSeek;

  const _Lane({
    required this.width,
    required this.spans,
    required this.pxPerSecond,
    required this.activeIds,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: LoreTrackTimeline.laneHeight,
      width: width,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.35),
                  borderRadius: AppRadius.smAll,
                ),
              ),
            ),
          ),
          ...spans.map((span) {
            final left = (span.startMs / 1000) * pxPerSecond;
            final rawW =
                ((span.endMs - span.startMs) / 1000) * pxPerSecond;
            final w = rawW.clamp(8.0, width);
            final active = activeIds.contains(span.eventId);
            return Positioned(
              left: left,
              width: w,
              top: 5,
              bottom: 5,
              child: Tooltip(
                message: '${span.title}\n${span.from} → ${span.to}',
                child: Material(
                  color: active
                      ? scheme.primary
                      : scheme.primary.withValues(alpha: 0.42),
                  borderRadius: AppRadius.smAll,
                  child: InkWell(
                    borderRadius: AppRadius.smAll,
                    onTap: () => onSeek(span.startMs),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          span.numeric
                              ? '${_n(span.from)}→${_n(span.to)}'
                              : '${span.to}',
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: AppTextStyles.caption.copyWith(
                            color: active
                                ? scheme.onPrimary
                                : scheme.onPrimary.withValues(alpha: 0.92),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _n(dynamic v) {
    if (v is num) return v.round().toString();
    return '$v';
  }
}

/// Compact param chip for the lore panel header strip.
class LoreParamCompactChip extends StatelessWidget {
  final String label;
  final String valueText;
  final double? gauge;
  final Color? accent;
  final bool active;
  final bool pulse;

  const LoreParamCompactChip({
    super.key,
    required this.label,
    required this.valueText,
    this.gauge,
    this.accent,
    this.active = false,
    this.pulse = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: AppAnimations.short,
      curve: AppAnimations.standard,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space8,
        vertical: AppSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: pulse
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: AppRadius.smAll,
        border: Border.all(
          color: active || pulse
              ? scheme.primary
              : scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
          Text(
            valueText,
            style: AppTextStyles.labelMedium.copyWith(
              color: active ? scheme.primary : scheme.onSurface,
            ),
          ),
          if (gauge != null) ...[
            const SizedBox(height: 2),
            SizedBox(
              width: 72,
              child: ClipRRect(
                borderRadius: AppRadius.fullAll,
                child: LinearProgressIndicator(
                  value: (gauge! / 100).clamp(0.0, 1.0),
                  minHeight: 3,
                  color: accent ?? scheme.primary,
                  backgroundColor: scheme.surface,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Param row that pulses when a discrete status change fires.
class LoreParamPulseTile extends StatefulWidget {
  final String label;
  final String module;
  final String valueText;
  final double? gauge;
  final Color? accent;
  final bool pulse;

  const LoreParamPulseTile({
    super.key,
    required this.label,
    required this.module,
    required this.valueText,
    this.gauge,
    this.accent,
    this.pulse = false,
  });

  @override
  State<LoreParamPulseTile> createState() => _LoreParamPulseTileState();
}

class _LoreParamPulseTileState extends State<LoreParamPulseTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppAnimations.medium,
    );
    if (widget.pulse) _ctrl.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant LoreParamPulseTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse && !oldWidget.pulse) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = Curves.easeOut.transform(_ctrl.value);
        final glow = Color.lerp(
          Colors.transparent,
          scheme.primary.withValues(alpha: 0.28),
          1 - t,
        )!;
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.space8),
          padding: const EdgeInsets.all(AppSpacing.space8),
          decoration: BoxDecoration(
            color: glow,
            borderRadius: AppRadius.mdAll,
            border: Border.all(
              color: Color.lerp(
                scheme.outlineVariant.withValues(alpha: 0),
                scheme.primary,
                1 - t,
              )!,
            ),
          ),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Text(
                widget.valueText,
                style: AppTextStyles.labelMedium.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (widget.gauge != null) ...[
            const SizedBox(height: AppSpacing.space4),
            ClipRRect(
              borderRadius: AppRadius.fullAll,
              child: LinearProgressIndicator(
                value: (widget.gauge! / 100).clamp(0.0, 1.0),
                minHeight: 6,
                color: widget.accent ?? scheme.primary,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
