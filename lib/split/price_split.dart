// lib/screens/price_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:login/split/show_split.dart';
import 'package:login/widgets/AppBar.dart';
import 'package:login/widgets/colors.dart';
import 'package:login/widgets/login_btn.dart';
import 'package:login/widgets/snackbar_utils.dart';
import 'package:login/widgets/logger.dart';
import 'package:login/widgets/expense_actions_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart';

final ConsoleAppLogger logger = ConsoleAppLogger();

class PriceScreen extends StatefulWidget {
  final String groupId;

  PriceScreen({required this.groupId});

  @override
  _PriceScreenState createState() => _PriceScreenState();
}

class _PriceScreenState extends State<PriceScreen> {
  List<Map<String, dynamic>> expenses = [];
  List<Map<String, dynamic>> filteredExpenses = [];
  double totalAmount = 0.0;
  double filteredAmount = 0.0;
  bool isLoading = true;

  List<String> members = [];
  String currentUserName = '';
  String selectedFilter = 'All';

  TextEditingController userController = TextEditingController();
  bool isShowingMembers = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
    _fetchExpenses();
    _fetchGroupMembers();
  }

  Future<void> _fetchCurrentUser() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          var userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            currentUserName =
                userData['username'] ?? user.displayName ?? user.email ?? 'You';
          });
          logger.d("Current user: $currentUserName");
        }
      }
    } catch (e) {
      logger.e("Error fetching current user: $e");
    }
  }

  Future _fetchExpenses() async {
    setState(() => isLoading = true);
    try {
      // Fetch the group document to get the total
      DocumentSnapshot groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      double storedTotal = 0.0;
      if (groupDoc.exists) {
        var groupData = groupDoc.data() as Map;
        if (groupData.containsKey('totalExpenses')) {
          storedTotal = (groupData['totalExpenses'] as num).toDouble();
        }
      }

      // Fetch expenses for display
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

        // Only add expenses that don't have isSplit set to true
        if (!(data['isSplit'] == true)) {
          fetchedExpenses.add(data);
        }
      }

      setState(() {
        expenses = fetchedExpenses;
        totalAmount = storedTotal;
        _applyFilter(selectedFilter);
        isLoading = false;
      });
    } catch (e) {
      logger.e("Error fetching expenses: $e");
      setState(() => isLoading = false);
      SnackbarUtils.showErrorSnackbar(context, "Failed to load expenses");
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      selectedFilter = filter;

      if (filter == 'All') {
        filteredExpenses = List.from(expenses);
        filteredAmount = totalAmount;
      } else {
        filteredExpenses =
            expenses.where((expense) => expense['user'] == filter).toList();
        filteredAmount = filteredExpenses.fold(
            0.0, (sum, expense) => sum + (expense['price'] as num).toDouble());
      }
    });
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
      // First get the expense amount
      DocumentSnapshot expenseDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('expenses')
          .doc(expenseId)
          .get();

      if (expenseDoc.exists) {
        var expenseData = expenseDoc.data() as Map<String, dynamic>;
        double expenseAmount = (expenseData['price'] as num).toDouble();

        // Begin a batch write
        WriteBatch batch = FirebaseFirestore.instance.batch();

        // Delete the expense
        batch.delete(expenseDoc.reference);

        // Update the group total
        DocumentReference groupRef =
            FirebaseFirestore.instance.collection('groups').doc(widget.groupId);

        batch.update(
            groupRef, {'totalExpenses': FieldValue.increment(-expenseAmount)});

        // Commit the batch
        await batch.commit();

        SnackbarUtils.showSuccessSnackbar(context, "Expense deleted");
        _fetchExpenses();
      }
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

                // Ensure proper parsing of the price
                double? newPrice = double.tryParse(priceController.text.trim());

                if (title.isEmpty ||
                    user.isEmpty ||
                    newPrice == null ||
                    newPrice <= 0) {
                  SnackbarUtils.showErrorSnackbar(
                      context, "Please fill valid values");
                  return;
                }

                try {
                  // Ensure oldPrice is properly cast to double
                  double oldPrice = (expense['price'] is double)
                      ? expense['price']
                      : (expense['price'] as num).toDouble();

                  double priceDifference = newPrice - oldPrice;

                  // Begin a batch write
                  WriteBatch batch = FirebaseFirestore.instance.batch();

                  // Update the expense
                  DocumentReference expenseRef = FirebaseFirestore.instance
                      .collection('groups')
                      .doc(widget.groupId)
                      .collection('expenses')
                      .doc(expense['id']);

                  batch.update(expenseRef, {
                    'title': title,
                    'user': user,
                    'price': newPrice,
                    'edited': true,
                  });

                  // Update the group total if price changed
                  if (priceDifference != 0) {
                    DocumentReference groupRef = FirebaseFirestore.instance
                        .collection('groups')
                        .doc(widget.groupId);

                    batch.update(groupRef, {
                      'totalExpenses': FieldValue.increment(priceDifference)
                    });
                  }

                  // Commit the batch
                  await batch.commit();

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

  // Method to add a new expense with batch operation
  void _showAddExpenseSheet() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    userController = TextEditingController();

    // Pre-fill with current user name if available
    if (currentUserName.isNotEmpty) {
      userController.text = currentUserName;
    }

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
                        // Begin a batch write for atomicity
                        WriteBatch batch = FirebaseFirestore.instance.batch();

                        // Add the new expense
                        DocumentReference expenseRef = FirebaseFirestore
                            .instance
                            .collection('groups')
                            .doc(widget.groupId)
                            .collection('expenses')
                            .doc(); // Auto-generated ID

                        batch.set(expenseRef, {
                          'title': title,
                          'price': price,
                          'user': user,
                          'createdAt': Timestamp.now(),
                        });

                        // Update the group total
                        DocumentReference groupRef = FirebaseFirestore.instance
                            .collection('groups')
                            .doc(widget.groupId);

                        batch.update(groupRef,
                            {'totalExpenses': FieldValue.increment(price)});

                        // Commit the batch
                        await batch.commit();

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

  // New method to show the action sheet with multiple buttons
  void _showActionsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ExpenseActionsSheet(
          groupId: widget.groupId,
          members: members,
          onAddExpensePressed: _showAddExpenseSheet,
          amount: totalAmount,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Expenses"),
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

                // Total expense container
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
                              ? "Total Expenses"
                              : selectedFilter == currentUserName
                                  ? "Your Expenses"
                                  : "$selectedFilter's Expenses",
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

                // Expenses list
                Expanded(
                  child: filteredExpenses.isEmpty
                      ? Center(
                          child: Text(
                              selectedFilter == 'All'
                                  ? "No expenses added yet"
                                  : "No expenses for $selectedFilter",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 16)),
                        )
                      : ListView.builder(
                          itemCount: filteredExpenses.length,
                          padding: EdgeInsets.all(16),
                          itemBuilder: (context, index) {
                            final expense = filteredExpenses[index];
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
                                      "Rs.${(expense['price'] as num).toStringAsFixed(2)}",
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Receipt/statement button
          FloatingActionButton(
            onPressed: () {
              // Add your receipt/statement functionality here
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SplitExpensesScreen(
                    groupId: widget.groupId,
                    groupTitle: '',
                    members: members,
                  ),
                ),
              );
            },
            backgroundColor: AppColors.main,
            heroTag: "receiptButton",
            child: Icon(Icons.receipt, color: Colors.white),
          ),
          SizedBox(height: 16), // Space between buttons
          // Add expense button
          FloatingActionButton(
            onPressed: _showActionsSheet,
            backgroundColor: AppColors.main,
            heroTag: "addButton",
            child: Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
