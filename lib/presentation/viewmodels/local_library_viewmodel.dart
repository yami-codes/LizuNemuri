import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:path/path.dart' as p;
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/audio/i_audio_player_service.dart';
import 'package:lizunemu/core/audio/models/playback_context.dart';
import 'package:lizunemu/core/library/local_library_scanner.dart';
import 'package:lizunemu/core/library/models/local_album.dart';
import 'package:lizunemu/core/library/scan_roots_store.dart';
import 'package:lizunemu/core/library/storage/local_library_repository.dart';
import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/data/models/files/files.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'package:lizunemu/utils/user_facing_error.dart';

class LocalLibraryViewModel extends ChangeNotifier {
  LocalLibraryViewModel({
    LocalLibraryRepository? repository,
    ScanRootsStore? rootsStore,
    IAudioPlayerService? audioService,
  })  : _repository = repository ?? GetIt.I<LocalLibraryRepository>(),
        _rootsStore = rootsStore ?? GetIt.I<ScanRootsStore>(),
        _audioService = audioService ?? GetIt.I<IAudioPlayerService>();

  final LocalLibraryRepository _repository;
  final ScanRootsStore _rootsStore;
  final IAudioPlayerService _audioService;

  List<LocalAlbum> _albums = [];
  List<String> _roots = [];
  bool _isLoading = false;
  bool _isScanning = false;
  String? _error;
  String _query = '';

  List<LocalAlbum> get albums => _albums;
  List<String> get scanRoots => _roots;
  bool get isLoading => _isLoading;
  bool get isScanning => _isScanning;
  String? get error => _error;
  bool get isEmpty =>
      !_isLoading && _error == null && _albums.isEmpty && _roots.isEmpty;

  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _roots = _rootsStore.roots;
      _albums = await _repository.listAlbums(query: _query);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = userFacingError(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  void setQuery(String value) {
    final trimmed = value.trim();
    if (_query == trimmed) return;
    _query = trimmed;
    load();
  }

  Future<void> pickAndAddFolder() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path == null || path.isEmpty) return;
    await _rootsStore.addRoot(path);
    _roots = _rootsStore.roots;
    notifyListeners();
    await scan();
  }

  Future<void> removeRoot(String path) async {
    await _rootsStore.removeRoot(path);
    _roots = _rootsStore.roots;
    notifyListeners();
  }

  Future<void> scan() async {
    if (_isScanning) return;
    _roots = _rootsStore.roots;
    if (_roots.isEmpty) {
      _albums = [];
      notifyListeners();
      return;
    }
    _isScanning = true;
    _error = null;
    notifyListeners();
    try {
      final scanned = LocalLibraryScanner.scanRoots(_roots);
      await _repository.replaceLibrary(scanned);
      _albums = await _repository.listAlbums(query: _query);
      _isScanning = false;
      notifyListeners();
    } catch (e) {
      _error = userFacingError(e);
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> playAlbum(LocalAlbum album) async {
    final tracks = await _repository.tracksForAlbum(album.id);
    if (tracks.isEmpty) return;

    final children = tracks
        .map(
          (t) => Child(
            type: 'audio',
            title: p.basename(t.filePath),
            mediaDownloadUrl: 'file://${t.filePath}',
          ),
        )
        .toList();

    final work = Work(
      id: album.id,
      title: album.title,
      name: album.artist,
    );
    final files = Files(children: children);
    final context = PlaybackContext.withFilteredPlaylist(
      work: work,
      files: files,
      currentFile: children.first,
      playlist: children,
    );

    await _audioService.playWithContext(context);
  }

  String subtitleFor(LocalAlbum album) {
    final parts = <String>[];
    if (album.artist != null && album.artist!.isNotEmpty) {
      parts.add(album.artist!);
    }
    parts.add(Strings.localLibraryTrackCount(album.trackCount));
    return parts.join(' · ');
  }
}
