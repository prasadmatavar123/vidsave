import 'package:intl/intl.dart';

class Fmt {
  static String bytes(int b) {
    if (b <= 0) return 'Unknown size';
    const units = ['B', 'KB', 'MB', 'GB'];
    var v = b.toDouble();
    var i = 0;
    while (v >= 1024 && i < units.length - 1) {
      v /= 1024;
      i++;
    }
    return '${v.toStringAsFixed(i == 0 ? 0 : 1)} ${units[i]}';
  }

  static String seconds(int s) => s <= 0 ? '—' : clock(Duration(seconds: s));

  static String clock(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = two(d.inMinutes % 60);
    final s = two(d.inSeconds % 60);
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  static String date(String iso) {
    try {
      return DateFormat('d MMM yyyy, h:mm a').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }
}
