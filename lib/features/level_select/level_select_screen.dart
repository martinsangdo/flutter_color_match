import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/progress.dart';
import '../gameplay/gameplay_screen.dart';
import '../gameplay/widgets/result_dialog.dart';

/// Reactive level grid — it watches [progressProvider], so returning from a
/// level (win, lose, or exit) reflects updated stars/unlocks immediately.
class LevelSelectScreen extends ConsumerWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final levelCount = ref.watch(levelRepositoryProvider).levelCount;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text('Select Level',
                          textAlign: TextAlign.center, style: AppTheme.title(22)),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: levelCount,
                  itemBuilder: (context, index) {
                    final p = progress[index] ?? LevelProgress(index: index);
                    final unlocked =
                        index == 0 || (progress[index - 1]?.completed ?? false);
                    return _LevelTile(
                      number: index + 1,
                      progress: p,
                      unlocked: unlocked,
                      onTap: unlocked
                          ? () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => GameplayScreen(levelIndex: index),
                                ),
                              )
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  final int number;
  final LevelProgress progress;
  final bool unlocked;
  final VoidCallback? onTap;

  const _LevelTile({
    required this.number,
    required this.progress,
    required this.unlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final completed = progress.completed;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: unlocked ? AppColors.panel : AppColors.panel.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: completed ? AppColors.accent2 : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!unlocked)
              const Icon(Icons.lock_rounded, color: AppColors.locked, size: 26)
            else
              Text('$number',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Opacity(
              opacity: unlocked ? 1 : 0.3,
              child: StarsRow(stars: progress.stars, size: 14),
            ),
          ],
        ),
      ),
    );
  }
}
