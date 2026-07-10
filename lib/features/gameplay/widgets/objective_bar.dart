import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/level.dart';
import '../../../data/models/piece.dart';
import '../game_engine.dart';

/// Shows the win condition and live progress. For endless it shows the score.
class ObjectiveBar extends StatelessWidget {
  final GameEngine engine;
  final LevelDefinition? level;

  const ObjectiveBar({super.key, required this.engine, this.level});

  @override
  Widget build(BuildContext context) {
    if (level == null) {
      return _panel(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stat('SCORE', '${engine.score}'),
            _stat('CLEARED', '${engine.totalCleared}'),
          ],
        ),
      );
    }

    final objective = level!.objective;
    final target = objective.targetTotal;
    final cleared = engine.totalCleared;
    final progress = target == 0 ? 1.0 : (cleared / target).clamp(0.0, 1.0);

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('Clear blocks',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const Spacer(),
              Text('${min(cleared, target)} / $target',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.panelLight,
              valueColor: const AlwaysStoppedAnimation(AppColors.accent2),
            ),
          ),
          if (objective.targetByColor.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: objective.targetByColor.entries.map((e) {
                final done = (engine.clearedByColor[e.key] ?? 0);
                return _colorQuota(e.key, min(done, e.value), e.value);
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _panel({required Widget child}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      );

  Widget _stat(String label, String value) => Column(
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
        ],
      );

  Widget _colorQuota(int colorIndex, int done, int target) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: kPieceColors[colorIndex],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 4),
          Text('$done/$target',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
        ],
      );
}
