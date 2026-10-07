import 'package:flutter/material.dart';
import 'home_page.dart';
import 'history_screen.dart';
import 'theme/app_colors.dart';
import 'goals_screen.dart';

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
    const GoalsScreen(),
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Personal Tracker"),
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

                      SizedBox(width: 10),

                      Text(
                        "Personal Tracker",
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
                  leading: const Icon(Icons.home),
                  title: const Text("Dashboard"),
                  onTap: () {},
               ),

                ListTile(
                  leading: const Icon(Icons.flag),
                  title: const Text("Goals"),
                  onTap: () {},
               ),

                ListTile(
                  leading: const Icon(Icons.task),
                  title: const Text("All Tasks"),
                  onTap: () {},
               ),

               ListTile(
                  leading: const Icon(Icons.currency_rupee),
                  title: const Text("Expenses"),
                  onTap: () {},
               ),

               ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text("Settings"),
                  onTap: () {},
               ),


            ],
          ),
      ),

      body: pages[selectedIndex],

      bottomNavigationBar: BottomNavigationBar(

        currentIndex: selectedIndex,

        selectedItemColor:
            AppColors.primary,

        unselectedItemColor:
            Colors.grey,

        selectedLabelStyle:
            const TextStyle(
          fontWeight:
              FontWeight.bold,
        ),

        type:
            BottomNavigationBarType.fixed,

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

          BottomNavigationBarItem(
            icon: Icon(Icons.flag),
            label: "Goals",
          ),

        ],
      ),

    );
  }
}