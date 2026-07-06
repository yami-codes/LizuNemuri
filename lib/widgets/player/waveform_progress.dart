import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/core/theme/app_text_styles.dart';
import 'package:lizunemu/presentation/viewmodels/player_viewmodel.dart';

/// Waveform progress bar (reference design). Visual replacement for `PlayerProgress`;
/// drag/tap seek and time binding fully reuse `PlayerViewModel` (same seek/position/duration).
///
/// Bar heights are a deterministic motif (streaming clients lack per-track amplitude;
/// same as the reference). Decorative only; played fraction and drag position are real.
/// Played segment uses accent; remainder is neutral.
class WaveformProgress extends StatelessWidget {
  const WaveformProgress({super.key});

  static const double _height = 40;
  static const int _bars = 56;

  String _fmt(Duration? d) {
    if (d == null) return '--:--';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = GetIt.I<PlayerViewModel>();
    final cs = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final posMs = viewModel.position?.inMilliseconds.toDouble() ?? 0;
        final durMs = viewModel.duration?.inMilliseconds.toDouble() ?? 1;
        final fraction =
            durMs <= 0 ? 0.0 : (posMs / durMs).clamp(0.0, 1.0);

        void seekToDx(double dx, double width) {
          if (width <= 0 || durMs <= 0) return;
          final f = (dx / width).clamp(0.0, 1.0);
          viewModel.seek(Duration(milliseconds: (durMs * f).round()));
        }

        return RepaintBoundary(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space4),
            child: Column(
              children: [
                SizedBox(
                  height: _height,
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final width = c.maxWidth;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (d) =>
                            seekToDx(d.localPosition.dx, width),
                        onHorizontalDragUpdate: (d) =>
                            seekToDx(d.localPosition.dx, width),
                        child: CustomPaint(
                          size: Size(width, _height),
                          painter: _WaveformPainter(
                            fraction: fraction,
                            playedColor: cs.primary,
                            restColor:
                                cs.onSurfaceVariant.withValues(alpha: 0.35),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _fmt(viewModel.position),
                        style: AppTextStyles.caption.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        _fmt(viewModel.duration),
                        style: AppTextStyles.caption.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.fraction,
    required this.playedColor,
    required this.restColor,
  });

  final double fraction;
  final Color playedColor;
  final Color restColor;

  @override
  void paint(Canvas canvas, Size size) {
    const n = WaveformProgress._bars;
    final slot = size.width / n;
    final barW = slot * 0.5;
    final cy = size.height / 2;
    final playedX = size.width * fraction;

    final played = Paint()
      ..color = playedColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barW;
    final rest = Paint()
      ..color = restColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barW;

    for (var i = 0; i < n; i++) {
      // Deterministic waveform motif: two sine waves at different frequencies for a stable wave look.
      final t = i.toDouble();
      final amp = 0.18 +
          0.82 *
              ((math.sin(t * 0.9) + 1) / 2 * 0.6 +
                  (math.sin(t * 0.27 + 1.3) + 1) / 2 * 0.4);
      final h = amp * size.height;
      final x = slot * i + slot / 2;
      canvas.drawLine(
        Offset(x, cy - h / 2),
        Offset(x, cy + h / 2),
        x <= playedX ? played : rest,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.fraction != fraction ||
      old.playedColor != playedColor ||
      old.restColor != restColor;
}
