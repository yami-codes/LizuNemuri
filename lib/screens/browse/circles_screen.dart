import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/presentation/viewmodels/circles_viewmodel.dart';
import 'package:lizunemu/screens/browse/widgets/browse_search_bar.dart';
import 'package:lizunemu/screens/browse/widgets/browse_grid_item.dart';
import 'package:lizunemu/widgets/common/back_leading.dart';
import 'package:lizunemu/utils/i18n_name_resolver.dart';

class CirclesScreen extends StatelessWidget {
  const CirclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CirclesViewModel(),
      child: Scaffold(
        appBar: PoppableAppBar(title: Strings.browseAllCircles),
        body: Consumer<CirclesViewModel>(
          builder: (context, viewModel, _) {
            return Column(
              children: [
                BrowseSearchBar(
                  hintText: Strings.browseSearchCirclesHint,
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

  Widget _buildContent(BuildContext context, CirclesViewModel viewModel) {
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
    if (viewModel.circles.isEmpty) {
      return Center(child: Text(Strings.browseEmptyCircles));
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
        itemCount: viewModel.circles.length,
        itemBuilder: (context, index) {
          final circle = viewModel.circles[index];
          final name = I18nNameResolver.resolve(
            circle.i18n,
            locale: Localizations.localeOf(context),
            fallback: circle.name ?? '',
          );
          return BrowseGridItem(
            name: name,
            count: circle.count ?? 0,
            onTap: name.isNotEmpty
                ? () => _onCircleTap(context, name)
                : null,
          );
        },
      ),
    );
  }

  void _onCircleTap(BuildContext context, String circleName) {
    Navigator.pushNamed(
      context,
      '/search',
      arguments: '\$circle:$circleName\$',
    );
  }
}
