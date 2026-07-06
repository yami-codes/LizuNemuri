import 'package:flutter/material.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/presentation/viewmodels/player_viewmodel.dart';
import 'package:lizunemu/widgets/player/circular_cover.dart';
import 'package:lizunemu/widgets/player/player_work_info.dart';
import 'package:lizunemu/widgets/player/player_immersive_scope.dart';
import 'package:lizunemu/widgets/player/player_surface_transition.dart';

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
                  albumArtStyle: true,
                  isPlaying: viewModel.isPlaying,
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
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontWeight: FontWeight.w500,
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
