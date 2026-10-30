import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../../core/utils/safe_notifier.dart';
import '../../../data/models/download_model.dart';

class PlayerViewModel extends ChangeNotifier with SafeNotifier {
  PlayerViewModel(this.video) {
    _init();
  }

  final DownloadModel video;
  VideoPlayerController? controller;
  String? error;
  bool loading = true;
  bool fullscreen = false;
  bool controlsVisible = true;
  double speed = 1;
  double? _drag;
  Timer? _hide;

  bool get ready => controller?.value.isInitialized ?? false;
  bool get playing => controller?.value.isPlaying ?? false;
  Duration get position => controller?.value.position ?? Duration.zero;
  Duration get duration => controller?.value.duration ?? Duration.zero;
  double get maxMs => math.max(1, duration.inMilliseconds.toDouble());
  double get sliderValue =>
      (_drag ?? position.inMilliseconds.toDouble()).clamp(0, maxMs).toDouble();

  Future<void> _init() async {
    final file = File(video.videoPath);
    if (!await file.exists()) {
      error = 'This video file could not be found on the device.';
      loading = false;
      notifyListeners();
      return;
    }
    final c = VideoPlayerController.file(file);
    controller = c;
    try {
      await c.initialize();
      c.addListener(notifyListeners);
      await c.play();
      _scheduleHide();
    } catch (_) {
      error = 'This video can’t be played.';
      controller = null;
      await c.dispose();
    }
    loading = false;
    notifyListeners();
  }

  Future<void> togglePlay() async {
    final c = controller;
    if (c == null) return;
    if (c.value.isPlaying) {
      await c.pause();
      _hide?.cancel();
    } else {
      if (position >= duration) await c.seekTo(Duration.zero);
      await c.play();
      _scheduleHide();
    }
    notifyListeners();
  }

  Future<void> skip(int seconds) async {
    final c = controller;
    if (c == null) return;
    final t = position + Duration(seconds: seconds);
    await c.seekTo(t < Duration.zero ? Duration.zero : (t > duration ? duration : t));
  }

  void dragStart(double v) => _drag = v;
  void drag(double v) {
    _drag = v;
    notifyListeners();
  }

  Future<void> dragEnd(double v) async {
    _drag = null;
    await controller?.seekTo(Duration(milliseconds: v.round()));
  }

  Future<void> setSpeed(double s) async {
    speed = s;
    await controller?.setPlaybackSpeed(s);
    notifyListeners();
  }

  void toggleControls() {
    controlsVisible = !controlsVisible;
    if (controlsVisible) _scheduleHide();
    notifyListeners();
  }

  void _scheduleHide() {
    _hide?.cancel();
    _hide = Timer(const Duration(seconds: 3), () {
      if (playing) {
        controlsVisible = false;
        notifyListeners();
      }
    });
  }

  Future<void> toggleFullscreen() async {
    fullscreen = !fullscreen;
    if (fullscreen) {
      await SystemChrome.setPreferredOrientations(
          [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await _restoreSystem();
    }
    notifyListeners();
  }

  static Future<void> _restoreSystem() async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    _hide?.cancel();
    controller?.removeListener(notifyListeners);
    controller?.dispose();
    if (fullscreen) _restoreSystem();
    super.dispose();
  }
}
