import 'package:flutter/material.dart';
import 'package:login/widgets/AppBar.dart';
import 'package:login/widgets/category_utils.dart';
import 'package:login/widgets/colors.dart';
import 'package:login/widgets/logger.dart';


final ConsoleAppLogger logger = ConsoleAppLogger(); 

class GroupDetailScreen extends StatelessWidget {
  final String groupId;
  final String title;
  final String description;
  final List<String> members;
  final String category;

  GroupDetailScreen({
    required this.groupId,
    required this.title,
    required this.description,
    required this.members,
    required this.category,
  });



  @override
  Widget build(BuildContext context) {
    
     logger.d("Group Details -> ID: $groupId, Title: $title, Category: $category, Members: $members");
     
    return Scaffold(
      appBar: CustomAppBar(
          title: "${CategoryUtils.getCategoryEmoji(category)} $title"),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "${CategoryUtils.getCategoryEmoji(category)} $title",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Description:",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            SizedBox(height: 5),
            Text(
              description,
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            SizedBox(height: 20),
            Text(
              "Members:",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            SizedBox(height: 10),
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
                      maxHeight:
                          members.length > 3 ? 200 : members.length * 61.0,
                    ),
                    child: SizedBox(
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: members.length > 3
                            ? BouncingScrollPhysics()
                            : NeverScrollableScrollPhysics(),
                        itemCount: members.length,
                        itemBuilder: (context, index) {
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
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
