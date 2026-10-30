import 'package:flutter/material.dart';
import '../../../core/services/download_manager.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/utils/safe_notifier.dart';
import '../../../data/models/download_model.dart';
import '../../../data/repositories/download_repository.dart';

class SettingsViewModel extends ChangeNotifier with SafeNotifier {
  SettingsViewModel(this._settings, this._repo, this._manager) {
    _tick = _manager.libraryTick;
    _manager.addListener(_onManager);
    loadStorage();
  }

  final SettingsService _settings;
  final DownloadRepository _repo;
  final DownloadManager _manager;
  int _tick = 0;

  int videoCount = 0;
  int usedBytes = 0;
  String downloadPath = '';

  ThemeMode get themeMode => _settings.themeMode;
  bool get autoGallery => _settings.autoSaveToGallery;
  DownloadLocation get location => _settings.location;

  void _onManager() {
    if (_manager.libraryTick != _tick) {
      _tick = _manager.libraryTick;
      loadStorage();
    }
  }

  Future<void> loadStorage() async {
    videoCount = await _repo.count(statuses: [DownloadStatus.completed]);
    usedBytes = await _repo.totalSize();
    downloadPath = (await _settings.downloadDir()).path;
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode m) async {
    await _settings.setThemeMode(m);
    notifyListeners();
  }

  Future<void> setAutoGallery(bool v) async {
    await _settings.setAutoSaveToGallery(v);
    notifyListeners();
  }

  Future<void> setLocation(DownloadLocation l) async {
    await _settings.setLocation(l);
    await loadStorage();
  }

  Future<void> clearHistory() => _manager.clearHistory();

  @override
  void dispose() {
    _manager.removeListener(_onManager);
    super.dispose();
  }
}
