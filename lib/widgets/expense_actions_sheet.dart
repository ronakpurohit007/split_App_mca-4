// lib/widgets/expense_actions_sheet.dart
import 'package:flutter/material.dart';
import 'package:login/other/print.dart';
import 'package:login/other/splite.dart';
import 'package:login/widgets/calculator.dart';
import 'package:login/widgets/colors.dart';


class ExpenseActionsSheet extends StatelessWidget {
  final String groupId;
  final List<String> members;
  final Function() onAddExpensePressed;

  const ExpenseActionsSheet({
    Key? key,
    required this.groupId,
    required this.members,
    required this.onAddExpensePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 16, bottom: 32, left: 24, right: 24),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: AppColors.gray, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.gray,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          SizedBox(height: 24),
          
          // Title
          Text(
            "Expense Actions",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 32),
          
          // Action buttons in a row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Print Button
              _buildActionButton(
                context,
                Icons.print_rounded,
                "Print",
                AppColors.accentColor,
                () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PrintExpenseScreen(
                        groupId: groupId,
                        members: members,
                      ),
                    ),
                  );
                },
              ),
              
              // Calculator Button
              _buildActionButton(
                context,
                Icons.calculate_rounded,
                "Calculator",
                AppColors.main,
                () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CalculatorScreen(
                        groupId: groupId,
                      ),
                    ),
                  );
                },
              ),
              
              // Split Button
              _buildActionButton(
                context,
                Icons.pie_chart_rounded,
                "Split",
                AppColors.SuccessColor,
                () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SplitBillScreen(
                        groupId: groupId,
                        members: members,
                      ),
                    ),
                  );
                },
              ),
              
              // Add Expense Button
              _buildActionButton(
                context,
                Icons.add_rounded,
                "Add",
                AppColors.main,
                () {
                  Navigator.pop(context);
                  onAddExpensePressed();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 70,
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.5),
              ),
              child: Icon(
                icon,
                color: color,
                size: 26,
              ),
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}