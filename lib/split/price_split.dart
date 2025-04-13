// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:login/widgets/AppBar.dart';
// import 'package:login/widgets/colors.dart';
// import 'package:login/widgets/login_btn.dart';
// import 'package:login/widgets/snackbar_utils.dart';
// import 'package:login/widgets/logger.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// final ConsoleAppLogger logger = ConsoleAppLogger();

// class PriceScreen extends StatefulWidget {
//   final String groupId;

//   PriceScreen({required this.groupId});

//   @override
//   _PriceScreenState createState() => _PriceScreenState();
// }

// class _PriceScreenState extends State<PriceScreen> {
//   List<Map<String, dynamic>> expenses = [];
//   List<Map<String, dynamic>> filteredExpenses = [];
//   double totalAmount = 0.0;
//   double filteredAmount = 0.0;
//   bool isLoading = true;

//   List<String> members = [];
//   String currentUserName = '';
//   String selectedFilter = 'All';

//   TextEditingController userController = TextEditingController();
//   bool isShowingMembers = false;

//   @override
//   void initState() {
//     super.initState();
//     _fetchCurrentUser();
//     _fetchExpenses();
//     _fetchGroupMembers();
//   }

//   Future<void> _fetchCurrentUser() async {
//     try {
//       User? user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         DocumentSnapshot userDoc = await FirebaseFirestore.instance
//             .collection('users')
//             .doc(user.uid)
//             .get();

//         if (userDoc.exists) {
//           var userData = userDoc.data() as Map<String, dynamic>;
//           setState(() {
//             currentUserName =
//                 userData['username'] ?? user.displayName ?? user.email ?? 'You';
//           });
//           logger.d("Current user: $currentUserName");
//         }
//       }
//     } catch (e) {
//       logger.e("Error fetching current user: $e");
//     }
//   }

//   Future<void> _fetchExpenses() async {
//     setState(() => isLoading = true);
//     try {
//       QuerySnapshot snapshot = await FirebaseFirestore.instance
//           .collection('groups')
//           .doc(widget.groupId)
//           .collection('expenses')
//           .orderBy('createdAt', descending: true)
//           .get();

//       List<Map<String, dynamic>> fetchedExpenses = [];
//       double sum = 0.0;

//       for (var doc in snapshot.docs) {
//         Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
//         data['id'] = doc.id;
//         fetchedExpenses.add(data);
//         sum += (data['price'] as num).toDouble();
//       }

//       setState(() {
//         expenses = fetchedExpenses;
//         totalAmount = sum;
//         _applyFilter(selectedFilter);
//         isLoading = false;
//       });
//     } catch (e) {
//       logger.e("Error fetching expenses: $e");
//       setState(() => isLoading = false);
//       SnackbarUtils.showErrorSnackbar(context, "Failed to load expenses");
//     }
//   }

//   void _applyFilter(String filter) {
//     setState(() {
//       selectedFilter = filter;

//       if (filter == 'All') {
//         filteredExpenses = List.from(expenses);
//         filteredAmount = totalAmount;
//       } else {
//         // Filter by specific username (including current user)
//         filteredExpenses =
//             expenses.where((expense) => expense['user'] == filter).toList();

//         // Recalculate filtered total
//         filteredAmount = filteredExpenses.fold(
//             0.0, (sum, expense) => sum + (expense['price'] as num).toDouble());
//       }
//     });
//   }

//   Future<void> _fetchGroupMembers() async {
//     try {
//       DocumentSnapshot groupDoc = await FirebaseFirestore.instance
//           .collection('groups')
//           .doc(widget.groupId)
//           .get();

//       if (groupDoc.exists) {
//         var data = groupDoc.data() as Map<String, dynamic>;
//         if (data.containsKey('members') && data['members'] is List) {
//           setState(() {
//             members = List<String>.from(data['members']);
//           });
//           logger.d("Fetched group members: $members");
//         }
//       }
//     } catch (e) {
//       logger.e("Error fetching group members: $e");
//     }
//   }

//   void _deleteExpense(String expenseId) async {
//     try {
//       await FirebaseFirestore.instance
//           .collection('groups')
//           .doc(widget.groupId)
//           .collection('expenses')
//           .doc(expenseId)
//           .delete();

//       SnackbarUtils.showSuccessSnackbar(context, "Expense deleted");
//       _fetchExpenses();
//     } catch (e) {
//       logger.e("Error deleting expense: $e");
//       SnackbarUtils.showErrorSnackbar(context, "Failed to delete expense");
//     }
//   }

//   void _showEditDialog(Map<String, dynamic> expense) {
//     final TextEditingController titleController =
//         TextEditingController(text: expense['title']);
//     final TextEditingController priceController =
//         TextEditingController(text: expense['price'].toString());
//     final TextEditingController userController =
//         TextEditingController(text: expense['user']);

//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           backgroundColor: AppColors.black,
//           title: Text("Edit Expense", style: TextStyle(color: Colors.white)),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: titleController,
//                 style: TextStyle(color: Colors.white),
//                 decoration: InputDecoration(
//                   labelText: "Title",
//                   labelStyle: TextStyle(color: AppColors.gray),
//                 ),
//               ),
//               SizedBox(height: 10),
//               TextField(
//                 controller: userController,
//                 style: TextStyle(color: Colors.white),
//                 decoration: InputDecoration(
//                   labelText: "User",
//                   labelStyle: TextStyle(color: AppColors.gray),
//                 ),
//               ),
//               SizedBox(height: 10),
//               TextField(
//                 controller: priceController,
//                 keyboardType: TextInputType.numberWithOptions(decimal: true),
//                 style: TextStyle(color: Colors.white),
//                 decoration: InputDecoration(
//                   labelText: "Price",
//                   labelStyle: TextStyle(color: AppColors.gray),
//                 ),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: Text("Cancel", style: TextStyle(color: Colors.white70)),
//             ),
//             TextButton(
//               onPressed: () async {
//                 String title = titleController.text.trim();
//                 String user = userController.text.trim();
//                 double? price = double.tryParse(priceController.text.trim());

//                 if (title.isEmpty ||
//                     user.isEmpty ||
//                     price == null ||
//                     price <= 0) {
//                   SnackbarUtils.showErrorSnackbar(
//                       context, "Please fill valid values");
//                   return;
//                 }

//                 try {
//                   await FirebaseFirestore.instance
//                       .collection('groups')
//                       .doc(widget.groupId)
//                       .collection('expenses')
//                       .doc(expense['id'])
//                       .update({
//                     'title': title,
//                     'user': user,
//                     'price': price,
//                     'edited': true,
//                   });

//                   Navigator.pop(context);
//                   _fetchExpenses();
//                   SnackbarUtils.showSuccessSnackbar(context, "Expense updated");
//                 } catch (e) {
//                   logger.e("Error updating expense: $e");
//                   SnackbarUtils.showErrorSnackbar(
//                       context, "Failed to update expense");
//                 }
//               },
//               child: Text("Save", style: TextStyle(color: AppColors.main)),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _showAddExpenseSheet() {
//     final TextEditingController titleController = TextEditingController();
//     final TextEditingController priceController = TextEditingController();
//     userController = TextEditingController();

//     // Pre-fill with current user name if available
//     if (currentUserName.isNotEmpty) {
//       userController.text = currentUserName;
//     }

