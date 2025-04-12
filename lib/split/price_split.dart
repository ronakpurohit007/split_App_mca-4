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

  List<String> members = [];
  TextEditingController userController = TextEditingController();
  bool isShowingMembers = false;

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
    _fetchGroupMembers();
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
      double sum = 0.0;

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        fetchedExpenses.add(data);
        sum += (data['price'] as num).toDouble();
      }

      setState(() {
        expenses = fetchedExpenses;
        totalAmount = sum;
        isLoading = false;
      });
    } catch (e) {
      logger.e("Error fetching expenses: $e");
      setState(() => isLoading = false);
      SnackbarUtils.showErrorSnackbar(context, "Failed to load expenses");
    }
  }

  Future<void> _fetchGroupMembers() async {
    try {
      DocumentSnapshot groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (groupDoc.exists) {
        var data = groupDoc.data() as Map<String, dynamic>;
        if (data.containsKey('members') && data['members'] is List) {
          setState(() {
            members = List<String>.from(data['members']);
          });
          logger.d("Fetched group members: $members");
        }
      }
    } catch (e) {
      logger.e("Error fetching group members: $e");
    }
  }

  void _deleteExpense(String expenseId) async {
    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('expenses')
          .doc(expenseId)
          .delete();

      SnackbarUtils.showSuccessSnackbar(context, "Expense deleted");
      _fetchExpenses();
    } catch (e) {
      logger.e("Error deleting expense: $e");
      SnackbarUtils.showErrorSnackbar(context, "Failed to delete expense");
    }
  }

  void _showEditDialog(Map<String, dynamic> expense) {
    final TextEditingController titleController =
        TextEditingController(text: expense['title']);
    final TextEditingController priceController =
        TextEditingController(text: expense['price'].toString());
    final TextEditingController userController =
        TextEditingController(text: expense['user']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.black,
          title: Text("Edit Expense", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Title",
                  labelStyle: TextStyle(color: AppColors.gray),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: userController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "User",
                  labelStyle: TextStyle(color: AppColors.gray),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Price",
                  labelStyle: TextStyle(color: AppColors.gray),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () async {
                String title = titleController.text.trim();
                String user = userController.text.trim();
                double? price = double.tryParse(priceController.text.trim());

                if (title.isEmpty ||
                    user.isEmpty ||
                    price == null ||
                    price <= 0) {
                  SnackbarUtils.showErrorSnackbar(
                      context, "Please fill valid values");
                  return;
                }

                try {
                  await FirebaseFirestore.instance
                      .collection('groups')
                      .doc(widget.groupId)
                      .collection('expenses')
                      .doc(expense['id'])
                      .update({
                    'title': title,
                    'user': user,
                    'price': price,
                    'edited': true,
                  });

                  Navigator.pop(context);
                  _fetchExpenses();
                  SnackbarUtils.showSuccessSnackbar(context, "Expense updated");
                } catch (e) {
                  logger.e("Error updating expense: $e");
                  SnackbarUtils.showErrorSnackbar(
                      context, "Failed to update expense");
                }
              },
              child: Text("Save", style: TextStyle(color: AppColors.main)),
            ),
          ],
        );
      },
    );
  }

  void _showAddExpenseSheet() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    userController = TextEditingController();
    List<String> filteredMembers = List.from(members);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.gray, width: 1),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: SingleChildScrollView(
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
                  Text("Add Expense",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
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
                    controller: userController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "User",
                      labelStyle: TextStyle(color: AppColors.gray),
                      hintText: "Type to search members",
                      hintStyle: TextStyle(color: AppColors.gray),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.gray),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.main),
                      ),
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setModalState(() {
                            isShowingMembers = !isShowingMembers;
                          });
                        },
                        child: Icon(
                          isShowingMembers
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                          color: AppColors.gray,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      setModalState(() {
                        isShowingMembers = true;
                        filteredMembers = members
                            .where((member) => member
                                .toLowerCase()
                                .contains(value.toLowerCase()))
                            .toList();
                      });
                    },
                    onTap: () {
                      setModalState(() {
                        isShowingMembers = true;
                      });
                    },
                  ),
                  if (isShowingMembers)
                    Container(
                      margin: EdgeInsets.only(top: 5),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.mainShadow,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.gray),
                      ),
                      constraints: BoxConstraints(maxHeight: 150),
                      child: filteredMembers.isEmpty
                          ? Center(
                              child: Text("No matching members found",
                                  style: TextStyle(color: Colors.white70)),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filteredMembers.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  dense: true,
                                  title: Text(filteredMembers[index],
                                      style: TextStyle(color: Colors.white)),
                                  onTap: () {
                                    setModalState(() {
                                      userController.text =
                                          filteredMembers[index];
                                      isShowingMembers = false;
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  SizedBox(height: 16),
                  TextField(
                    controller: priceController,
                    style: TextStyle(color: Colors.white),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
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
                      String user = userController.text.trim();

                      if (title.isEmpty) {
                        SnackbarUtils.showErrorSnackbar(
                            context, "Title cannot be empty");
                        return;
                      }

                      if (user.isEmpty) {
                        SnackbarUtils.showErrorSnackbar(
                            context, "Please select a user");
                        return;
                      }

                      double? price = double.tryParse(priceText);
                      if (price == null || price <= 0) {
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
                          'user': user,
                          'createdAt': Timestamp.now(),
                        });

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
            ),
          );
        });
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
                      Text("Total Expenses",
                          style:
                              TextStyle(fontSize: 16, color: Colors.white70)),
                      SizedBox(height: 8),
                      Text("₹${totalAmount.toStringAsFixed(2)}",
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ],
                  ),
                ),
                Expanded(
                  child: expenses.isEmpty
                      ? Center(
                          child: Text("No expenses added yet",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 16)),
                        )
                      : ListView.builder(
                          itemCount: expenses.length,
                          padding: EdgeInsets.all(16),
                          itemBuilder: (context, index) {
                            final expense = expenses[index];
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
                                  expense['title'],
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${_formatTimestamp(expense['createdAt'])}\nUser: ${expense['user'] ?? 'N/A'}",
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 12),
                                    ),
                                    if ((expense['edited'] ?? false))
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
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "₹${(expense['price'] as num).toStringAsFixed(2)}",
                                      style: TextStyle(
                                          color: Colors.amber,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18),
                                    ),
                                    SizedBox(width: 10),
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _showEditDialog(expense);
                                        } else if (value == 'delete') {
                                          _deleteExpense(expense['id']);
                                        }
                                      },
                                      itemBuilder: (context) =>
                                          <PopupMenuEntry<String>>[
                                        PopupMenuItem(
                                            value: 'edit', child: Text("Edit")),
                                        PopupMenuItem(
                                            value: 'delete',
                                            child: Text("Delete")),
                                      ],
                                      icon: Icon(Icons.more_vert,
                                          color: Colors.white),
                                    ),
                                  ],
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
