import 'dart:ui';

import 'package:flutter/cupertino.dart';

class NutrientItem extends StatelessWidget {
  final String label;
  final String value;
  final String imagePath;

  const NutrientItem({
    super.key,
    required this.label,
    required this.value,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          imagePath,
          width: 28,
          height: 28,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
