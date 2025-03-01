import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class Custom_Lottie extends StatelessWidget {
  final String assetPath;
  final Color color;
  final double scale;

  static const defaultColor = Color(0xFF3F67F4);

  const Custom_Lottie({
    Key? key,
    required this.assetPath,
    this.color = defaultColor,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Lottie.asset(assetPath),
    );
  }
}
