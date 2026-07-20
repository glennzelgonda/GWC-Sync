import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TireInventoryApp());
}

class TireInventoryApp extends StatelessWidget {
  const TireInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GWC Sync',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkIndustrial,
      home: const SplashScreen(),
    );
  }
}