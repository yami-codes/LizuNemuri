import 'package:xuro/common/constants/strings.dart';
import 'package:xuro/data/models/works/work.dart';
import 'package:flutter/foundation.dart';
import 'package:xuro/data/models/my_lists/my_playlists/playlist.dart';
import 'package:xuro/data/models/my_lists/my_playlists/pagination.dart';
import 'package:xuro/data/services/api_service.dart';
import 'package:xuro/utils/user_facing_error.dart';
import 'package:xuro/utils/logger.dart';
import 'package:get_it/get_it.dart';
import 'package:xuro/common/constants/log_strings.dart';

class PlaylistsViewModel extends ChangeNotifier {
  final ApiService _apiService = GetIt.I<ApiService>();
  
  List<Playlist>? _playlists;
  bool _isLoading = false;
  String? _error;
  Pagination? _pagination;
  int _currentPage = 1;

  // 添加视图切换相关状态
  Playlist? _selectedPlaylist;
  List<Work> _playlistWorks = [];
  bool _loadingWorks = false;
  String? _worksError;
  Pagination? _worksPagination;
  int _worksCurrentPage = 1;

  // Getters
  List<Playlist> get playlists => _playlists ?? [];
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int? get totalPages => _pagination?.totalCount != null && _pagination?.pageSize != null
      ? (_pagination!.totalCount! / _pagination!.pageSize!).ceil()
      : null;
  Playlist? get selectedPlaylist => _selectedPlaylist;
  List<Work> get playlistWorks => _playlistWorks;
  bool get loadingWorks => _loadingWorks;
  String? get worksError => _worksError;
  int get worksCurrentPage => _worksCurrentPage;
  int? get worksTotalPages => _worksPagination?.totalCount != null && _worksPagination?.pageSize != null
      ? (_worksPagination!.totalCount! / _worksPagination!.pageSize!).ceil()
      : null;

  PlaylistsViewModel() {
    loadPlaylists();
  }

  /// 加载播放列表
  Future<void> loadPlaylists({int page = 1}) async {
    if (_isLoading) return;
    if (page < 1 || (totalPages != null && page > totalPages!)) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getMyPlaylists(page: page);
      _playlists = response.playlists;
      _pagination = response.pagination;
      _currentPage = page;
      AppLogger.info(LogStrings.logPlaylistsPageLoaded(page.toString(), (_playlists?.length ?? 0).toString()));
    } catch (e) {
      AppLogger.error(LogStrings.logLoadPlaylistsFailed, e);
      _error = userFacingError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 刷新播放列表
  Future<void> refresh() async {
    await loadPlaylists(page: 1);
  }

  /// 选择播放列表并加载作品
  Future<void> selectPlaylist(Playlist playlist) async {
    _selectedPlaylist = playlist;
    _playlistWorks = [];
    _worksError = null;
    _worksPagination = null;
    _worksCurrentPage = 1;
    notifyListeners();
    
    await loadPlaylistWorks();
  }

  /// 清除选中的播放列表
  void clearSelectedPlaylist() {
    _selectedPlaylist = null;
    _playlistWorks = [];
    _worksError = null;
    _worksPagination = null;
    _worksCurrentPage = 1;
    notifyListeners();
  }

  /// 加载播放列表作品
  Future<void> loadPlaylistWorks({int page = 1}) async {
    if (_loadingWorks || _selectedPlaylist == null) return;
    if (page < 1 || (worksTotalPages != null && page > worksTotalPages!)) return;

    _loadingWorks = true;
    _worksError = null;
    notifyListeners();

    try {
      final response = await _apiService.getPlaylistWorks(
        playlistId: _selectedPlaylist!.id!,
        page: page,
      );
      
      _playlistWorks = response.works;
      _worksPagination = response.pagination as Pagination?;
      _worksCurrentPage = page;
      AppLogger.info(LogStrings.logPageListLoaded(page.toString(), LogStrings.logPageNamePlaylistWorks, response.works.length.toString()));
    } catch (e) {
      AppLogger.error(LogStrings.logLoadPlaylistWorksFailed, e);
      _worksError = userFacingError(e);
    } finally {
      _loadingWorks = false;
      notifyListeners();
    }
  }

  /// 刷新播放列表作品
  Future<void> refreshWorks() => loadPlaylistWorks(page: 1);

  /// 获取播放列表显示名称
  String getDisplayName(String? name) {
    switch (name) {
      case '__SYS_PLAYLIST_MARKED':
        return Strings.playlistMarked;
      case '__SYS_PLAYLIST_LIKED':
        return Strings.playlistLiked;
      default:
        return name ?? '';
    }
  }

  @override
  void dispose() {
    AppLogger.info(LogStrings.logDisposingPlaylistsviewmodele5090);
    super.dispose();
  }
} 