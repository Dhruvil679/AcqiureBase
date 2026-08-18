import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions
          .currentPlatform,
    );

    try {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: const AndroidPlayIntegrityProvider(),
      );
    } catch (e) {
      debugPrint('App Check activation failed (non-fatal): $e');
    }
  } on UnsupportedError catch (e) {
    debugPrint('Firebase not configured for this platform: $e');
  }

  runApp(const ProviderScope(child: AcquireBaseApp()));
}

class AcquireBaseApp extends StatelessWidget {
  const AcquireBaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AcquireBase',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
