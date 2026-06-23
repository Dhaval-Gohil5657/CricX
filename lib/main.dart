import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'screens/welcome_screen.dart';
import 'constants/app_colors.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CricX – Live Cricket. Simplified.',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: AppColors.primaryTurf,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.accentCrease,
          secondary: AppColors.pitchGold,
          background: AppColors.background,
          surface: AppColors.cardBg,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onBackground: AppColors.textDark,
          onSurface: AppColors.textDark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.appBarGreen,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textDark),
          bodyMedium: TextStyle(color: AppColors.textDarkSecondary),
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}
