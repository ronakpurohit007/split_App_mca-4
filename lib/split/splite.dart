// lib/screens/split_bill_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:login/widgets/AppBar.dart';
import 'package:login/widgets/colors.dart';
import 'package:login/widgets/login_btn.dart';
import 'package:login/widgets/snackbar_utils.dart';
import 'package:login/widgets/logger.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

final ConsoleAppLogger logger = ConsoleAppLogger();

enum SplitMethod { equal, percentage, amount, ratio }

class SplitBillScreen extends StatefulWidget {
  final String groupId;
  final List<String> members;
  final double totalAmount; // Required total amount from expense screen

  SplitBillScreen({
    required this.groupId,
    required this.members,
    required this.totalAmount, // Make this required
  });

  @override
  _SplitBillScreenState createState() => _SplitBillScreenState();
}

class _SplitBillScreenState extends State<SplitBillScreen> {
  SplitMethod selectedMethod = SplitMethod.equal;
  double totalAmount = 0.0;
  bool isLoading = false;
  String groupTitle = "Group"; // Default value before fetching
  bool isCalculated = false; // Flag to track if calculation was performed

  // Store individual member split info
  Map<String, double> memberShares = {};
  Map<String, TextEditingController> memberControllers = {};

  @override
  void initState() {
    super.initState();
    // Initialize member controllers and shares
    for (String member in widget.members) {
      memberControllers[member] = TextEditingController();
      memberShares[member] = 0.0;
    }

    // Set total amount from expenses screen
    totalAmount = widget.totalAmount;

    // For equal split, calculate immediately since no input is needed
    if (selectedMethod == SplitMethod.equal) {
      _updateCalculation();
      isCalculated = true;
    }

    // Fetch group title
    _fetchGroupTitle();
  }

