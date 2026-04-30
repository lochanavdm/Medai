import 'package:flutter/material.dart';
import 'utils/app_colors.dart';
import 'screens/home/main_navigation.dart';
import 'screens/home/home_screen.dart';
import 'screens/scan/scan_details_screen.dart';
import 'services/history_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/history_service.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await HistoryService.loadHistory();

  runApp(const MedAIApp());
}

class MedAIApp extends StatelessWidget {
  const MedAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MedAI',

      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primaryPurple,
      ),

      //home: const MainNavigation(),
      home: const SplashScreen(),
    );
  }
}
