import 'package:lizunemu/core/theme/app_animations.dart';
import 'package:flutter/material.dart';
import 'package:lizunemu/widgets/mini_player/mini_player.dart';
import 'package:lizunemu/widgets/sidebar/sidebar_menu.dart';
import 'package:lizunemu/screens/contents/library_tab_content.dart';
import 'package:lizunemu/screens/contents/search_tab_content.dart';
import 'package:lizunemu/screens/contents/hot_tab_content.dart';
import 'package:provider/provider.dart';
import 'package:lizunemu/presentation/viewmodels/home_viewmodel.dart';
import 'package:lizunemu/presentation/viewmodels/popular_viewmodel.dart';
import 'package:lizunemu/common/constants/strings.dart';

/// MainScreen 是应用的主界面，负责管理底部导航栏和对应的内容页面。
/// 它采用了集中式的状态管理架构，所有子页面的 ViewModel 都在这里初始化和提供。
///
/// 架构说明：
/// 1. ViewModel 初始化：所有页面的 ViewModel 都在 MainScreen 中初始化，确保单一实例
/// 2. 状态提供：通过 MultiProvider 将 ViewModel 提供给整个子树
/// 3. 生命周期管理：负责所有 ViewModel 的创建和销毁
///
/// Eara Milestone D: bottom bar = Library | Search | Hot (3 tabs).
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _pageController = PageController(initialPage: 0);
  int _currentIndex = 0;

  late final HomeViewModel _homeViewModel;
  late final PopularViewModel _popularViewModel;

  static const _pages = [
    LibraryTabContent(),
    SearchTabContent(),
    HotTabContent(),
  ];

  String _pageTitle(int index) {
    switch (index) {
      case 0:
        return Strings.tabLibrary;
      case 1:
        return Strings.tabSearch;
      case 2:
        return Strings.tabHot;
      default:
        return Strings.tabLibrary;
    }
  }

  @override
  void initState() {
    super.initState();
    _homeViewModel = HomeViewModel();
    _popularViewModel = PopularViewModel();
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
    super.dispose();
  }

  PreferredSizeWidget? _buildAppBar(BuildContext context) {
    // Library and Search tabs own their AppBar.
    if (_currentIndex == 0 || _currentIndex == 1) return null;

    final totalCount = _currentIndex == 2
        ? context.select<PopularViewModel, int?>(
            (vm) => vm.pagination?.totalCount,
          )
        : null;

    final title = totalCount != null
        ? '${_pageTitle(_currentIndex)} ($totalCount)'
        : _pageTitle(_currentIndex);

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
                      icon: const Icon(Icons.library_music_outlined),
                      selectedIcon: const Icon(Icons.library_music),
                      label: Strings.tabLibrary,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.search_outlined),
                      selectedIcon: const Icon(Icons.search),
                      label: Strings.tabSearch,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.local_fire_department_outlined),
                      selectedIcon: const Icon(Icons.local_fire_department),
                      label: Strings.tabHot,
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
