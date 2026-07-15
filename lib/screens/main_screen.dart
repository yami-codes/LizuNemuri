import 'package:lizunemu/core/theme/app_animations.dart';
import 'package:flutter/material.dart';
import 'package:lizunemu/widgets/mini_player/mini_player.dart';
import 'package:lizunemu/widgets/lore/lore_generate_queue_mini_indicator.dart';
import 'package:lizunemu/widgets/translation_queue/translation_queue_mini_indicator.dart';
import 'package:lizunemu/widgets/sidebar/sidebar_menu.dart';
import 'package:lizunemu/screens/contents/favorites_tab_content.dart';
import 'package:lizunemu/screens/contents/home_tab_content.dart';
import 'package:lizunemu/screens/contents/recommend_tab_content.dart';
import 'package:lizunemu/screens/contents/hot_tab_content.dart';
import 'package:provider/provider.dart';
import 'package:lizunemu/presentation/viewmodels/auth_viewmodel.dart';
import 'package:lizunemu/presentation/viewmodels/favorites_viewmodel.dart';
import 'package:lizunemu/presentation/viewmodels/home_viewmodel.dart';
import 'package:lizunemu/presentation/viewmodels/popular_viewmodel.dart';
import 'package:lizunemu/presentation/viewmodels/recommend_viewmodel.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:get_it/get_it.dart';

/// MainScreen is the app root: bottom navigation and tab content.
///
/// Architecture:
/// 1. ViewModels initialized here as singletons per tab
/// 2. MultiProvider exposes them to the subtree
/// 3. Lifecycle: create and dispose ViewModels
///
/// Primary tabs (ASMR.one-style): Favorites | Home | Recommended | Popular.
/// Secondary destinations (Library, Search, DLsite, …) live in [SidebarMenu].
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static const homeTabIndex = 1;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _pageController = PageController(initialPage: MainScreen.homeTabIndex);
  int _currentIndex = MainScreen.homeTabIndex;

  late final HomeViewModel _homeViewModel;
  late final PopularViewModel _popularViewModel;
  late final FavoritesViewModel _favoritesViewModel;
  late final RecommendViewModel _recommendViewModel;

  static const _pages = [
    FavoritesTabContent(),
    HomeTabContent(),
    RecommendTabContent(),
    PopularTabContent(),
  ];

  String _baseTitle(int index) {
    switch (index) {
      case 0:
        return Strings.tabFavorites;
      case 1:
        return Strings.tabHome;
      case 2:
        return Strings.homeTitleRecommend;
      case 3:
        return Strings.homeTitlePopular;
      default:
        return Strings.tabHome;
    }
  }

  @override
  void initState() {
    super.initState();
    _homeViewModel = HomeViewModel();
    _popularViewModel = PopularViewModel();
    final auth = GetIt.I<AuthViewModel>();
    _favoritesViewModel = FavoritesViewModel(auth);
    _recommendViewModel = RecommendViewModel(auth);
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: AppAnimations.medium,
      curve: AppAnimations.standard,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _homeViewModel.dispose();
    _popularViewModel.dispose();
    _favoritesViewModel.dispose();
    _recommendViewModel.dispose();
    super.dispose();
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final totalCount = switch (_currentIndex) {
      0 => context.select<FavoritesViewModel, int?>(
          (vm) => vm.totalCount,
        ),
      1 => context.select<HomeViewModel, int?>(
          (vm) => vm.pagination?.totalCount,
        ),
      2 => context.select<RecommendViewModel, int?>(
          (vm) => vm.pagination?.totalCount,
        ),
      3 => context.select<PopularViewModel, int?>(
          (vm) => vm.pagination?.totalCount,
        ),
      _ => null,
    };

    final title = totalCount != null
        ? '${_baseTitle(_currentIndex)} ($totalCount)'
        : _baseTitle(_currentIndex);

    return AppBar(
      title: Text(title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _homeViewModel),
        ChangeNotifierProvider.value(value: _popularViewModel),
        ChangeNotifierProvider.value(value: _favoritesViewModel),
        ChangeNotifierProvider.value(value: _recommendViewModel),
      ],
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: _buildAppBar(context),
            drawer: const SidebarMenu(),
            body: PageView(
              controller: _pageController,
              physics: const ClampingScrollPhysics(),
              onPageChanged: _onPageChanged,
              children: _pages,
            ),
            bottomNavigationBar: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TranslationQueueMiniIndicator(),
                const LoreGenerateQueueMiniIndicator(),
                const MiniPlayer(),
                NavigationBar(
                  height: 60,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  elevation: 0,
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _onTabTapped,
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.favorite_border),
                      selectedIcon: const Icon(Icons.favorite),
                      label: Strings.tabFavorites,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.home_outlined),
                      selectedIcon: const Icon(Icons.home),
                      label: Strings.tabHome,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.thumb_up_outlined),
                      selectedIcon: const Icon(Icons.thumb_up),
                      label: Strings.tabRecommend,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.trending_up_outlined),
                      selectedIcon: const Icon(Icons.trending_up),
                      label: Strings.tabPopular,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
