import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:login/Services/authentication.dart';
import 'package:login/group/GroupDetailScreen.dart';
import 'package:login/widgets/AppBar.dart';
import 'package:login/widgets/category_utils.dart';
import 'package:login/widgets/colors.dart';
import 'package:login/widgets/logger.dart';

import '../group/create_group.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? userName;
  String? userId;
  List<Map<String, dynamic>> userGroups = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  void fetchUserData() async {
    setState(() {
      isLoading = true;
    });

    String? name = await AuthServices().getUserName();
    String? uid = FirebaseAuth.instance.currentUser?.uid;

    setState(() {
      userName = name ?? "User";
      userId = uid;
    });

    if (name != null) {
      await fetchUserGroups(name);
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchUserGroups(String name) async {
    try {
      print("Fetching groups for user name: $name"); // Debug log

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("groups")
          .where("members", arrayContains: name)
          .get();

      print(
          "Query returned ${querySnapshot.docs.length} documents"); // Debug log

      List<Map<String, dynamic>> groups = querySnapshot.docs.map((doc) {
        return {
          "id": doc.id,
          "title": doc["title"] ?? "Untitled Group",
          "description": doc["description"] ?? "No description available",
          "category": doc["category"] ?? "Other",
          "members": List<String>.from(doc["members"] ?? []),
        };
      }).toList();

      setState(() {
        userGroups = groups;
        isLoading = false;
        ConsoleAppLogger().d("Data ${groups}");
      });
    } catch (e) {
      print("Error fetching groups: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Welcome, $userName",
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: userGroups.isEmpty
                  ? Center(
                      child: Text(
                        "You are not part of any groups yet.",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    )
                  : GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1,
                      ),
                      itemCount: userGroups.length,
                      itemBuilder: (context, index) {
                        var group = userGroups[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GroupDetailScreen(
                                  groupId: group["id"],
                                  title: group["title"],
                                  description: group["description"],
                                  members: group["members"],
                                  category: group["category"],
                                ),
                              ),
                            );
                          },
                          child: Card(
                            color: AppColors.mainShadow,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(10),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    CategoryUtils.getCategoryEmoji(
                                        group["category"]),
                                    style: TextStyle(fontSize: 30),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    group["title"],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    group["description"],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateGroupScreen()),
          ).then((_) {
            if (userName != null) fetchUserGroups(userName!);
          });
        },
        child: Icon(Icons.group_add, color: AppColors.white),
        backgroundColor: AppColors.main,
      ),
    );
  }
}
