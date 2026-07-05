import 'package:lizunemu/common/constants/strings.dart';
import 'package:flutter/material.dart';
import 'package:lizunemu/presentation/viewmodels/player_viewmodel.dart';
import 'package:lizunemu/widgets/player/player_surface_transition.dart';
import 'mini_player_controls.dart';
import 'mini_player_progress.dart';
import 'package:get_it/get_it.dart';
import 'mini_player_cover.dart';

class MiniPlayer extends StatelessWidget {
  static const height = 48.0;
  static const _boxShadow = [
    BoxShadow(
      color: Color(0x1A000000), // Colors.black at 10% opacity
      blurRadius: 4,
      offset: Offset(0, -1),
    ),
  ];

  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = GetIt.I<PlayerViewModel>();
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(createPlayerScreenRoute());
          },
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: _boxShadow,
            ),
            child: Column(
              children: [
                const MiniPlayerProgress(),
                Expanded(
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                        child: Hero(
                          tag: kMiniPlayerCoverHeroTag,
                          flightShuttleBuilder: playerHeroFlightShuttle,
                          child: MiniPlayerCover(
                            coverUrl: viewModel.currentTrackInfo?.coverUrl,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Hero(
                            tag: kPlayerTitleHeroTag,
                            flightShuttleBuilder: playerHeroFlightShuttle,
                            child: Material(
                              color: Colors.transparent,
                              child: Text(
                                viewModel.currentTrackInfo?.title ??
                                    Strings.notPlaying,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const MiniPlayerControls(),
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
