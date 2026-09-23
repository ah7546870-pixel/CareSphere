import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashNavNotifier extends StateNotifier<bool> {
  SplashNavNotifier() : super(true);

  void finishSplash() {
    state = false;
  }
}

final splashNavProvider = StateNotifierProvider<SplashNavNotifier, bool>((ref) {
  return SplashNavNotifier();
});
