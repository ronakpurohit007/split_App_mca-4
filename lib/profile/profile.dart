import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:login/Services/authentication.dart';
import 'package:login/Login/Screen/login_screen.dart';
import 'package:login/widgets/AppBar.dart';
import 'package:login/widgets/colors.dart';
import 'package:login/widgets/logger.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? userName;
  String? email;
  bool isLoading = true;
  List<Map<String, dynamic>> expensesByCategory = [];
  Map<String, double> categoryTotals = {};
  final ConsoleAppLogger logger = ConsoleAppLogger();

  List<Color> categoryColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.amber,
    Colors.pink,
    Colors.indigo,
    Colors.cyan,
  ];

  int? touchedIndex;
  String? selectedCategory;
  double? selectedAmount;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  void fetchUserData() async {
    try {
      String? name = await AuthServices().getUserName();
      String? userEmail = await AuthServices().getUserEmail();

      setState(() {
        userName = name ?? "User";
        email = userEmail ?? "user@example.com";
      });

      fetchExpenseCategories(name);
    } catch (e) {
      logger.e("Error fetching user data: $e");
      setState(() => isLoading = false);
    }
  }

  void fetchExpenseCategories(String? username) async {
    if (username == null) {
      logger.e("Cannot fetch expenses: username is null");
      setState(() => isLoading = false);
      return;
    }

    setState(() => isLoading = true);

    try {
      QuerySnapshot groupsSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .where('members', arrayContains: username)
          .get();

      Map<String, double> tempCategoryTotals = {};

      for (var groupDoc in groupsSnapshot.docs) {
        String groupId = groupDoc.id;

        QuerySnapshot expensesSnapshot = await FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
            .collection('expenses')
            .get();

        for (var expenseDoc in expensesSnapshot.docs) {
          var data = expenseDoc.data() as Map<String, dynamic>;

          if (data['isSplit'] == true) continue;

          String category =
              data['category'] ?? data['title'] ?? 'Uncategorized';

          double price = 0;
          if (data.containsKey('price') && data['price'] is num) {
            price = (data['price'] as num).toDouble();
          }

          if (tempCategoryTotals.containsKey(category)) {
            tempCategoryTotals[category] =
                tempCategoryTotals[category]! + price;
          } else {
            tempCategoryTotals[category] = price;
          }
        }
      }

      List<Map<String, dynamic>> tempExpensesByCategory = [];
      tempCategoryTotals.forEach((category, total) {
        tempExpensesByCategory.add({'category': category, 'amount': total});
      });

      setState(() {
        categoryTotals = tempCategoryTotals;
        expensesByCategory = tempExpensesByCategory;
        isLoading = false;
      });
    } catch (e) {
      logger.e("Error fetching expense categories: $e");
      setState(() => isLoading = false);
    }
  }

  void logoutUser() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      logger.e("Error during logout: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CustomAppBar(title: email ?? "Profile"),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[800],
                child: Icon(Icons.person, size: 60, color: Colors.white70),
              ),
              SizedBox(height: 20),
              Card(
                color: AppColors.mainShadow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.gray, width: 1),
                ),
                elevation: 5,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  child: Column(
                    children: [
                      Text(
                        userName ?? "User",
                        style: TextStyle(
                          fontSize: 26,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        email ?? "user@example.com",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),
              Card(
                color: AppColors.mainShadow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.gray, width: 1),
                ),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Expenses",
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
                      isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                color: AppColors.main,
                              ),
                            )
                          : expensesByCategory.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Text(
                                      "No expense data available",
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: [
                                    Container(
                                      height: 300,
                                      padding: EdgeInsets.all(10),
                                      child: PieChart(
                                        PieChartData(
                                          sectionsSpace: 2,
                                          centerSpaceRadius: 40,
                                          sections: _generatePieChartSections(),
                                          pieTouchData: PieTouchData(
                                            touchCallback: (FlTouchEvent event,
                                                pieTouchResponse) {
                                              if (!event
                                                      .isInterestedForInteractions ||
                                                  pieTouchResponse == null ||
                                                  pieTouchResponse
                                                          .touchedSection ==
                                                      null) {
                                                setState(() {
                                                  touchedIndex = null;
                                                  selectedCategory = null;
                                                  selectedAmount = null;
                                                });
                                                return;
                                              }

                                              final index = pieTouchResponse
                                                  .touchedSection!
                                                  .touchedSectionIndex;
                                              final category = categoryTotals
                                                  .keys
                                                  .elementAt(index);
                                              final amount =
                                                  categoryTotals[category]!;

                                              setState(() {
                                                touchedIndex = index;
                                                selectedCategory = category;
                                                selectedAmount = amount;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (selectedCategory != null &&
                                        selectedAmount != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 20),
                                        child: Text(
                                          '$selectedCategory: Rs.${selectedAmount!.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: logoutUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(Icons.logout, color: Colors.white),
                label: Text(
                  "Logout",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _generatePieChartSections() {
    List<PieChartSectionData> sections = [];
    double total = categoryTotals.values.fold(0, (sum, amount) => sum + amount);

    int colorIndex = 0;
    categoryTotals.forEach((category, amount) {
      final isTouched = colorIndex == touchedIndex;
      final double radius = isTouched ? 100 : 90;
      final double fontSize = isTouched ? 14 : 12;

      double percentage = total > 0 ? (amount / total) * 100 : 0;

      sections.add(
        PieChartSectionData(
          color: categoryColors[colorIndex % categoryColors.length],
          value: amount,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    });

    return sections;
  }
}
