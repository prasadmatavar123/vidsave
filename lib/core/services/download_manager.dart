import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../../data/models/download_model.dart';
import '../../data/models/video_info.dart';
import '../../data/repositories/download_repository.dart';
import '../constants/app_constants.dart';
import '../utils/net_errors.dart';
import 'gallery_service.dart';
import 'settings_service.dart';
import 'thumbnail_service.dart';

enum EnqueueResult { started, duplicate }

enum _Intent { none, pause, cancel }

class _Task {
  _Task(this.resumable);
  final bool resumable;
  CancelToken? token;
  _Intent intent = _Intent.none;
}

/// Owns every download: queueing, progress, pause/resume (only when the
/// server supports HTTP range requests), cancel, verification, SQLite
/// updates and Gallery saving. Lives above the UI so state survives tab changes.
class DownloadManager extends ChangeNotifier {
  DownloadManager({
    required DownloadRepository repo,
    required SettingsService settings,
    required ThumbnailService thumbnails,
    required GalleryService gallery,
    required Dio dio,
  })  : _repo = repo,
        _settings = settings,
        _thumbs = thumbnails,
        _gallery = gallery,
        _dio = dio;

  final DownloadRepository _repo;
  final SettingsService _settings;
  final ThumbnailService _thumbs;
  final GalleryService _gallery;
  final Dio _dio;

  final Map<int, _Task> _tasks = {};
  final Map<int, String> _errors = {};
  final Map<int, int> _lastDbWrite = {};
  List<DownloadModel> _items = [];
  Timer? _notifyTimer;

  /// Incremented whenever the library of finished downloads changes.
  int libraryTick = 0;

  List<DownloadModel> get items => List.unmodifiable(_items);
  int get activeCount => _items.where((m) => m.isActive).length;
  String? errorFor(int id) => _errors[id];
  bool canPause(int id) => _tasks[id]?.resumable ?? false;

  Future<void> init() async {
    // Downloads interrupted by an app restart cannot continue: mark failed
    // so the user can retry them.
    final stale = await _repo.fetch(statuses: [
      DownloadStatus.queued,
      DownloadStatus.downloading,
      DownloadStatus.paused,
    ]);
    for (final m in stale) {
      await _repo.updateStatus(m.id!, DownloadStatus.failed);
    }
    _items = await _repo.fetch(limit: 50);
    notifyListeners();
  }

  // ---------------------------------------------------------------- public
  Future<EnqueueResult> enqueue(VideoInfo info) async {
    if (_items.any((m) => m.originalUrl == info.url && m.isActive)) {
      return EnqueueResult.duplicate;
    }
    final dir = await _settings.downloadDir();
    final safe = info.title.replaceAll(RegExp(r'[^\w\- ]'), '_').trim();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final base = safe.isEmpty ? 'video' : safe.substring(0, math.min(safe.length, 60));
    final path = p.join(dir.path, '${base}_$stamp.${info.format}');

    var model = DownloadModel(
      originalUrl: info.url,
      videoTitle: info.title,
      videoPath: path,
      thumbnailPath: info.thumbnailPath,
      platform: info.platform,
      fileSize: info.fileSize,
      duration: info.durationSeconds,
      status: DownloadStatus.queued,
      createdAt: DateTime.now().toIso8601String(),
    );
    final id = await _repo.insert(model);
    model = model.copyWith(id: id);
    _items.insert(0, model);
    _tasks[id] = _Task(info.supportsRange);
    notifyListeners();
    _pump();
    return EnqueueResult.started;
  }

  void pause(int id) {
    final t = _tasks[id];
    if (t == null || !t.resumable) return;
    if (_byId(id)?.status != DownloadStatus.downloading) return;
    t.intent = _Intent.pause;
    t.token?.cancel();
  }

  void resume(int id) {
    if (_byId(id)?.status != DownloadStatus.paused) return;
    _setStatus(id, DownloadStatus.queued);
    _pump();
  }

  Future<void> cancel(int id) async {
    final m = _byId(id);
    if (m == null) return;
    final t = _tasks[id];
    if (m.status == DownloadStatus.downloading && t != null) {
      t.intent = _Intent.cancel;
      t.token?.cancel();
      return;
    }
    await deleteDownload(m);
  }

  Future<void> retry(int id) async {
    final m = _byId(id);
    if (m == null || m.status != DownloadStatus.failed) return;
    _tasks.putIfAbsent(id, () => _Task(false));
    _errors.remove(id);
    _replace(m.copyWith(status: DownloadStatus.queued, progress: 0));
    await _repo.update(_byId(id)!);
    notifyListeners();
    _pump();
  }

  Future<void> deleteDownload(DownloadModel m, {bool deleteFile = true}) async {
    final id = m.id;
    if (id != null) {
      _tasks[id]?.token?.cancel();
      _tasks.remove(id);
      _errors.remove(id);
    }
    if (deleteFile) {
      await _tryDelete(m.videoPath);
      await _tryDelete('${m.videoPath}.part');
    }
    if (m.thumbnailPath != null) await _tryDelete(m.thumbnailPath!);
    if (id != null) await _repo.delete(id);
    _items.removeWhere((e) => e.id == id);
    libraryTick++;
    notifyListeners();
  }

