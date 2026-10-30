import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import '../../../core/services/thumbnail_service.dart';
import '../../../core/utils/safe_notifier.dart';
import '../../../data/models/video_info.dart';

class PreviewViewModel extends ChangeNotifier with SafeNotifier {
  PreviewViewModel(this._info, this._thumbs) {
    _loadThumbnail();
    _initPlayer();
  }

  final ThumbnailService _thumbs;
  VideoInfo _info;
  VideoInfo get info => _info;

  VideoPlayerController? controller;
  bool loading = true;
  bool previewFailed = false;
  bool started = false;

  bool get ready => controller?.value.isInitialized ?? false;
  bool get playing => controller?.value.isPlaying ?? false;
  double get aspect => ready ? controller!.value.aspectRatio : 16 / 9;

  Future<void> _loadThumbnail() async {
    final path = await _thumbs.generate(
        source: _info.url, name: 'pv_${_info.url.hashCode.abs()}');
    if (path != null) {
      _info = _info.copyWith(thumbnailPath: path);
      notifyListeners();
    }
  }

  Future<void> _initPlayer() async {
    final c = VideoPlayerController.networkUrl(Uri.parse(_info.url));
    controller = c;
    try {
      await c.initialize();
      c.addListener(notifyListeners);
      _info = _info.copyWith(durationSeconds: c.value.duration.inSeconds);
    } catch (_) {
      previewFailed = true;
      controller = null;
      await c.dispose();
    }
    loading = false;
    notifyListeners();
  }

  Future<void> togglePlay() async {
    final c = controller;
    if (c == null || !ready) return;
    started = true;
    c.value.isPlaying ? await c.pause() : await c.play();
    notifyListeners();
  }

  @override
  void dispose() {
    controller?.removeListener(notifyListeners);
    controller?.dispose();
    super.dispose();
  }
}
