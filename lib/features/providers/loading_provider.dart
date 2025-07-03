import 'dart:async';
import 'package:flutter/material.dart';

class LoadingProvider with ChangeNotifier {
  double _progress = 0.0;
  double get progress => _progress;

  List<String> _recommendations = [];
  List<String> get recommendations => _recommendations;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Timer? _timer;

  void startLoading({VoidCallback? onComplete}) {
    _progress = 0;
    _isInitialized = true;
    _recommendations = [
      'Calculate daily calorie needs',
      'Set up macro distribution',
      'Plan meal timings',
      'Track water intake',
      'Monitor activity levels'
    ];
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_progress >= 100) {
        timer.cancel();
        onComplete?.call();
      } else {
        _progress += 1;
        notifyListeners();
      }
    });
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