//     List<String> filteredMembers = List.from(members);

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: AppColors.black,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//         side: BorderSide(color: AppColors.gray, width: 1),
//       ),
//       builder: (context) {
//         return StatefulBuilder(builder: (context, setModalState) {
//           return Padding(
//             padding: EdgeInsets.only(
//               bottom: MediaQuery.of(context).viewInsets.bottom,
//               left: 16,
//               right: 16,
//               top: 16,
//             ),
//             child: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Center(
//                     child: Container(
//                       width: 40,
//                       height: 5,
//                       decoration: BoxDecoration(
//                         color: AppColors.gray,
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 20),
//                   Text("Add Expense",
//                       style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white)),
//                   SizedBox(height: 20),
//                   TextField(
//                     controller: titleController,
//                     style: TextStyle(color: Colors.white),
//                     decoration: InputDecoration(
//                       labelText: "Title",
//                       labelStyle: TextStyle(color: AppColors.gray),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                         borderSide: BorderSide(color: AppColors.gray),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                         borderSide: BorderSide(color: AppColors.main),
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 16),
//                   TextField(
//                     controller: userController,
//                     style: TextStyle(color: Colors.white),
//                     decoration: InputDecoration(
//                       labelText: "User",
//                       labelStyle: TextStyle(color: AppColors.gray),
//                       hintText: "Type to search members",
//                       hintStyle: TextStyle(color: AppColors.gray),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                         borderSide: BorderSide(color: AppColors.gray),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                         borderSide: BorderSide(color: AppColors.main),
//                       ),
//                       suffixIcon: GestureDetector(
//                         onTap: () {
//                           setModalState(() {
//                             isShowingMembers = !isShowingMembers;
//                           });
//                         },
//                         child: Icon(
//                           isShowingMembers
//                               ? Icons.arrow_drop_up
//                               : Icons.arrow_drop_down,
//                           color: AppColors.gray,
//                         ),
//                       ),
//                     ),
//                     onChanged: (value) {
//                       setModalState(() {
//                         isShowingMembers = true;
//                         filteredMembers = members
//                             .where((member) => member
//                                 .toLowerCase()
//                                 .contains(value.toLowerCase()))
//                             .toList();
//                       });
//                     },
//                     onTap: () {
//                       setModalState(() {
//                         isShowingMembers = true;
//                       });
//                     },
//                   ),
//                   if (isShowingMembers)
//                     Container(
//                       margin: EdgeInsets.only(top: 5),
//                       padding: EdgeInsets.all(10),
//                       decoration: BoxDecoration(
//                         color: AppColors.mainShadow,
//                         borderRadius: BorderRadius.circular(10),
//                         border: Border.all(color: AppColors.gray),
//                       ),
//                       constraints: BoxConstraints(maxHeight: 150),
//                       child: filteredMembers.isEmpty
//                           ? Center(
//                               child: Text("No matching members found",
//                                   style: TextStyle(color: Colors.white70)),
//                             )
//                           : ListView.builder(
//                               shrinkWrap: true,
//                               itemCount: filteredMembers.length,
//                               itemBuilder: (context, index) {
//                                 return ListTile(
//                                   dense: true,
//                                   title: Text(filteredMembers[index],
//                                       style: TextStyle(color: Colors.white)),
//                                   onTap: () {
//                                     setModalState(() {
//                                       userController.text =
//                                           filteredMembers[index];
//                                       isShowingMembers = false;
//                                     });
//                                   },
//                                 );
//                               },
//                             ),
//                     ),
//                   SizedBox(height: 16),
//                   TextField(
//                     controller: priceController,
//                     style: TextStyle(color: Colors.white),
//                     keyboardType:
//                         TextInputType.numberWithOptions(decimal: true),
//                     decoration: InputDecoration(
//                       labelText: "Price",
//                       labelStyle: TextStyle(color: AppColors.gray),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                         borderSide: BorderSide(color: AppColors.gray),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                         borderSide: BorderSide(color: AppColors.main),
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 20),
//                   CustomMainButton(
//                     width: double.infinity,
//                     text: "Save",
//                     onPressed: () async {
//                       String title = titleController.text.trim();
//                       String priceText = priceController.text.trim();
//                       String user = userController.text.trim();

//                       if (title.isEmpty) {
//                         SnackbarUtils.showErrorSnackbar(
//                             context, "Title cannot be empty");
//                         return;
//                       }

//                       if (user.isEmpty) {
//                         SnackbarUtils.showErrorSnackbar(
//                             context, "Please select a user");
//                         return;
//                       }

//                       double? price = double.tryParse(priceText);
//                       if (price == null || price <= 0) {
//                         SnackbarUtils.showErrorSnackbar(
//                             context, "Please enter a valid price");
//                         return;
//                       }

//                       try {
//                         await FirebaseFirestore.instance
//                             .collection('groups')
//                             .doc(widget.groupId)
//                             .collection('expenses')
//                             .add({
//                           'title': title,
//                           'price': price,
//                           'user': user,
//                           'createdAt': Timestamp.now(),
//                         });

//                         Navigator.pop(context);
//                         _fetchExpenses();
//                         SnackbarUtils.showSuccessSnackbar(
//                             context, "Expense added successfully");
//                       } catch (e) {
//                         logger.e("Error adding expense: $e");
//                         SnackbarUtils.showErrorSnackbar(
//                             context, "Failed to add expense");
//                       }
//                     },
//                   ),
//                   SizedBox(height: 20),
//                 ],
//               ),
//             ),
//           );
//         });
//       },
//     );
//   }

//   String _formatTimestamp(dynamic timestamp) {
//     if (timestamp is Timestamp) {
//       final date = timestamp.toDate();
//       return "${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
//     }
//     return "Unknown date";
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CustomAppBar(title: "Expenses"),
//       body: isLoading
//           ? Center(child: CircularProgressIndicator(color: AppColors.main))
//           : Column(
//               children: [
//                 // Filter chips row
//                 Container(
//                   height: 60,
//                   padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   child: SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: Row(
//                       children: [
//                         // All filter
//                         GestureDetector(
//                           onTap: () => _applyFilter('All'),
//                           child: Container(
//                             padding: EdgeInsets.symmetric(
//                                 horizontal: 16, vertical: 8),
//                             margin: EdgeInsets.only(right: 8),
//                             decoration: BoxDecoration(
//                               color: selectedFilter == 'All'
//                                   ? AppColors.main
//                                   : AppColors.mainShadow,
//                               borderRadius: BorderRadius.circular(20),
//                               border: Border.all(
//                                   color: selectedFilter == 'All'
//                                       ? AppColors.main
//                                       : AppColors.gray),
//                             ),
//                             child: Text(
//                               "All",
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: selectedFilter == 'All'
//                                     ? FontWeight.bold
//                                     : FontWeight.normal,
//                               ),
//                             ),
//                           ),
//                         ),

//                         // Current user filter (showing actual username instead of "You")
//                         if (currentUserName.isNotEmpty)
//                           GestureDetector(
//                             onTap: () => _applyFilter(currentUserName),
//                             child: Container(
//                               padding: EdgeInsets.symmetric(
//                                   horizontal: 16, vertical: 8),
//                               margin: EdgeInsets.only(right: 8),
//                               decoration: BoxDecoration(
//                                 color: selectedFilter == currentUserName
//                                     ? AppColors.main
//                                     : AppColors.mainShadow,
//                                 borderRadius: BorderRadius.circular(20),
//                                 border: Border.all(
//                                     color: selectedFilter == currentUserName
//                                         ? AppColors.main
//                                         : AppColors.gray),
//                               ),
//                               child: Row(
//                                 children: [
//                                   Text(
//                                     currentUserName,
//                                     style: TextStyle(
//                                       color: Colors.white,
//                                       fontWeight:
//                                           selectedFilter == currentUserName
//                                               ? FontWeight.bold
//                                               : FontWeight.normal,
//                                     ),
//                                   ),
//                                   SizedBox(width: 4),
//                                   Icon(
//                                     Icons.person,
//                                     size: 16,
//                                     color: Colors.white70,
//                                   )
//                                 ],
//                               ),
//                             ),
//                           ),

//                         // Individual member filters (excluding current user)
//                         ...members
//                             .where((member) => member != currentUserName)
//                             .map((member) {
//                           return GestureDetector(
//                             onTap: () => _applyFilter(member),
//                             child: Container(
//                               padding: EdgeInsets.symmetric(
//                                   horizontal: 16, vertical: 8),
//                               margin: EdgeInsets.only(right: 8),
//                               decoration: BoxDecoration(
//                                 color: selectedFilter == member
//                                     ? AppColors.main
//                                     : AppColors.mainShadow,
//                                 borderRadius: BorderRadius.circular(20),
//                                 border: Border.all(
//                                     color: selectedFilter == member
//                                         ? AppColors.main
//                                         : AppColors.gray),
//                               ),
//                               child: Text(
//                                 member,
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontWeight: selectedFilter == member
//                                       ? FontWeight.bold
//                                       : FontWeight.normal,
//                                 ),
//                               ),
//                             ),
//                           );
//                         }).toList(),
//                       ],
//                     ),
//                   ),
//                 ),

