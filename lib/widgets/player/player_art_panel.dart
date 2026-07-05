import 'package:flutter/material.dart';
import 'package:xuro/common/constants/strings.dart';
import 'package:xuro/core/theme/app_spacing.dart';
import 'package:xuro/presentation/viewmodels/player_viewmodel.dart';
import 'package:xuro/widgets/player/circular_cover.dart';
import 'package:xuro/widgets/player/player_work_info.dart';
import 'package:xuro/widgets/player/player_immersive_scope.dart';
import 'package:xuro/widgets/player/player_surface_transition.dart';

/// Cover art, track title, and work metadata column for the player.
class PlayerArtPanel extends StatelessWidget {
  final PlayerViewModel viewModel;
  final double coverSize;

  const PlayerArtPanel({
    super.key,
    required this.viewModel,
    required this.coverSize,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final immersive = PlayerImmersiveScope.maybeOf(context);
        final ringColor = immersive?.enabled == true
            ? immersive!.accentStrong.withValues(alpha: 0.45)
            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.25);

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: coverSize,
              height: coverSize,
              child: Hero(
                tag: kMiniPlayerCoverHeroTag,
                flightShuttleBuilder: playerHeroFlightShuttle,
                child: CircularCover(
                  coverUrl: viewModel.currentTrackInfo?.coverUrl,
                  maxSize: coverSize,
                  ringColor: ringColor,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space24),
              child: Column(
                children: [
                  Hero(
                    tag: kPlayerTitleHeroTag,
                    flightShuttleBuilder: playerHeroFlightShuttle,
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        viewModel.currentTrackInfo?.title ?? Strings.notPlaying,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (viewModel.currentTrackInfo?.artist != null) ...[
                    const SizedBox(height: AppSpacing.space8),
                    Text(
                      viewModel.currentTrackInfo!.artist,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space16),
            PlayerWorkInfo(context: viewModel.currentContext),
          ],
        );
      },
    );
  }
}
