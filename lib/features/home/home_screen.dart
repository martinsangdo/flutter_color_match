import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';
import '../gameplay/gameplay_screen.dart';
import '../how_to_play/how_to_play_screen.dart';
import '../level_select/level_select_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioServiceProvider).startMusic();
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressProvider.notifier);
    final totalStars = ref.watch(progressProvider.select(
      (m) => m.values.fold<int>(0, (s, p) => s + p.stars),
    ));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              const AppLogo(size: 128),
              const SizedBox(height: 20),
              Text('Color Match', style: AppTheme.title(34)),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded, color: AppColors.star, size: 20),
                  const SizedBox(width: 4),
                  Text('$totalStars stars · ${progress.completedCount} cleared',
                      style: const TextStyle(color: AppColors.textMuted)),
                ],
              ),
              const Spacer(flex: 2),
              _MenuButton(
                icon: Icons.play_arrow_rounded,
                label: 'Play',
                primary: true,
                onTap: () => _push(const LevelSelectScreen()),
              ),
              _MenuButton(
                icon: Icons.all_inclusive_rounded,
                label: 'Endless',
                onTap: () => _push(const GameplayScreen()),
              ),
              _MenuButton(
                icon: Icons.help_outline_rounded,
                label: 'How to Play',
                onTap: () => _push(const HowToPlayScreen()),
              ),
              _MenuButton(
                icon: Icons.settings_rounded,
                label: 'Settings',
                onTap: () => _push(const SettingsScreen()),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 7),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onTap,
          icon: Icon(icon),
          label: Text(label, style: const TextStyle(fontSize: 17)),
          style: FilledButton.styleFrom(
            backgroundColor: primary ? AppColors.accent : AppColors.panel,
            foregroundColor: AppColors.textPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }
}
