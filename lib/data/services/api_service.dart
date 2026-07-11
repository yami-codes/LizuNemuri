import 'package:lizunemu/core/cache/recommendation_cache_manager.dart';
import 'package:lizunemu/data/models/mark_status.dart';
import 'package:lizunemu/data/models/playlists_with_exist_statu/playlists_with_exist_statu.dart';
import 'package:dio/dio.dart';
import 'package:lizunemu/data/models/files/files.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'package:lizunemu/data/models/works/pagination.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:lizunemu/data/services/interceptors/auth_interceptor.dart';
import 'package:lizunemu/data/services/interceptors/accept_language_interceptor.dart';
import 'package:lizunemu/data/services/interceptors/retry_interceptor.dart';
import 'package:lizunemu/data/services/exceptions/network_exception.dart';
import 'package:lizunemu/data/models/playlists_with_exist_statu/playlist.dart';
import 'package:lizunemu/data/models/my_lists/my_playlists/my_playlists.dart';
import 'package:lizunemu/data/models/tags/tag_item.dart';
import 'package:lizunemu/data/models/circles/circle_item.dart';
import 'package:lizunemu/data/models/vas/voice_actor.dart';
import 'package:lizunemu/data/models/works/work_info.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/data/services/asmr_api_headers.dart';
import 'package:lizunemu/common/constants/log_strings.dart';


class WorksResponse {
  final List<Work> works;
  final Pagination pagination;

  WorksResponse({required this.works, required this.pagination});
}

class ApiService {
  final Dio _dio;
  final _recommendationCache = RecommendationCacheManager();

  final AppSettingsService _settings;

