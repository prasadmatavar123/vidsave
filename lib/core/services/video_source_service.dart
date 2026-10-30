import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import '../../data/models/video_info.dart';
import '../constants/app_constants.dart';
import '../utils/net_errors.dart';
import '../utils/url_validator.dart';

/// Validates that a URL is a direct, accessible video file and reads its
/// metadata via HEAD (falling back to a 1-byte ranged GET). It never tries
/// to bypass authentication, DRM or platform restrictions.
class VideoSourceService {
  VideoSourceService(this._dio);
  final Dio _dio;

  static const _mimeToExt = {
    'video/mp4': 'mp4',
    'video/webm': 'webm',
    'video/quicktime': 'mov',
    'video/x-matroska': 'mkv',
    'video/x-m4v': 'm4v',
    'video/3gpp': '3gp',
  };

  Future<VideoInfo> resolve(String raw) async {
    final uri = UrlValidator.parse(raw);
    final blocked = UrlValidator.blockedPlatform(uri);
    if (blocked != null) throw SourceException.unsupported(blocked);

    final h = await _probe(uri);
    final type = (h.value('content-type') ?? '').split(';').first.trim().toLowerCase();
    final urlExt = p.extension(uri.path).replaceFirst('.', '').toLowerCase();
    final genericBinary =
        type.isEmpty || type == 'application/octet-stream' || type == 'binary/octet-stream';
    final isVideo = type.startsWith('video/') ||
        (genericBinary && AppConstants.videoExtensions.contains(urlExt));
    if (!isVideo) {
      throw const SourceException(
        'Not a video file',
        'This link does not point to a downloadable video file. '
            'Use a direct HTTPS link ending in a video format such as .mp4.',
      );
    }

    // Size: Content-Range total (ranged GET) or Content-Length (HEAD).
    var size = 0;
    final range = h.value('content-range');
    if (range != null && range.contains('/')) {
      size = int.tryParse(range.split('/').last) ?? 0;
    }
    if (size == 0) size = int.tryParse(h.value('content-length') ?? '') ?? 0;

    final supportsRange = (h.value('accept-ranges') ?? '').toLowerCase().contains('bytes') ||
        range != null;

    final format = _mimeToExt[type] ??
        (AppConstants.videoExtensions.contains(urlExt) ? urlExt : 'mp4');

    return VideoInfo(
      url: uri.toString(),
      title: _title(h, uri),
      platform: uri.host,
      format: format,
      mimeType: type.isEmpty ? 'video/$format' : type,
      fileSize: size,
      supportsRange: supportsRange,
    );
  }

  Future<Headers> _probe(Uri uri) async {
    bool ok(int? s) => s != null && s < 400;
    try {
      final r = await _dio.headUri(uri, options: Options(validateStatus: ok));
      return r.headers;
    } on DioException {
      final token = CancelToken();
      try {
        final r = await _dio.getUri<ResponseBody>(
          uri,
          cancelToken: token,
          options: Options(
            responseType: ResponseType.stream,
            headers: {'range': 'bytes=0-0'},
            validateStatus: ok,
          ),
        );
        token.cancel(); // we only wanted the headers
        return r.headers;
      } on DioException catch (e) {
        throw SourceException('Cannot reach this link', NetErrors.describe(e));
      }
    }
  }

  String _title(Headers h, Uri uri) {
    final cd = h.value('content-disposition');
    String? name;
    if (cd != null) {
      final m = RegExp(r'filename\*?=(?:UTF-8\x27\x27)?"?([^";]+)"?').firstMatch(cd);
      name = m?.group(1);
    }
    name ??= uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
    if (name != null) {
      try {
        name = Uri.decodeComponent(name);
      } catch (_) {}
      name = p.basenameWithoutExtension(name!).trim();
    }
    return (name == null || name.isEmpty)
        ? 'video_${DateTime.now().millisecondsSinceEpoch}'
        : name;
  }
}
