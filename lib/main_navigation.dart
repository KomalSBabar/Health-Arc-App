
import 'package:flutter/material.dart';

import 'home_page.dart';
import 'history_screen.dart';
import 'goals_screen.dart';
import 'long_term_goal_screen.dart';
import 'theme/app_colors.dart';
import 'expenses_screen.dart';


class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  // Page indexes:
  // 0 = Home
  // 1 = History
  // 2 = Goals
  // 3 = Dashboard
  // 4 = All Tasks
  // 5 = Expenses
  // 6 = Settings

  int selectedPage = 0;

  // Bottom navigation selection
  int selectedBottomIndex = 0;

  final List<Widget> pages = [
      const HomePage(),                 // Index 0: Home
      const HistoryScreen(),            // Index 1: History
      const GoalsScreen(),               // Index 2: Tasks
      const SizedBox.shrink(),           // Index 3: Dashboard
      const LongTermGoalScreen(),        // Index 4: Goals
      const ExpensesScreen(), // Index 5
      const Center(child: Text('Settings')), // Index 6
  ];

  void navigateToPage(int pageIndex) {
    setState(() {
      selectedPage = pageIndex;

      // Update footer selection when navigating
      // to Home, History, or Goals.
      if (pageIndex >= 0 && pageIndex <= 2) {
        selectedBottomIndex = pageIndex;
      }
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Tracker'),
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Row(
                children: [
                  Icon(
                    Icons.track_changes,
                    size: 35,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Personal Tracker',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              selected: selectedPage == 3,
              onTap: () => navigateToPage(3),
            ),

            ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('Goals'),
              selected: selectedPage == 4,
              onTap: () => navigateToPage(4),
            ),

            ListTile(
              leading: const Icon(Icons.task),
              title: const Text('All Tasks'),
              selected: selectedPage == 2,
              onTap: () => navigateToPage(2),
            ),

            ListTile(
              leading: const Icon(Icons.currency_rupee),
              title: const Text('Expenses'),
              selected: selectedPage == 5,
              onTap: () => navigateToPage(5),
            ),

            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              selected: selectedPage == 6,
              onTap: () => navigateToPage(6),
            ),
          ],
        ),
      ),

      // Main page content
      body: IndexedStack(
        index: selectedPage,
        children: pages,
      ),

      // Persistent bottom navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedBottomIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,

        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
        ),

        onTap: (index) {
          setState(() {
            selectedBottomIndex = index;
            selectedPage = index;
          });
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag),
            label: 'Tasks',
          ),
        ],
      ),
    );
  }
}