  ApiService({required AppSettingsService settings})
      : _settings = settings,
        _dio = Dio(BaseOptions(
          baseUrl: settings.serverUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 15),
          headers: AsmrApiHeaders.defaultHeaders,
        )) {
    _dio.interceptors.add(const AcceptLanguageInterceptor());
    _dio.interceptors.add(RetryInterceptor(dio: _dio));
    _dio.interceptors.add(AuthInterceptor());
    // Listen for server URL changes
    _settings.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    if (_dio.options.baseUrl != _settings.serverUrl) {
      _dio.options.baseUrl = _settings.serverUrl;
      _recommendationCache.clear();
      AppLogger.info(LogStrings.logApiServerSwitchedSettingsSer60b99(_settings.serverUrl));
    }
  }

  /// Fetch work file tree.
  Future<Files> getWorkFiles(String workId, {CancelToken? cancelToken}) async {
    try {
      final response = await _dio.get(
        '/tracks/$workId', 
        queryParameters: {
          'v': '2',
        },
        cancelToken: cancelToken,  // Optional cancel token
      );

      if (response.statusCode == 200) {
        final filesData = {
          'type': 'root',
          'title': 'Root',
          'children': response.data,
        };

        return Files.fromJson(filesData);
      }

      throw Exception(LogStrings.logFetchFileListFailed(response.statusCode.toString()));
    } on DioException catch (e) {
      AppLogger.error(LogStrings.logNetworkRequestFailed, e, e.stackTrace);
      throw NetworkException.fromDioException(e);
    } catch (e, stackTrace) {
      AppLogger.error(LogStrings.logParseDataFailed, e, stackTrace);
      throw Exception(LogStrings.logParseFailedDetail(e.toString()));
    }
  }

  /// Fetch paginated works list.
  Future<WorksResponse> getWorks({
    int page = 1,
    bool hasSubtitle = false,
    String order = 'create_date',
    String sort = 'desc',
    String playlistId = '',
  }) async {
    try {
      final queryParams = {
        'page': page,
        'subtitle': hasSubtitle ? 1 : 0,
        'order': order,
        'sort': sort,
      };

      // Add playlist ID to query params when provided
      if (playlistId.isNotEmpty) {
        queryParams['withPlaylistStatus[]'] = playlistId;
      }

      final response = await _dio.get(
        '/works',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> works = response.data['works'] ?? [];
        final pagination = Pagination.fromJson(response.data['pagination']);

        return WorksResponse(
          works: works.map((work) => Work.fromJson(work)).toList(),
          pagination: pagination,
        );
      }

      throw Exception(LogStrings.logFetchWorksFailed(response.statusCode.toString()));
    } on DioException catch (e) {
      AppLogger.error(LogStrings.logNetworkRequestFailed, e, e.stackTrace);
      throw NetworkException.fromDioException(e);
    } catch (e, stackTrace) {
      AppLogger.error(LogStrings.logParseDataFailed, e, stackTrace);
      throw Exception(LogStrings.logParseFailedDetail(e.toString()));
    }
  }

  /// Search works.
  ///
  /// Note: `keyword` is a path segment. Tag names may contain `/` (e.g. "巨乳/爆乳");
  /// string concatenation can decode `%2F` back to `/` and the server splits the path → 404.
  /// Use `Uri.pathSegments` + `getUri` so the keyword stays one segment on the wire.
  Future<WorksResponse> searchWorks({
    required String keyword,
    int page = 1,
    String order = 'create_date',
    String sort = 'desc',
    bool hasSubtitle = false,
  }) async {
    try {
      final response = await _dio.getUri(
        _buildSearchUri(
          keyword: keyword,
          page: page,
          order: order,
          sort: sort,
          hasSubtitle: hasSubtitle,
        ),
      );

      if (response.statusCode == 200) {
        AppLogger.debug(LogStrings.logSearchResponseDataResponseDad62cd(response.data));

        final works = (response.data['works'] as List)
            .map((work) => Work.fromJson(work))
            .toList();

        final pagination = Pagination.fromJson(response.data['pagination']);

        return WorksResponse(
          works: works,
          pagination: pagination,
        );
      }

      throw Exception(LogStrings.logSearchFailedCode(response.statusCode.toString()));
    } on DioException catch (e) {
      AppLogger.error(LogStrings.logNetworkRequestFailed, e, e.stackTrace);
      throw NetworkException.fromDioException(e);
    } catch (e, stackTrace) {
      AppLogger.error(LogStrings.logParseDataFailed, e, stackTrace);
      throw Exception(LogStrings.logParseFailedDetail(e.toString()));
    }
  }

  Uri _buildSearchUri({
    required String keyword,
    required int page,
    required String order,
    required String sort,
    required bool hasSubtitle,
  }) {
    return buildSearchUri(
      baseUrl: _dio.options.baseUrl,
      keyword: keyword,
      page: page,
      order: order,
      sort: sort,
      hasSubtitle: hasSubtitle,
    );
  }

  /// Public for unit tests: build full `/search/<keyword>` URI.
  /// Guarantees keyword is always **one path segment** on the wire via `Uri.pathSegments`.
  static Uri buildSearchUri({
    required String baseUrl,
    required String keyword,
    required int page,
    required String order,
    required String sort,
    required bool hasSubtitle,
  }) {
    final base = Uri.parse(baseUrl);
    return base.replace(
      pathSegments: [...base.pathSegments, 'search', keyword],
      queryParameters: <String, String>{
        'page': '$page',
        'order': order,
        'sort': sort,
        'subtitle': hasSubtitle ? '1' : '0',
        'includeTranslationWorks': 'true',
      },
    );
  }

  /// Fetch favorites.
  Future<WorksResponse> getFavorites({int page = 1}) async {
    try {
      final response = await _dio.get('/review', queryParameters: {
        'page': page,
        'order': 'updated_at',
        'sort': 'desc',
      });

      if (response.statusCode == 200) {
        final List<dynamic> works = response.data['works'] ?? [];
        final pagination = Pagination.fromJson(response.data['pagination']);

        return WorksResponse(
          works: works.map((work) => Work.fromJson(work)).toList(),
          pagination: pagination,
        );
      }

      throw Exception(LogStrings.logFetchFavoritesFailed(response.statusCode.toString()));
    } on DioException catch (e) {
      AppLogger.error(LogStrings.logNetworkRequestFailed, e, e.stackTrace);
      throw NetworkException.fromDioException(e);
    } catch (e, stackTrace) {
      AppLogger.error(LogStrings.logParseDataFailed, e, stackTrace);
      throw Exception(LogStrings.logParseFailedDetail(e.toString()));
    }
  }

  /// Fetch recommended works.
  Future<WorksResponse> getRecommendations({
    required String uuid,
    int page = 1,
    bool hasSubtitle = false,
  }) async {
    try {
      final response = await _dio.post(
        '/recommender/recommend-for-user',
        data: {
          'keyword': ' ',
          'userId': uuid,
          'page': page,
          'subtitle': hasSubtitle ? 1 : 0,
          'localSubtitledWorks': [],
          'withPlaylistStatus': [],
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> works = response.data['works'] ?? [];
        final pagination = Pagination.fromJson(response.data['pagination']);

        return WorksResponse(
          works: works.map((work) => Work.fromJson(work)).toList(),
          pagination: pagination,
        );
      }

      throw Exception(LogStrings.logFetchRecommendFailed(response.statusCode.toString()));
    } on DioException catch (e) {
      AppLogger.error(LogStrings.logNetworkRequestFailed, e, e.stackTrace);
      throw NetworkException.fromDioException(e);
    } catch (e, stackTrace) {
      AppLogger.error(LogStrings.logParseDataFailed, e, stackTrace);
      throw Exception(LogStrings.logParseFailedDetail(e.toString()));
    }
  }

  /// Fetch popular works.
  Future<WorksResponse> getPopular({
    int page = 1,
    bool hasSubtitle = false,
  }) async {
    try {
      final response = await _dio.post(
        '/recommender/popular',
        data: {
          'keyword': ' ',
          'page': page,
          'subtitle': hasSubtitle ? 1 : 0,
          'localSubtitledWorks': [],
          'withPlaylistStatus': [],
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> works = response.data['works'] ?? [];
        final pagination = Pagination.fromJson(response.data['pagination']);

        return WorksResponse(
          works: works.map((work) => Work.fromJson(work)).toList(),
          pagination: pagination,
        );
      }

      throw Exception(LogStrings.logFetchPopularFailed(response.statusCode.toString()));
    } on DioException catch (e) {
      AppLogger.error(LogStrings.logNetworkRequestFailed, e, e.stackTrace);
      throw NetworkException.fromDioException(e);
    } catch (e, stackTrace) {
      AppLogger.error(LogStrings.logParseDataFailed, e, stackTrace);
      throw Exception(LogStrings.logParseFailedDetail(e.toString()));
    }
  }

  /// Fetch similar works.
  Future<WorksResponse> getItemNeighbors({
    required String itemId,
    int page = 1,
    bool hasSubtitle = false,
  }) async {
    try {
      // Try cache first
      final cachedData = _recommendationCache.get(itemId, page, hasSubtitle ? 1 : 0);
      if (cachedData != null) {
        return cachedData;
      }

      // Cache miss — fetch from network
      final response = await _dio.post(
        '/recommender/item-neighbors',
        data: {
          'keyword': '',
          'itemId': itemId,
          'page': page,
          'subtitle': hasSubtitle ? 1 : 0,
          'localSubtitledWorks': [],
          'withPlaylistStatus': [],
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> works = response.data['works'] ?? [];
        final pagination = Pagination.fromJson(response.data['pagination']);

        final worksResponse = WorksResponse(
          works: works.map((work) => Work.fromJson(work)).toList(),
          pagination: pagination,
        );

        // Store in cache
        _recommendationCache.set(itemId, page, hasSubtitle ? 1 : 0, worksResponse);

        return worksResponse;
      }

      throw Exception(LogStrings.logFetchSimilarFailed(response.statusCode.toString()));
    } on DioException catch (e) {
      AppLogger.error(LogStrings.logNetworkRequestFailed, e, e.stackTrace);
      throw NetworkException.fromDioException(e);
    } catch (e, stackTrace) {
      AppLogger.error(LogStrings.logParseDataFailed, e, stackTrace);
      throw Exception(LogStrings.logParseFailedDetail(e.toString()));
    }
  }

  /// Fetch work mark status in playlists.
  Future<PlaylistsWithExistStatu> getWorkExistStatusInPlaylists({
    required String workId,
    int page = 1,
  }) async {
    try {
      final response = await _dio.get(
        '/playlist/get-work-exist-status-in-my-playlists',
        queryParameters: {
          'workID': workId,
          'page': page,
          'version': 2,
        },
      );

      if (response.statusCode == 200) {
        return PlaylistsWithExistStatu.fromJson(response.data);
      }

      throw Exception(LogStrings.logFetchPlaylistsFailed(response.statusCode.toString()));
    } on DioException catch (e) {
      AppLogger.error(LogStrings.logNetworkRequestFailed, e, e.stackTrace);
      throw NetworkException.fromDioException(e);
    } catch (e, stackTrace) {
      AppLogger.error(LogStrings.logParseDataFailed, e, stackTrace);
      throw Exception(LogStrings.logParseFailedDetail(e.toString()));
    }
  }

  /// Add work to playlist.
  Future<void> addWorkToPlaylist({
    required String playlistId,
    required String workId,
  }) async {
    try {
      await _dio.post(
        '/playlist/add-works-to-playlist',
        data: {
          'id': playlistId,
          'works': [int.parse(workId)],
        },
      );
    } on DioException catch (e) {
      AppLogger.error(LogStrings.logNetworkRequestFailed, e, e.stackTrace);
      throw NetworkException.fromDioException(e);
    } catch (e, stackTrace) {
      AppLogger.error(LogStrings.logAddToPlaylistFailed, e, stackTrace);
      throw Exception(LogStrings.logAddToPlaylistFailedDetail(e.toString()));
    }
  }

  /// Remove work from playlist.
  Future<void> removeWorkFromPlaylist({
    required String playlistId,
    required String workId,
  }) async {
    try {
      await _dio.post(
        '/playlist/remove-works-from-playlist',
        data: {
          'id': playlistId,
          'works': [int.parse(workId)],
        },
      );
    } on DioException catch (e) {
      AppLogger.error(LogStrings.logNetworkRequestFailed, e, e.stackTrace);
      throw NetworkException.fromDioException(e);
    } catch (e, stackTrace) {
      AppLogger.error(LogStrings.logRemoveFromPlaylistFailed, e, stackTrace);
      throw Exception(LogStrings.logRemoveFromPlaylistFailedDetail(e.toString()));
    }
  }

  /// Update work mark status.
  Future<void> updateWorkMarkStatus(String workId, String status) async {
    try {
      final response = await _dio.put(
        '/review',
        data: {
          'work_id': int.parse(workId),
          'progress': status,
        },
      );

      if (response.statusCode != 200) {
        throw Exception(LogStrings.logMarkFailedCode(response.statusCode.toString()));
      }
    } on DioException catch (e) {
      AppLogger.error(LogStrings.logNetworkRequestFailed, e, e.stackTrace);
      throw NetworkException.fromDioException(e);
    } catch (e, stackTrace) {
      AppLogger.error(LogStrings.logUpdateMarkFailed, e, stackTrace);
      rethrow;
    }
  }

  /// Map MarkStatus enum to API param.
  String convertMarkStatusToApi(MarkStatus status) {
    switch (status) {
      case MarkStatus.wantToListen:
        return 'marked';
      case MarkStatus.listening:
        return 'listening';
      case MarkStatus.listened:
        return 'listened';
      case MarkStatus.relistening:
        return 'replay';
      case MarkStatus.onHold:
        return 'postponed';
    }
  }

  /// Fetch default mark target playlist.
  Future<Playlist> getDefaultMarkTargetPlaylist() async {
    try {
      final response = await _dio.get('/playlist/get-default-mark-target-playlist');

      if (response.statusCode == 200) {
        final playlist = Playlist.fromJson(response.data);
        AppLogger.info(LogStrings.logDefaultMarkPlaylistFetchedId166ef(playlist.id, playlist.name));
        return playlist;
      }

      throw Exception(LogStrings.logFetchDefaultMarkPlaylistFailed(response.statusCode.toString()));
    } on DioException catch (e) {
      AppLogger.error(LogStrings.logNetworkRequestFailed, e, e.stackTrace);
      throw NetworkException.fromDioException(e);
    } catch (e, stackTrace) {
      AppLogger.error(LogStrings.logParseDataFailed, e, stackTrace);
      throw Exception(LogStrings.logParseFailedDetail(e.toString()));
    }
  }

  /// Fetch user playlists.
  Future<MyPlaylists> getMyPlaylists({int page = 1}) async {
    try {
      final response = await _dio.get(
        '/playlist/get-playlists',
        queryParameters: {
          'page': page,
        },
      );

      if (response.statusCode == 200) {
        final myPlaylists = MyPlaylists.fromJson(response.data);
        AppLogger.info(LogStrings.logMyPlaylistsFetched((myPlaylists.playlists?.length ?? 0).toString()));
        return myPlaylists;
      }

      throw Exception(LogStrings.logFetchMyPlaylistsFailed(response.statusCode.toString()));
    } on DioException catch (e) {
      AppLogger.error(LogStrings.logNetworkRequestFailed, e, e.stackTrace);
      throw NetworkException.fromDioException(e);
    } catch (e, stackTrace) {
      AppLogger.error(LogStrings.logParseDataFailed, e, stackTrace);
      throw Exception(LogStrings.logParseFailedDetail(e.toString()));
    }
  }

  /// Fetch all tags.
  Future<List<TagItem>> getTags() async {
    try {
      final response = await _dio.get('/tags/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => TagItem.fromJson(item)).toList();
      }

      throw Exception(LogStrings.logFetchTagsFailed(response.statusCode.toString()));
    } on DioException catch (e) {
      AppLogger.error(LogStrings.logNetworkRequestFailed, e, e.stackTrace);
      throw NetworkException.fromDioException(e);
    } catch (e, stackTrace) {
      AppLogger.error(LogStrings.logParseDataFailed, e, stackTrace);
      throw Exception(LogStrings.logParseFailedDetail(e.toString()));
    }
  }

  /// Fetch all circles.
  Future<List<CircleItem>> getCircles() async {
    try {
      final response = await _dio.get('/circles/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => CircleItem.fromJson(item)).toList();
      }

      throw Exception(LogStrings.logFetchCirclesFailed(response.statusCode.toString()));
    } on DioException catch (e) {
      AppLogger.error(LogStrings.logNetworkRequestFailed, e, e.stackTrace);
      throw NetworkException.fromDioException(e);
    } catch (e, stackTrace) {
      AppLogger.error(LogStrings.logParseDataFailed, e, stackTrace);
      throw Exception(LogStrings.logParseFailedDetail(e.toString()));
    }
  }

  /// Fetch all voice actors.
  Future<List<VoiceActor>> getVoiceActors() async {
    try {
      final response = await _dio.get('/vas/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => VoiceActor.fromJson(item)).toList();
      }

      throw Exception(LogStrings.logFetchVoiceActorsFailed(response.statusCode.toString()));
    } on DioException catch (e) {
      AppLogger.error(LogStrings.logNetworkRequestFailed, e, e.stackTrace);
      throw NetworkException.fromDioException(e);
    } catch (e, stackTrace) {
      AppLogger.error(LogStrings.logParseDataFailed, e, stackTrace);
      throw Exception(LogStrings.logParseFailedDetail(e.toString()));
    }
  }

  /// Fetch work details.
  Future<WorkInfo> getWorkInfo(String workId, {CancelToken? cancelToken}) async {
    try {
      final response = await _dio.get('/workInfo/$workId', cancelToken: cancelToken);

      if (response.statusCode == 200) {
        return WorkInfo.fromJson(response.data);
      }

      throw Exception(LogStrings.logFetchWorkDetailFailed(response.statusCode.toString()));
    } on DioException catch (e) {
      AppLogger.error(LogStrings.logNetworkRequestFailed, e, e.stackTrace);
      throw NetworkException.fromDioException(e);
    } catch (e, stackTrace) {
      AppLogger.error(LogStrings.logParseDataFailed, e, stackTrace);
      throw Exception(LogStrings.logParseFailedDetail(e.toString()));
    }
  }

  /// Fetch works in a playlist.
  Future<WorksResponse> getPlaylistWorks({
    required String playlistId,
    int page = 1,
    int pageSize = 12,
  }) async {
    try {
      final response = await _dio.get(
        '/playlist/get-playlist-works',
        queryParameters: {
          'id': playlistId,
          'page': page,
          'pageSize': pageSize,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> works = response.data['works'] ?? [];
        final pagination = Pagination.fromJson(response.data['pagination']);

        return WorksResponse(
          works: works.map((work) => Work.fromJson(work)).toList(),
          pagination: pagination,
        );
      }

      throw Exception(LogStrings.logFetchPlaylistWorksFailed(response.statusCode.toString()));
    } on DioException catch (e) {
      AppLogger.error(LogStrings.logNetworkRequestFailed, e, e.stackTrace);
      throw NetworkException.fromDioException(e);
    } catch (e, stackTrace) {
      AppLogger.error(LogStrings.logParseDataFailed, e, stackTrace);
      throw Exception(LogStrings.logParseFailedDetail(e.toString()));
    }
  }
}
