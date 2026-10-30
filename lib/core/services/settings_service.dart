import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DownloadLocation { external, private }

class SettingsService {
  SettingsService(this._prefs);
  final SharedPreferences _prefs;

  ThemeMode get themeMode => ThemeMode.values.firstWhere(
        (m) => m.name == _prefs.getString('theme'),
        orElse: () => ThemeMode.dark,
      );
  Future<void> setThemeMode(ThemeMode m) => _prefs.setString('theme', m.name);

  bool get autoSaveToGallery => _prefs.getBool('autoGallery') ?? true;
  Future<void> setAutoSaveToGallery(bool v) => _prefs.setBool('autoGallery', v);

  DownloadLocation get location => DownloadLocation.values.firstWhere(
        (l) => l.name == _prefs.getString('location'),
        orElse: () => DownloadLocation.external,
      );
  Future<void> setLocation(DownloadLocation l) => _prefs.setString('location', l.name);

  /// App-specific directories need no storage permission on any Android version.
  Future<Directory> downloadDir() async {
    Directory? base;
    if (location == DownloadLocation.external) {
      base = await getExternalStorageDirectory();
    }
    base ??= await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'Videos'));
    await dir.create(recursive: true);
    return dir;
  }
}
