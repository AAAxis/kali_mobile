import 'dart:async';
import 'package:flutter/material.dart';

class LoadingProvider with ChangeNotifier {
  double _progress = 0.0;
  double get progress => _progress;

  Timer? _timer;

  void startLoading({VoidCallback? onComplete}) {
    _progress = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_progress >= 100) {
        _timer?.cancel();
        onComplete?.call(); // 🔥 Call when done
      } else {
        _progress += 1;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