//                 // Total expense container
//                 Container(
//                   width: double.infinity,
//                   padding: EdgeInsets.all(16),
//                   margin: EdgeInsets.symmetric(horizontal: 16),
//                   decoration: BoxDecoration(
//                     color: AppColors.mainShadow,
//                     borderRadius: BorderRadius.circular(10),
//                     border: Border.all(color: AppColors.gray),
//                   ),
//                   child: Column(
//                     children: [
//                       Text(
//                           selectedFilter == 'All'
//                               ? "Total Expenses"
//                               : selectedFilter == currentUserName
//                                   ? "Your Expenses"
//                                   : "$selectedFilter's Expenses",
//                           style:
//                               TextStyle(fontSize: 16, color: Colors.white70)),
//                       SizedBox(height: 8),
//                       Text(
//                           "Rs.${selectedFilter == 'All' ? totalAmount.toStringAsFixed(2) : filteredAmount.toStringAsFixed(2)}",
//                           style: TextStyle(
//                               fontSize: 28,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white)),
//                     ],
//                   ),
//                 ),

//                 // Expenses list
//                 Expanded(
//                   child: filteredExpenses.isEmpty
//                       ? Center(
//                           child: Text(
//                               selectedFilter == 'All'
//                                   ? "No expenses added yet"
//                                   : "No expenses for $selectedFilter",
//                               style: TextStyle(
//                                   color: Colors.white70, fontSize: 16)),
//                         )
//                       : ListView.builder(
//                           itemCount: filteredExpenses.length,
//                           padding: EdgeInsets.all(16),
//                           itemBuilder: (context, index) {
//                             final expense = filteredExpenses[index];
//                             return Card(
//                               color: AppColors.mainShadow,
//                               margin: EdgeInsets.only(bottom: 10),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                                 side:
//                                     BorderSide(color: AppColors.gray, width: 1),
//                               ),
//                               child: ListTile(
//                                 title: Text(
//                                   expense['title'],
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 subtitle: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       "${_formatTimestamp(expense['createdAt'])}\nUser: ${expense['user'] ?? 'N/A'}",
//                                       style: TextStyle(
//                                           color: Colors.white70, fontSize: 12),
//                                     ),
//                                     if ((expense['edited'] ?? false))
//                                       Padding(
//                                         padding: const EdgeInsets.only(top: 4),
//                                         child: Text(
//                                           "edited",
//                                           style: TextStyle(
//                                             color: Colors.orangeAccent,
//                                             fontSize: 10,
//                                             fontStyle: FontStyle.italic,
//                                           ),
//                                         ),
//                                       ),
//                                   ],
//                                 ),
//                                 trailing: Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     Text(
//                                       "Rs.${(expense['price'] as num).toStringAsFixed(2)}",
//                                       style: TextStyle(
//                                           color: Colors.amber,
//                                           fontWeight: FontWeight.bold,
//                                           fontSize: 18),
//                                     ),
//                                     SizedBox(width: 10),
//                                     PopupMenuButton<String>(
//                                       onSelected: (value) {
//                                         if (value == 'edit') {
//                                           _showEditDialog(expense);
//                                         } else if (value == 'delete') {
//                                           _deleteExpense(expense['id']);
//                                         }
//                                       },
//                                       itemBuilder: (context) =>
//                                           <PopupMenuEntry<String>>[
//                                         PopupMenuItem(
//                                             value: 'edit', child: Text("Edit")),
//                                         PopupMenuItem(
//                                             value: 'delete',
//                                             child: Text("Delete")),
//                                       ],
//                                       icon: Icon(Icons.more_vert,
//                                           color: Colors.white),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                 ),
//               ],
//             ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _showAddExpenseSheet,
//         backgroundColor: AppColors.main,
//         child: Icon(Icons.add, color: Colors.white),
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:login/widgets/AppBar.dart';
// import 'package:login/widgets/colors.dart';
// import 'package:login/widgets/login_btn.dart';
// import 'package:login/widgets/snackbar_utils.dart';
// import 'package:login/widgets/logger.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_speed_dial/flutter_speed_dial.dart'; // Add this package
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:path_provider/path_provider.dart';
// import 'package:open_file/open_file.dart';
// import 'dart:io';

// final ConsoleAppLogger logger = ConsoleAppLogger();

// class PriceScreen extends StatefulWidget {
//   final String groupId;

//   PriceScreen({required this.groupId});

//   @override
//   _PriceScreenState createState() => _PriceScreenState();
// }

// class _PriceScreenState extends State<PriceScreen> {
//   List<Map<String, dynamic>> expenses = [];
//   List<Map<String, dynamic>> filteredExpenses = [];
//   double totalAmount = 0.0;
//   double filteredAmount = 0.0;
//   bool isLoading = true;

//   List<String> members = [];
//   String currentUserName = '';
//   String selectedFilter = 'All';
//   String groupName = 'Group';

//   TextEditingController userController = TextEditingController();
//   bool isShowingMembers = false;

//   @override
//   void initState() {
//     super.initState();
//     _fetchCurrentUser();
//     _fetchExpenses();
//     _fetchGroupDetails();
//   }

//   Future<void> _fetchCurrentUser() async {
//     try {
//       User? user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         DocumentSnapshot userDoc = await FirebaseFirestore.instance
//             .collection('users')
//             .doc(user.uid)
//             .get();

//         if (userDoc.exists) {
//           var userData = userDoc.data() as Map<String, dynamic>;
//           setState(() {
//             currentUserName =
//                 userData['username'] ?? user.displayName ?? user.email ?? 'You';
//           });
//           logger.d("Current user: $currentUserName");
//         }
//       }
//     } catch (e) {
//       logger.e("Error fetching current user: $e");
//     }
//   }

//   Future<void> _fetchGroupDetails() async {
//     try {
//       DocumentSnapshot groupDoc = await FirebaseFirestore.instance
//           .collection('groups')
//           .doc(widget.groupId)
//           .get();

//       if (groupDoc.exists) {
//         var data = groupDoc.data() as Map<String, dynamic>;
//         setState(() {
//           groupName = data['name'] ?? 'Group';
//           if (data.containsKey('members') && data['members'] is List) {
//             members = List<String>.from(data['members']);
//           }
//         });
//         logger.d("Fetched group: $groupName with members: $members");
//       }
//     } catch (e) {
//       logger.e("Error fetching group details: $e");
//     }
//   }

//   Future<void> _fetchExpenses() async {
//     setState(() => isLoading = true);
//     try {
//       QuerySnapshot snapshot = await FirebaseFirestore.instance
//           .collection('groups')
//           .doc(widget.groupId)
//           .collection('expenses')
//           .orderBy('createdAt', descending: true)
//           .get();

//       List<Map<String, dynamic>> fetchedExpenses = [];
//       double sum = 0.0;

//       for (var doc in snapshot.docs) {
//         Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
//         data['id'] = doc.id;
//         fetchedExpenses.add(data);
//         sum += (data['price'] as num).toDouble();
//       }

//       setState(() {
//         expenses = fetchedExpenses;
//         totalAmount = sum;
//         _applyFilter(selectedFilter);
//         isLoading = false;
//       });
//     } catch (e) {
//       logger.e("Error fetching expenses: $e");
//       setState(() => isLoading = false);
//       SnackbarUtils.showErrorSnackbar(context, "Failed to load expenses");
//     }
//   }

//   void _applyFilter(String filter) {
//     setState(() {
//       selectedFilter = filter;

//       if (filter == 'All') {
//         filteredExpenses = List.from(expenses);
//         filteredAmount = totalAmount;
//       } else {
//         // Filter by specific username (including current user)
//         filteredExpenses =
//             expenses.where((expense) => expense['user'] == filter).toList();

//         // Recalculate filtered total
//         filteredAmount = filteredExpenses.fold(
//             0.0, (sum, expense) => sum + (expense['price'] as num).toDouble());
//       }
//     });
//   }

//   void _deleteExpense(String expenseId) async {
//     try {
//       await FirebaseFirestore.instance
//           .collection('groups')
//           .doc(widget.groupId)
//           .collection('expenses')
//           .doc(expenseId)
//           .delete();

//       SnackbarUtils.showSuccessSnackbar(context, "Expense deleted");
//       _fetchExpenses();
//     } catch (e) {
//       logger.e("Error deleting expense: $e");
//       SnackbarUtils.showErrorSnackbar(context, "Failed to delete expense");
//     }
//   }

//   void _showEditDialog(Map<String, dynamic> expense) {
//     final TextEditingController titleController =
//         TextEditingController(text: expense['title']);
//     final TextEditingController priceController =
//         TextEditingController(text: expense['price'].toString());
//     final TextEditingController userController =
//         TextEditingController(text: expense['user']);

