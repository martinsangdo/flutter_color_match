import 'package:color_match/data/levels/level_generator.dart';
import 'package:color_match/data/levels/level_solver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Level generation', () {
    test('every campaign level is generated and solvable', () {
      for (int i = 0; i < kLevelCount; i++) {
        final level = LevelGenerator.generate(i);
        expect(level.pieceQueue, isNotEmpty, reason: 'level ${i + 1} has no pieces');
        expect(level.objective.targetTotal, greaterThan(0),
            reason: 'level ${i + 1} has a non-positive target');
        expect(LevelSolver.verify(level), isTrue,
            reason: 'level ${i + 1} is not solvable');
      }
    });

    test('generation is deterministic per index', () {
      final a = LevelGenerator.generate(37);
      final b = LevelGenerator.generate(37);
      expect(a.seed, b.seed);
      expect(a.objective.targetTotal, b.objective.targetTotal);
      expect(a.pieceQueue.length, b.pieceQueue.length);
    });

    test('difficulty escalates: later levels demand more', () {
      final early = LevelGenerator.generate(1);
      final late = LevelGenerator.generate(80);
      expect(late.objective.targetTotal, greaterThan(early.objective.targetTotal));
    });
  });
}
