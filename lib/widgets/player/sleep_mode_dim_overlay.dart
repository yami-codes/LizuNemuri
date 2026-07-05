import 'package:flutter/material.dart';
import 'package:xuro/core/platform/sleep_timer_controller.dart';
import 'package:xuro/core/theme/app_animations.dart';

/// Pass-through dim veil for sleep-timer "sleep mode" on the player screen.
class SleepModeDimOverlay extends StatelessWidget {
  final SleepTimerController controller;

  const SleepModeDimOverlay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final opacity = controller.dimOpacity;
        if (opacity <= 0) return const SizedBox.shrink();
        return Positioned.fill(
          child: IgnorePointer(
            child: AnimatedContainer(
              duration: AppAnimations.medium,
              curve: AppAnimations.standard,
              color: Colors.black.withValues(alpha: opacity),
            ),
          ),
        );
      },
    );
  }
}
