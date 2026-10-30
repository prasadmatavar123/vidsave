import 'package:gal/gal.dart';
import '../constants/app_constants.dart';

class GalleryService {
  /// Returns true when the video was copied to the Gallery.
  Future<bool> saveVideo(String path) async {
    try {
      if (!await Gal.hasAccess(toAlbum: true)) {
        if (!await Gal.requestAccess(toAlbum: true)) return false;
      }
      await Gal.putVideo(path, album: AppConstants.albumName);
      return true;
    } catch (_) {
      return false;
    }
  }
}
