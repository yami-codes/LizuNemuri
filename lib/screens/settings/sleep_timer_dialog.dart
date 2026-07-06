import 'package:flutter/material.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/platform/sleep_timer_controller.dart';

/// Sleep timer radio dialog: off / 15 / 30 / 45 / 60 / 90 minutes.
/// Selection writes [SleepTimerController] and closes (no confirm button).
class SleepTimerDialog extends StatelessWidget {
  final SleepTimerController controller;

  const SleepTimerDialog({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final current = controller.minutes;

    Widget option(String label, int? minutes) {
      final selected = current == minutes;
      return ListTile(
        title: Text(label),
        trailing: selected ? Icon(Icons.check, color: cs.primary) : null,
        onTap: () {
          controller.setMinutes(minutes);
          Navigator.pop(context);
        },
      );
    }

    return AlertDialog(
      title: Text(Strings.sleepTimer),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            option(Strings.sleepTimerOff, null),
            for (final m in SleepTimerController.presetMinutes)
              option(Strings.sleepTimerMinutes(m), m),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(Strings.cancel),
        ),
      ],
    );
  }
}
