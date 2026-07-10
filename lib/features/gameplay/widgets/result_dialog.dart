import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Reusable row of 0-3 stars.
class StarsRow extends StatelessWidget {
  final int stars;
  final double size;
  const StarsRow({super.key, required this.stars, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final filled = i < stars;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          color: filled ? AppColors.star : AppColors.locked,
          size: size,
        );
      }),
    );
  }
}

/// Win / lose / game-over sheet shown at the end of a session.
class ResultDialog extends StatelessWidget {
  final bool won;
  final bool isEndless;
  final int stars;
  final int cleared;
  final int score;
  final bool hasNext;
  final VoidCallback onRetry;
  final VoidCallback onNext;
  final VoidCallback onExit;

  const ResultDialog({
    super.key,
    required this.won,
    required this.isEndless,
    required this.stars,
    required this.cleared,
    required this.score,
    required this.hasNext,
    required this.onRetry,
    required this.onNext,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final title = isEndless
        ? 'Game Over'
        : won
            ? 'Level Complete!'
            : 'Out of Moves';

    return Dialog(
      backgroundColor: AppColors.panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              won ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
              size: 56,
              color: won ? AppColors.star : AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(title, style: AppTheme.title(24)),
            const SizedBox(height: 16),
            if (won && !isEndless) ...[
              StarsRow(stars: stars, size: 40),
              const SizedBox(height: 12),
            ],
            Text(
              isEndless ? 'Score: $score' : 'Blocks cleared: $cleared',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 15),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRetry,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.accent),
                    ),
                    child: Text(isEndless ? 'Play again' : 'Retry',
                        style: const TextStyle(color: AppColors.textPrimary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: (won && !isEndless && hasNext) ? onNext : onExit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.accent,
                    ),
                    child: Text(
                      (won && !isEndless && hasNext) ? 'Next' : 'Menu',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
