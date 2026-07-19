import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/splash/splash_screen.dart';

class ColorMatchApp extends StatelessWidget {
  const ColorMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Color Match',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const SplashScreen(),
    );
  }
}
