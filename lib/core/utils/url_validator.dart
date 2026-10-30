import '../constants/app_constants.dart';

class SourceException implements Exception {
  const SourceException(this.title, this.message);
  final String title;
  final String message;

  factory SourceException.unsupported(String platform) {
    if (platform == 'Instagram') {
      return const SourceException(
        "Instagram links aren't supported",
        'Instagram content is protected by sign-in and platform controls, '
            'and VidSave does not bypass them. Use a direct link to a video '
            'file that you own or are authorised to download.',
      );
    }
    return SourceException(
      "$platform links aren't supported",
      '$platform links open web pages, not downloadable video files, and the '
          'platform restricts downloading. Use a direct HTTPS link to a video '
          'file that you are authorised to save.',
    );
  }
}

class UrlValidator {
  static Uri parse(String raw) {
    final text = raw.trim();
    if (text.isEmpty) {
      throw const SourceException('Enter a link', 'Paste a video link to continue.');
    }
    final uri = Uri.tryParse(text);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty || text.contains(' ')) {
      throw const SourceException(
          'Invalid link', "That doesn't look like a valid URL. Check it and try again.");
    }
    if (uri.scheme != 'https') {
      throw const SourceException('Secure link required',
          'Only HTTPS links are supported to keep your downloads secure.');
    }
    return uri;
  }

  static String? blockedPlatform(Uri uri) {
    final host = uri.host.toLowerCase();
    for (final e in AppConstants.blockedHosts.entries) {
      if (host == e.key || host.endsWith('.${e.key}')) return e.value;
    }
    return null;
  }
}
