import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xuro/common/constants/strings.dart';
import 'package:xuro/core/image/cache/image_cache_manager.dart';
import 'package:xuro/core/theme/app_radius.dart';
import 'package:xuro/core/theme/app_spacing.dart';
import 'package:xuro/core/theme/app_text_styles.dart';
import 'package:xuro/presentation/viewmodels/dlsite_library_viewmodel.dart';
import 'package:xuro/screens/dlsite/dlsite_login_screen.dart';
import 'package:xuro/utils/user_facing_error.dart';
import 'package:xuro/widgets/common/app_search_field.dart';
import 'package:xuro/widgets/common/back_leading.dart';

class DlsiteLibraryScreen extends StatelessWidget {
  const DlsiteLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DlsiteLibraryViewModel()..load(),
      child: const _DlsiteLibraryBody(),
    );
  }
}

class _DlsiteLibraryBody extends StatefulWidget {
  const _DlsiteLibraryBody();

  @override
  State<_DlsiteLibraryBody> createState() => _DlsiteLibraryBodyState();
}

class _DlsiteLibraryBodyState extends State<_DlsiteLibraryBody> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DlsiteLibraryViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          appBar: AppBar(
            leading: const BackLeading(),
            automaticallyImplyLeading: false,
            title: Text(Strings.dlsiteLibraryTitle),
            actions: [
              if (vm.isLoggedIn)
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: Strings.dlsiteLogout,
                  onPressed: () => vm.logout(),
                ),
              IconButton(
                icon: const Icon(Icons.login),
                tooltip: Strings.dlsiteLoginTitle,
                onPressed: () async {
                  final ok = await Navigator.of(context).push<bool>(
                    CupertinoPageRoute(
                      builder: (_) => const DlsiteLoginScreen(),
                    ),
                  );
                  if (ok == true && context.mounted) {
                    await context.read<DlsiteLibraryViewModel>().load();
                  }
                },
              ),
            ],
          ),
          body: _buildBody(context, vm),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, DlsiteLibraryViewModel vm) {
    if (!vm.isLoggedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Strings.dlsiteLoginRequired,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.space16),
              FilledButton(
                onPressed: () async {
                  final ok = await Navigator.of(context).push<bool>(
                    CupertinoPageRoute(
                      builder: (_) => const DlsiteLoginScreen(),
                    ),
                  );
                  if (ok == true && context.mounted) {
                    await context.read<DlsiteLibraryViewModel>().load();
                  }
                },
                child: Text(Strings.dlsiteLoginTitle),
              ),
            ],
          ),
        ),
      );
    }

    if (vm.isLoading && vm.albums.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.error != null && vm.albums.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(vm.error!),
            const SizedBox(height: AppSpacing.space12),
            FilledButton(
              onPressed: vm.refresh,
              child: Text(Strings.retry),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: vm.refresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageMobile,
          AppSpacing.space12,
          AppSpacing.pageMobile,
          AppSpacing.space64,
        ),
        itemCount: vm.albums.length + 1,
        separatorBuilder: (_, index) {
          if (index == 0) return const SizedBox(height: AppSpacing.space12);
          return const SizedBox(height: AppSpacing.space8);
        },
        itemBuilder: (context, index) {
          if (index == 0) {
            return AppSearchField(
              controller: _searchController,
              hintText: Strings.searchInputHint,
              onChanged: vm.setQuery,
            );
          }
          final album = vm.albums[index - 1];
          final cs = Theme.of(context).colorScheme;
          return Material(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: AppRadius.mdAll,
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
              leading: ClipRRect(
                borderRadius: AppRadius.smAll,
                child: album.coverUrl != null && album.coverUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: album.coverUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        cacheManager: ImageCacheManager.instance,
                        errorWidget: (_, __, ___) => _placeholder(cs),
                      )
                    : _placeholder(cs),
              ),
              title: Text(
                album.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleMedium,
              ),
              subtitle: Text('${album.workno} · ${album.subtitle}'),
              trailing: IconButton(
                icon: const Icon(Icons.play_circle_fill),
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

  Widget _placeholder(ColorScheme cs) {
    return Container(
      width: 48,
      height: 48,
      color: cs.primaryContainer,
      child: Icon(Icons.album_outlined, color: cs.onPrimaryContainer),
    );
  }
}
