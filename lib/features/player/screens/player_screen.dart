import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/download_model.dart';
import '../../../shared/widgets/app_card.dart';
import '../viewmodels/player_viewmodel.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key, required this.video});
  final DownloadModel video;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => PlayerViewModel(video),
        child: const _PlayerView(),
      );
}

class _PlayerView extends StatelessWidget {
  const _PlayerView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlayerViewModel>();
    final stage = _Stage(vm: vm);
    return PopScope(
      canPop: !vm.fullscreen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) vm.toggleFullscreen();
      },
      child: Scaffold(
        backgroundColor: vm.fullscreen ? Colors.black : null,
        body: vm.fullscreen
            ? SizedBox.expand(child: stage)
            : SafeArea(
                child: Column(
                  children: [
                    AspectRatio(aspectRatio: 16 / 9, child: stage),
                    Expanded(child: _Info(video: vm.video, vm: vm)),
                  ],
                ),
              ),
      ),
    );
  }
}

class _Stage extends StatelessWidget {
  const _Stage({required this.vm});
  final PlayerViewModel vm;

  @override
  Widget build(BuildContext context) {
    final c = vm.controller;
    return Container(
      color: Colors.black,
      child: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : vm.error != null || c == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
                      const SizedBox(height: 10),
                      Text(vm.error ?? 'Playback error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white)),
                      TextButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          child: const Text('Go back')),
                    ]),
                  ),
                )
              : GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: vm.toggleControls,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Center(
                          child: AspectRatio(
                              aspectRatio: c.value.aspectRatio, child: VideoPlayer(c))),
                      AnimatedOpacity(
                        opacity: vm.controlsVisible ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: IgnorePointer(
                            ignoring: !vm.controlsVisible, child: _Controls(vm: vm)),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.vm});
  final PlayerViewModel vm;

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black54, Colors.transparent, Colors.black54],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: white),
                onPressed: () => Navigator.of(context).maybePop()),
            Expanded(
                child: Text(vm.video.videoTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: white, fontWeight: FontWeight.w600))),
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(
                iconSize: 32,
                icon: const Icon(Icons.replay_10_rounded, color: white),
                onPressed: () => vm.skip(-10)),
            const SizedBox(width: 12),
            IconButton(
              iconSize: 48,
              icon: Icon(vm.playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                  color: white),
              onPressed: vm.togglePlay,
            ),
            const SizedBox(width: 12),
            IconButton(
                iconSize: 32,
                icon: const Icon(Icons.forward_10_rounded, color: white),
                onPressed: () => vm.skip(10)),
          ]),
          Row(children: [
            const SizedBox(width: 12),
            Text(Fmt.clock(vm.position),
                style: const TextStyle(color: white, fontSize: 12)),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  activeTrackColor: context.cs.primary,
                  thumbColor: context.cs.primary,
                  inactiveTrackColor: Colors.white24,
                ),
                child: Slider(
                  value: vm.sliderValue,
                  max: vm.maxMs,
                  onChangeStart: vm.dragStart,
                  onChanged: vm.drag,
                  onChangeEnd: vm.dragEnd,
                ),
              ),
            ),
            Text(Fmt.clock(vm.duration),
                style: const TextStyle(color: white, fontSize: 12)),
            PopupMenuButton<double>(
              tooltip: 'Playback speed',
              initialValue: vm.speed,
              onSelected: vm.setSpeed,
              itemBuilder: (_) => [
                for (final s in const [0.5, 1.0, 1.25, 1.5, 2.0])
                  PopupMenuItem(value: s, child: Text('${s}x')),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('${vm.speed}x',
                    style: const TextStyle(color: white, fontWeight: FontWeight.w700)),
              ),
            ),
            IconButton(
              icon: Icon(vm.fullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                  color: white),
              onPressed: vm.toggleFullscreen,
            ),
          ]),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.video, required this.vm});
  final DownloadModel video;
  final PlayerViewModel vm;

  @override
  Widget build(BuildContext context) {
    final dur = vm.ready ? vm.duration.inSeconds : video.duration;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(video.videoTitle,
            style: context.tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        AppCard(
          child: Column(children: [
            _line(context, 'Duration', Fmt.seconds(dur)),
            _line(context, 'Size', Fmt.bytes(video.fileSize)),
            _line(context, 'Source', video.platform),
            _line(context, 'Downloaded', Fmt.date(video.createdAt)),
            _line(context, 'Playback', 'Offline', last: true),
          ]),
        ),
      ],
    );
  }

  Widget _line(BuildContext context, String k, String v, {bool last = false}) => Padding(
        padding: EdgeInsets.only(bottom: last ? 0 : 12),
        child: Row(children: [
          Text(k, style: TextStyle(color: context.muted)),
          const Spacer(),
          Flexible(
              child: Text(v,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
      );
}
