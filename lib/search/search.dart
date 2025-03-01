import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/AppBar.dart';
import '../widgets/colors.dart';
import '../widgets/login_btn.dart';

class SearchMemberScreen extends StatefulWidget {
  final List<String> selectedMembers;

  SearchMemberScreen({required this.selectedMembers});

  @override
  _SearchMemberScreenState createState() => _SearchMemberScreenState();
}

class _SearchMemberScreenState extends State<SearchMemberScreen> {
  final TextEditingController searchController = TextEditingController();
  List<String> allMembers = [];
  List<String> filteredMembers = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAllMembers();
    searchController.addListener(_filterMembers);
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
  String query = searchController.text.trim().toLowerCase();
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


  /// Select a member
  void _selectMember(String member) {
    if (!widget.selectedMembers.contains(member)) {
      widget.selectedMembers.add(member);
    }
    Navigator.pop(context, widget.selectedMembers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Search Member"),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Field
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: AppColors.gray),
                hintText: "Search for members...",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            SizedBox(height: 16),

            // Show loading indicator
            if (isLoading) Center(child: CircularProgressIndicator()),

            // Show filtered results
            Expanded(
              child: filteredMembers.isEmpty && !isLoading
                  ? Center(child: Text(""))
                  : ListView.builder(
                      itemCount: filteredMembers.length,
                      itemBuilder: (context, index) {
                        print(
                            "Displaying: ${filteredMembers[index]}"); 
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.mainShadow,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(filteredMembers[index],
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          onTap: () => _selectMember(filteredMembers[index]),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}
