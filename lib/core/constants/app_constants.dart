class AppConstants {
  static const appName = 'VidSave';
  static const appVersion = '1.0.0';
  static const dbName = 'video_downloader.db';
  static const dbVersion = 1;
  static const albumName = 'VidSave';
  static const maxConcurrent = 3;
  static const pageSize = 20;

  static const videoExtensions = ['mp4', 'm4v', 'mov', 'webm', 'mkv', '3gp'];

  /// Platforms whose links are web pages protected by login / platform
  /// controls. We never try to bypass these.
  static const blockedHosts = <String, String>{
    'instagram.com': 'Instagram',
    'facebook.com': 'Facebook',
    'fb.watch': 'Facebook',
    'tiktok.com': 'TikTok',
    'youtube.com': 'YouTube',
    'youtu.be': 'YouTube',
    'twitter.com': 'X (Twitter)',
    'x.com': 'X (Twitter)',
    'netflix.com': 'Netflix',
    'primevideo.com': 'Prime Video',
    'hotstar.com': 'Hotstar',
    'disneyplus.com': 'Disney+',
  };

  static const privacyPolicy =
      'VidSave works entirely on your device.\n\n'
      '• No account, no sign-in, no cloud database.\n'
      '• Download history is stored locally in a SQLite database.\n'
      '• Videos are saved in local storage (and optionally your Gallery).\n'
      '• The app only contacts the video URLs you enter.\n'
      '• No personal information is collected or shared.\n\n'
      'Only download videos you own or are authorised to save.';
}
