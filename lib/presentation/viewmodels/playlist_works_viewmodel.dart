import 'package:lizunemu/data/models/my_lists/my_playlists/playlist.dart';
import 'package:flutter/foundation.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'package:lizunemu/data/models/works/pagination.dart';
import 'package:lizunemu/data/services/api_service.dart';
import 'package:lizunemu/utils/user_facing_error.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/common/constants/log_strings.dart';

class PlaylistWorksViewModel extends ChangeNotifier {
  final ApiService _apiService = GetIt.I<ApiService>();
  final Playlist playlist;
  
  List<Work> _works = [];
  bool _isLoading = false;
  String? _error;
  Pagination? _pagination;
  int _currentPage = 1;

  PlaylistWorksViewModel(this.playlist);

  List<Work> get works => _works;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int? get totalPages => _pagination?.totalCount != null && _pagination?.pageSize != null
      ? (_pagination!.totalCount! / _pagination!.pageSize!).ceil()
      : null;

  Future<void> loadWorks({int page = 1}) async {
    if (_isLoading) return;
    if (page < 1 || (totalPages != null && page > totalPages!)) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getPlaylistWorks(
        playlistId: playlist.id!,
        page: page,
      );
      
      _works = response.works;
      _pagination = response.pagination;
      _currentPage = page;
      AppLogger.info(LogStrings.logPageListLoaded(page.toString(), LogStrings.logPageNamePlaylistWorks, response.works.length.toString()));
    } catch (e) {
      AppLogger.error(LogStrings.logLoadPlaylistWorksFailed, e);
      _error = userFacingError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadWorks(page: 1);
}
