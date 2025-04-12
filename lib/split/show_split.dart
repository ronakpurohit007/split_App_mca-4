import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:login/group/create_group.dart';
import 'package:login/widgets/AppBar.dart';
import 'package:login/widgets/colors.dart';
import 'package:login/widgets/snackbar_utils.dart';
import 'package:login/widgets/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SplitExpensesScreen extends StatefulWidget {
  final String groupId;
  final String groupTitle;
  final List<String> members;

  const SplitExpensesScreen({
    Key? key,
    required this.groupId,
    required this.groupTitle,
    required this.members,
  }) : super(key: key);

  @override
  _SplitExpensesScreenState createState() => _SplitExpensesScreenState();
}

class _SplitExpensesScreenState extends State<SplitExpensesScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> splits = [];
  double totalAmount = 0.0;
  String selectedFilter = 'All';
  List<Map<String, dynamic>> filteredSplits = [];
  double filteredAmount = 0.0;
  String currentUserName = '';
  List<String> members = [];

  @override
  void initState() {
    super.initState();
    members = widget.members;
    _getCurrentUser();
    _loadSplits();
  }

  Future<void> _getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          currentUserName = userDoc.data()?['name'] ?? '';
        });
      }
    }
  }

  Future<void> _loadSplits() async {
    setState(() {
      isLoading = true;
    });

    try {
      final QuerySnapshot splitsSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('splits')
          .orderBy('createdAt', descending: true)
          .get();

      final List<Map<String, dynamic>> loadedSplits = [];
      double total = 0.0;

      for (var doc in splitsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final splitData = {
          'id': doc.id,
          'expenseId': data['expenseId'] ?? '',
          'title': data['title'] ?? 'Split Expense',
          'payer': data['payer'] ?? '',
          'recipient': data['recipient'] ?? '',
          'amount': (data['amount'] ?? 0.0).toDouble(),
          'settled': data['settled'] ?? false,
          'createdAt': data['createdAt'] ?? Timestamp.now(),
          'splitMethod': data['splitMethod'] ?? 'Equal',
        };
        loadedSplits.add(splitData);
        total += splitData['amount'];
      }

      setState(() {
        splits = loadedSplits;
        totalAmount = total;
        _applyFilter('All');
        isLoading = false;
      });
    } catch (e) {
      logger.e("Error loading splits: $e");
      SnackbarUtils.showErrorSnackbar(context, "Failed to load splits");
      setState(() {
        isLoading = false;
      });
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      selectedFilter = filter;

      if (filter == 'All') {
        filteredSplits = List.from(splits);
        filteredAmount = totalAmount;
      } else {
        // Filter splits where the selected person is either payer or recipient
        filteredSplits = splits.where((split) {
          return split['recipient'] == filter || split['payer'] == filter;
        }).toList();

        // Calculate the filtered amount
        filteredAmount = filteredSplits.fold(0.0, (sum, split) {
          return sum + (split['amount'] ?? 0.0);
        });
      }
    });
  }

  String _formatTimestamp(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    final DateFormat formatter = DateFormat('MMM d, yyyy • h:mm a');
    return formatter.format(dateTime);
  }

  void _settleSplit(String splitId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('splits')
          .doc(splitId)
          .update({'settled': !currentStatus});

      _loadSplits();
      SnackbarUtils.showSuccessSnackbar(context,
          "Split marked as ${!currentStatus ? 'settled' : 'unsettled'}");
    } catch (e) {
      logger.e("Error updating split status: $e");
      SnackbarUtils.showErrorSnackbar(context, "Failed to update split status");
    }
  }

  void _deleteSplit(String splitId) async {
    // Show confirmation dialog
    bool confirmDelete = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.black,
            title: Text('Delete Split', style: TextStyle(color: Colors.white)),
            content: Text('Are you sure you want to delete this split?',
                style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                child: Text('Cancel', style: TextStyle(color: Colors.white70)),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: Text('Delete', style: TextStyle(color: Colors.red)),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmDelete) return;

    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('splits')
          .doc(splitId)
          .delete();

      _loadSplits();
      SnackbarUtils.showSuccessSnackbar(context, "Split deleted successfully");
    } catch (e) {
      logger.e("Error deleting split: $e");
      SnackbarUtils.showErrorSnackbar(context, "Failed to delete split");
    }
  }

  void _showSplitDetails(Map<String, dynamic> split) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Split Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _detailRow('Title', split['title'] ?? 'Split Expense'),
            _detailRow('Split Method', split['splitMethod'] ?? 'Equal'),
            _detailRow('Amount', 'Rs.${split['amount'].toStringAsFixed(2)}'),
            _detailRow('Payer', split['payer'] ?? 'Unknown'),
            _detailRow('Recipient', split['recipient'] ?? 'Unknown'),
            _detailRow('Date', _formatTimestamp(split['createdAt'])),
            _detailRow('Status', split['settled'] ? 'Settled' : 'Unsettled'),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _settleSplit(split['id'], split['settled']);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.main,
                  ),
                  child: Text(
                    split['settled'] ? 'Mark as Unsettled' : 'Mark as Settled',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteSplit(split['id']);
                  },
                  child: Text(
                    'Delete Split',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Function to generate and print the bill as PDF
  Future<void> _generateAndPrintBill() async {
    try {
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.nunitoRegular();
      final fontBold = await PdfGoogleFonts.nunitoBold();

      // Create PDF content
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Container(
              padding: pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'Expense Bill',
                          style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              font: fontBold),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          widget.groupTitle,
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Date: ${DateFormat('dd-MM-yyyy').format(DateTime.now())}',
                          style: pw.TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 20),

                  // Summary
                  pw.Container(
                    padding: pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(),
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Total Amount',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text(
                              'Rs.${totalAmount.toStringAsFixed(2)}',
                              style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              'No. of Splits',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text(
                              '${splits.length}',
                              style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 20),

                  // Splits Table
                  pw.Text(
                    'Expense Details',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),

                  // Table Header
                  pw.Container(
                    color: PdfColors.grey300,
                    padding:
                        pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            'Description',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            'From -> To',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(
                            'Status',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(
                            'Amount',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Table Rows
                  ...splits.map((split) {
                    return pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: PdfColors.grey300),
                        ),
                      ),
                      padding:
                          pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 3,
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  split['title'] ?? 'Split Expense',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold),
                                ),
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  _formatTimestamp(split['createdAt'])
                                      .split('•')[0],
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    color: PdfColors.grey700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              '${split['payer']} -> ${split['recipient']}',
                            ),
                          ),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Text(
                              split['settled'] ? 'Settled' : 'Pending',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                color: split['settled']
                                    ? PdfColors.green
                                    : PdfColors.orange,
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Text(
                              'Rs.${(split['amount'] as num).toStringAsFixed(2)}',
                              textAlign: pw.TextAlign.right,
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  pw.SizedBox(height: 30),

                  // Summary by Status
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      pw.Column(
                        children: [
                          pw.Text(
                            'Settled',
                            style: pw.TextStyle(
                              color: PdfColors.green700,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            '${splits.where((split) => split['settled']).length}',
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.green700,
                            ),
                          ),
                        ],
                      ),
                      pw.Container(
                        height: 40,
                        width: 1,
                        color: PdfColors.grey400,
                      ),
                      pw.Column(
                        children: [
                          pw.Text(
                            'Unsettled',
                            style: pw.TextStyle(
                              color: PdfColors.orange700,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            '${splits.where((split) => !split['settled']).length}',
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.orange700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  pw.Spacer(),

                  // Footer
                  pw.Center(
                    child: pw.Text(
                      'Generated on ${DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now())}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
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

      // Alternatively, save the PDF to a file
      // final output = await getTemporaryDirectory();
      // final file = File('${output.path}/expense_bill.pdf');
      // await file.writeAsBytes(await pdf.save());
      // SnackbarUtils.showSuccessSnackbar(context, "Bill saved to ${file.path}");

      SnackbarUtils.showSuccessSnackbar(
          context, "Expense bill generated successfully");
    } catch (e) {
      logger.e("Error generating PDF: $e");
      SnackbarUtils.showErrorSnackbar(
          context, "Failed to generate expense bill");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Split Expenses"),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.main))
          : Column(
              children: [
                // Filter chips row
                Container(
                  height: 60,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // All filter
                        GestureDetector(
                          onTap: () => _applyFilter('All'),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            margin: EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: selectedFilter == 'All'
                                  ? AppColors.main
                                  : AppColors.mainShadow,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: selectedFilter == 'All'
                                      ? AppColors.main
                                      : AppColors.gray),
                            ),
                            child: Text(
                              "All",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: selectedFilter == 'All'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),

                        // Current user filter
                        if (currentUserName.isNotEmpty)
                          GestureDetector(
                            onTap: () => _applyFilter(currentUserName),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              margin: EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: selectedFilter == currentUserName
                                    ? AppColors.main
                                    : AppColors.mainShadow,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: selectedFilter == currentUserName
                                        ? AppColors.main
                                        : AppColors.gray),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    currentUserName,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight:
                                          selectedFilter == currentUserName
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Colors.white70,
                                  )
                                ],
                              ),
                            ),
                          ),

                        // Individual member filters
                        ...members
                            .where((member) => member != currentUserName)
                            .map((member) {
                          return GestureDetector(
                            onTap: () => _applyFilter(member),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              margin: EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: selectedFilter == member
                                    ? AppColors.main
                                    : AppColors.mainShadow,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: selectedFilter == member
                                        ? AppColors.main
                                        : AppColors.gray),
                              ),
                              child: Text(
                                member,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: selectedFilter == member
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
                ),

                // Total splits container
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.mainShadow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.gray),
                  ),
                  child: Column(
                    children: [
                      Text(
                          selectedFilter == 'All'
                              ? "Total Split Amount"
                              : selectedFilter == currentUserName
                                  ? "Your Split Amount"
                                  : "$selectedFilter's Split Amount",
                          style:
                              TextStyle(fontSize: 16, color: Colors.white70)),
                      SizedBox(height: 8),
                      Text(
                          "Rs.${selectedFilter == 'All' ? totalAmount.toStringAsFixed(2) : filteredAmount.toStringAsFixed(2)}",
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ],
                  ),
                ),

                // Split status summary
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  margin: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.mainShadow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.gray),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statusCounter(
                        "Settled",
                        filteredSplits
                            .where((split) => split['settled'])
                            .length,
                        Colors.green,
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: AppColors.gray,
                      ),
                      _statusCounter(
                        "Unsettled",
                        filteredSplits
                            .where((split) => !split['settled'])
                            .length,
                        Colors.orange,
                      ),
                    ],
                  ),
                ),

                // Splits list
                Expanded(
                  child: filteredSplits.isEmpty
                      ? Center(
                          child: Text(
                              selectedFilter == 'All'
                                  ? "No splits added yet"
                                  : "No splits for $selectedFilter",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 16)),
                        )
                      : ListView.builder(
                          itemCount: filteredSplits.length,
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) {
                            final split = filteredSplits[index];
                            return Card(
                              color: AppColors.mainShadow,
                              margin: EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: split['settled']
                                      ? Colors.green.withOpacity(0.5)
                                      : AppColors.gray,
                                  width: 1,
                                ),
                              ),
                              child: InkWell(
                                onTap: () => _showSplitDetails(split),
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              split['title'],
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            "Rs.${(split['amount'] as num).toStringAsFixed(2)}",
                                            style: TextStyle(
                                                color: Colors.amber,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.person_outline,
                                              size: 14, color: Colors.white70),
                                          SizedBox(width: 4),
                                          Text(
                                            "${split['payer']} -> ${split['recipient']}",
                                            style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 14),
                                          ),
                                          Spacer(),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: split['settled']
                                                  ? Colors.green
                                                      .withOpacity(0.2)
                                                  : Colors.orange
                                                      .withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              split['settled']
                                                  ? "Settled"
                                                  : "Unsettled",
                                              style: TextStyle(
                                                color: split['settled']
                                                    ? Colors.green
                                                    : Colors.orange,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today,
                                              size: 14, color: Colors.white70),
                                          SizedBox(width: 4),
                                          Text(
                                            _formatTimestamp(
                                                split['createdAt']),
                                            style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12),
                                          ),
                                          Spacer(),
                                          Text(
                                            split['splitMethod'] ?? "Equal",
                                            style: TextStyle(
                                                color: Colors.white54,
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // New functionality - print bill instead of adding expense
          _generateAndPrintBill();
        },
        backgroundColor: AppColors.main,
        child: Icon(Icons.print, color: Colors.white), // Changed icon to print
      ),
    );
  }

  Widget _statusCounter(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
