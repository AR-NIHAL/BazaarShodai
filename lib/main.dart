import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific options (Spark plan, asia-south1)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: BazaarShodaiApp(),
    ),
  );
}

/// Root widget for BazaarShodai multi-vendor application.
class BazaarShodaiApp extends StatelessWidget {
  const BazaarShodaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BazaarShodai',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
