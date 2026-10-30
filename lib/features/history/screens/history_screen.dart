import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_route.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/download_model.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/video_thumb.dart';
import '../../player/screens/player_screen.dart';
import '../viewmodels/history_viewmodel.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) {
        context.read<HistoryViewModel>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _play(DownloadModel m) async {
    if (m.status != DownloadStatus.completed || !await File(m.videoPath).exists()) {
      _snack('The video file is no longer available.');
      return;
    }
    if (!mounted) return;
    Navigator.of(context).push(AppRoute.fade(PlayerScreen(video: m)));
  }

  Future<void> _share(DownloadModel m) async {
    if (!await File(m.videoPath).exists()) {
      _snack('The video file is no longer available.');
      return;
    }
    await Share.shareXFiles([XFile(m.videoPath)], text: m.videoTitle);
  }

  Future<void> _delete(DownloadModel m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete video?'),
        content: const Text('The file and its history entry will be removed from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok == true && mounted) await context.read<HistoryViewModel>().delete(m);
  }

  Future<void> _info(DownloadModel m) async {
    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(k, style: TextStyle(color: context.muted, fontSize: 12)),
            SelectableText(v, style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
        );
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('File information'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            row('Title', m.videoTitle),
            row('Status', m.status.name),
            row('Size', Fmt.bytes(m.fileSize)),
            row('Duration', Fmt.seconds(m.duration)),
            row('Source', m.platform),
            row('Downloaded', Fmt.date(m.createdAt)),
            row('Location', m.videoPath),
            row('Original link', m.originalUrl),
          ]),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HistoryViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          PopupMenuButton<bool>(
            tooltip: 'Sort',
            icon: const Icon(Icons.sort_rounded),
            initialValue: vm.newest,
            onSelected: vm.setNewest,
            itemBuilder: (_) => const [
              PopupMenuItem(value: true, child: Text('Newest first')),
              PopupMenuItem(value: false, child: Text('Oldest first')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: TextField(
              onChanged: vm.setQuery,
              decoration: const InputDecoration(
                  hintText: 'Search videos', prefixIcon: Icon(Icons.search_rounded)),
            ),
          ),
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                for (final f in HistoryFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f.name[0].toUpperCase() + f.name.substring(1)),
                      selected: vm.filter == f,
                      onSelected: (_) => vm.setFilter(f),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: vm.items.isEmpty && !vm.loading
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.history_rounded, size: 60, color: context.muted),
                      const SizedBox(height: 10),
                      Text('Nothing here yet', style: context.tt.titleMedium),
                    ]),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: vm.items.length + (vm.loading ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i >= vm.items.length) {
                        return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()));
                      }
                      final m = vm.items[i];
                      return Padding(
                        key: ValueKey(m.id),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _HistoryTile(
                          item: m,
                          onPlay: () => _play(m),
                          onShare: () => _share(m),
                          onInfo: () => _info(m),
                          onDelete: () => _delete(m),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.item,
    required this.onPlay,
    required this.onShare,
    required this.onInfo,
    required this.onDelete,
  });
  final DownloadModel item;
  final VoidCallback onPlay, onShare, onInfo, onDelete;

  @override
  Widget build(BuildContext context) {
    final ok = item.status == DownloadStatus.completed;
    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: ok ? onPlay : onInfo,
      child: Row(
        children: [
          VideoThumb(path: item.thumbnailPath, width: 92, height: 68),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.videoTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('${Fmt.bytes(item.fileSize)} • ${Fmt.date(item.createdAt)}',
                    style: context.tt.bodySmall?.copyWith(color: context.muted)),
                const SizedBox(height: 4),
                Text(ok ? 'Completed' : 'Failed',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ok ? AppColors.success : AppColors.error)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              switch (v) {
                case 'play':
                  onPlay();
                case 'share':
                  onShare();
                case 'info':
                  onInfo();
                case 'delete':
                  onDelete();
              }
            },
            itemBuilder: (_) => [
              if (ok) const PopupMenuItem(value: 'play', child: Text('Play')),
              if (ok) const PopupMenuItem(value: 'share', child: Text('Share')),
              const PopupMenuItem(value: 'info', child: Text('File information')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}
