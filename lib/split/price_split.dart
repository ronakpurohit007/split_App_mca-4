import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:login/widgets/AppBar.dart';
import 'package:login/widgets/colors.dart';
import 'package:login/widgets/login_btn.dart';
import 'package:login/widgets/snackbar_utils.dart';
import 'package:login/widgets/logger.dart';

final ConsoleAppLogger logger = ConsoleAppLogger();

class PriceScreen extends StatefulWidget {
  final String groupId;

  PriceScreen({required this.groupId});

  @override
  _PriceScreenState createState() => _PriceScreenState();
}

class _PriceScreenState extends State<PriceScreen> {
  List<Map<String, dynamic>> expenses = [];
  double totalAmount = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    setState(() {
      isLoading = true;
    });

    try {
      logger.d("Fetching expenses for group: ${widget.groupId}");
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('expenses')
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> fetchedExpenses = [];
      double sum = 0.0;

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        logger.d("Fetched document: ${doc.id} => $data");
        fetchedExpenses.add(data);
        sum += (data['price'] as num).toDouble();
      }

      setState(() {
        expenses = fetchedExpenses;
        totalAmount = sum;
        isLoading = false;
      });

      logger.d("Fetched expenses: ${expenses.length}, Total: $totalAmount");
    } catch (e) {
      logger.e("Error fetching expenses: $e");
      setState(() {
        isLoading = false;
      });
      SnackbarUtils.showErrorSnackbar(context, "Failed to load expenses");
    }
  }

  void _showAddExpenseSheet() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController priceController = TextEditingController();

    logger.d("Opening add expense bottom sheet");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.gray, width: 1),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              SizedBox(height: 20),
              Text(
                "Add Expense",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
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
              TextField(
                controller: priceController,
                style: TextStyle(color: Colors.white),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "Price",
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
              SizedBox(height: 20),
              CustomMainButton(
                width: double.infinity,
                text: "Save",
                onPressed: () async {
                  String title = titleController.text.trim();
                  String priceText = priceController.text.trim();
                  logger.d(
                      "Attempting to save expense with title: '$title' and price: '$priceText'");

                  if (title.isEmpty) {
                    logger.d("Title validation failed: empty title");
                    SnackbarUtils.showErrorSnackbar(
                        context, "Title cannot be empty");
                    return;
                  }

                  double? price = double.tryParse(priceText);
                  if (price == null || price <= 0) {
                    logger.d(
                        "Price validation failed: invalid price entered: '$priceText'");
                    SnackbarUtils.showErrorSnackbar(
                        context, "Please enter a valid price");
                    return;
                  }

                  try {
                    await FirebaseFirestore.instance
                        .collection('groups')
                        .doc(widget.groupId)
                        .collection('expenses')
                        .add({
                      'title': title,
                      'price': price,
                      'createdAt': Timestamp.now(),
                    });

                    logger.d("Expense added: title='$title', price=$price");

                    Navigator.pop(context);
                    _fetchExpenses();
                    SnackbarUtils.showSuccessSnackbar(
                        context, "Expense added successfully");
                  } catch (e) {
                    logger.e("Error adding expense: $e");
                    SnackbarUtils.showErrorSnackbar(
                        context, "Failed to add expense");
                  }
                },
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return "${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    }
    return "Unknown date";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Expenses"),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.main))
          : Column(
              children: [
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
                        "Total Expenses",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "₹${totalAmount.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: expenses.isEmpty
                      ? Center(
                          child: Text(
                            "No expenses added yet",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: expenses.length,
                          padding: EdgeInsets.all(16),
                          itemBuilder: (context, index) {
                            return Card(
                              color: AppColors.mainShadow,
                              margin: EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side:
                                    BorderSide(color: AppColors.gray, width: 1),
                              ),
                              child: ListTile(
                                title: Text(
                                  expenses[index]['title'],
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  _formatTimestamp(
                                      expenses[index]['createdAt']),
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Text(
                                  "₹${(expenses[index]['price'] as num).toStringAsFixed(2)}",
                                  style: TextStyle(
                                    color: AppColors.main,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
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
        onPressed: _showAddExpenseSheet,
        backgroundColor: AppColors.main,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
