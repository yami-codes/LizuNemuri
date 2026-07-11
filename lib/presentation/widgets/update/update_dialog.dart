import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/data/services/update_service.dart';
import 'package:lizunemu/presentation/viewmodels/update_viewmodel.dart';

/// Update-check dialog: auto-check on open — checking / up to date / new version / error with retry.
class UpdateDialog extends StatelessWidget {
  const UpdateDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<UpdateViewModel>(
      create: (_) =>
          UpdateViewModel(service: GetIt.I<UpdateService>())..check(),
      child: const _UpdateDialogBody(),
    );
  }
}

class _UpdateDialogBody extends StatelessWidget {
  const _UpdateDialogBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<UpdateViewModel>(
      builder: (context, vm, _) {
        if (vm.isChecking) {
          return AlertDialog(
            title: Text(Strings.checkForUpdates),
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 16),
                Text(Strings.updateChecking),
              ],
            ),
          );
        }

        if (vm.error != null) {
          return AlertDialog(
            title: Text(Strings.checkForUpdates),
            content: Text(vm.error!),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(Strings.cancel),
              ),
              FilledButton(
                onPressed: () => vm.check(),
                child: Text(Strings.retry),
              ),
            ],
          );
        }

        final info = vm.latest;
        if (!vm.hasUpdate || info == null) {
          return AlertDialog(
            title: Text(Strings.checkForUpdates),
            content: Text(
              '${Strings.updateUpToDate}'
              '${vm.currentVersion.isEmpty ? '' : '（${Strings.updateCurrentVersionLabel} ${vm.currentVersion}）'}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(Strings.updateOk),
              ),
            ],
          );
        }

        return AlertDialog(
          title: Text('${Strings.updateNewVersionTitle} ${info.version}'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280, maxWidth: 360),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (vm.currentVersion.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        '${Strings.updateCurrentVersionLabel} ${vm.currentVersion}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  Text(
                    info.releaseNotes.isEmpty
                        ? info.tagName
                        : info.releaseNotes,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(Strings.updateLater),
            ),
            FilledButton(
              onPressed: () => _download(context, vm),
              child: Text(Strings.updateDownload),
            ),
          ],
        );
      },
    );
  }

  Future<void> _download(BuildContext context, UpdateViewModel vm) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await vm.openDownload();
    if (ok) {
      navigator.pop();
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(Strings.cannotOpenLink)),
      );
    }
  }
}
