import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/download_manager.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/download_model.dart';
import '../widgets/download_card.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = context.watch<DownloadManager>().items;
    final active = items.where((m) => m.isActive).toList();
    final done = items.where((m) => !m.isActive).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Downloads')),
      body: items.isEmpty
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.cloud_download_outlined, size: 64, color: context.muted),
                const SizedBox(height: 12),
                Text('No downloads yet', style: context.tt.titleMedium),
                const SizedBox(height: 4),
                Text('Paste a link on the Home tab to start.',
                    style: TextStyle(color: context.muted)),
              ]),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                if (active.isNotEmpty) _Header('Active (${active.length})'),
                for (final m in active) _item(m),
                if (done.isNotEmpty) _Header('Finished'),
                for (final m in done) _item(m),
              ],
            ),
    );
  }

  Widget _item(DownloadModel m) => Padding(
        key: ValueKey(m.id),
        padding: const EdgeInsets.only(bottom: 12),
        child: DownloadCard(item: m),
      );
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 12),
        child: Text(text,
            style: context.tt.titleSmall
                ?.copyWith(color: context.muted, fontWeight: FontWeight.w700)),
      );
}
