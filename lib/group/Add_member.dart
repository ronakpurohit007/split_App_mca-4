import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:login/widgets/AppBar.dart';
import '../widgets/colors.dart';
import '../widgets/login_btn.dart';
import '../widgets/snackbar_utils.dart';

class AddMemberScreen extends StatefulWidget {
  final List<String> existingMembers;
  AddMemberScreen({required this.existingMembers});

  @override
  _AddMemberScreenState createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final TextEditingController nameController = TextEditingController();
  late List<String> members;
  User? currentUser;
  String userName = "Loading...";
  bool isNameEmpty = true;
  List<String> allMembers = [];
  List<String> filteredMembers = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    members = List.from(widget.existingMembers);
    _fetchCurrentUser();

    nameController.addListener(() {
      setState(() {
        isNameEmpty = nameController.text.trim().isEmpty;
      });
    });
  }


  /// Fetch all members from Firestore (Array inside Document)
  void _fetchAllMembers() async {
    setState(() {
      isLoading = true;
    });

    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('members')
          .doc('F4YXH6A1ijWcUzl3lsl48m1Sg233')
          .get();

      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;
        List<dynamic> membersArray = data['members'] ?? [];

        // Debugging Output
        print("Fetched Data: $data");
        print("Members Array: $membersArray");

        // Convert members to List<String>
        setState(() {
          allMembers = membersArray.cast<String>();
          filteredMembers = []; // Show all initially
          isLoading = false;
        });

        print("All Members: $allMembers");
      } else {
        print("No members found.");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching members: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Search & filter members
void _filterMembers() {
  String query = nameController.text.trim().toLowerCase();
  setState(() {
    if (query.isEmpty) {
      filteredMembers = [];
    } else {
      filteredMembers = allMembers
          .where((member) => member.toLowerCase().contains(query))
          .toList();
    }
  });

  print("Filtered Members: $filteredMembers");
}


  void _fetchCurrentUser() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String name = user.displayName ?? user.email ?? "User";
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection("user")
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data() != null) {
          var data = doc.data() as Map<String, dynamic>;
          name = data["name"] ?? name;
        }
        setState(() {
          currentUser = user;
          userName = name;
        });
      } else {
        setState(() => userName = "No user found");
      }
    } catch (error) {
      setState(() => userName = "Error fetching user");
    }
  }

  void _addMember() {
    String name = nameController.text.trim();

    if (name.isEmpty) {
      SnackbarUtils.showErrorSnackbar(context, "Name is empty!");
      return;
    }

    if (!members.contains(name)) {
      setState(() {
        members.add(name);
        nameController.clear(); // Clear the input field
      });
      SnackbarUtils.showSuccessSnackbar(context, "Member Added Successfully");
    } else {
      nameController.clear();
      SnackbarUtils.showErrorSnackbar(context, "Member already exists!");
    }
  }

  void _removeMember(int index) {
    setState(() {
      members.removeAt(index);
    });
    SnackbarUtils.showExitSnackbar(context, "Member Removed Successfully");
  }

  void _saveAndReturn() async {
    if (currentUser == null) return;

    DocumentReference docRef =
    FirebaseFirestore.instance.collection("members").doc(currentUser!.uid);

    DocumentSnapshot docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      List<dynamic> existingMembers = docSnapshot["members"] ?? [];
      existingMembers.addAll(members);
      existingMembers = existingMembers.toSet().toList(); // Remove duplicates

      await docRef.update({"members": existingMembers});
    } else {
      await docRef.set({"members": members});
    }

    Navigator.pop(context, members); // Send members back to Create Group Screen
  }



  Future<void> _updateMembersInFirestore() async {
    if (currentUser == null) return;
    await FirebaseFirestore.instance
        .collection("members")
        .doc(currentUser!.uid)
        .set({"members": members});
  }

  void _editMember(int index) {
    TextEditingController editController =
        TextEditingController(text: members[index]);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.black,
          title: Text(
            "Edit Member",
            style: TextStyle(color: AppColors.white),
          ),
          content: CustomTextFieldNew(
            controller: editController,
            label: "Name",
          ),
          actions: [
            CustomMainButton(
              width: double.infinity,
              text: "Save",
              onPressed: () {
                setState(() {
                  members[index] = editController.text.trim();
                });
                _updateMembersInFirestore();
                Navigator.pop(context);
              },
            ),
            SizedBox(
              height: 10,
            ),
            CustomCancelButton(
              width: double.infinity,
              onPressed: () {
                Navigator.pop(context);
              },
              text: ("Cancel"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Add Member"),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextFieldNew(
                  controller: nameController, label: "Enter Member Name"),
              SizedBox(height: 16),
              if (!isNameEmpty)
                Center(
                  child: CustomMainButton(
                    width: double.infinity,
                    text: "Add Member",
                    onPressed: _addMember,
                  ),
                ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.gray),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: members.length > 3
                            ? 200
                            : members.length * 61.0, 
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: members.length > 3
                            ? BouncingScrollPhysics()
                            : NeverScrollableScrollPhysics(),
                        itemCount: members.length,
                        itemBuilder: (context, index){
                          return Card(
                            color: AppColors.mainShadow,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: AppColors.gray, width: 1),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(3),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      children: [
                                        Icon(Icons.person,
                                            size: 24, color: AppColors.white),
                                        SizedBox(width: 10),
                                        Text(members[index],
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _editMember(index);
                                      } else if (value == 'remove') {
                                        _removeMember(index);
                                      }
                                    },
                                    shadowColor: AppColors.mainShadow,
                                    color: AppColors.black,
                                    shape: RoundedRectangleBorder(
                                      side: BorderSide(
                                          color: AppColors.gray,
                                          width: 1),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(
                                              8),
                                      ), // Rounded corners
                                    ),
                                    itemBuilder: (BuildContext context) {
                                      return [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit,
                                                  color: AppColors.white),
                                              SizedBox(width: 8),
                                              Text('Edit',
                                                  style: TextStyle(
                                                      color: AppColors.white)),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'remove',
                                          child: Row(
                                            children: [
                                              Icon(Icons.close,
                                                  color: AppColors.white),
                                              SizedBox(width: 8),
                                              Text('Remove',
                                                  style: TextStyle(
                                                      color: AppColors.white)),
                                            ],
                                          ),
                                        ),
                                      ];
                                    },
                                    child: Icon(Icons.more_vert,
                                        color:
                                        AppColors.gray), // Three-dot button
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
              ),
              SizedBox(height: 20),
              Center(
                child: CustomMainButton(
                  width: double.infinity,
                  text: "Done",
                  onPressed: _saveAndReturn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
