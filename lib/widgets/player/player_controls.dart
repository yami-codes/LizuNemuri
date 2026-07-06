import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/presentation/viewmodels/player_viewmodel.dart';

/// Transport row styled after Apple Music Now Playing.
class PlayerControls extends StatelessWidget {
  const PlayerControls({super.key});

  static const _seekStep = Duration(seconds: 10);

  void _seekBy(PlayerViewModel vm, Duration delta) {
    final position = vm.position;
    if (position == null) return;
    var target = position + delta;
    if (target < Duration.zero) target = Duration.zero;
    final duration = vm.duration;
    if (duration != null && target > duration) target = duration;
    vm.seek(target);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = GetIt.I<PlayerViewModel>();
    final cs = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                iconSize: 26,
                color: cs.onSurface.withValues(alpha: 0.85),
                icon: const Icon(Icons.replay_10),
                tooltip: Strings.playerSeekBack10,
                onPressed: () => _seekBy(viewModel, -_seekStep),
              ),
              IconButton(
                iconSize: 36,
                color: cs.onSurface,
                icon: const Icon(Icons.skip_previous_rounded),
                tooltip: Strings.playerPrevTrack,
                onPressed: viewModel.previous,
              ),
              Material(
                color: cs.onSurface,
                shape: const CircleBorder(),
                elevation: 6,
                shadowColor: Colors.black.withValues(alpha: 0.35),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: viewModel.playPause,
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: Icon(
                      viewModel.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 40,
                      color: cs.surface,
                    ),
                  ),
                ),
              ),
              IconButton(
                iconSize: 36,
                color: cs.onSurface,
                icon: const Icon(Icons.skip_next_rounded),
                tooltip: Strings.playerNextTrack,
                onPressed: viewModel.next,
              ),
              IconButton(
                iconSize: 26,
                color: cs.onSurface.withValues(alpha: 0.85),
                icon: const Icon(Icons.forward_10),
                tooltip: Strings.playerSeekForward10,
                onPressed: () => _seekBy(viewModel, _seekStep),
              ),
            ],
          ),
        );
      },
    );
  }
}
