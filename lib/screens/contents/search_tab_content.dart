import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xuro/presentation/viewmodels/search_viewmodel.dart';
import 'package:xuro/screens/search_screen.dart';

/// Eara-style Search tab — embeds [SearchScreenContent] with its own scaffold.
///
/// Outer [MainScreen] hides its AppBar on this tab so the search field and
/// chips are not duplicated.
class SearchTabContent extends StatefulWidget {
  const SearchTabContent({super.key});

  @override
  State<SearchTabContent> createState() => _SearchTabContentState();
}

class _SearchTabContentState extends State<SearchTabContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ChangeNotifierProvider(
      create: (_) => SearchViewModel(),
      child: const SearchScreenContent(),
    );
  }
}
