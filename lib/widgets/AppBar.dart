import 'package:flutter/material.dart';


import 'colors.dart'; // Make sure to import your AppColors

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final double height;
  final List<Widget>? actions; // Optional actions parameter

  CustomAppBar({
    required this.title,
    
    this.height = 80,
    this.actions, // Initialize the optional actions
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 2,
      automaticallyImplyLeading: false,
      title: Padding(
        padding: const EdgeInsets.only(top: 28.0),
        child: Text(
          title,
          style: TextStyle(color: AppColors.black, fontSize: 18),
        ),
      ),
      centerTitle: true,
      toolbarHeight: height,
      toolbarOpacity: 0.8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
            bottomRight: Radius.circular(25),
            bottomLeft: Radius.circular(25)),
      ),
      elevation: 0.00,
      backgroundColor: AppColors.main,
      actions: actions, // Use the actions parameter
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
