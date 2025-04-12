// lib/screens/print_expense_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:login/widgets/AppBar.dart';
import 'package:login/widgets/colors.dart';
import 'package:login/widgets/login_btn.dart';
import 'package:login/widgets/snackbar_utils.dart';
import 'package:login/widgets/logger.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

final ConsoleAppLogger logger = ConsoleAppLogger();

class PrintExpenseScreen extends StatefulWidget {
  final String groupId;
  final List<String> members;

  const PrintExpenseScreen(
      {Key? key, required this.groupId, required this.members})
      : super(key: key);

  @override
  _PrintExpenseScreenState createState() => _PrintExpenseScreenState();
}

class _PrintExpenseScreenState extends State<PrintExpenseScreen> {
  bool isLoading = false;
  String selectedMember = 'All';
  List<Map<String, dynamic>> expenses = [];
  String groupName = '';

  @override
  void initState() {
    super.initState();
    _fetchGroupInfo();
    _fetchExpenses();
  }

  Future<void> _fetchGroupInfo() async {
    try {
      DocumentSnapshot groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (groupDoc.exists) {
        var data = groupDoc.data() as Map<String, dynamic>;
        setState(() {
          groupName = data['name'] ?? 'Group';
        });
      }
    } catch (e) {
      logger.e("Error fetching group info: $e");
    }
  }

  Future<void> _fetchExpenses() async {
    setState(() => isLoading = true);
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('expenses')
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> fetchedExpenses = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        fetchedExpenses.add(data);
      }

      setState(() {
        expenses = fetchedExpenses;
        isLoading = false;
      });
    } catch (e) {
      logger.e("Error fetching expenses: $e");
      setState(() => isLoading = false);
      SnackbarUtils.showErrorSnackbar(context, "Failed to load expenses");
    }
  }

  List<Map<String, dynamic>> _getFilteredExpenses() {
    if (selectedMember == 'All') {
      return expenses;
    } else {
      return expenses
          .where((expense) => expense['user'] == selectedMember)
          .toList();
    }
  }

  double _getFilteredTotal() {
    List<Map<String, dynamic>> filteredExpenses = _getFilteredExpenses();
    return filteredExpenses.fold(
        0.0, (sum, expense) => sum + (expense['price'] as num).toDouble());
  }

  Future<void> _generateAndOpenPdf() async {
    setState(() => isLoading = true);

    try {
      final pdf = pw.Document();
      final filteredExpenses = _getFilteredExpenses();
      final totalAmount = _getFilteredTotal();

      // Get current date for the receipt
      final now = DateTime.now();
      final formattedDate = "${now.day}/${now.month}/${now.year}";

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('EXPENSE REPORT',
                            style: pw.TextStyle(
                                fontSize: 24, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Date: $formattedDate',
                            style: pw.TextStyle(fontSize: 12))
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(groupName, style: pw.TextStyle(fontSize: 18)),
                    pw.SizedBox(height: 5),
                    pw.Text(
                        selectedMember == 'All'
                            ? 'All Members'
                            : 'Member: $selectedMember',
                        style: pw.TextStyle(fontSize: 14)),
                    pw.Divider(thickness: 2),
                  ],
                ),
              ),

              // Summary
              pw.Container(
                padding: pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('SUMMARY',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Expenses:'),
                        pw.Text('Rs.${totalAmount.toStringAsFixed(2)}',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Number of Items:'),
                        pw.Text('${filteredExpenses.length}',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Expense Details Table
              pw.Table.fromTextArray(
                headers: ['Date', 'Description', 'Added By', 'Amount (Rs.)'],
                data: filteredExpenses.map((expense) {
                  final date = (expense['createdAt'] as Timestamp).toDate();
                  final formattedDate =
                      "${date.day}/${date.month}/${date.year}";

                  return [
                    formattedDate,
                    expense['title'],
                    expense['user'],
                    (expense['price'] as num).toStringAsFixed(2),
                  ];
                }).toList(),
                border: pw.TableBorder.all(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerRight,
                },
              ),

              pw.SizedBox(height: 20),

              // Total at bottom
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  padding: pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                    color: PdfColors.grey200,
                  ),
                  child: pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text('TOTAL: ',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Rs.${totalAmount.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
              ),

              // Footer
              pw.SizedBox(height: 40),
              pw.Footer(
                trailing: pw.Text(
                  'Generated via ExpenseTracker App',
                  style: pw.TextStyle(
                      fontSize: 10, fontStyle: pw.FontStyle.italic),
                ),
              ),
            ];
          },
        ),
      );

      // Save PDF
      final output = await getTemporaryDirectory();
      final String fileName =
          'expenses_${selectedMember == 'All' ? 'all' : selectedMember}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Open PDF
      await OpenFile.open(file.path);

      setState(() => isLoading = false);
      SnackbarUtils.showSuccessSnackbar(context, "PDF generated successfully");
    } catch (e) {
      setState(() => isLoading = false);
      logger.e("Error generating PDF: $e");
      SnackbarUtils.showErrorSnackbar(context, "Failed to generate PDF");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Print Expenses"),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.main))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Instructions
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.mainShadow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.gray),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Print Expense Report",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Generate a PDF report of expenses that you can download, share, or print.",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Select Member
                  Text(
                    "Select Member",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),

                  // Member selection chips
                  Container(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // All members chip
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedMember = 'All';
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            margin: EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: selectedMember == 'All'
                                  ? AppColors.main
                                  : AppColors.mainShadow,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selectedMember == 'All'
                                    ? AppColors.main
                                    : AppColors.gray,
                              ),
                            ),
                            child: Text(
                              "All",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: selectedMember == 'All'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),

                        // Individual member chips
                        ...widget.members.map((member) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedMember = member;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              margin: EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: selectedMember == member
                                    ? AppColors.main
                                    : AppColors.mainShadow,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selectedMember == member
                                      ? AppColors.main
                                      : AppColors.gray,
                                ),
                              ),
                              child: Text(
                                member,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: selectedMember == member
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Preview information
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.mainShadow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.gray),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Report Preview",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Items:",
                                style: TextStyle(color: Colors.white70)),
                            Text(
                              "${_getFilteredExpenses().length}",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Total Amount:",
                                style: TextStyle(color: Colors.white70)),
                            Text(
                              "Rs.${_getFilteredTotal().toStringAsFixed(2)}",
                              style: TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32),

                  // Generate PDF Button
                  CustomMainButton(
                    width: double.infinity,
                    text: "Generate PDF",
                    onPressed: _generateAndOpenPdf,
                    // icon: Icons.picture_as_pdf_rounded,
                  ),
                ],
              ),
            ),
    );
  }
}
