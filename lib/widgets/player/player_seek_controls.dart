import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/presentation/viewmodels/player_viewmodel.dart';

class PlayerSeekControls extends StatelessWidget {
  const PlayerSeekControls({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = GetIt.I<PlayerViewModel>();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Rewind 30s
        IconButton(
          icon: const Icon(Icons.replay_30),
          iconSize: 24,
          onPressed: () {
            final position = viewModel.position;
            if (position != null) {
              viewModel.seek(position - const Duration(seconds: 30));
            }
          },
        ),
        // Rewind 5s
        IconButton(
          icon: const Icon(Icons.replay_5),
          iconSize: 24,
          onPressed: () {
            final position = viewModel.position;
            if (position != null) {
              viewModel.seek(position - const Duration(seconds: 5));
            }
          },
        ),
        // Previous lyric line
        IconButton(
          icon: const Icon(Icons.skip_previous),
          iconSize: 24,
          onPressed: () => viewModel.seekToPreviousLyric(),
        ),
        // Next lyric line
        IconButton(
          icon: const Icon(Icons.skip_next),
          iconSize: 24,
          onPressed: () => viewModel.seekToNextLyric(),
        ),
        // Forward 5s
        IconButton(
          icon: const Icon(Icons.forward_5),
          iconSize: 24,
          onPressed: () {
            final position = viewModel.position;
            if (position != null) {
              viewModel.seek(position + const Duration(seconds: 5));
            }
          },
        ),
        // Forward 30s
        IconButton(
          icon: const Icon(Icons.forward_30),
          iconSize: 24,
          onPressed: () {
            final position = viewModel.position;
            if (position != null) {
              viewModel.seek(position + const Duration(seconds: 30));
            }
          },
        ),
      ],
    );
  }
} 