//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           backgroundColor: AppColors.black,
//           title: Text("Edit Expense", style: TextStyle(color: Colors.white)),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: titleController,
//                 style: TextStyle(color: Colors.white),
//                 decoration: InputDecoration(
//                   labelText: "Title",
//                   labelStyle: TextStyle(color: AppColors.gray),
//                 ),
//               ),
//               SizedBox(height: 10),
//               TextField(
//                 controller: userController,
//                 style: TextStyle(color: Colors.white),
//                 decoration: InputDecoration(
//                   labelText: "User",
//                   labelStyle: TextStyle(color: AppColors.gray),
//                 ),
//               ),
//               SizedBox(height: 10),
//               TextField(
//                 controller: priceController,
//                 keyboardType: TextInputType.numberWithOptions(decimal: true),
//                 style: TextStyle(color: Colors.white),
//                 decoration: InputDecoration(
//                   labelText: "Price",
//                   labelStyle: TextStyle(color: AppColors.gray),
//                 ),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: Text("Cancel", style: TextStyle(color: Colors.white70)),
//             ),
//             TextButton(
//               onPressed: () async {
//                 String title = titleController.text.trim();
//                 String user = userController.text.trim();
//                 double? price = double.tryParse(priceController.text.trim());

//                 if (title.isEmpty ||
//                     user.isEmpty ||
//                     price == null ||
//                     price <= 0) {
//                   SnackbarUtils.showErrorSnackbar(
//                       context, "Please fill valid values");
//                   return;
//                 }

//                 try {
//                   await FirebaseFirestore.instance
//                       .collection('groups')
//                       .doc(widget.groupId)
//                       .collection('expenses')
//                       .doc(expense['id'])
//                       .update({
//                     'title': title,
//                     'user': user,
//                     'price': price,
//                     'edited': true,
//                   });

//                   Navigator.pop(context);
//                   _fetchExpenses();
//                   SnackbarUtils.showSuccessSnackbar(context, "Expense updated");
//                 } catch (e) {
//                   logger.e("Error updating expense: $e");
//                   SnackbarUtils.showErrorSnackbar(
//                       context, "Failed to update expense");
//                 }
//               },
//               child: Text("Save", style: TextStyle(color: AppColors.main)),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _showAddExpenseSheet() {
//     final TextEditingController titleController = TextEditingController();
//     final TextEditingController priceController = TextEditingController();
//     userController = TextEditingController();

//     // Pre-fill with current user name if available
//     if (currentUserName.isNotEmpty) {
//       userController.text = currentUserName;
//     }

//     List<String> filteredMembers = List.from(members);

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: AppColors.black,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//         side: BorderSide(color: AppColors.gray, width: 1),
//       ),
//       builder: (context) {
//         return StatefulBuilder(builder: (context, setModalState) {
//           return Padding(
//             padding: EdgeInsets.only(
//               bottom: MediaQuery.of(context).viewInsets.bottom,
//               left: 16,
//               right: 16,
//               top: 16,
//             ),
//             child: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Center(
//                     child: Container(
//                       width: 40,
//                       height: 5,
//                       decoration: BoxDecoration(
//                         color: AppColors.gray,
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 20),
//                   Text("Add Expense",
//                       style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white)),
//                   SizedBox(height: 20),
//                   TextField(
//                     controller: titleController,
//                     style: TextStyle(color: Colors.white),
//                     decoration: InputDecoration(
//                       labelText: "Title",
//                       labelStyle: TextStyle(color: AppColors.gray),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                         borderSide: BorderSide(color: AppColors.gray),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                         borderSide: BorderSide(color: AppColors.main),
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 16),
//                   TextField(
//                     controller: userController,
//                     style: TextStyle(color: Colors.white),
//                     decoration: InputDecoration(
//                       labelText: "User",
//                       labelStyle: TextStyle(color: AppColors.gray),
//                       hintText: "Type to search members",
//                       hintStyle: TextStyle(color: AppColors.gray),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                         borderSide: BorderSide(color: AppColors.gray),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                         borderSide: BorderSide(color: AppColors.main),
//                       ),
//                       suffixIcon: GestureDetector(
//                         onTap: () {
//                           setModalState(() {
//                             isShowingMembers = !isShowingMembers;
//                           });
//                         },
//                         child: Icon(
//                           isShowingMembers
//                               ? Icons.arrow_drop_up
//                               : Icons.arrow_drop_down,
//                           color: AppColors.gray,
//                         ),
//                       ),
//                     ),
//                     onChanged: (value) {
//                       setModalState(() {
//                         isShowingMembers = true;
//                         filteredMembers = members
//                             .where((member) => member
//                                 .toLowerCase()
//                                 .contains(value.toLowerCase()))
//                             .toList();
//                       });
//                     },
//                     onTap: () {
//                       setModalState(() {
//                         isShowingMembers = true;
//                       });
//                     },
//                   ),
//                   if (isShowingMembers)
//                     Container(
//                       margin: EdgeInsets.only(top: 5),
//                       padding: EdgeInsets.all(10),
//                       decoration: BoxDecoration(
//                         color: AppColors.mainShadow,
//                         borderRadius: BorderRadius.circular(10),
//                         border: Border.all(color: AppColors.gray),
//                       ),
//                       constraints: BoxConstraints(maxHeight: 150),
//                       child: filteredMembers.isEmpty
//                           ? Center(
//                               child: Text("No matching members found",
//                                   style: TextStyle(color: Colors.white70)),
//                             )
//                           : ListView.builder(
//                               shrinkWrap: true,
//                               itemCount: filteredMembers.length,
//                               itemBuilder: (context, index) {
//                                 return ListTile(
//                                   dense: true,
//                                   title: Text(filteredMembers[index],
//                                       style: TextStyle(color: Colors.white)),
//                                   onTap: () {
//                                     setModalState(() {
//                                       userController.text =
//                                           filteredMembers[index];
//                                       isShowingMembers = false;
//                                     });
//                                   },
//                                 );
//                               },
//                             ),
//                     ),
//                   SizedBox(height: 16),
//                   TextField(
//                     controller: priceController,
//                     style: TextStyle(color: Colors.white),
//                     keyboardType:
//                         TextInputType.numberWithOptions(decimal: true),
//                     decoration: InputDecoration(
//                       labelText: "Price",
//                       labelStyle: TextStyle(color: AppColors.gray),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                         borderSide: BorderSide(color: AppColors.gray),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                         borderSide: BorderSide(color: AppColors.main),
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 20),
//                   CustomMainButton(
//                     width: double.infinity,
//                     text: "Save",
//                     onPressed: () async {
//                       String title = titleController.text.trim();
//                       String priceText = priceController.text.trim();
//                       String user = userController.text.trim();

//                       if (title.isEmpty) {
//                         SnackbarUtils.showErrorSnackbar(
//                             context, "Title cannot be empty");
//                         return;
//                       }

//                       if (user.isEmpty) {
//                         SnackbarUtils.showErrorSnackbar(
//                             context, "Please select a user");
//                         return;
//                       }

//                       double? price = double.tryParse(priceText);
//                       if (price == null || price <= 0) {
//                         SnackbarUtils.showErrorSnackbar(
//                             context, "Please enter a valid price");
//                         return;
//                       }

//                       try {
//                         await FirebaseFirestore.instance
//                             .collection('groups')
//                             .doc(widget.groupId)
//                             .collection('expenses')
//                             .add({
//                           'title': title,
//                           'price': price,
//                           'user': user,
//                           'createdAt': Timestamp.now(),
//                         });

//                         Navigator.pop(context);
//                         _fetchExpenses();
//                         SnackbarUtils.showSuccessSnackbar(
//                             context, "Expense added successfully");
//                       } catch (e) {
//                         logger.e("Error adding expense: $e");
//                         SnackbarUtils.showErrorSnackbar(
//                             context, "Failed to add expense");
//                       }
//                     },
//                   ),
//                   SizedBox(height: 20),
//                 ],
//               ),
//             ),
//           );
//         });
//       },
//     );
//   }

//   String _formatTimestamp(dynamic timestamp) {
//     if (timestamp is Timestamp) {
//       final date = timestamp.toDate();
//       return "${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
//     }
//     return "Unknown date";
//   }

//   // New methods for added functionality

