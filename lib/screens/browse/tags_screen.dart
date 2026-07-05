import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/presentation/viewmodels/tags_viewmodel.dart';
import 'package:lizunemu/screens/browse/widgets/browse_search_bar.dart';
import 'package:lizunemu/screens/browse/widgets/browse_grid_item.dart';
import 'package:lizunemu/widgets/common/back_leading.dart';
import 'package:lizunemu/utils/i18n_name_resolver.dart';

class TagsScreen extends StatelessWidget {
  const TagsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TagsViewModel(),
      child: Scaffold(
        appBar: PoppableAppBar(title: Strings.browseAllTags),
        body: Consumer<TagsViewModel>(
          builder: (context, viewModel, _) {
            return Column(
              children: [
                BrowseSearchBar(
                  hintText: Strings.browseSearchTagsHint,
                  onChanged: viewModel.search,
                ),
                Expanded(
                  child: _buildContent(context, viewModel),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, TagsViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(Strings.loadFailed,
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: viewModel.refresh,
              child: Text(Strings.retry),
            ),
          ],
        ),
      );
    }
    if (viewModel.tags.isEmpty) {
      return Center(child: Text(Strings.browseEmptyTags));
    }
    return RefreshIndicator(
      onRefresh: viewModel.refresh,
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: viewModel.tags.length,
        itemBuilder: (context, index) {
          final tag = viewModel.tags[index];
          final displayName = I18nNameResolver.resolve(
            tag.i18n,
            locale: Localizations.localeOf(context),
            fallback: tag.name ?? '',
          );
          final searchName = tag.name ?? '';
          return BrowseGridItem(
            name: displayName,
            count: tag.count ?? 0,
            onTap: searchName.isNotEmpty
                ? () => _onTagTap(context, searchName)
                : null,
          );
        },
      ),
    );
  }

  void _onTagTap(BuildContext context, String tagName) {
    Navigator.pushNamed(
      context,
      '/search',
      arguments: '\$tag:$tagName\$',
    );
  }
}
