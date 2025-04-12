// lib/screens/split_bill_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:login/widgets/AppBar.dart';
import 'package:login/widgets/colors.dart';
import 'package:login/widgets/login_btn.dart';
import 'package:login/widgets/snackbar_utils.dart';
import 'package:login/widgets/logger.dart';

final ConsoleAppLogger logger = ConsoleAppLogger();

enum SplitMethod { equal, percentage, amount, ratio }

class SplitBillScreen extends StatefulWidget {
  final String groupId;
  final List<String> members;

  SplitBillScreen({
    required this.groupId,
    required this.members,
  });

  @override
  _SplitBillScreenState createState() => _SplitBillScreenState();
}

class _SplitBillScreenState extends State<SplitBillScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  SplitMethod selectedMethod = SplitMethod.equal;
  String selectedPayer = '';
  double totalAmount = 0.0;
  bool isLoading = false;

  // Store individual member split info
  Map<String, double> memberShares = {};
  Map<String, TextEditingController> memberControllers = {};

  @override
  void initState() {
    super.initState();
    // Initialize with the first member as default payer if available
    if (widget.members.isNotEmpty) {
      selectedPayer = widget.members[0];
    }

    // Initialize member controllers and shares
    for (String member in widget.members) {
      memberControllers[member] = TextEditingController();
      memberShares[member] = 0.0;
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    titleController.dispose();
    amountController.dispose();
    memberControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  // Calculate equal split
  void _calculateEqualSplit() {
    double amount = double.tryParse(amountController.text) ?? 0.0;
    int memberCount = widget.members.length;

    if (memberCount > 0 && amount > 0) {
      double equalShare = amount / memberCount;

      for (String member in widget.members) {
        memberShares[member] = equalShare;
        memberControllers[member]?.text = equalShare.toStringAsFixed(2);
      }

      setState(() {
        totalAmount = amount;
      });
    }
  }

  // Calculate percentage split
  void _calculatePercentageSplit() {
    double amount = double.tryParse(amountController.text) ?? 0.0;
    double totalPercentage = 0.0;

    // Calculate total assigned percentage first
    for (String member in widget.members) {
      double percentage =
          double.tryParse(memberControllers[member]?.text ?? '0') ?? 0.0;
      totalPercentage += percentage;
    }

    // Update shares based on percentage
    if (amount > 0 && totalPercentage > 0) {
      for (String member in widget.members) {
        double percentage =
            double.tryParse(memberControllers[member]?.text ?? '0') ?? 0.0;
        double share = (percentage / totalPercentage) * amount;
        memberShares[member] = share;
      }

      setState(() {
        totalAmount = amount;
      });
    }
  }

  // Calculate amount-based split
  void _calculateAmountSplit() {
    double amount = double.tryParse(amountController.text) ?? 0.0;
    double totalAssigned = 0.0;

    for (String member in widget.members) {
      double share =
          double.tryParse(memberControllers[member]?.text ?? '0') ?? 0.0;
      memberShares[member] = share;
      totalAssigned += share;
    }

    setState(() {
      totalAmount = totalAssigned;
    });
  }

  // Calculate ratio-based split
  void _calculateRatioSplit() {
    double amount = double.tryParse(amountController.text) ?? 0.0;
    double totalRatio = 0.0;

    // Calculate total ratio first
    for (String member in widget.members) {
      double ratio =
          double.tryParse(memberControllers[member]?.text ?? '0') ?? 0.0;
      totalRatio += ratio;
    }

    // Update shares based on ratio
    if (amount > 0 && totalRatio > 0) {
      for (String member in widget.members) {
        double ratio =
            double.tryParse(memberControllers[member]?.text ?? '0') ?? 0.0;
        double share = (ratio / totalRatio) * amount;
        memberShares[member] = share;
      }

      setState(() {
        totalAmount = amount;
      });
    }
  }

  // Update calculations based on selected method
  void _updateCalculation() {
    switch (selectedMethod) {
      case SplitMethod.equal:
        _calculateEqualSplit();
        break;
      case SplitMethod.percentage:
        _calculatePercentageSplit();
        break;
      case SplitMethod.amount:
        _calculateAmountSplit();
        break;
      case SplitMethod.ratio:
        _calculateRatioSplit();
        break;
    }
  }

  // Save the split expenses to Firestore
  void _saveSplitExpenses() async {
    String title = titleController.text.trim();
    if (title.isEmpty) {
      SnackbarUtils.showErrorSnackbar(
          context, "Please enter a title for this split");
      return;
    }

    if (totalAmount <= 0) {
      SnackbarUtils.showErrorSnackbar(context, "Please enter a valid amount");
      return;
    }

    if (selectedPayer.isEmpty) {
      SnackbarUtils.showErrorSnackbar(context, "Please select who paid");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Create a batch to handle multiple operations
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Save the main expense for the payer
      DocumentReference mainExpenseRef = FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('expenses')
          .doc();

      batch.set(mainExpenseRef, {
        'title': title,
        'price': totalAmount,
        'user': selectedPayer,
        'createdAt': Timestamp.now(),
        'isSplit': true,
        'splitMethod': selectedMethod.toString().split('.').last,
      });

      // Save individual splits as separate documents
      for (String member in widget.members) {
        if (member != selectedPayer && memberShares[member]! > 0) {
          DocumentReference splitRef = FirebaseFirestore.instance
              .collection('groups')
              .doc(widget.groupId)
              .collection('splits')
              .doc();

          batch.set(splitRef, {
            'expenseId': mainExpenseRef.id,
            'title': title,
            'payer': selectedPayer,
            'recipient': member,
            'amount': memberShares[member],
            'settled': false,
            'createdAt': Timestamp.now(),
          });
        }
      }

      // Commit the batch
      await batch.commit();

      SnackbarUtils.showSuccessSnackbar(context, "Split saved successfully");
      Navigator.pop(context);
    } catch (e) {
      logger.e("Error saving split expenses: $e");
      SnackbarUtils.showErrorSnackbar(context, "Failed to save split");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Reset the input fields
  void _resetFields() {
    titleController.clear();
    amountController.clear();

    for (String member in widget.members) {
      memberControllers[member]?.clear();
      memberShares[member] = 0.0;
    }

    setState(() {
      totalAmount = 0.0;
    });
  }

  // Build the input fields based on selected split method
  Widget _buildInputFields() {
    switch (selectedMethod) {
      case SplitMethod.equal:
        return Column(
          children: [
            Text(
              "Everyone pays the same amount",
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 16),
            // For equal split, we just show the member names and their equal shares
            ...widget.members.map((member) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child:
                          Text(member, style: TextStyle(color: Colors.white)),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        "₹${memberShares[member]?.toStringAsFixed(2) ?? '0.00'}",
                        style: TextStyle(color: Colors.amber),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        );

      case SplitMethod.percentage:
        return Column(
          children: [
            Text(
              "Enter percentage for each person (total should be 100%)",
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 16),
            ...widget.members.map((member) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child:
                          Text(member, style: TextStyle(color: Colors.white)),
                    ),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: memberControllers[member],
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "0%",
                          hintStyle: TextStyle(color: AppColors.gray),
                          suffix: Text("%",
                              style: TextStyle(color: Colors.white70)),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.gray),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.main),
                          ),
                        ),
                        onChanged: (_) => _updateCalculation(),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "₹${memberShares[member]?.toStringAsFixed(2) ?? '0.00'}",
                      style: TextStyle(color: Colors.amber),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        );

      case SplitMethod.amount:
        return Column(
          children: [
            Text(
              "Enter exact amount for each person",
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 16),
            ...widget.members.map((member) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child:
                          Text(member, style: TextStyle(color: Colors.white)),
                    ),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: memberControllers[member],
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          prefixText: "₹",
                          prefixStyle: TextStyle(color: Colors.white70),
                          hintText: "0.00",
                          hintStyle: TextStyle(color: AppColors.gray),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.gray),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.main),
                          ),
                        ),
                        onChanged: (_) => _updateCalculation(),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        );

      case SplitMethod.ratio:
        return Column(
          children: [
            Text(
              "Enter ratio for each person (e.g., 1:2:3)",
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 16),
            ...widget.members.map((member) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child:
                          Text(member, style: TextStyle(color: Colors.white)),
                    ),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: memberControllers[member],
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "1",
                          hintStyle: TextStyle(color: AppColors.gray),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.gray),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.main),
                          ),
                        ),
                        onChanged: (_) => _updateCalculation(),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "₹${memberShares[member]?.toStringAsFixed(2) ?? '0.00'}",
                      style: TextStyle(color: Colors.amber),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Split Bill"),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.main))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title field
                  TextField(
                    controller: titleController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Title",
                      labelStyle: TextStyle(color: AppColors.gray),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.gray),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.main),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Amount field
                  TextField(
                    controller: amountController,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Total Amount",
                      labelStyle: TextStyle(color: AppColors.gray),
                      prefixText: "₹",
                      prefixStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.gray),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.main),
                      ),
                    ),
                    onChanged: (_) => _updateCalculation(),
                  ),
                  SizedBox(height: 24),

                  // Payer selection
                  Text(
                    "Who paid?",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.gray),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButton<String>(
                      value: selectedPayer,
                      isExpanded: true,
                      dropdownColor: AppColors.black,
                      style: TextStyle(color: Colors.white),
                      underline: SizedBox(),
                      items: widget.members.map((String member) {
                        return DropdownMenuItem<String>(
                          value: member,
                          child: Text(member),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedPayer = newValue;
                          });
                        }
                      },
                    ),
                  ),
                  SizedBox(height: 24),

                  // Split method selection
                  Text(
                    "Split Method",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMethodButton(
                        icon: Icons.balance_rounded,
                        label: "Equal",
                        method: SplitMethod.equal,
                      ),
                      _buildMethodButton(
                        icon: Icons.percent_rounded,
                        label: "Percent",
                        method: SplitMethod.percentage,
                      ),
                      _buildMethodButton(
                        icon: Icons.attach_money_rounded,
                        label: "Amount",
                        method: SplitMethod.amount,
                      ),
                      _buildMethodButton(
                        icon: Icons.radio_button_checked,
                        label: "Ratio",
                        method: SplitMethod.ratio,
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Divider
                  Divider(color: AppColors.gray),
                  SizedBox(height: 16),

                  // Input fields based on selected method
                  _buildInputFields(),
                  SizedBox(height: 24),

                  // Total amount display
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.mainShadow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.gray),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Total Amount",
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "₹${totalAmount.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _resetFields,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.gray),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            "Reset",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: CustomMainButton(
                          text: "Save Split",
                          onPressed: _saveSplitExpenses,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildMethodButton({
    required IconData icon,
    required String label,
    required SplitMethod method,
  }) {
    bool isSelected = selectedMethod == method;

    return InkWell(
      onTap: () {
        setState(() {
          selectedMethod = method;

          // Reset member inputs when changing method
          for (String member in widget.members) {
            memberControllers[member]?.clear();
          }

          _updateCalculation();
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 70,
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.main.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.main : AppColors.gray,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.main : Colors.white70,
              size: 24,
            ),
            SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
