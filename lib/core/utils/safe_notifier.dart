import 'package:flutter/foundation.dart';

/// Prevents "notifyListeners after dispose" errors from async work.
mixin SafeNotifier on ChangeNotifier {
  bool _disposed = false;
  bool get isDisposed => _disposed;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
