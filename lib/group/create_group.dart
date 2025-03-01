import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:login/widgets/AppBar.dart';
import 'package:login/widgets/colors.dart';
import 'package:login/widgets/logger.dart';
import '../widgets/CustomDropdown.dart';
import '../widgets/login_btn.dart';
import '../widgets/snackbar_utils.dart';
import 'Add_member.dart';


final ConsoleAppLogger logger = ConsoleAppLogger();

class CreateGroupScreen extends StatefulWidget {
  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController title = TextEditingController();
  final TextEditingController discretion = TextEditingController();

  String selectedCategory = 'Trip';
  List<String> categoryOptions = ['Travel', 'Food & Drink', 'Movies & TV', 'Party', 'House Rent', 'Other'];

  User? currentUser;
  String userName = "Loading...";
  List<String> members = []; // Store selected members

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
  }

  void _fetchCurrentUser() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String name = user.displayName ?? user.email ?? "User"; // Default to displayName or email

        // Fetch user name from Firestore
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection("user").doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          var data = doc.data() as Map<String, dynamic>;
          name = data["name"] ?? name;
        }

        setState(() {
          currentUser = user;
          userName = name;
          members.add(name); // Add the current user as a default member
        });
      } else {
        setState(() {
          userName = "No user found";
        });
      }
    } catch (error) {
      print("Error fetching user: $error");
      setState(() {
        userName = "Error fetching user";
      });
    }
  }

  void _navigateToAddMemberScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMemberScreen(existingMembers: members),
      ),
    );

    if (result != null && result is List<String>) {
      setState(() {
        members = result; // Update members in Create Group screen
      });
    }
  }


  void _createGroup() async {
    if (title.text.trim().isEmpty) {
      SnackbarUtils.showErrorSnackbar(context, "Title cannot be empty!");
      return;
    }

    if (members.isEmpty) {
      SnackbarUtils.showErrorSnackbar(context,"Please add at least one member!");
      return;
    }

    try {
      // Add a new document with a generated ID
      DocumentReference groupRef = await FirebaseFirestore.instance.collection("groups").add({
        "title": title.text.trim(),
        "description": discretion.text.trim(),
        "category": selectedCategory,
        "createdBy": currentUser!.uid,
        "members": members,
        "createdAt": Timestamp.now(),
      });
      logger.d("Title: $title, description: $discretion, Members: $members ,category: $selectedCategory, createdBy : $currentUser,createdAt: $Timestamp.now");

      SnackbarUtils.showSuccessSnackbar(context,"Group Created Successfully!");
      Navigator.pop(context); // Go back after creating the group
    } catch (e) {
      print("Error saving group: $e");
      SnackbarUtils.showErrorSnackbar(context,"Failed to create group!");
      SnackbarUtils.showErrorSnackbar(context,"Failed to create group!");
    }
  }


  @override
  Widget build(BuildContext context) {
       logger.d("Title: $title, description: $discretion, Members: $members ,category: $selectedCategory, createdBy : $currentUser,createdAt: $Timestamp.now");
    return Scaffold(
      appBar: CustomAppBar(title: "Create Group"),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                CustomTextFieldNew(
                  label: "Title",
                  controller: title,
                ),
                SizedBox(height: 20),
                CustomTextFieldNew(
                  label: "Description",
                  controller: discretion,
                ),
                SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14.0),
                  child: Text(
                    'Category',
                    style: AppTypography.captionText(context),
                  ),
                ),
                SizedBox(height: 1),
                CustomDropdown(
                  items: categoryOptions,
                  hintText: "Select a category",
                  isRead: true,
                  defaultValue: selectedCategory,
                  onItemSelected: (value) {
                    setState(() {
                      selectedCategory = value;
                    });
                  },
                ),
                SizedBox(height: 30),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14.0),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(

                      color: Colors.transparent, 
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.gray)
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton(
                          onPressed:_navigateToAddMemberScreen,
                          child:Text(
                            "Add Member",
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.main,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.main,
                              decorationThickness: 2,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                    ...members.map((member) => Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.person, size: 24, color: AppColors.white),
                          SizedBox(width: 10),
                          Text(member, style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    )).toList(),
                      ],
                    ),
                  ),
                ),


                SizedBox(height: 30),
                Center(
                  child: CustomMainButton(
                    width: double.infinity,
                    text: "Create Group",
                    onPressed: _createGroup
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