  /// Removes finished/failed records. Saved video files are kept.
  Future<void> clearHistory() async {
    await _repo.clearFinished();
    _items.removeWhere((m) => !m.isActive);
    libraryTick++;
    notifyListeners();
  }

  // --------------------------------------------------------------- engine
  void _pump() {
    var running = _items.where((m) => m.status == DownloadStatus.downloading).length;
    for (final m in _items.reversed.toList()) {
      if (running >= AppConstants.maxConcurrent) break;
      if (m.status == DownloadStatus.queued && m.id != null) {
        running++;
        _run(m.id!);
      }
    }
  }

  Future<void> _run(int id) async {
    final task = _tasks[id];
    final m = _byId(id);
    if (task == null || m == null) return;

    _setStatus(id, DownloadStatus.downloading); // synchronous: prevents double start
    task.intent = _Intent.none;
    final token = task.token = CancelToken();
    final part = File('${m.videoPath}.part');

    try {
      var existing = 0;
      if (await part.exists()) {
        if (task.resumable) {
          existing = await part.length();
        } else {
          await part.delete();
        }
      }

      final res = await _dio.download(
        m.originalUrl,
        part.path,
        cancelToken: token,
        deleteOnError: false,
        fileAccessMode: existing > 0 ? FileAccessMode.append : FileAccessMode.write,
        options: Options(
          headers: existing > 0 ? {HttpHeaders.rangeHeader: 'bytes=$existing-'} : null,
          receiveTimeout: const Duration(seconds: 30),
        ),
        onReceiveProgress: (received, total) {
          final all = total > 0 ? existing + total : m.fileSize;
          if (all > 0) _progress(id, ((existing + received) / all).clamp(0.0, 1.0));
        },
      );

      // Verify the payload really is a video and not an error/HTML page.
      final type = (res.headers.value('content-type') ?? '').toLowerCase();
      if (type.startsWith('text/') || type.contains('html') || type.contains('json')) {
        throw const FormatException('The server returned a web page instead of a video.');
      }
      final size = await part.length();
      if (size <= 0) throw const FormatException('The downloaded file is empty.');
      await part.rename(m.videoPath);
      if (!await File(m.videoPath).exists()) {
        throw const FormatException('The file could not be saved.');
      }

      var thumb = m.thumbnailPath;
      if (thumb == null || !await File(thumb).exists()) {
        thumb = await _thumbs.generate(source: m.videoPath, name: 'dl_$id');
      }
      final done = (_byId(id) ?? m).copyWith(
        status: DownloadStatus.completed,
        progress: 1,
        fileSize: size,
        thumbnailPath: thumb,
      );
      await _repo.update(done);
      _replace(done);
      _tasks.remove(id);
      libraryTick++;
      notifyListeners();
      if (_settings.autoSaveToGallery) await _gallery.saveVideo(done.videoPath);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        await _afterCancel(id, task, part);
      } else {
        await _fail(id, NetErrors.describe(e));
      }
    } on FileSystemException catch (e) {
      await _fail(id, NetErrors.storage(e));
    } on FormatException catch (e) {
      await _tryDelete(part.path);
      await _fail(id, e.message);
    } catch (_) {
      await _fail(id, 'Download failed. Please try again.');
    } finally {
      _pump();
    }
  }

  Future<void> _afterCancel(int id, _Task task, File part) async {
    if (task.intent == _Intent.pause) {
      _setStatus(id, DownloadStatus.paused);
    } else if (task.intent == _Intent.cancel) {
      final m = _byId(id);
      if (m != null) await deleteDownload(m);
    } else {
      await _fail(id, 'Download was interrupted.');
    }
  }

  Future<void> _fail(int id, String message) async {
    if (_byId(id) == null) return;
    _errors[id] = message;
    _setStatus(id, DownloadStatus.failed);
    await _repo.updateStatus(id, DownloadStatus.failed);
  }

  // -------------------------------------------------------------- helpers
  int _index(int id) => _items.indexWhere((m) => m.id == id);
  DownloadModel? _byId(int id) {
    final i = _index(id);
    return i < 0 ? null : _items[i];
  }

  void _replace(DownloadModel m) {
    final i = _index(m.id!);
    if (i >= 0) _items[i] = m;
  }

  void _setStatus(int id, DownloadStatus s) {
    final m = _byId(id);
    if (m == null) return;
    _replace(m.copyWith(status: s));
    notifyListeners();
    _repo.updateStatus(id, s);
  }

  void _progress(int id, double v) {
    final m = _byId(id);
    if (m == null) return;
    _replace(m.copyWith(progress: v));
    if (!(_notifyTimer?.isActive ?? false)) {
      _notifyTimer = Timer(const Duration(milliseconds: 250), notifyListeners);
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - (_lastDbWrite[id] ?? 0) > 1500) {
      _lastDbWrite[id] = now;
      _repo.updateProgress(id, v);
    }
  }

  Future<void> _tryDelete(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  @override
  void dispose() {
    _notifyTimer?.cancel();
    for (final t in _tasks.values) {
      t.token?.cancel();
    }
    super.dispose();
  }
}
