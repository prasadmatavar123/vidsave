enum DownloadStatus { queued, downloading, paused, completed, failed }

class DownloadModel {
  const DownloadModel({
    this.id,
    required this.originalUrl,
    required this.videoTitle,
    required this.videoPath,
    this.thumbnailPath,
    required this.platform,
    this.fileSize = 0,
    this.duration = 0,
    this.status = DownloadStatus.queued,
    this.progress = 0,
    required this.createdAt,
  });

  final int? id;
  final String originalUrl;
  final String videoTitle;
  final String videoPath;
  final String? thumbnailPath;
  final String platform;
  final int fileSize;
  final int duration; // seconds
  final DownloadStatus status;
  final double progress; // 0..1
  final String createdAt;

  bool get isActive =>
      status == DownloadStatus.queued ||
      status == DownloadStatus.downloading ||
      status == DownloadStatus.paused;

  DownloadModel copyWith({
    int? id,
    String? thumbnailPath,
    int? fileSize,
    int? duration,
    DownloadStatus? status,
    double? progress,
  }) =>
      DownloadModel(
        id: id ?? this.id,
        originalUrl: originalUrl,
        videoTitle: videoTitle,
        videoPath: videoPath,
        thumbnailPath: thumbnailPath ?? this.thumbnailPath,
        platform: platform,
        fileSize: fileSize ?? this.fileSize,
        duration: duration ?? this.duration,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'original_url': originalUrl,
        'video_title': videoTitle,
        'video_path': videoPath,
        'thumbnail_path': thumbnailPath,
        'platform': platform,
        'file_size': fileSize,
        'duration': duration,
        'download_status': status.name,
        'progress': progress,
        'created_at': createdAt,
      };

  factory DownloadModel.fromMap(Map<String, Object?> m) => DownloadModel(
        id: m['id'] as int?,
        originalUrl: m['original_url'] as String? ?? '',
        videoTitle: m['video_title'] as String? ?? 'Video',
        videoPath: m['video_path'] as String? ?? '',
        thumbnailPath: m['thumbnail_path'] as String?,
        platform: m['platform'] as String? ?? '',
        fileSize: (m['file_size'] as num?)?.toInt() ?? 0,
        duration: (m['duration'] as num?)?.toInt() ?? 0,
        status: DownloadStatus.values.firstWhere(
          (s) => s.name == m['download_status'],
          orElse: () => DownloadStatus.failed,
        ),
        progress: (m['progress'] as num?)?.toDouble() ?? 0,
        createdAt: m['created_at'] as String? ?? '',
      );
}
