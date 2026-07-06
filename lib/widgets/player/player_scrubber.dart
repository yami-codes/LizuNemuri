import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/core/theme/app_text_styles.dart';
import 'package:lizunemu/presentation/viewmodels/player_viewmodel.dart';

/// Apple Music–style thin scrubber with elapsed / remaining time labels.
class PlayerScrubber extends StatelessWidget {
  const PlayerScrubber({super.key});

  String _fmt(Duration? d) {
    if (d == null) return '--:--';
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '$h:${two(m)}:${two(s)}';
    }
    return '${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = GetIt.I<PlayerViewModel>();
    final cs = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final pos = viewModel.position ?? Duration.zero;
        final dur = viewModel.duration ?? Duration.zero;
        final fraction = dur.inMilliseconds <= 0
            ? 0.0
            : (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  activeTrackColor: cs.onSurface,
                  inactiveTrackColor:
                      cs.onSurface.withValues(alpha: 0.22),
                  thumbColor: cs.onSurface,
                  overlayColor: cs.onSurface.withValues(alpha: 0.12),
                ),
                child: Slider(
                  value: fraction,
                  onChanged: dur.inMilliseconds <= 0
                      ? null
                      : (v) => viewModel.seek(
                            Duration(
                              milliseconds: (dur.inMilliseconds * v).round(),
                            ),
                          ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.space8,
                  0,
                  AppSpacing.space8,
                  AppSpacing.space4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _fmt(pos),
                      style: AppTextStyles.caption.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.65),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      '-${_fmt(dur - pos)}',
                      style: AppTextStyles.caption.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.65),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
