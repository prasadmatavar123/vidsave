import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/download_manager.dart';
import '../../core/utils/shell_controller.dart';
import '../../features/downloads/screens/downloads_screen.dart';
import '../../features/history/screens/history_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const _pages = <Widget>[
    HomeScreen(),
    DownloadsScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final shell = context.watch<ShellController>();
    final active = context.select<DownloadManager, int>((m) => m.activeCount);
    return Scaffold(
      // IndexedStack keeps every tab (and its state) alive when switching.
      body: IndexedStack(index: shell.index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.index,
        onDestinationSelected: shell.goTo,
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home'),
          NavigationDestination(
              icon: Badge(
                  isLabelVisible: active > 0,
                  label: Text('$active'),
                  child: const Icon(Icons.download_outlined)),
              selectedIcon: const Icon(Icons.download_rounded),
              label: 'Downloads'),
          const NavigationDestination(
              icon: Icon(Icons.history_rounded),
              selectedIcon: Icon(Icons.history_rounded),
              label: 'History'),
          const NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Settings'),
        ],
      ),
    );
  }
}
