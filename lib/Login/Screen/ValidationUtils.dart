import 'package:flutter/src/widgets/framework.dart';

class ValidationUtils {
  ValidationUtils(BuildContext context);

  /// Validate email format
  /// Validate email format
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return "Email is required";
    }
    // Basic email validation regex
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      return "Enter a valid email";
    }
    return null;
  }

  /// Validate password strength
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return "Password is required";
    }
    if (password.length < 8) {
      return "Password must be at least 8 characters long";
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return "Password must include at least one uppercase letter";
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return "Password must include at least one lowercase letter";
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return "Password must include at least one digit";
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return "Password must include at least one special character";
    }
    return null;
  }

  /// Confirm password logic
  static String? validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return "Confirm Password is required";
    }
    if (password != confirmPassword) {
      return "Passwords do not match";
    }
    return null;
  }
}
