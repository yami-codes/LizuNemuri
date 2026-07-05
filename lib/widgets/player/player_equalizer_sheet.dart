import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/audio/effects/audio_effects_controller.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/core/theme/app_text_styles.dart';

/// Android graphic EQ band sheet (just_audio AndroidEqualizer).
class PlayerEqualizerSheet extends StatefulWidget {
  const PlayerEqualizerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const PlayerEqualizerSheet(),
    );
  }

  @override
  State<PlayerEqualizerSheet> createState() => _PlayerEqualizerSheetState();
}

class _PlayerEqualizerSheetState extends State<PlayerEqualizerSheet> {
  Future<AndroidEqualizerParameters?>? _paramsFuture;

  @override
  void initState() {
    super.initState();
    _paramsFuture = context.read<AudioEffectsController>().loadParameters();
  }

  @override
  Widget build(BuildContext context) {
    final fx = context.watch<AudioEffectsController>();
    if (!fx.isSupported) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.space24),
        child: Text(
          Strings.equalizerUnsupported,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pageMobile,
        AppSpacing.space8,
        AppSpacing.pageMobile,
        MediaQuery.paddingOf(context).bottom + AppSpacing.space24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            Strings.equalizerTitle,
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            Strings.equalizerDesc,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.space12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(Strings.equalizerEnable),
            value: fx.enabled,
            onChanged: (v) => fx.setEnabled(v),
          ),
          const SizedBox(height: AppSpacing.space8),
          FutureBuilder<AndroidEqualizerParameters?>(
            future: _paramsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(AppSpacing.space24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final params = snapshot.data!;
              return Column(
                children: params.bands.map((band) {
                  return StreamBuilder<double>(
                    stream: band.gainStream,
                    initialData: band.gain,
                    builder: (context, snap) {
                      final gain = (snap.data ?? band.gain).clamp(
                        params.minDecibels,
                        params.maxDecibels,
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${band.centerFrequency.round()} Hz',
                            style: AppTextStyles.labelMedium,
                          ),
                          Slider(
                            value: gain,
                            min: params.minDecibels,
                            max: params.maxDecibels,
                            onChanged: fx.enabled
                                ? (v) => band.setGain(v)
                                : null,
                          ),
                        ],
                      );
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
