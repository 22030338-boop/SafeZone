
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeProvider =
    NotifierProvider<ThemeNotifier, bool>(ThemeNotifier.new);

class ThemeNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  void toggleTheme() {
    state = !state;
  }

  void setDarkMode(bool value) {
    state = value;
  }
}