//   void _showPrintScreen() {
//     String selectedMember = 'All';

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: AppColors.black,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//         side: BorderSide(color: AppColors.gray, width: 1),
//       ),
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setState) {
//             return Padding(
//               padding: EdgeInsets.all(16),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Center(
//                     child: Container(
//                       width: 40,
//                       height: 5,
//                       decoration: BoxDecoration(
//                         color: AppColors.gray,
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 20),
//                   Text(
//                     "Print Expenses",
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                   SizedBox(height: 20),

//                   Text(
//                     "Select Member",
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: Colors.white70,
//                     ),
//                   ),
//                   SizedBox(height: 10),

//                   Container(
//                     padding: EdgeInsets.symmetric(horizontal: 16),
//                     decoration: BoxDecoration(
//                       color: AppColors.mainShadow,
//                       borderRadius: BorderRadius.circular(10),
//                       border: Border.all(color: AppColors.gray),
//                     ),
//                     child: DropdownButton<String>(
//                       value: selectedMember,
//                       isExpanded: true,
//                       dropdownColor: AppColors.black,
//                       underline: SizedBox(),
//                       style: TextStyle(color: Colors.white),
//                       onChanged: (String? newValue) {
//                         if (newValue != null) {
//                           setState(() {
//                             selectedMember = newValue;
//                           });
//                         }
//                       },
//                       items: [
//                         DropdownMenuItem(
//                           value: 'All',
//                           child: Text('All Members'),
//                         ),
//                         ...members.map((member) {
//                           return DropdownMenuItem(
//                             value: member,
//                             child: Text(member),
//                           );
//                         }).toList(),
//                       ],
//                     ),
//                   ),

//                   SizedBox(height: 30),

//                   CustomMainButton(
//                     width: double.infinity,
//                     text: "Generate PDF",
//                     onPressed: () {
//                       Navigator.pop(context);
//                       _generatePdf(selectedMember);
//                     },
//                   ),

//                   SizedBox(height: 20),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   Future<void> _generatePdf(String member) async {
//     try {
//       // Show loading indicator
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => Center(
//           child: CircularProgressIndicator(color: AppColors.main),
//         ),
//       );

//       final pdf = pw.Document();
//       final expensesToPrint = member == 'All'
//         ? expenses
//         : expenses.where((expense) => expense['user'] == member).toList();

//       final totalAmount = expensesToPrint.fold<double>(
//         0, (sum, expense) => sum + (expense['price'] as num).toDouble());

//       // Add content to PDF
//       pdf.addPage(
//         pw.Page(
//           build: (pw.Context context) {
//             return pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.start,
//               children: [
//                 pw.Header(
//                   level: 0,
//                   child: pw.Row(
//                     mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                     children: [
//                       pw.Text('Expense Report',
//                         style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
//                       pw.Text('Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
//                         style: pw.TextStyle(fontSize: 12)),
//                     ],
//                   ),
//                 ),

//                 pw.SizedBox(height: 20),

//                 pw.Container(
//                   padding: pw.EdgeInsets.all(10),
//                   decoration: pw.BoxDecoration(
//                     border: pw.Border.all(),
//                     borderRadius: pw.BorderRadius.circular(10),
//                   ),
//                   child: pw.Column(
//                     crossAxisAlignment: pw.CrossAxisAlignment.start,
//                     children: [
//                       pw.Text('Group: $groupName', style: pw.TextStyle(fontSize: 14)),
//                       pw.SizedBox(height: 5),
//                       pw.Text('Member: ${member == 'All' ? 'All Members' : member}',
//                         style: pw.TextStyle(fontSize: 14)),
//                       pw.SizedBox(height: 5),
//                       pw.Text('Total Amount: Rs.${totalAmount.toStringAsFixed(2)}',
//                         style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//                     ],
//                   ),
//                 ),

//                 pw.SizedBox(height: 20),

//                 pw.Table(
//                   border: pw.TableBorder.all(),
//                   columnWidths: {
//                     0: pw.FlexColumnWidth(1),
//                     1: pw.FlexColumnWidth(2),
//                     2: pw.FlexColumnWidth(1),
//                     3: pw.FlexColumnWidth(1),
//                   },
//                   children: [
//                     pw.TableRow(
//                       decoration: pw.BoxDecoration(color: PdfColors.grey300),
//                       children: [
//                         pw.Padding(
//                           padding: pw.EdgeInsets.all(5),
//                           child: pw.Text('No.',
//                             style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
//                         ),
//                         pw.Padding(
//                           padding: pw.EdgeInsets.all(5),
//                           child: pw.Text('Description',
//                             style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
//                         ),
//                         pw.Padding(
//                           padding: pw.EdgeInsets.all(5),
//                           child: pw.Text('User',
//                             style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
//                         ),
//                         pw.Padding(
//                           padding: pw.EdgeInsets.all(5),
//                           child: pw.Text('Amount (Rs.)',
//                             style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
//                         ),
//                       ]
//                     ),

//                     ...expensesToPrint.asMap().entries.map((entry) {
//                       final index = entry.key;
//                       final expense = entry.value;
//                       DateTime date = (expense['createdAt'] as Timestamp).toDate();
//                       String formattedDate = "${date.day}/${date.month}/${date.year}";

//                       return pw.TableRow(
//                         children: [
//                           pw.Padding(
//                             padding: pw.EdgeInsets.all(5),
//                             child: pw.Text('${index + 1}'),
//                           ),
//                           pw.Padding(
//                             padding: pw.EdgeInsets.all(5),
//                             child: pw.Column(
//                               crossAxisAlignment: pw.CrossAxisAlignment.start,
//                               children: [
//                                 pw.Text(expense['title']),
//                                 pw.SizedBox(height: 2),
//                                 pw.Text(formattedDate,
//                                   style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
//                               ],
//                             ),
//                           ),
//                           pw.Padding(
//                             padding: pw.EdgeInsets.all(5),
//                             child: pw.Text(expense['user']),
//                           ),
//                           pw.Padding(
//                             padding: pw.EdgeInsets.all(5),
//                             child: pw.Text('${(expense['price'] as num).toStringAsFixed(2)}'),
//                           ),
//                         ]
//                       );
//                     }).toList(),

//                     pw.TableRow(
//                       decoration: pw.BoxDecoration(color: PdfColors.grey300),
//                       children: [
//                         pw.Padding(
//                           padding: pw.EdgeInsets.all(5),
//                           child: pw.Text(''),
//                         ),
//                         pw.Padding(
//                           padding: pw.EdgeInsets.all(5),
//                           child: pw.Text(''),
//                         ),
//                         pw.Padding(
//                           padding: pw.EdgeInsets.all(5),
//                           child: pw.Text('Total:',
//                             style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
//                         ),
//                         pw.Padding(
//                           padding: pw.EdgeInsets.all(5),
//                           child: pw.Text('Rs.${totalAmount.toStringAsFixed(2)}',
//                             style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
//                         ),
//                       ]
//                     ),
//                   ],
//                 ),

//                 pw.SizedBox(height: 40),

//                 pw.Footer(
//                   title: pw.Text(
//                     'Generated on ${DateTime.now().toString()}',
//                     style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
//                   ),
//                 ),
//               ],
//             );
//           },
//         ),
//       );

//       // Save the PDF
//       final output = await getTemporaryDirectory();
//       final fileName = 'Expenses_${member == 'All' ? 'All' : member}_${DateTime.now().millisecondsSinceEpoch}.pdf';
//       final file = File('${output.path}/$fileName');
//       await file.writeAsBytes(await pdf.save());

//       // Close loading indicator
//       Navigator.pop(context);

//       // Open the created PDF
//       await OpenFile.open(file.path);

//       SnackbarUtils.showSuccessSnackbar(
//         context,
//         "PDF generated successfully"
//       );

//     } catch (e) {
//       // Close loading indicator if open
//       if (Navigator.canPop(context)) {
//         Navigator.pop(context);
//       }

//       logger.e("Error generating PDF: $e");
//       SnackbarUtils.showErrorSnackbar(
//         context,
//         "Failed to generate PDF"
//       );
//     }
//   }

//   void _showCalculatorScreen() {
//     final TextEditingController calculationController = TextEditingController();
//     String result = '';
//     List<String> history = [];

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: AppColors.black,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//         side: BorderSide(color: AppColors.gray, width: 1),
//       ),
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setState) {

//             void calculateResult() {
//               try {
//                 // Simple expression evaluator (you may want to use a proper math parser package)
//                 String sanitizedExpression = calculationController.text
//                     .replaceAll('×', '*')
//                     .replaceAll('÷', '/');

//                 // This is a simple evaluation - use a proper math parser for production
//                 dynamic eval = _evaluateExpression(sanitizedExpression);

//                 setState(() {
//                   result = eval.toString();
//                   history.add('${calculationController.text} = $result');
//                 });
//               } catch (e) {
//                 setState(() {
//                   result = 'Error';
//                 });
//               }
//             }

//             return Container(
//               height: MediaQuery.of(context).size.height * 0.8,
//               padding: EdgeInsets.all(16),
//               child: Column(
//                 children: [
//                   Center(
//                     child: Container(
//                       width: 40,
//                       height: 5,
//                       decoration: BoxDecoration(
//                         color: AppColors.gray,
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 20),
//                   Text(
//                     "Calculator",
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                   SizedBox(height: 20),

