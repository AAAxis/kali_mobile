import 'package:flutter/material.dart';

class OtpProvider extends ChangeNotifier {
  final int length;
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;

  OtpProvider({this.length = 6})
      : controllers = List.generate(6, (_) => TextEditingController()),
        focusNodes = List.generate(6, (_) => FocusNode());

  String get otp => controllers.map((controller) => controller.text).join();

  void onChanged(String value, int index) {
    if (value.length == 1 && index < length - 1) {
      focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
    for (final n in focusNodes) {
      n.dispose();
    }
    super.dispose();
  }
}
