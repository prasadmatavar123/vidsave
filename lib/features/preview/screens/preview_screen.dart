import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../core/services/download_manager.dart';
import '../../../core/services/thumbnail_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/shell_controller.dart';
import '../../../data/models/video_info.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/video_thumb.dart';
import '../viewmodels/preview_viewmodel.dart';

class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key, required this.info});
  final VideoInfo info;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (c) => PreviewViewModel(info, c.read<ThumbnailService>()),
        child: const _PreviewView(),
      );
}

class _PreviewView extends StatelessWidget {
  const _PreviewView();

  Future<void> _download(BuildContext context, PreviewViewModel vm) async {
    final manager = context.read<DownloadManager>();
    final shell = context.read<ShellController>();
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await manager.enqueue(vm.info);
    if (result == EnqueueResult.duplicate) {
      messenger.showSnackBar(
          const SnackBar(content: Text('This video is already being downloaded.')));
      return;
    }
    shell.goTo(1);
    nav.popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PreviewViewModel>();
    final info = vm.info;
    final c = vm.controller;
    return Scaffold(
      appBar: AppBar(title: const Text('Video preview')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          AspectRatio(
            aspectRatio: vm.aspect,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (vm.ready && vm.started && c != null)
                    VideoPlayer(c)
                  else
                    VideoThumb(path: info.thumbnailPath, radius: 0),
                  if (vm.loading)
                    const Center(child: CircularProgressIndicator())
                  else if (vm.ready)
                    GestureDetector(
                      onTap: vm.togglePlay,
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedOpacity(
                        opacity: vm.playing ? 0 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: const BoxDecoration(
                                color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.play_arrow_rounded,
                                color: Colors.white, size: 40),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (vm.ready && vm.started && c != null) ...[
            const SizedBox(height: 10),
            VideoProgressIndicator(c, allowScrubbing: true,
                colors: VideoProgressColors(playedColor: context.cs.primary)),
          ],
          if (vm.previewFailed)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Preview isn’t available for this source, but it can still be downloaded.',
                style: context.tt.bodySmall?.copyWith(color: AppColors.warning),
              ),
            ),
          const SizedBox(height: 20),
          Text(info.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: context.tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          AppCard(
            child: Column(children: [
              _Row('Duration', vm.loading ? 'Loading…' : Fmt.seconds(info.durationSeconds)),
              _Row('Format', info.format.toUpperCase()),
              _Row('File size', Fmt.bytes(info.fileSize)),
              _Row('Source', info.platform),
              _Row('Pause / resume', info.supportsRange ? 'Supported' : 'Not supported',
                  last: true),
            ]),
          ),
          const SizedBox(height: 22),
          GradientButton(
            label: 'Download video',
            icon: Icons.download_rounded,
            onPressed: () => _download(context, vm),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.last = false});
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: last ? 0 : 12),
        child: Row(
          children: [
            Text(label, style: TextStyle(color: context.muted)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(value,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}