//                   // Display calculations and result
//                   Container(
//                     padding: EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: AppColors.mainShadow,
//                       borderRadius: BorderRadius.circular(10),
//                       border: Border.all(color: AppColors.gray),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       children: [
//                         TextField(
//                           controller: calculationController,
//                           keyboardType: TextInputType.none, // Disable keyboard
//                           style: TextStyle(color: Colors.white, fontSize: 24),
//                           textAlign: TextAlign.right,
//                           decoration: InputDecoration(
//                             border: InputBorder.none,
//                             hintText: '0',
//                             hintStyle: TextStyle(color: Colors.white54),
//                           ),
//                         ),
//                         SizedBox(height: 8),
//                         Text(
//                           result,
//                           style: TextStyle(
//                             color: AppColors.main,
//                             fontSize: 32,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   SizedBox(height: 20),

//                   // Calculator buttons
//                   Expanded(
//                     child: GridView
//                     // Calculator buttons
//                   Expanded(
//                     child: GridView.count(
//                       crossAxisCount: 4,
//                       childAspectRatio: 1.3,
//                       crossAxisSpacing: 10,
//                       mainAxisSpacing: 10,
//                       children: [
//                         _buildCalcButton('C', Colors.redAccent, () {
//                           setState(() {
//                             calculationController.text = '';
//                             result = '';
//                           });
//                         }),
//                         _buildCalcButton('⌫', Colors.orange, () {
//                           if (calculationController.text.isNotEmpty) {
//                             setState(() {
//                               calculationController.text = calculationController.text
//                                   .substring(0, calculationController.text.length - 1);
//                             });
//                           }
//                         }),
//                         _buildCalcButton('%', Colors.blueAccent, () {
//                           setState(() {
//                             calculationController.text += '%';
//                           });
//                         }),
//                         _buildCalcButton('÷', Colors.blueAccent, () {
//                           setState(() {
//                             calculationController.text += '÷';
//                           });
//                         }),
//                         _buildCalcButton('7', Colors.white70, () {
//                           setState(() {
//                             calculationController.text += '7';
//                           });
//                         }),
//                         _buildCalcButton('8', Colors.white70, () {
//                           setState(() {
//                             calculationController.text += '8';
//                           });
//                         }),
//                         _buildCalcButton('9', Colors.white70, () {
//                           setState(() {
//                             calculationController.text += '9';
//                           });
//                         }),
//                         _buildCalcButton('×', Colors.blueAccent, () {
//                           setState(() {
//                             calculationController.text += '×';
//                           });
//                         }),
//                         _buildCalcButton('4', Colors.white70, () {
//                           setState(() {
//                             calculationController.text += '4';
//                           });
//                         }),
//                         _buildCalcButton('5', Colors.white70, () {
//                           setState(() {
//                             calculationController.text += '5';
//                           });
//                         }),
//                         _buildCalcButton('6', Colors.white70, () {
//                           setState(() {
//                             calculationController.text += '6';
//                           });
//                         }),
//                         _buildCalcButton('-', Colors.blueAccent, () {
//                           setState(() {
//                             calculationController.text += '-';
//                           });
//                         }),
//                         _buildCalcButton('1', Colors.white70, () {
//                           setState(() {
//                             calculationController.text += '1';
//                           });
//                         }),
//                         _buildCalcButton('2', Colors.white70, () {
//                           setState(() {
//                             calculationController.text += '2';
//                           });
//                         }),
//                         _buildCalcButton('3', Colors.white70, () {
//                           setState(() {
//                             calculationController.text += '3';
//                           });
//                         }),
//                         _buildCalcButton('+', Colors.blueAccent, () {
//                           setState(() {
//                             calculationController.text += '+';
//                           });
//                         }),
//                         _buildCalcButton('00', Colors.white70, () {
//                           setState(() {
//                             calculationController.text += '00';
//                           });
//                         }),
//                         _buildCalcButton('0', Colors.white70, () {
//                           setState(() {
//                             calculationController.text += '0';
//                           });
//                         }),
//                         _buildCalcButton('.', Colors.white70, () {
//                           setState(() {
//                             calculationController.text += '.';
//                           });
//                         }),
//                         _buildCalcButton('=', AppColors.main, calculateResult),
//                       ],
//                     ),
//                   ),

//                   Divider(color: AppColors.gray),

//                   // History section
//                   Container(
//                     height: 150,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           "History",
//                           style: TextStyle(
//                             color: Colors.white70,
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         SizedBox(height: 8),
//                         Expanded(
//                           child: history.isEmpty
//                             ? Center(
//                                 child: Text(
//                                   "No calculations yet",
//                                   style: TextStyle(color: Colors.white38),
//                                 ),
//                               )
//                             : ListView.builder(
//                                 itemCount: history.length,
//                                 reverse: true,
//                                 itemBuilder: (context, index) {
//                                   return ListTile(
//                                     dense: true,
//                                     title: Text(
//                                       history[history.length - 1 - index],
//                                       style: TextStyle(color: Colors.white),
//                                     ),
//                                     trailing: IconButton(
//                                       icon: Icon(Icons.copy, size: 18, color: AppColors.main),
//                                       onPressed: () {
//                                         final parts = history[history.length - 1 - index].split(' = ');
//                                         calculationController.text = parts[0];
//                                         setState(() {
//                                           result = parts[1];
//                                         });
//                                       },
//                                     ),
//                                   );
//                                 },
//                               ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   Widget _buildCalcButton(String text, Color textColor, VoidCallback onPressed) {
//     return ElevatedButton(
//       onPressed: onPressed,
//       style: ElevatedButton.styleFrom(
//         foregroundColor: textColor,
//         backgroundColor: AppColors.mainShadow,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//           side: BorderSide(color: AppColors.gray.withOpacity(0.5)),
//         ),
//       ),
//       child: Text(
//         text,
//         style: TextStyle(fontSize: 20),
//       ),
//     );
//   }

//   // Simple expression evaluator
//   dynamic _evaluateExpression(String expression) {
//     // Note: This is a simplified implementation - use a proper math parser for production
//     expression = expression.replaceAll('%', '/100*');

//     try {
//       // Split by operators while preserving the operators
//       List<String> tokens = [];
//       String currentNumber = '';

//       for (int i = 0; i < expression.length; i++) {
//         String char = expression[i];
//         if ('+-*/'.contains(char)) {
//           if (currentNumber.isNotEmpty) {
//             tokens.add(currentNumber);
//             currentNumber = '';
//           }
//           tokens.add(char);
//         } else {
//           currentNumber += char;
//         }
//       }

//       if (currentNumber.isNotEmpty) {
//         tokens.add(currentNumber);
//       }

//       // Process * and /
//       for (int i = 1; i < tokens.length - 1; i += 2) {
//         if (tokens[i] == '*' || tokens[i] == '/') {
//           double left = double.parse(tokens[i-1]);
//           double right = double.parse(tokens[i+1]);
//           double result;

//           if (tokens[i] == '*') {
//             result = left * right;
//           } else {
//             result = left / right;
//           }

//           tokens[i-1] = result.toString();
//           tokens.removeAt(i);
//           tokens.removeAt(i);
//           i -= 2;  // Adjust index after removal
//         }
//       }

//       // Process + and -
//       double result = double.parse(tokens[0]);
//       for (int i = 1; i < tokens.length; i += 2) {
//         double operand = double.parse(tokens[i+1]);
//         if (tokens[i] == '+') {
//           result += operand;
//         } else if (tokens[i] == '-') {
//           result -= operand;
//         }
//       }

//       return result;
//     } catch (e) {
//       return 'Error';
//     }
//   }

