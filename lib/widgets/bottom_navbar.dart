import 'package:flutter/material.dart';
import 'package:login/demo/test.dart';
import '../Home/home.dart';
import '../profile/profile.dart';
import '../search/search.dart';

import 'colors.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  List<String> members = [];

  final List<Widget> _screens = [
    HomeScreen(),
    SearchMemberScreen(selectedMembers: []),
    DemoTest(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _screens[_selectedIndex], // Dynamically loads the selected screen
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: AppColors.main,
        ),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(25)),
            child: BottomNavigationBar(
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: "Home",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: "Search",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.notifications),
                  label: "Notifications",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: "Profile",
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: AppColors.black,
              unselectedItemColor: AppColors.white,
              backgroundColor: Colors.transparent,
              // backgroundColor: Colors.transparent,
              elevation: 0,
              onTap: _onItemTapped,
            ),
          ),
        ),
      ),
    );
  }
}
