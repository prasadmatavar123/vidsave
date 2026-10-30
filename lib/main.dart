import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_constants.dart';
import 'core/services/download_manager.dart';
import 'core/services/gallery_service.dart';
import 'core/services/settings_service.dart';
import 'core/services/thumbnail_service.dart';
import 'core/services/video_source_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/shell_controller.dart';
import 'data/database/database_helper.dart';
import 'data/repositories/download_repository.dart';
import 'features/history/viewmodels/history_viewmodel.dart';
import 'features/home/viewmodels/home_viewmodel.dart';
import 'features/settings/viewmodels/settings_viewmodel.dart';
import 'shared/widgets/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final prefs = await SharedPreferences.getInstance();
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 15),
    headers: {'User-Agent': '${AppConstants.appName}/${AppConstants.appVersion}'},
  ));

  final repo = DownloadRepository(DatabaseHelper.instance);
  final settings = SettingsService(prefs);
  final thumbs = ThumbnailService();
  final manager = DownloadManager(
    repo: repo,
    settings: settings,
    thumbnails: thumbs,
    gallery: GalleryService(),
    dio: dio,
  );
  await manager.init();

  runApp(MultiProvider(
    providers: [
      Provider<DownloadRepository>.value(value: repo),
      Provider<ThumbnailService>.value(value: thumbs),
      Provider<VideoSourceService>.value(value: VideoSourceService(dio)),
      ChangeNotifierProvider<DownloadManager>.value(value: manager),
      ChangeNotifierProvider(create: (_) => ShellController()),
      ChangeNotifierProvider(create: (c) => SettingsViewModel(settings, repo, manager)),
      ChangeNotifierProvider(
          create: (c) => HomeViewModel(repo, manager, c.read<VideoSourceService>())),
      ChangeNotifierProvider(create: (c) => HistoryViewModel(repo, manager)),
    ],
    child: const VideoDownloaderApp(),
  ));
}

class VideoDownloaderApp extends StatelessWidget {
  const VideoDownloaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.select<SettingsViewModel, ThemeMode>((s) => s.themeMode);
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      home: const AppShell(),
    );
  }
}
