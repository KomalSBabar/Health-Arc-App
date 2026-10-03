import 'package:flutter/material.dart';
import 'main_navigation.dart';
import 'theme/app_colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: ThemeData(

        scaffoldBackgroundColor:
            AppColors.background,

        primaryColor:
            AppColors.primary,

        appBarTheme: const AppBarTheme(
          backgroundColor:
              AppColors.primary,

          foregroundColor:
              Colors.white,

          centerTitle: true,

          elevation: 0,
        ),

        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        elevatedButtonTheme:
            ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize:
                const Size(double.infinity, 55),

            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(15),
            ),
          ),
        ),
      ),

      home: const MainNavigation(),
    );
  }

}


