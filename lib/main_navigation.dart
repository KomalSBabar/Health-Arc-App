import 'package:flutter/material.dart';
import 'home_page.dart';
import 'history_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() =>
      _MainNavigationState();
}

class _MainNavigationState
    extends State<MainNavigation> {

  int selectedIndex = 0;

  final List<Widget> pages = [
    const HomePage(),
    const HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: pages[selectedIndex],

      bottomNavigationBar: BottomNavigationBar(

        currentIndex: selectedIndex,

        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },

        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: "History",
          ),

        ],
      ),
    );
  }
}