import 'package:flutter/material.dart';
import 'package:login/widgets/colors.dart';

class SnackbarUtils {
  static void showErrorSnackbar(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 3)}) {
    _showSnackbar(
      context,
      message,
      backgroundColor: AppColors.ErrorColor,
      textColor: AppColors.backgroundColor,
      icon: Icons.error,
      duration: duration,
    );
  }

  static void showSuccessSnackbar(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 3)}) {
    _showSnackbar(
      context,
      message,
      backgroundColor: AppColors.SuccessColor,
      textColor: AppColors.backgroundColor,
      icon: Icons.check_circle,
      duration: duration,
    );
  }


  static void showExitSnackbar(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 3)}) {
    _showSnackbarExit(
      context,
      message,
      backgroundColor: AppColors.main,
      textColor: AppColors.black,
      // icon: Icons.check_circle,
      duration: duration,
    );
  }

  static void _showSnackbar(
      BuildContext context,
      String message, {
        required Color backgroundColor,
        required Color textColor,
        required IconData icon,
        required Duration duration,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: textColor),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: textColor),
              ),
            ),

            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
              child: Icon(Icons.close, color: Colors.black),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: duration,
      ),
    );
  }


  static void _showSnackbarExit(
      BuildContext context,
      String message, {
        required Color backgroundColor,
        required Color textColor,
        // required IconData icon,
        required Duration duration,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            // Icon(icon, color: textColor),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: textColor),
              ),
            ),

            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
              child: Icon(Icons.close, color: Colors.black),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: duration,
      ),
    );
  }

}
