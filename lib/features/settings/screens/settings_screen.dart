import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';
import '../viewmodels/settings_viewmodel.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _pickLocation(BuildContext context, SettingsViewModel vm) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final (l, title, sub) in [
            (DownloadLocation.external, 'App storage (external)',
                'Visible in Android/data/…/files/Videos'),
            (DownloadLocation.private, 'Private app storage',
                'Hidden from other apps and file managers'),
          ])
            ListTile(
              title: Text(title),
              subtitle: Text(sub),
              trailing: vm.location == l
                  ? Icon(Icons.check_circle_rounded, color: context.cs.primary)
                  : null,
              onTap: () {
                vm.setLocation(l);
                Navigator.pop(sheet);
              },
            ),
        ]),
      ),
    );
  }

  Future<void> _clear(BuildContext context, SettingsViewModel vm) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Clear download history?'),
        content: const Text(
            'History entries are removed. Videos already saved on your device or in the Gallery are kept.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(d, true),
              child: const Text('Clear', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok == true) {
      await vm.clearHistory();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('History cleared')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          _Section('Appearance'),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Theme', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_rounded)),
                    ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_rounded)),
                    ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto_rounded)),
                  ],
                  selected: {vm.themeMode},
                  onSelectionChanged: (s) => vm.setTheme(s.first),
                ),
              ),
            ]),
          ),
          _Section('Downloads'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: const Text('Default download location'),
                subtitle: Text(vm.downloadPath, maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () => _pickLocation(context, vm),
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.photo_library_outlined),
                title: const Text('Automatically save to Gallery'),
                subtitle: const Text('Copy finished videos to the VidSave album'),
                value: vm.autoGallery,
                onChanged: vm.setAutoGallery,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.storage_outlined),
                title: const Text('Storage usage'),
                subtitle: Text('${vm.videoCount} videos • ${Fmt.bytes(vm.usedBytes)}'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                title: const Text('Clear download history'),
                onTap: () => _clear(context, vm),
              ),
            ]),
          ),
          _Section('About'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              const ListTile(
                leading: Icon(Icons.info_outline_rounded),
                title: Text('App version'),
                trailing: Text(AppConstants.appVersion),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy policy'),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (d) => AlertDialog(
                    title: const Text('Privacy policy'),
                    content: SingleChildScrollView(child: Text(AppConstants.privacyPolicy)),
                    actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('Close'))],
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.favorite_border_rounded),
                title: const Text('About application'),
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: AppConstants.appName,
                  applicationVersion: AppConstants.appVersion,
                  children: const [
                    Text('Download direct video links you are authorised to save, '
                        'and watch them offline. Built with Flutter, SQLite and Dio.'),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Text(text,
            style: context.tt.titleSmall
                ?.copyWith(color: context.muted, fontWeight: FontWeight.w700)),
      );
}
