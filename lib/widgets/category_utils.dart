
import 'dart:ui';

import 'package:flutter/material.dart';

class CategoryUtils {
  // Function to get emoji based on category
  static String getCategoryEmoji(String category) {
    switch (category) {
      case "Travel":
        return "✈️";
      case "House Rent":
        return "🏠";
      case "Food & Drink":
        return "🍔";
      case "Movies & TV":
        return "📺";
      case "Party":
        return "🎊";
      case "Other":
        return "📌";
      default:
        return "📁"; // Default emoji
    }
  }
  
  // Function to get color based on category
  static Color getCategoryColor(String category) {
    switch (category) {
      case "Travel":
        return Colors.blue;
      case "House Rent":
        return Colors.green;
      case "Food & Drink":
        return Colors.orange;
      case "Movies & TV":
        return Colors.purple;
      case "Party":
        return Colors.pink;
      case "Other":
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }
}



