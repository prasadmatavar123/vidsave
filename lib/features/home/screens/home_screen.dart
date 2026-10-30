import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_route.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/download_model.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/video_thumb.dart';
import '../../player/screens/player_screen.dart';
import '../../preview/screens/preview_screen.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/url_input_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  /// When the user returns from copying a link, pre-fill the field.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _controller.text.isEmpty) {
      _readClipboard(silent: true);
    }
  }

  Future<void> _readClipboard({bool silent = false}) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (!mounted) return;
    if (text.isEmpty) {
      if (!silent) _snack('Clipboard is empty');
      return;
    }
    if (silent && !text.startsWith('https://')) return;
    _controller.text = text;
    _controller.selection = TextSelection.collapsed(offset: text.length);
    context.read<HomeViewModel>().clearError();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _download() async {
    FocusScope.of(context).unfocus();
    final vm = context.read<HomeViewModel>();
    final info = await vm.check(_controller.text);
    if (info != null && mounted) {
      Navigator.of(context).push(AppRoute.fade(PreviewScreen(info: info)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    gradient: AppColors.gradient, borderRadius: BorderRadius.circular(13)),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Text(AppConstants.appName,
                  style: context.tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: context.cs.primary.withOpacity(.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  Icon(Icons.download_done_rounded, size: 16, color: context.cs.primary),
                  const SizedBox(width: 6),
                  Text('${vm.totalDownloads} downloads',
                      style: context.tt.labelMedium?.copyWith(
                          color: context.cs.primary, fontWeight: FontWeight.w700)),
                ]),
              ),
            ],
          ).animate().fadeIn(),
          const SizedBox(height: 28),
          Text('Download Your Favourite Videos',
                  style: context.tt.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800, height: 1.15))
              .animate()
              .fadeIn(delay: 80.ms)
              .slideY(begin: .15),
          const SizedBox(height: 8),
          Text('Save videos for offline viewing.',
                  style: context.tt.bodyLarge?.copyWith(color: context.muted))
              .animate()
              .fadeIn(delay: 140.ms),
          const SizedBox(height: 22),
          UrlInputCard(
            controller: _controller,
            loading: vm.resolving,
            onPaste: _readClipboard,
            onClear: () {
              _controller.clear();
              vm.clearError();
            },
            onDownload: _download,
            onChanged: vm.clearError,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: .12),
          if (vm.error != null) ...[
            const SizedBox(height: 14),
            _ErrorBanner(title: vm.error!.title, message: vm.error!.message)
                .animate()
                .fadeIn()
                .shake(hz: 3, duration: 350.ms),
          ],
          const SizedBox(height: 16),
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_user_outlined, color: context.cs.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Supported sources',
                          style: context.tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        'Direct HTTPS links to video files (MP4, WebM, MOV, M4V, MKV) that '
                        'you own or are authorised to download. Instagram, YouTube, TikTok '
                        'and other protected platform links are not supported.',
                        style: context.tt.bodySmall?.copyWith(color: context.muted, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 260.ms),
          const SizedBox(height: 28),
          Text('Recently downloaded',
              style: context.tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (vm.recent.isEmpty)
            AppCard(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text('Your downloaded videos will appear here.',
                      style: TextStyle(color: context.muted)),
                ),
              ),
            )
          else
            SizedBox(
              height: 168,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: vm.recent.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _RecentTile(video: vm.recent[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.video});
  final DownloadModel video;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(AppRoute.fade(PlayerScreen(video: video))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(children: [
                VideoThumb(path: video.thumbnailPath, radius: 18, width: 170),
                const Positioned.fill(
                    child: Center(
                        child: Icon(Icons.play_circle_fill_rounded,
                            color: Colors.white70, size: 38))),
              ]),
            ),
            const SizedBox(height: 8),
            Text(video.videoTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            Text(Fmt.bytes(video.fileSize),
                style: context.tt.bodySmall?.copyWith(color: context.muted)),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.error.withOpacity(.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: context.tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(message,
                    style: context.tt.bodySmall?.copyWith(color: context.muted, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
