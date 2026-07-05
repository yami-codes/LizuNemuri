import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/theme/app_radius.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/core/theme/app_text_styles.dart';
import 'package:lizunemu/presentation/viewmodels/local_library_viewmodel.dart';
import 'package:lizunemu/utils/user_facing_error.dart';

/// Local folder library — scan roots + album list (Milestone F).
class LocalLibraryContent extends StatefulWidget {
  const LocalLibraryContent({super.key});

  @override
  State<LocalLibraryContent> createState() => _LocalLibraryContentState();
}

class _LocalLibraryContentState extends State<LocalLibraryContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocalLibraryViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalLibraryViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading && vm.albums.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            if (vm.isScanning)
              const LinearProgressIndicator(minHeight: 2),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageMobile,
                AppSpacing.space8,
                AppSpacing.pageMobile,
                AppSpacing.space4,
              ),
              child: Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: vm.isScanning ? null : vm.pickAndAddFolder,
                    icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                    label: Text(Strings.localLibraryAddFolder),
                  ),
                  const SizedBox(width: AppSpacing.space8),
                  OutlinedButton.icon(
                    onPressed: vm.isScanning || vm.scanRoots.isEmpty
                        ? null
                        : vm.scan,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(Strings.localLibraryScan),
                  ),
                ],
              ),
            ),
            if (vm.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageMobile,
                ),
                child: Text(
                  vm.error!,
                  style: AppTextStyles.caption.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            Expanded(child: _buildBody(context, vm)),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, LocalLibraryViewModel vm) {
    if (vm.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space24),
          child: Text(
            Strings.localLibraryEmpty,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    if (vm.albums.isEmpty && vm.scanRoots.isNotEmpty) {
      return Center(
        child: Text(
          Strings.localLibraryNoAlbums,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: vm.refresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageMobile,
          AppSpacing.space8,
          AppSpacing.pageMobile,
          AppSpacing.space64,
        ),
        itemCount: vm.albums.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.space8),
        itemBuilder: (context, index) {
          final album = vm.albums[index];
          final cs = Theme.of(context).colorScheme;
          return Material(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: AppRadius.mdAll,
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
              leading: CircleAvatar(
                backgroundColor: cs.primaryContainer,
                child: Icon(Icons.album_outlined, color: cs.onPrimaryContainer),
              ),
              title: Text(
                album.title,
                style: AppTextStyles.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(vm.subtitleFor(album)),
              trailing: IconButton(
                icon: const Icon(Icons.play_circle_fill),
                tooltip: Strings.downloadsPlayA11y,
                onPressed: () async {
                  try {
                    await vm.playAlbum(album);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          Strings.playFailed(userFacingError(e)),
                        ),
                      ),
                    );
                  }
                },
              ),
              onTap: () async {
                try {
                  await vm.playAlbum(album);
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(Strings.playFailed(userFacingError(e))),
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}
