import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:login/split/price_split.dart';
import 'package:login/widgets/AppBar.dart';
import 'package:login/widgets/colors.dart';
import 'package:login/widgets/logger.dart';
import 'package:login/Services/authentication.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class ExpenseHistoryScreen extends StatefulWidget {
  const ExpenseHistoryScreen({Key? key}) : super(key: key);

  @override
  _ExpenseHistoryScreenState createState() => _ExpenseHistoryScreenState();
}

class _ExpenseHistoryScreenState extends State<ExpenseHistoryScreen> {
  List<Map<String, dynamic>> userExpenses = [];
  bool isLoading = true;
  String? userName;
  String? userId;
  final ConsoleAppLogger logger = ConsoleAppLogger();
  bool isPrinting = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Using the same authentication service as in HomeScreen
      String? name = await AuthServices().getUserName();
      String? uid = FirebaseAuth.instance.currentUser?.uid;

      setState(() {
        userName = name ?? "User";
        userId = uid;
      });

      logger.d("Fetched user name: $userName, ID: $userId");

      if (name != null) {
        await _fetchUserExpenseHistory(name);
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      logger.e("Error fetching user data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchUserExpenseHistory(String name) async {
    try {
      logger.d("Fetching expense history for user: $name");

      // First get all groups the user is a member of (similar to the HomeScreen logic)
      QuerySnapshot groupsSnapshot = await FirebaseFirestore.instance
          .collection("groups")
          .where("members", arrayContains: name)
          .get();

      logger.d("Found ${groupsSnapshot.docs.length} groups for user");

      List<Map<String, dynamic>> allExpenses = [];

      // For each group, get the expenses where this user paid
      for (var groupDoc in groupsSnapshot.docs) {
        String groupId = groupDoc.id;
        Map<String, dynamic> groupData =
            groupDoc.data() as Map<String, dynamic>;
        String groupTitle = groupData["title"] ?? "Untitled Group";

        logger.d("Processing group: $groupTitle");

        // Get expenses from this group where the user is the payer
        QuerySnapshot expensesSnapshot = await FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
            .collection('expenses')
            .where('user', isEqualTo: name)
            .orderBy('createdAt', descending: true)
            .get();

        logger
            .d("Found ${expensesSnapshot.docs.length} expenses in $groupTitle");

        for (var expenseDoc in expensesSnapshot.docs) {
          Map<String, dynamic> expenseData =
              expenseDoc.data() as Map<String, dynamic>;

          // Skip split expenses
          if (expenseData['isSplit'] == true) continue;

          allExpenses.add({
            'id': expenseDoc.id,
            'groupId': groupId,
            'groupTitle': groupTitle,
            'title': expenseData['title'] ?? 'No Title',
            'price': expenseData['price'] ?? 0.0,
            'createdAt': expenseData['createdAt'],
            'edited': expenseData['edited'] ?? false,
          });
        }
      }

      // Sort expenses by date (newest first)
      allExpenses.sort((a, b) {
        Timestamp timeA = a['createdAt'] as Timestamp;
        Timestamp timeB = b['createdAt'] as Timestamp;
        return timeB.compareTo(timeA);
      });

      logger.d("Total expenses found: ${allExpenses.length}");

      setState(() {
        userExpenses = allExpenses;
        isLoading = false;
      });
    } catch (e) {
      logger.e("Error fetching expense history: $e");
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load expense history')),
      );
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return "${date.day}_/${date.month}_/${date.year}_${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    }
    return "Unknown date";
  }

  Future<void> _printExpenseDetails() async {
    if (userExpenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No expenses to print')),
      );
      return;
    }

    setState(() {
      isPrinting = true;
    });

    try {
      final pdf = pw.Document();
      final totalAmount = userExpenses.fold<double>(
          0,
          (sum, item) =>
              sum +
              (item['price'] is double
                  ? item['price']
                  : (item['price'] as num).toDouble()));

      // Format the current date and time for the report
      final now = DateTime.now();
      final formattedDate =
          DateFormat('yyyyMMdd_HHmmss').format(now); // Format to avoid slashes

      // Create PDF document
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text('Expense History Report',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Generated on: $formattedDate'),
              pw.Text('User: $userName'),
              pw.SizedBox(height: 16),
              pw.Container(
                padding: pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.amber50,
                  border: pw.Border.all(color: PdfColors.amber),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Spending:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Rs.${totalAmount.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 16,
                            color: PdfColors.amber900)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Expense Details (${userExpenses.length} items)',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              // Table header
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: {
                  0: pw.FlexColumnWidth(2), // Title
                  1: pw.FlexColumnWidth(1.5), // Group
                  2: pw.FlexColumnWidth(1.5), // Date
                  3: pw.FlexColumnWidth(1), // Amount
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('Title',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('Group',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('Date',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('Amount',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  // Table data
                  ...userExpenses.map((expense) {
                    final date = (expense['createdAt'] as Timestamp).toDate();
                    final formattedDate =
                        DateFormat('dd/MM/yyyy HH:mm').format(date);

                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(expense['title']),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(expense['groupTitle']),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(formattedDate),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                              'Rs.${(expense['price'] as num).toStringAsFixed(2)}',
                              textAlign: pw.TextAlign.right),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Footer(
                title: pw.Text(
                    'This is an automatically generated report of your expenses.',
                    style: pw.TextStyle(
                        fontSize: 10, fontStyle: pw.FontStyle.italic)),
              ),
            ];
          },
        ),
      );

      // Use a more reliable approach to save the file
      Directory? directory;

      // Try to get the Downloads directory first
      try {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory =
              await getExternalStorageDirectory(); // Fallback to app external directory
        }
      } catch (e) {
        // If we can't access external storage, use app documents directory
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception("Could not access any storage directory");
      }

      // Create a filename with formatted date and time
      final String fileName = 'expense_history_$formattedDate.pdf';
      final String filePath = '${directory.path}/$fileName';

      // Save the PDF file
      final File file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // Show success message with file location
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved to: $filePath'),
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );

      // Open the file after saving it
      await OpenFile.open(filePath);

      logger.d("PDF successfully saved to: $filePath");
    } catch (e) {
      logger.e("Error generating PDF: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate expense report: $e')),
      );
    } finally {
      setState(() {
        isPrinting = false;
      });
    }
  }

  void _showExpenseDetailDialog(Map<String, dynamic> expense) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: AppColors.main, width: 1),
          ),
          title: Text('Expense Details',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Title', expense['title']),
                _buildDetailRow('Amount',
                    'Rs.${(expense['price'] as num).toStringAsFixed(2)}'),
                _buildDetailRow('Group', expense['groupTitle']),
                _buildDetailRow('Date', _formatTimestamp(expense['createdAt'])),
                _buildDetailRow('Expense ID', expense['id']),
                _buildDetailRow('Edited', expense['edited'] ? 'Yes' : 'No'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: TextStyle(color: AppColors.main)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          Divider(color: AppColors.gray.withOpacity(0.5)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: CustomAppBar(title: "My Expense History"),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.main))
          : userExpenses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, color: Colors.white70, size: 64),
                      SizedBox(height: 16),
                      Text(
                        "No expenses found",
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                      SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () => _fetchUserData(),
                        icon: Icon(Icons.refresh, color: AppColors.main),
                        label: Text("Refresh",
                            style: TextStyle(color: AppColors.main)),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // User's total expenses
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      margin: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.mainShadow,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.gray),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Your Total Spending",
                            style:
                                TextStyle(fontSize: 16, color: Colors.white70),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Rs.${userExpenses.fold<double>(0, (sum, item) => sum + (item['price'] is double ? item['price'] : (item['price'] as num).toDouble())).toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Expense list header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        children: [
                          Icon(Icons.history, color: Colors.white70, size: 16),
                          SizedBox(width: 8),
                          Text(
                            "Expense History (${userExpenses.length})",
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),

                    // Expense list
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => _fetchUserData(),
                        color: AppColors.main,
                        child: ListView.builder(
                          itemCount: userExpenses.length,
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) {
                            final expense = userExpenses[index];
                            return Card(
                              color: AppColors.mainShadow,
                              margin: EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side:
                                    BorderSide(color: AppColors.gray, width: 1),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        expense['title'],
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.main.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                        border:
                                            Border.all(color: AppColors.main),
                                      ),
                                      child: Text(
                                        expense['groupTitle'],
                                        style: TextStyle(
                                          color: AppColors.main,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 4),
                                    Text(
                                      _formatTimestamp(expense['createdAt']),
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 12),
                                    ),
                                    if (expense['edited'] == true)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          "edited",
                                          style: TextStyle(
                                            color: Colors.orangeAccent,
                                            fontSize: 10,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Text(
                                  "Rs.${(expense['price'] as num).toStringAsFixed(2)}",
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                onTap: () {
                                  // Show expense details dialog on tap
                                  _showExpenseDetailDialog(expense);
                                },
                                onLongPress: () {
                                  // Navigate to expense details or group screen
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => PriceScreen(
                                        groupId: expense['groupId'],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Print expenses button
          FloatingActionButton(
            heroTag: "print",
            onPressed: isPrinting ? null : _printExpenseDetails,
            backgroundColor: Colors.amber,
            child: isPrinting
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(Icons.print, color: Colors.white),
            tooltip: 'Print Expense History',
          ),
          SizedBox(height: 16),
          // Refresh button
          FloatingActionButton(
            heroTag: "refresh",
            onPressed: () => _fetchUserData(),
            backgroundColor: AppColors.main,
            child: Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Expenses',
          ),
        ],
      ),
    );
  }
}
