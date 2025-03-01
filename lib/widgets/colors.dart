import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF006064);
  static const Color secondaryColor = Color(0xFF80DEEA);
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Colors.black;
  static const Color accentColor = Colors.blueAccent;
  static  Color blueGrid1 = Color(0xFF0277BD);
  static  Color blueGrid2 = Color(0xFF90CAF9);
  static const FocusColor = Colors.blue;
  static const ButtonColor = Color(0xFF303030);
  static const ErrorColor = Colors.red;
  static const SuccessColor = Colors.green;


  static const mainShadow = Color(0xFF252525);
  static const Color main = Color(0xFFFFB900);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color gray = Colors.grey;

  static BoxShadow softShadow = BoxShadow(
    color: Colors.black.withOpacity(0.08),
    spreadRadius: 0,
    blurRadius: 50.4,
    offset: const Offset(0, 4),
  );
  static BoxShadow hardShadow = BoxShadow(
    color: Colors.black.withOpacity(0.08),
    spreadRadius: 0,
    blurRadius: 50.4,
    offset: const Offset(0, 4),
  );

}
