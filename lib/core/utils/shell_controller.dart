import 'package:flutter/foundation.dart';

/// Keeps the selected bottom-navigation tab so any screen can switch tabs.
class ShellController extends ChangeNotifier {
  int index = 0;
  void goTo(int i) {
    if (i == index) return;
    index = i;
    notifyListeners();
  }
}