//   void _showSplitScreen() {
//     double totalBill = totalAmount;
//     int numberOfPeople = members.isEmpty ? 1 : members.length;
//     String splitMethod = 'Equal';
//     Map<String, double> customSplits = {};
//     Map<String, bool> includedMembers = {};

//     // Initialize all members as included
//     for (var member in members) {
//       includedMembers[member] = true;
//       customSplits[member] = 0.0;
//     }

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: AppColors.black,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//         side: BorderSide(color: AppColors.gray, width: 1),
//       ),
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setState) {

//             // Calculate per person amount based on split method
//             double calculatePerPersonAmount() {
//               int activePeople = includedMembers.values.where((v) => v).length;
//               if (activePeople == 0) return 0.0;

//               switch (splitMethod) {
//                 case 'Equal':
//                   return totalBill / activePeople;
//                 case 'Percentage':
//                   // Implemented in the UI directly
//                   return 0.0;
//                 case 'Custom':
//                   // Implemented in the UI directly
//                   return 0.0;
//                 default:
//                   return totalBill / activePeople;
//               }
//             }

//             return Container(
//               height: MediaQuery.of(context).size.height * 0.85,
//               padding: EdgeInsets.all(16),
//               child: Column(
//                 children: [
//                   Center(
//                     child: Container(
//                       width: 40,
//                       height: 5,
//                       decoration: BoxDecoration(
//                         color: AppColors.gray,
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 20),
//                   Text(
//                     "Split Bill",
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                   SizedBox(height: 20),

//                   // Total amount display
//                   Container(
//                     padding: EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: AppColors.mainShadow,
//                       borderRadius: BorderRadius.circular(10),
//                       border: Border.all(color: AppColors.gray),
//                     ),
//                     child: Column(
//                       children: [
//                         Text(
//                           "Total Bill Amount",
//                           style: TextStyle(
//                             color: Colors.white70,
//                             fontSize: 16,
//                           ),
//                         ),
//                         SizedBox(height: 8),
//                         Text(
//                           "Rs.${totalBill.toStringAsFixed(2)}",
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 28,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   SizedBox(height: 20),

//                   // Split method selector
//                   Container(
//                     padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                     decoration: BoxDecoration(
//                       color: AppColors.mainShadow,
//                       borderRadius: BorderRadius.circular(10),
//                       border: Border.all(color: AppColors.gray),
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           "Split Method",
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 16,
//                           ),
//                         ),
//                         DropdownButton<String>(
//                           value: splitMethod,
//                           dropdownColor: AppColors.black,
//                           underline: SizedBox(),
//                           style: TextStyle(color: AppColors.main, fontSize: 16),
//                           items: ['Equal', 'Percentage', 'Custom'].map((String value) {
//                             return DropdownMenuItem<String>(
//                               value: value,
//                               child: Text(value),
//                             );
//                           }).toList(),
//                           onChanged: (newValue) {
//                             setState(() {
//                               splitMethod = newValue!;
//                             });
//                           },
//                         ),
//                       ],
//                     ),
//                   ),

//                   SizedBox(height: 20),

//                   // Member selection
//                   Text(
//                     "Who's included?",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),

//                   SizedBox(height: 10),

//                   Expanded(
//                     child: members.isEmpty
//                       ? Center(
//                           child: Text(
//                             "No members in this group",
//                             style: TextStyle(color: Colors.white70),
//                           ),
//                         )
//                       : ListView.builder(
//                           itemCount: members.length,
//                           itemBuilder: (context, index) {
//                             final member = members[index];
//                             return Container(
//                               margin: EdgeInsets.only(bottom: 8),
//                               decoration: BoxDecoration(
//                                 color: AppColors.mainShadow,
//                                 borderRadius: BorderRadius.circular(10),
//                                 border: Border.all(color: AppColors.gray),
//                               ),
//                               child: ListTile(
//                                 title: Text(
//                                   member,
//                                   style: TextStyle(color: Colors.white),
//                                 ),
//                                 trailing: splitMethod == 'Custom'
//                                   ? Container(
//                                       width: 100,
//                                       child: TextField(
//                                         keyboardType: TextInputType.numberWithOptions(decimal: true),
//                                         style: TextStyle(color: Colors.white),
//                                         decoration: InputDecoration(
//                                           prefixText: 'Rs.',
//                                           prefixStyle: TextStyle(color: Colors.white70),
//                                           hintText: '0.00',
//                                           hintStyle: TextStyle(color: Colors.white38),
//                                           contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 8),
//                                           border: OutlineInputBorder(
//                                             borderRadius: BorderRadius.circular(5),
//                                             borderSide: BorderSide(color: AppColors.gray),
//                                           ),
//                                         ),
//                                         onChanged: (value) {
//                                           double? amount = double.tryParse(value);
//                                           setState(() {
//                                             customSplits[member] = amount ?? 0.0;
//                                           });
//                                         },
//                                       ),
//                                     )
//                                   : splitMethod == 'Percentage'
//                                     ? Container(
//                                         width: 100,
//                                         child: TextField(
//                                           keyboardType: TextInputType.numberWithOptions(decimal: true),
//                                           style: TextStyle(color: Colors.white),
//                                           decoration: InputDecoration(
//                                             suffixText: '%',
//                                             suffixStyle: TextStyle(color: Colors.white70),
//                                             hintText: '0.0',
//                                             hintStyle: TextStyle(color: Colors.white38),
//                                             contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 8),
//                                             border: OutlineInputBorder(
//                                               borderRadius: BorderRadius.circular(5),
//                                               borderSide: BorderSide(color: AppColors.gray),
//                                             ),
//                                           ),
//                                           onChanged: (value) {
//                                             double? percentage = double.tryParse(value);
//                                             if (percentage != null) {
//                                               setState(() {
//                                                 customSplits[member] = totalBill * (percentage / 100);
//                                               });
//                                             }
//                                           },
//                                         ),
//                                       )
//                                     : Checkbox(
//                                         activeColor: AppColors.main,
//                                         checkColor: Colors.white,
//                                         value: includedMembers[member] ?? true,
//                                         onChanged: (newValue) {
//                                           setState(() {
//                                             includedMembers[member] = newValue ?? true;
//                                           });
//                                         },
//                                       ),
//                               ),
//                             );
//                           },
//                         ),
//                   ),

//                   SizedBox(height: 20),

//                   // Results section
//                   Container(
//                     padding: EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: AppColors.mainShadow,
//                       borderRadius: BorderRadius.circular(10),
//                       border: Border.all(color: AppColors.main.withOpacity(0.5)),
//                     ),
//                     child: Column(
//                       children: [
//                         Text(
//                           "Split Result",
//                           style: TextStyle(
//                             color: Colors.white70,
//                             fontSize: 16,
//                           ),
//                         ),
//                         SizedBox(height: 10),

