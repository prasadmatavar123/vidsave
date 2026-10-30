/// Result of validating a source URL (before the download is queued).
class VideoInfo {
  const VideoInfo({
    required this.url,
    required this.title,
    required this.platform,
    required this.format,
    required this.mimeType,
    this.fileSize = 0,
    this.supportsRange = false,
    this.durationSeconds = 0,
    this.thumbnailPath,
  });

  final String url;
  final String title;
  final String platform;
  final String format;
  final String mimeType;
  final int fileSize;
  final bool supportsRange;
  final int durationSeconds;
  final String? thumbnailPath;

  VideoInfo copyWith({int? durationSeconds, String? thumbnailPath}) => VideoInfo(
        url: url,
        title: title,
        platform: platform,
        format: format,
        mimeType: mimeType,
        fileSize: fileSize,
        supportsRange: supportsRange,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      );
}
