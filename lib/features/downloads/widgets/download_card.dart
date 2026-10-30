import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../../../core/services/download_manager.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_route.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/download_model.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/video_thumb.dart';
import '../../player/screens/player_screen.dart';

class DownloadCard extends StatelessWidget {
  const DownloadCard({super.key, required this.item});
  final DownloadModel item;

  @override
  Widget build(BuildContext context) {
    final manager = context.read<DownloadManager>();
    final id = item.id!;
    final s = item.status;
    final pct = '${(item.progress * 100).toStringAsFixed(0)}%';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              VideoThumb(path: item.thumbnailPath, width: 88, height: 66),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.basename(item.videoPath),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(Fmt.bytes(item.fileSize),
                        style: context.tt.bodySmall?.copyWith(color: context.muted)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(s),
            ],
          ),
          if (s == DownloadStatus.downloading ||
              s == DownloadStatus.queued ||
              s == DownloadStatus.paused) ...[
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: s == DownloadStatus.queued ? null : item.progress,
                    minHeight: 7,
                    backgroundColor: context.cs.outlineVariant,
                    color: s == DownloadStatus.paused ? AppColors.warning : context.cs.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(pct, style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
          ],
          if (s == DownloadStatus.failed && manager.errorFor(id) != null) ...[
            const SizedBox(height: 10),
            Text(manager.errorFor(id)!,
                style: context.tt.bodySmall?.copyWith(color: AppColors.error)),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (s == DownloadStatus.downloading && manager.canPause(id))
                _Action(Icons.pause_rounded, 'Pause', () => manager.pause(id)),
              if (s == DownloadStatus.paused)
                _Action(Icons.play_arrow_rounded, 'Resume', () => manager.resume(id)),
              if (s == DownloadStatus.failed)
                _Action(Icons.refresh_rounded, 'Retry', () => manager.retry(id)),
              if (s == DownloadStatus.completed)
                _Action(Icons.play_circle_outline_rounded, 'Play', () {
                  Navigator.of(context).push(AppRoute.fade(PlayerScreen(video: item)));
                }),
              if (s != DownloadStatus.completed)
                _Action(Icons.close_rounded, s == DownloadStatus.failed ? 'Remove' : 'Cancel',
                    () => manager.cancel(id),
                    color: AppColors.error),
            ],
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action(this.icon, this.label, this.onTap, {this.color});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) => TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: TextButton.styleFrom(foregroundColor: color ?? context.cs.primary),
      );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);
  final DownloadStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      DownloadStatus.queued => ('Queued', context.muted),
      DownloadStatus.downloading => ('Downloading', context.cs.primary),
      DownloadStatus.paused => ('Paused', AppColors.warning),
      DownloadStatus.completed => ('Completed', AppColors.success),
      DownloadStatus.failed => ('Failed', AppColors.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: color.withOpacity(.14), borderRadius: BorderRadius.circular(12)),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