//                         if (splitMethod == 'Equal')
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Text(
//                                 "Each person pays: ",
//                                 style: TextStyle(color: Colors.white),
//                               ),
//                               Text(
//                                 "Rs.${calculatePerPersonAmount().toStringAsFixed(2)}",
//                                 style: TextStyle(
//                                   color: AppColors.main,
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 18,
//                                 ),
//                               ),
//                             ],
//                           ),

//                         if (splitMethod == 'Percentage' || splitMethod == 'Custom')
//                           Column(
//                             children: members
//                                 .where((member) => includedMembers[member] ?? false)
//                                 .map((member) {
//                               double amount = customSplits[member] ?? 0.0;
//                               return Padding(
//                                 padding: const EdgeInsets.symmetric(vertical: 4),
//                                 child: Row(
//                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     Text(
//                                       member,
//                                       style: TextStyle(color: Colors.white),
//                                     ),
//                                     Text(
//                                       "Rs.${amount.toStringAsFixed(2)}",
//                                       style: TextStyle(
//                                         color: AppColors.main,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               );
//                             }).toList(),
//                           ),
//                       ],
//                     ),
//                   ),

//                   SizedBox(height: 20),

//                   CustomMainButton(
//                     width: double.infinity,
//                     text: "Done",
//                     onPressed: () {
//                       Navigator.pop(context);
//                     },
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CustomAppBar(title: "Expenses"),
//       body: isLoading
//           ? Center(child: CircularProgressIndicator(color: AppColors.main))
//           : Column(
//               children: [
//                 // Filter chips row
//                 Container(
//                   height: 60,
//                   padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   child: SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: Row(
//                       children: [
//                         // All filter
//                         GestureDetector(
//                           onTap: () => _applyFilter('All'),
//                           child: Container(
//                             padding: EdgeInsets.symmetric(
//                                 horizontal: 16, vertical: 8),
//                             margin: EdgeInsets.only(right: 8),
//                             decoration: BoxDecoration(
//                               color: selectedFilter == 'All'
//                                   ? AppColors.main
//                                   : AppColors.mainShadow,
//                               borderRadius: BorderRadius.circular(20),
//                               border: Border.all(
//                                   color: selectedFilter == 'All'
//                                       ? AppColors.main
//                                       : AppColors.gray),
//                             ),
//                             child: Text(
//                               "All",
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: selectedFilter == 'All'
//                                     ? FontWeight.bold
//                                     : FontWeight.normal,
//                               ),
//                             ),
//                           ),
//                         ),

//                         // Current user filter (showing actual username instead of "You")
//                         if (currentUserName.isNotEmpty)
//                           GestureDetector(
//                             onTap: () => _applyFilter(currentUserName),
//                             child: Container(
//                               padding: EdgeInsets.symmetric(
//                                   horizontal: 16, vertical: 8),
//                               margin: EdgeInsets.only(right: 8),
//                               decoration: BoxDecoration(
//                                 color: selectedFilter == currentUserName
//                                     ? AppColors.main
//                                     : AppColors.mainShadow,
//                                 borderRadius: BorderRadius.circular(20),
//                                 border: Border.all(
//                                     color: selectedFilter == currentUserName
//                                         ? AppColors.main
//                                         : AppColors.gray),
//                               ),
//                               child: Row(
//                                 children: [
//                                   Text(
//                                     currentUserName,
//                                     style: TextStyle(
//                                       color: Colors.white,
//                                       fontWeight:
//                                           selectedFilter == currentUserName
//                                               ? FontWeight.bold
//                                               : FontWeight.normal,
//                                     ),
//                                   ),
//                                   SizedBox(width: 4),
//                                   Icon(
//                                     Icons.person,
//                                     size: 16,
//                                     color: Colors.white70,
//                                   )
//                                 ],
//                               ),
//                             ),
//                           ),

//                         // Individual member filters (excluding current user)
//                         ...members
//                             .where((member) => member != currentUserName)
//                             .map((member) {
//                           return GestureDetector(
//                             onTap: () => _applyFilter(member),
//                             child: Container(
//                               padding: EdgeInsets.symmetric(
//                                   horizontal: 16, vertical: 8),
//                               margin: EdgeInsets.only(right: 8),
//                               decoration: BoxDecoration(
//                                 color: selectedFilter == member
//                                     ? AppColors.main
//                                     : AppColors.mainShadow,
//                                 borderRadius: BorderRadius.circular(20),
//                                 border: Border.all(
//                                     color: selectedFilter == member
//                                         ? AppColors.main
//                                         : AppColors.gray),
//                               ),
//                               child: Text(
//                                 member,
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontWeight: selectedFilter == member
//                                       ? FontWeight.bold
//                                       : FontWeight.normal,
//                                 ),
//                               ),
//                             ),
//                           );
//                         }).toList(),
//                       ],
//                     ),
//                   ),
//                 ),

//                 // Total expense container
//                 Container(
//                   width: double.infinity,
//                   padding: EdgeInsets.all(16),
//                   margin: EdgeInsets.symmetric(horizontal: 16),
//                   decoration: BoxDecoration(
//                     color: AppColors.mainShadow,
//                     borderRadius: BorderRadius.circular(10),
//                     border: Border.all(color: AppColors.gray),
//                   ),
//                   child: Column(
//                     children: [
//                       Text(
//                           selectedFilter == 'All'
//                               ? "Total Expenses"
//                               : selectedFilter == currentUserName
//                                   ? "Your Expenses"
//                                   : "$selectedFilter's Expenses",
//                           style:
//                               TextStyle(fontSize: 16, color: Colors.white70)),
//                       SizedBox(height: 8),
//                       Text(
//                           "Rs.${selectedFilter == 'All' ? totalAmount.toStringAsFixed(2) : filteredAmount.toStringAsFixed(2)}",
//                           style: TextStyle(
//                               fontSize: 28,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white)),
//                     ],
//                   ),
//                 ),

//                 // Expenses list
//                 Expanded(
//                   child: filteredExpenses.isEmpty
//                       ? Center(
//                           child: Text(
//                               selectedFilter == 'All'
//                                   ? "No expenses added yet"
//                                   : "No expenses for $selectedFilter",
//                               style: TextStyle(
//                                   color: Colors.white70, fontSize: 16)),
//                         )
//                       : ListView.builder(
//                           itemCount: filteredExpenses.length,
//                           padding: EdgeInsets.all(16),
//                           itemBuilder: (context, index) {
//                             final expense = filteredExpenses[index];
//                             return Card(
//                               color: AppColors.mainShadow,
//                               margin: EdgeInsets.only(bottom: 10),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                                 side:
//                                     BorderSide(color: AppColors.gray, width: 1),
//                               ),
//                               child: ListTile(
//                                 title: Text(
//                                   expense['title'],
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 subtitle: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       "${_formatTimestamp(expense['createdAt'])}\nUser: ${expense['user'] ?? 'N/A'}",
//                                       style: TextStyle(
//                                           color: Colors.white70, fontSize: 12),
//                                     ),
//                                     if ((expense['edited'] ?? false))
//                                       Padding(
//                                         padding: const EdgeInsets.only(top: 4),
//                                         child: Text(
//                                           "edited",
//                                           style: TextStyle(
//                                             color: Colors.orangeAccent,
//                                             fontSize: 10,
//                                             fontStyle: FontStyle.italic,
//                                           ),
//                                         ),
//                                       ),
//                                   ],
//                                 ),
//                                 trailing: Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     Text(
//                                       "Rs.${(expense['price'] as num).toStringAsFixed(2)}",
//                                       style: TextStyle(
//                                           color: Colors.amber,
//                                           fontWeight: FontWeight.bold,
//                                           fontSize: 18),
//                                     ),
//                                     SizedBox(width: 10),
//                                     PopupMenuButton<String>(
//                                       onSelected: (value) {
//                                         if (value == 'edit') {
//                                           _showEditDialog(expense);
//                                         } else if (value == 'delete') {
//                                           _deleteExpense(expense['id']);
//                                         }
//                                       },
//                                       itemBuilder: (context) =>
//                                           <PopupMenuEntry<String>>[
//                                         PopupMenuItem(
//                                             value: 'edit', child: Text("Edit")),
//                                         PopupMenuItem(
//                                             value: 'delete',
//                                             child: Text("Delete")),
//                                       ],
//                                       icon: Icon(Icons.more_vert,
//                                           color: Colors.white),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                 ),
//               ],
//             ),
//       floatingActionButton: SpeedDial(
//         icon: Icons.add,
//         activeIcon: Icons.close,
//         backgroundColor: AppColors.main,
//         foregroundColor: Colors.white,
//         activeBackgroundColor: AppColors.gray,
//         spacing: 3,
//         childPadding: EdgeInsets.all(5),
//         spaceBetweenChildren: 4,
//         elevation: 8.0,
//         animationCurve: Curves.elasticInOut,
//         children: [
//           SpeedDialChild(
//             child: Icon(Icons.print, color: Colors.white),
//             backgroundColor: Colors.blue,
//             label: 'Print',
//             labelStyle: TextStyle(fontSize: 16.0),
//             onTap: _showPrintScreen,
//           ),
//           SpeedDialChild(
//             child: Icon(Icons.calculate, color: Colors.white),
//             backgroundColor: Colors.purple,
//             label: 'Calculator',
//             labelStyle: TextStyle(fontSize: 16.0),
//             onTap: _showCalculatorScreen,
//           ),
//           SpeedDialChild(
//             child: Icon(Icons.call_split, color: Colors.white),
//             backgroundColor: Colors.orange,
//             label: 'Split',
//             labelStyle: TextStyle(fontSize: 16.0),
//             onTap: _showSplitScreen,
//           ),
//           SpeedDialChild(
//             child: Icon(Icons.post_add, color: Colors.white),
//             backgroundColor: Colors.green,
//             label: 'Add Expense',
//             labelStyle: TextStyle(fontSize: 16.0),
//             onTap: _showAddExpenseSheet,
//           ),
//         ],
//       ),
//     );
//   }
// }

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
