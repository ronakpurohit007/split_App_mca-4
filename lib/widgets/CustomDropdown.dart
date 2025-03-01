import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'colors.dart';
import 'login_btn.dart';

class CustomDropdown extends StatefulWidget {
  final List<String> items;
  final Function(String) onItemSelected;
  final String hintText;
  final String? defaultValue;
  final bool isRead;
  final double? containerHeight;

  const CustomDropdown({
    super.key,
    required this.items,
    required this.onItemSelected,
    required this.hintText,
    required this.isRead,
    this.defaultValue,
    this.containerHeight,
  });

  @override
  CustomDropdownState createState() => CustomDropdownState();
}

class CustomDropdownState extends State<CustomDropdown>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool isDropdownOpen = false;
  late String selectedItem;

  @override
  void initState() {
    super.initState();

    selectedItem = widget.defaultValue?.isNotEmpty == true
        ? widget.defaultValue!
        : widget.hintText;

    // Animation setup
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.0),
          child: GestureDetector(
            onTap: () {
              if (widget.isRead) {
                setState(() {
                  isDropdownOpen = !isDropdownOpen;
                });
                isDropdownOpen ? _animationController.forward() : _animationController.reverse();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.gray,
                    width: 1, // Adjust thickness
                  ),
                ),
                color: AppColors.black, // Background color
                boxShadow: [AppColors.softShadow],

              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child:
                       Text(
                        selectedItem,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: AppTypography.inputPlaceholder(context).copyWith(
                          color: widget.defaultValue?.isNotEmpty == true
                              ? Colors.white
                              : AppColors.gray,
                        ),
                      ),
                    ),

                  RotationTransition(
                    turns: Tween(begin: 0.0, end: 0.5).animate(_animationController),
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey,
                      ),
                      child: Icon(
                        CupertinoIcons.chevron_down, // Always use chevron_down
                        size: 25,
                        color: Colors.black,
                      ),
                    ),
                  )

                ],
              ),
            ),
          ),
        ),

        // Dropdown List (Always in Tree, Controls Visibility)
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: isDropdownOpen
              ? widget.containerHeight ?? 200
              : 0, // Keeps it in tree
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.gray),
                borderRadius: BorderRadius.circular(9),
                color: AppColors.black,
                boxShadow: [AppColors.softShadow],
              ),
              child: ListView.builder(
                key: ValueKey(
                    isDropdownOpen),
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: widget.items.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedItem = widget.items[index];
                        isDropdownOpen = false;
                        widget.onItemSelected(selectedItem);
                        _animationController.reverse();
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        widget.items[index],
                        style: AppTypography.inputPlaceholder(context).copyWith(
                          color: widget.defaultValue?.isNotEmpty == true
                              ? Colors.white
                              : AppColors.gray,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
