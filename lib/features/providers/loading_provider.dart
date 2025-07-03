import 'dart:async';
import 'package:flutter/material.dart';

class LoadingProvider with ChangeNotifier {
  double _progress = 0.0;
  double get progress => _progress;

  List<String> _recommendations = [];
  List<String> get recommendations => _recommendations;

  String _currentStatus = '';
  String get currentStatus => _currentStatus;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Timer? _timer;

  void startLoading({VoidCallback? onComplete}) {
    _progress = 0;
    _isInitialized = true;
    _currentStatus = 'Initializing your profile...';
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
        _currentStatus = 'Your nutrition guide is ready!';
        notifyListeners();
        onComplete?.call();
      } else {
        _progress += 1;
        _updateStatus();
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void _updateStatus() {
    if (_progress < 20) {
      _currentStatus = 'Analyzing your profile...';
    } else if (_progress < 40) {
      _currentStatus = 'Calculating nutrition needs...';
    } else if (_progress < 60) {
      _currentStatus = 'Optimizing meal plans...';
    } else if (_progress < 80) {
      _currentStatus = 'Finalizing recommendations...';
    } else if (_progress < 100) {
      _currentStatus = 'Almost ready...';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
