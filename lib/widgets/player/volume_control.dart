import 'package:flutter/material.dart';
import 'package:xuro/common/constants/strings.dart';
import 'package:xuro/core/theme/app_spacing.dart';
import 'package:xuro/presentation/viewmodels/player_viewmodel.dart';

/// App-bar volume control — icon opens a slider dialog.
class PlayerVolumeButton extends StatelessWidget {
  final PlayerViewModel viewModel;

  const PlayerVolumeButton({super.key, required this.viewModel});

  IconData _iconForVolume(double volume) {
    if (volume <= 0) return Icons.volume_off_outlined;
    if (volume < 0.5) return Icons.volume_down_outlined;
    return Icons.volume_up_outlined;
  }

  Future<void> _openVolumeDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) {
            final volume = viewModel.volume;
            final pct = (volume * 100).round();
            return AlertDialog(
              title: Text(Strings.playerVolume),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(_iconForVolume(volume)),
                      const SizedBox(width: AppSpacing.space12),
                      Expanded(
                        child: Slider(
                          value: volume,
                          onChanged: (v) => viewModel.setVolume(v),
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '$pct%',
                          textAlign: TextAlign.end,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                    ],
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
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return IconButton(
          icon: Icon(_iconForVolume(viewModel.volume)),
          tooltip: Strings.playerVolume,
          onPressed: () => _openVolumeDialog(context),
        );
      },
    );
  }
}