  // Fetch group title from Firestore
  Future<void> _fetchGroupTitle() async {
    try {
      DocumentSnapshot groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (groupDoc.exists && groupDoc.data() != null) {
        Map<String, dynamic> groupData =
            groupDoc.data() as Map<String, dynamic>;
        if (groupData.containsKey('title')) {
          setState(() {
            groupTitle = groupData['title'];
          });
        }
      }
    } catch (e) {
      logger.e("Error fetching group title: $e");
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    memberControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  // Calculate equal split
  void _calculateEqualSplit() {
    int memberCount = widget.members.length;

    if (memberCount > 0 && totalAmount > 0) {
      double equalShare = totalAmount / memberCount;

      for (String member in widget.members) {
        memberShares[member] = equalShare;
        memberControllers[member]?.text = equalShare.toStringAsFixed(2);
      }
    }
  }

  // Calculate percentage split with auto-calculation for last member
  void _calculatePercentageSplit() {
    double totalPercentage = 0.0;
    int lastIndex = widget.members.length - 1;
    String lastMember = widget.members[lastIndex];

    // Calculate total assigned percentage first (excluding the last member)
    for (int i = 0; i < lastIndex; i++) {
      String member = widget.members[i];
      double percentage =
          double.tryParse(memberControllers[member]?.text ?? '0') ?? 0.0;
      totalPercentage += percentage;
    }

    // Ensure total percentage doesn't exceed 100%
    if (totalPercentage > 100) {
      totalPercentage = 100;
      // Adjust percentages for all members except last
      for (int i = 0; i < lastIndex; i++) {
        String member = widget.members[i];
        double percentage =
            double.tryParse(memberControllers[member]?.text ?? '0') ?? 0.0;
        double adjustedPercentage = (percentage / totalPercentage) * 100;
        memberControllers[member]?.text = adjustedPercentage.toStringAsFixed(2);
      }
      memberControllers[lastMember]?.text = "0.00";
    } else {
      // Set remaining percentage for last member
      double remainingPercentage = 100 - totalPercentage;
      memberControllers[lastMember]?.text =
          remainingPercentage.toStringAsFixed(2);
    }

    // Update shares based on percentage
    for (String member in widget.members) {
      double percentage =
          double.tryParse(memberControllers[member]?.text ?? '0') ?? 0.0;
      double share = (percentage / 100) * totalAmount;
      memberShares[member] = share;
    }
  }

  // Calculate amount-based split with auto-calculation for last member
  void _calculateAmountSplit() {
    double totalAssigned = 0.0;
    int lastIndex = widget.members.length - 1;
    String lastMember = widget.members[lastIndex];

    // Calculate total assigned amount first (excluding the last member)
    for (int i = 0; i < lastIndex; i++) {
      String member = widget.members[i];
      double share =
          double.tryParse(memberControllers[member]?.text ?? '0') ?? 0.0;
      totalAssigned += share;
      memberShares[member] = share;
    }

    // Ensure total assigned doesn't exceed total amount
    if (totalAssigned > totalAmount) {
      totalAssigned = totalAmount;
      // Set last member share to 0
      memberShares[lastMember] = 0;
      memberControllers[lastMember]?.text = "0.00";
    } else {
      // Set remaining amount for last member
      double remainingAmount = totalAmount - totalAssigned;
      memberShares[lastMember] = remainingAmount;
      memberControllers[lastMember]?.text = remainingAmount.toStringAsFixed(2);
    }
  }

  // Calculate ratio-based split
  void _calculateRatioSplit() {
    double totalRatio = 0.0;

    // Calculate total ratio first
    for (String member in widget.members) {
      double ratio =
          double.tryParse(memberControllers[member]?.text ?? '0') ?? 0.0;
      totalRatio += ratio;
    }

    // Update shares based on ratio
    if (totalAmount > 0 && totalRatio > 0) {
      for (String member in widget.members) {
        double ratio =
            double.tryParse(memberControllers[member]?.text ?? '0') ?? 0.0;
        double share = (ratio / totalRatio) * totalAmount;
        memberShares[member] = share;
      }
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

    setState(() {
      isCalculated = true;
    });
  }

  // Get split method as string
  String _getSplitMethodString() {
    return selectedMethod.toString().split('.').last;
  }

  // Save the split expenses to Firestore
  Future<String> _saveSplitExpenses() async {
    if (totalAmount <= 0) {
      SnackbarUtils.showErrorSnackbar(context, "Please enter a valid amount");
      return '';
    }

    if (!isCalculated) {
      SnackbarUtils.showErrorSnackbar(context, "Please calculate first");
      return '';
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Create a batch to handle multiple operations
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Save the main expense (use "Split Expense" as title)
      DocumentReference mainExpenseRef = FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('expenses')
          .doc();

      // Get the split method as string
      String splitMethodStr = _getSplitMethodString();

      batch.set(mainExpenseRef, {
        'title': "Split Expense",
        'price': totalAmount,
        'user': groupTitle, // Use group title as payer
        'createdAt': Timestamp.now(),
        'isSplit': true,
        'splitMethod': splitMethodStr, // Store the split method
      });

      // Save individual splits as separate documents with the same expense ID
      for (String member in widget.members) {
        if (memberShares[member]! > 0) {
          DocumentReference splitRef = FirebaseFirestore.instance
              .collection('groups')
              .doc(widget.groupId)
              .collection('splits')
              .doc();

          batch.set(splitRef, {
            'expenseId': mainExpenseRef.id,
            'title': "Split Expense",
            'payer': groupTitle, // Use group title as payer
            'recipient': member,
            'amount': memberShares[member],
            'settled': false,
            'createdAt': Timestamp.now(),
            'splitMethod': splitMethodStr, // Store the split method
          });
        }
      }

      // Commit the batch
      await batch.commit();

      SnackbarUtils.showSuccessSnackbar(context, "Split saved successfully");

      // Return the expense ID for bill display
      return mainExpenseRef.id;
    } catch (e) {
      logger.e("Error saving split expenses: $e");
      SnackbarUtils.showErrorSnackbar(context, "Failed to save split");
      return '';
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Generate and print PDF bill
  Future<void> _generateAndPrintPdf() async {
    final pdf = pw.Document();

    // Get current date/time formatted
    final dateFormatter = DateFormat('dd-MM-yyyy hh:mm a');
    final currentDate = dateFormatter.format(DateTime.now());

    // Create PDF content
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Text(
                    "EXPENSE SPLIT RECEIPT",
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 10),

                // Divider
                pw.Divider(thickness: 1),

                // Date and Receipt Info
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "Date: $currentDate",
                      style: pw.TextStyle(fontSize: 12),
                    ),
                    pw.Text(
                      "Group: $groupTitle",
                      style: pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Expense Details
                pw.Container(
                  padding: pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "Title: Split Expense",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        "Total Amount: Rs.${totalAmount.toStringAsFixed(2)}",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        "Split Method: ${_getSplitMethodString().toUpperCase()}",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Split Details Table
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: pw.FlexColumnWidth(2),
                    1: pw.FlexColumnWidth(1),
                  },
                  children: [
                    // Table Header
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(5),
                          child: pw.Text(
                            "Member",
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(5),
                          child: pw.Text(
                            "Amount (Rs.)",
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),

                    // Member Rows
                    ...widget.members
                        .map((member) => pw.TableRow(
                              children: [
                                pw.Padding(
                                  padding: pw.EdgeInsets.all(5),
                                  child: pw.Text(member),
                                ),
                                pw.Padding(
                                  padding: pw.EdgeInsets.all(5),
                                  child: pw.Text(memberShares[member]
                                          ?.toStringAsFixed(2) ??
                                      "0.00"),
                                ),
                              ],
                            ))
                        .toList(),
                  ],
                ),

                pw.SizedBox(height: 40),

                // Footer
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    "Thank you for using our app!",
                    style: pw.TextStyle(
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Print the document
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // Reset the input fields
  void _resetFields() {
    setState(() {
      for (String member in widget.members) {
        memberControllers[member]?.clear();
        memberShares[member] = 0.0;
      }

      isCalculated = false;

      // For equal split, recalculate immediately
      if (selectedMethod == SplitMethod.equal) {
        _updateCalculation();
        isCalculated = true;
      }
    });
  }

  // Show split bill result screen
  void _showSplitBillResult(String expenseId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SplitBillResultScreen(
          groupId: widget.groupId,
          expenseId: expenseId,
          title: "Split Expense",
          totalAmount: totalAmount,
          payer: groupTitle, // Use group title as payer
          memberShares: memberShares,
          splitMethod: selectedMethod,
          onPrintPressed: _generateAndPrintPdf,
        ),
      ),
    );
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
                        "Rs.${memberShares[member]?.toStringAsFixed(2) ?? '0.00'}",
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
              "Enter percentage for each person (total will be 100%)",
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 16),
            ...widget.members.asMap().entries.map((entry) {
              int index = entry.key;
              String member = entry.value;
              bool isLastMember = index == widget.members.length - 1;

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
                      child: isLastMember
                          ? Container(
                              padding: EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: AppColors.gray),
                                ),
                              ),
                              child: Text(
                                "${memberControllers[member]?.text ?? '0.00'}%",
                                style: TextStyle(color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : TextField(
                              controller: memberControllers[member],
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
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
                            ),
                    ),
                    SizedBox(width: 8),
                    isCalculated
                        ? Text(
                            "Rs.${memberShares[member]?.toStringAsFixed(2) ?? '0.00'}",
                            style: TextStyle(color: Colors.amber),
                          )
                        : Container(),
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
            ...widget.members.asMap().entries.map((entry) {
              int index = entry.key;
              String member = entry.value;
              bool isLastMember = index == widget.members.length - 1;

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
                      child: isLastMember
                          ? Container(
                              padding: EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: AppColors.gray),
                                ),
                              ),
                              child: Text(
                                "Rs.${memberControllers[member]?.text ?? '0.00'}",
                                style: TextStyle(color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : TextField(
                              controller: memberControllers[member],
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                prefixText: "Rs.",
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
                      ),
                    ),
                    SizedBox(width: 8),
                    isCalculated
                        ? Text(
                            "Rs.${memberShares[member]?.toStringAsFixed(2) ?? '0.00'}",
                            style: TextStyle(color: Colors.amber),
                          )
                        : Container(),
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
      appBar: CustomAppBar(title: "Split Expense"),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.main))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total Amount Display
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
                          "Total Amount to Split",
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Rs.${totalAmount.toStringAsFixed(2)}",
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
                  SizedBox(height: 16),

                  // Calculate button (only show for percentage, amount, and ratio)
                  if (selectedMethod != SplitMethod.equal)
                    Container(
                      width: double.infinity,
                      child: CustomMainButton(
                        text: "Calculate",
                        onPressed: _updateCalculation,
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
                          onPressed: () async {
                            String expenseId = await _saveSplitExpenses();
                            if (expenseId.isNotEmpty) {
                              _showSplitBillResult(expenseId);
                            }
                          },
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

          // Reset calculated flag
          isCalculated = false;

          // For equal split, calculate immediately since no input is needed
          if (method == SplitMethod.equal) {
            _updateCalculation();
            isCalculated = true;
          }
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

// New screen to show split bill results
class SplitBillResultScreen extends StatelessWidget {
  final String groupId;
  final String expenseId;
  final String title;
  final double totalAmount;
  final String payer;
  final Map<String, double> memberShares;
  final SplitMethod splitMethod;
  final VoidCallback onPrintPressed;

  SplitBillResultScreen({
    required this.groupId,
    required this.expenseId,
    required this.title,
    required this.totalAmount,
    required this.payer,
    required this.memberShares,
    required this.splitMethod,
    required this.onPrintPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Get current date/time formatted
    final dateFormatter = DateFormat('dd-MM-yyyy hh:mm a');
    final currentDate = dateFormatter.format(DateTime.now());

    return Scaffold(
      appBar: CustomAppBar(title: "Split Details"),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Receipt-like card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.mainShadow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.gray),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and date
                  Center(
                    child: Text(
                      "EXPENSE SPLIT RECEIPT",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Divider(color: AppColors.gray),
                  SizedBox(height: 10),

                  // Date and expense ID
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Date: $currentDate",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        "ID: ${expenseId.substring(0, 6)}...",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Main expense info
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.gray),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Title: $title",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Paid by: $payer",
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Total Amount: Rs.${totalAmount.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Split Method: ${splitMethod.toString().split('.').last.toUpperCase()}",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

                  // Split details
                  Text(
                    "Split Details",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),

                  // Header row
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.main.withOpacity(0.2),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(5),
                        topRight: Radius.circular(5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            "Member",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            "Amount (Rs.)",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Member rows
                  ...memberShares.entries.map((entry) {
                    final member = entry.key;
                    final amount = entry.value;
                    final isEqualToPayer = member == payer;

                    return Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.gray),
                          left: BorderSide(color: AppColors.gray),
                          right: BorderSide(color: AppColors.gray),
                        ),
                        color: isEqualToPayer
                            ? AppColors.main.withOpacity(0.1)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                Text(
                                  member,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: isEqualToPayer
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                if (isEqualToPayer)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      "(Paid)",
                                      style: TextStyle(
                                        color: AppColors.main,
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              amount.toStringAsFixed(2),
                              style: TextStyle(
                                color: isEqualToPayer
                                    ? Colors.amber
                                    : Colors.white,
                                fontWeight: isEqualToPayer
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  SizedBox(height: 30),

                  // Footer
                  Divider(color: AppColors.gray),
                  SizedBox(height: 10),
                  Center(
                    child: Text(
                      "Thank you for using our app!",
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.white70,
                      ),
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
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.gray),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      "Back",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: CustomMainButton(
                    text: "Print Receipt",
                    onPressed: onPrintPressed,
                    // icon: Icons.print,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Additional information
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.main.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.main.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.main, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "What's next?",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    "• Group members can view this split in the Expenses tab",
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "• Settlement can be done from the Settlements section",
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "• You can print this receipt at any time from the expense details",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
