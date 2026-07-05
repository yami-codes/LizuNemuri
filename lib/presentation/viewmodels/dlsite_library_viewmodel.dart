import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:path/path.dart' as p;
import 'package:xuro/common/constants/strings.dart';
import 'package:xuro/core/audio/i_audio_player_service.dart';
import 'package:xuro/core/audio/models/playback_context.dart';
import 'package:xuro/core/dlsite/auth/dlsite_auth_repository.dart';
import 'package:xuro/core/dlsite/dlsite_play_library_service.dart';
import 'package:xuro/core/dlsite/dlsite_play_work_service.dart';
import 'package:xuro/core/dlsite/models/dlsite_album.dart';
import 'package:xuro/data/models/files/child.dart';
import 'package:xuro/data/models/files/files.dart';
import 'package:xuro/data/models/works/work.dart';
import 'package:xuro/utils/user_facing_error.dart';

class DlsiteLibraryViewModel extends ChangeNotifier {
  DlsiteLibraryViewModel({
    DlsiteAuthRepository? auth,
    DlsitePlayLibraryService? library,
    DlsitePlayWorkService? workService,
    IAudioPlayerService? audioService,
  })  : _auth = auth ?? GetIt.I<DlsiteAuthRepository>(),
        _library = library ?? GetIt.I<DlsitePlayLibraryService>(),
        _workService = workService ?? GetIt.I<DlsitePlayWorkService>(),
        _audioService = audioService ?? GetIt.I<IAudioPlayerService>();

  final DlsiteAuthRepository _auth;
  final DlsitePlayLibraryService _library;
  final DlsitePlayWorkService _workService;
  final IAudioPlayerService _audioService;

  List<DlsiteAlbum> _albums = [];
  List<DlsiteAlbum> _allAlbums = [];
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _error;
  String _query = '';

  List<DlsiteAlbum> get albums => _albums;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get error => _error;

  Future<void> load() async {
    _isLoggedIn = await _auth.hasCredentials();
    if (!_isLoggedIn) {
      _albums = [];
      notifyListeners();
      return;
    }
    await refresh();
  }

  Future<void> refresh() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final all = await _library.listLibrary(forceRefresh: true);
      _allAlbums = all;
      _albums = _library.filter(all, _query);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = userFacingError(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  void setQuery(String value) {
    final trimmed = value.trim();
    if (_query == trimmed) return;
    _query = trimmed;
    _albums = _library.filter(_allAlbums, _query);
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.clear();
    _library.clearCache();
    _isLoggedIn = false;
    _albums = [];
    notifyListeners();
  }

  Future<void> playAlbum(DlsiteAlbum album) async {
    final tracks = await _workService.fetchAudioTracks(album.workno);
    if (tracks.isEmpty) {
      throw StateError(Strings.playlistEmpty);
    }

    final children = tracks
        .map(
          (t) => Child(
            type: 'audio',
            title: p.basename(t.displayPath),
            mediaDownloadUrl: t.streamUrl,
          ),
        )
        .toList();

    final work = Work(
      id: int.tryParse(album.workno.replaceAll(RegExp(r'\D'), '')),
      title: album.title,
      name: album.circle,
      sourceId: album.workno,
      mainCoverUrl: album.coverUrl,
    );

    final context = PlaybackContext.withFilteredPlaylist(
      work: work,
      files: Files(children: children),
      currentFile: children.first,
      playlist: children,
    );

    await _audioService.playWithContext(context);
  }
}
