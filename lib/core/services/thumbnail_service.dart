import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// Generates and caches JPEG thumbnails from a local file or a network URL.
class ThumbnailService {
  Future<String?> generate({required String source, required String name}) async {
    try {
      final base = await getApplicationSupportDirectory();
      final dir = Directory(p.join(base.path, 'thumbs'));
      await dir.create(recursive: true);
      final out = p.join(dir.path, '$name.jpg');
      if (await File(out).exists()) return out;
      return await VideoThumbnail.thumbnailFile(
        video: source,
        thumbnailPath: out,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 480,
        quality: 75,
        timeMs: 1000,
      );
    } catch (_) {
      return null;
    }
  }
}
