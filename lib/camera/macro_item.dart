import 'package:flutter/cupertino.dart';

class MacroItem extends StatelessWidget {
  final String image;
  final String label;
  final String value;

  const MacroItem({required this.image, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(image, width: 30, height: 30),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: "$label ", style: const TextStyle(fontWeight: FontWeight.w500)),
              TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}