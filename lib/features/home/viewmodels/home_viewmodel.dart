import 'package:flutter/foundation.dart';
import '../../../core/services/download_manager.dart';
import '../../../core/services/video_source_service.dart';
import '../../../core/utils/safe_notifier.dart';
import '../../../core/utils/url_validator.dart';
import '../../../data/models/download_model.dart';
import '../../../data/models/video_info.dart';
import '../../../data/repositories/download_repository.dart';

class HomeViewModel extends ChangeNotifier with SafeNotifier {
  HomeViewModel(this._repo, this._manager, this._source) {
    _tick = _manager.libraryTick;
    _manager.addListener(_onManager);
    load();
  }

  final DownloadRepository _repo;
  final DownloadManager _manager;
  final VideoSourceService _source;
  int _tick = 0;

  bool resolving = false;
  SourceException? error;
  List<DownloadModel> recent = [];
  int totalDownloads = 0;

  Future<void> load() async {
    recent = await _repo.fetch(statuses: [DownloadStatus.completed], limit: 6);
    totalDownloads = await _repo.count(statuses: [DownloadStatus.completed]);
    notifyListeners();
  }

  void _onManager() {
    if (_manager.libraryTick != _tick) {
      _tick = _manager.libraryTick;
      load();
    }
  }

  /// Validates the URL and resolves its metadata. Returns null on failure
  /// and exposes a user-friendly [error].
  Future<VideoInfo?> check(String url) async {
    resolving = true;
    error = null;
    notifyListeners();
    try {
      return await _source.resolve(url);
    } on SourceException catch (e) {
      error = e;
      return null;
    } catch (_) {
      error = const SourceException('Something went wrong', 'Could not check this link. Try again.');
      return null;
    } finally {
      resolving = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (error == null) return;
    error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _manager.removeListener(_onManager);
    super.dispose();
  }
}
