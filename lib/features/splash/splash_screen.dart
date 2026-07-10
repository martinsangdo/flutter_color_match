import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../home/home_screen.dart';
import '../how_to_play/how_to_play_screen.dart';

/// White background, centred logo, shown for exactly 2 seconds, then routes to
/// How-to-Play on first launch or Home otherwise.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final start = DateTime.now();
    // Kick off async work during the splash window.
    final settings = await ref.read(settingsRepositoryProvider).load();
    ref.read(progressProvider); // warm the progress store

    final elapsed = DateTime.now().difference(start);
    final remaining = const Duration(seconds: 2) - elapsed;
    if (remaining > Duration.zero) await Future.delayed(remaining);
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => settings.howToPlaySeen
            ? const HomeScreen()
            : const HowToPlayScreen(firstLaunch: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/xp_group_logo.png',
          width: 240,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
