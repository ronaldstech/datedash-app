import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth/sign_in_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const DateDashApp());
}

class DateDashApp extends StatelessWidget {
  const DateDashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DateDash',
      theme: AppTheme.lightTheme,
      home: const SignInScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
