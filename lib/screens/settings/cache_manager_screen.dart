import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/presentation/viewmodels/settings/cache_manager_viewmodel.dart';

class CacheManagerScreen extends StatelessWidget {
  const CacheManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CacheManagerViewModel()..loadCacheSize(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(Strings.cacheManager),
        ),
        body: Consumer<CacheManagerViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (viewModel.error != null) {
              return Center(
                child: Text(
                  viewModel.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              );
            }

            return ListView(
              children: [
                // 音频缓存
                ListTile(
                  title: Text(Strings.audioCache),
                  subtitle: Text(viewModel.audioCacheSizeFormatted),
                  trailing: TextButton(
                    onPressed: viewModel.isLoading
                      ? null
                      : () => viewModel.clearAudioCache(),
                    child: Text(Strings.cacheClean),
                  ),
                ),
                const Divider(),
                
                // 字幕缓存
                ListTile(
                  title: Text(Strings.subtitleCache),
                  subtitle: Text(viewModel.subtitleCacheSizeFormatted),
                  trailing: TextButton(
                    onPressed: viewModel.isLoading
                      ? null
                      : () => viewModel.clearSubtitleCache(),
                    child: Text(Strings.cacheClean),
                  ),
                ),
                const Divider(),

                // 图片缓存
                ListTile(
                  title: Text(Strings.imageCache),
                  subtitle: Text(viewModel.imageCacheSizeFormatted),
                  trailing: TextButton(
                    onPressed: viewModel.isLoading
                      ? null
                      : () => viewModel.clearImageCache(),
                    child: Text(Strings.cacheClean),
                  ),
                ),
                const Divider(),

                // 总缓存大小
                ListTile(
                  title: Text(Strings.totalCacheSize),
                  subtitle: Text(viewModel.totalCacheSizeFormatted),
                  trailing: TextButton(
                    onPressed: viewModel.isLoading
                      ? null
                      : () => viewModel.clearAllCache(),
                    child: Text(Strings.cacheCleanAll),
                  ),
                ),
                const Divider(),
                
                // 缓存说明
                ListTile(
                  title: Text(Strings.cacheExplainTitle),
                  subtitle: Text(Strings.cacheExplainBody),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
} 