import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/piece.dart';
import '../home/home_screen.dart';

/// Explains the core rules. Shown automatically on first launch (persisting a
/// "seen" flag) and reachable again from Settings.
class HowToPlayScreen extends ConsumerWidget {
  final bool firstLaunch;
  const HowToPlayScreen({super.key, this.firstLaunch = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: [
                    if (!firstLaunch)
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                        onPressed: () => Navigator.of(context).pop(),
                      )
                    else
                      const SizedBox(width: 48),
                    Expanded(
                      child: Text('How to Play',
                          textAlign: TextAlign.center, style: AppTheme.title(22)),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: const [
                    _Rule(
                      icon: Icons.touch_app_rounded,
                      title: 'Drag pieces to the board',
                      body: 'Drag the pieces from the tray onto the 10×10 grid. '
                          'Each little square has its own colour.',
                    ),
                    _MatchIllustration(),
                    _Rule(
                      icon: Icons.auto_awesome_rounded,
                      title: 'Match 3+ of a colour',
                      body: 'When three or more same-coloured squares connect '
                          'side-by-side, they clear away.',
                    ),
                    _Rule(
                      icon: Icons.bolt_rounded,
                      title: 'Chain combos',
                      body: 'Clears that trigger more clears cascade for bonus '
                          'points — set them up!',
                    ),
                    _Rule(
                      icon: Icons.flag_rounded,
                      title: 'Hit the goal',
                      body: 'Each level asks you to clear a number of blocks '
                          'within a limited set of pieces. Clear more for 3 stars.',
                    ),
                    _Rule(
                      icon: Icons.all_inclusive_rounded,
                      title: 'Endless mode',
                      body: 'Out of levels? Endless keeps remixing pieces of '
                          'rising difficulty for a high score chase.',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () async {
                      if (firstLaunch) {
                        await ref.read(settingsProvider.notifier).markHowToPlaySeen();
                        if (!context.mounted) return;
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text(firstLaunch ? "Let's play" : 'Got it'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _Rule({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accent2, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(body,
                    style: const TextStyle(color: AppColors.textMuted, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Little before/after strip of blocks illustrating a match clearing.
class _MatchIllustration extends StatelessWidget {
  const _MatchIllustration();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _blocks(const [0, 0, 0]),
          const SizedBox(width: 12),
          const Icon(Icons.arrow_forward_rounded, color: AppColors.textMuted),
          const SizedBox(width: 12),
          _blocks(const [-1, -1, -1]),
        ],
      ),
    );
  }

  Widget _blocks(List<int> colors) => Row(
        mainAxisSize: MainAxisSize.min,
        children: colors
            .map((c) => Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: c < 0 ? AppColors.panelLight : kPieceColors[c],
                    borderRadius: BorderRadius.circular(5),
                  ),
                ))
            .toList(),
      );
}
