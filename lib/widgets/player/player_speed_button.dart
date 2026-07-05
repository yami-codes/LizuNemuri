import 'package:flutter/material.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/settings/playback_speed_presets.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/presentation/viewmodels/player_viewmodel.dart';

/// App-bar playback speed control — opens a preset picker dialog.
class PlayerSpeedButton extends StatelessWidget {
  final PlayerViewModel viewModel;

  const PlayerSpeedButton({super.key, required this.viewModel});

  String _label(double speed) => Strings.playerSpeedLabel(speed);

  Future<void> _openSpeedDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) {
            final current = viewModel.playbackSpeed;
            return AlertDialog(
              title: Text(Strings.playerSpeed),
              content: Wrap(
                spacing: AppSpacing.space8,
                runSpacing: AppSpacing.space8,
                children: [
                  for (final speed in PlaybackSpeedPresets.values)
                    ChoiceChip(
                      label: Text(_label(speed)),
                      selected: PlaybackSpeedPresets.isSelected(current, speed),
                      onSelected: (_) async {
                        await viewModel.setPlaybackSpeed(speed);
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                      },
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(Strings.confirm),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final speed = viewModel.playbackSpeed;
        final isNormal =
            PlaybackSpeedPresets.isSelected(speed, PlaybackSpeedPresets.defaultSpeed);
        return IconButton(
          icon: Text(
            _label(speed),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isNormal ? null : cs.primary,
                ),
          ),
          tooltip: Strings.playerSpeed,
          onPressed: () => _openSpeedDialog(context),
        );
      },
    );
  }
}
