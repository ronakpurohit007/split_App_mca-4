import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:login/group/GroupDetailScreen.dart';
import '../widgets/AppBar.dart';
import '../widgets/colors.dart';
import '../widgets/category_utils.dart';

class SearchGroupScreen extends StatefulWidget {
  @override
  _SearchGroupScreenState createState() => _SearchGroupScreenState();
}

class _SearchGroupScreenState extends State<SearchGroupScreen> {
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredGroups = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_searchGroups);
  }

  /// Search for groups by title
  void _searchGroups() async {
    String query = searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() {
        filteredGroups = [];
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Query Firestore for groups where title contains the search query
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      // Process results
      List<Map<String, dynamic>> groups = querySnapshot.docs.map((doc) {
        return {
          "id": doc.id,
          "title": doc["title"] ?? "Untitled Group",
          "description": doc["description"] ?? "No description available",
          "category": doc["category"] ?? "Other",
          "createdBy": doc["createdBy"] ?? "Unknown",
          "members": List<String>.from(doc["members"] ?? []),
        };
      }).toList();

      setState(() {
        filteredGroups = groups;
        isLoading = false;
      });

      print("Filtered Groups: ${filteredGroups.length}");
    } catch (e) {
      print("Error searching groups: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Navigate to group details
  void _viewGroupDetails(Map<String, dynamic> group) {
    FocusScope.of(context).unfocus();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Search Groups"),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search Field
              // Search Field
              Container(
                decoration: BoxDecoration(
                  color: AppColors.mainShadow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: searchController,
                  style: TextStyle(color: Colors.white),
                  cursorColor: AppColors.white,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: AppColors.gray),
                    hintText: "Search for groups by title...",
                    hintStyle: TextStyle(color: Colors.white60),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.mainShadow),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.main, width: 1.5),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Show loading indicator
              if (isLoading)
                Center(
                    child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                )),

              // Show filtered results
              Expanded(
                child: filteredGroups.isEmpty && !isLoading
                    ? Center(
                        child: Text(
                        searchController.text.isEmpty
                            ? "Enter a group name to search"
                            : "No groups found",
                        style: TextStyle(color: Colors.white),
                      ))
                    : ListView.builder(
                        itemCount: filteredGroups.length,
                        itemBuilder: (context, index) {
                          var group = filteredGroups[index];
                          return Card(
                              color: AppColors.mainShadow,
                              margin: EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.main,
                                  child: Text(
                                    CategoryUtils.getCategoryEmoji(
                                        group["category"]),
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ),
                                title: Text(
                                  group["title"],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      group["description"],
                                      style: TextStyle(color: Colors.white70),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Created by: ${group["createdBy"]}",
                                      style: TextStyle(
                                        color: AppColors.main,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Text(
                                  "${group["members"].length} members",
                                  style: TextStyle(color: Colors.white70),
                                ),
                                onTap: () => _viewGroupDetails(group),
                              ));
                        },
                      ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
