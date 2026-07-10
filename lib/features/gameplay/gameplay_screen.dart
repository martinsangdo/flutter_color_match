import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/ads/banner_ad_slot.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/board.dart';
import '../../data/models/level.dart';
import '../../data/models/piece.dart';
import 'game_engine.dart';
import 'game_session_controller.dart';
import 'widgets/board_widget.dart';
import 'widgets/objective_bar.dart';
import 'widgets/piece_widget.dart';
import 'widgets/result_dialog.dart';
import 'widgets/tray_widget.dart';

/// Plays a single campaign level ([levelIndex] set) or an endless run (null).
class GameplayScreen extends ConsumerStatefulWidget {
  final int? levelIndex;
  const GameplayScreen({super.key, this.levelIndex});

  @override
  ConsumerState<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends ConsumerState<GameplayScreen> {
  late final GameSessionController _controller;
  LevelDefinition? _level;

  final GlobalKey _boardKey = GlobalKey();
  final GlobalKey _rootStackKey = GlobalKey();

  Offset? _dragPosition;
  Piece? _draggingPiece;
  int? _draggingIndex;
  int? _hoverRow;
  int? _hoverCol;
  bool _hoverValid = false;

  bool _resultShown = false;

  @override
  void initState() {
    super.initState();
    final audio = ref.read(audioServiceProvider);
    if (widget.levelIndex != null) {
      _level = ref.read(levelRepositoryProvider).level(widget.levelIndex!);
    }
    _controller = GameSessionController(level: _level, audio: audio);
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
    final status = _controller.engine.status;
    if (!_resultShown && status != GameStatus.playing) {
      _resultShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleResult(status));
    }
  }

  Future<void> _handleResult(GameStatus status) async {
    final engine = _controller.engine;
    if (_level != null && status == GameStatus.won) {
      final stars = _level!.starsFor(engine.totalCleared);
      await ref.read(progressProvider.notifier).record(
            _level!.index,
            completed: true,
            stars: stars,
            cleared: engine.totalCleared,
          );
    }
    if (!mounted) return;
    _showResultSheet(status);
  }

  // --- drag handling --------------------------------------------------------

  Rect? _boardRect() {
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _onDragStart(int index, Offset global) {
    HapticFeedback.lightImpact();
    _controller.clearHint();
    setState(() {
      _draggingIndex = index;
      _draggingPiece = _controller.engine.tray[index];
      _dragPosition = global;
    });
    _updateHover(global);
  }

  void _onDragUpdate(int index, Offset global) {
    setState(() => _dragPosition = global);
    _updateHover(global);
  }

  void _onDragEnd(int index) {
    if (_hoverRow != null && _hoverCol != null && _hoverValid) {
      HapticFeedback.mediumImpact();
      _controller.place(index, _hoverRow!, _hoverCol!);
    }
    setState(() {
      _draggingIndex = null;
      _draggingPiece = null;
      _dragPosition = null;
      _hoverRow = null;
      _hoverCol = null;
      _hoverValid = false;
    });
  }

  void _updateHover(Offset global) {
    final rect = _boardRect();
    final piece = _draggingPiece;
    if (rect == null || piece == null || !rect.contains(global)) {
      setState(() {
        _hoverRow = null;
        _hoverCol = null;
        _hoverValid = false;
      });
      return;
    }
    final cellSize = rect.width / kBoardSize;
    final localX = global.dx - piece.cols * cellSize / 2 - rect.left;
    final localY = global.dy - piece.rows * cellSize / 2 - rect.top;
    int col = (localX / cellSize).round().clamp(0, kBoardSize - piece.cols);
    int row = (localY / cellSize).round().clamp(0, kBoardSize - piece.rows);
    setState(() {
      _hoverRow = row;
      _hoverCol = col;
      _hoverValid = _controller.engine.canPlacePiece(piece, row, col);
    });
  }

  // --- result sheet ---------------------------------------------------------

  void _showResultSheet(GameStatus status) {
    final engine = _controller.engine;
    final won = status == GameStatus.won;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ResultDialog(
        won: won,
        isEndless: _level == null,
        stars: (won && _level != null) ? _level!.starsFor(engine.totalCleared) : 0,
        cleared: engine.totalCleared,
        score: engine.score,
        hasNext: _level != null && _level!.index + 1 < ref.read(levelRepositoryProvider).levelCount,
        onRetry: () {
          Navigator.of(ctx).pop();
          setState(() => _resultShown = false);
          _controller.restart();
        },
        onNext: () {
          final next = _level!.index + 1;
          Navigator.of(ctx).pop();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => GameplayScreen(levelIndex: next)),
          );
        },
        onExit: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _onHintPressed() {
    if (_controller.engine.status != GameStatus.playing) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('Hint', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Watch a short ad for a hint — rewarded ads coming soon.\n\n'
          'For now, tap "Show me" to highlight a good move.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _controller.requestHint();
            },
            child: const Text('Show me'),
          ),
        ],
      ),
    );
  }

  Set<int> _hintCells() {
    final hint = _controller.hint;
    if (hint == null) return const {};
    final piece = _controller.engine.tray[hint.trayIndex];
    if (piece == null) return const {};
    return {
      for (final cell in piece.coloredCells)
        (hint.row + cell.row) * kBoardSize + (hint.col + cell.col)
    };
  }

  // --- build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Stack(
            key: _rootStackKey,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final boardSize =
                      (constraints.maxWidth - 24).clamp(0.0, constraints.maxHeight * 0.62);
                  return Column(
                    children: [
                      _buildHeader(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: ObjectiveBar(engine: _controller.engine, level: _level),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: SizedBox(
                          key: _boardKey,
                          width: boardSize,
                          height: boardSize,
                          child: RepaintBoundary(
                            child: BoardWidget(
                              board: _controller.engine.board,
                              hoverPiece: _draggingPiece,
                              hoverRow: _hoverRow,
                              hoverCol: _hoverCol,
                              hoverValid: _hoverValid,
                              hintCells: _hintCells(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: TrayWidget(
                          tray: _controller.engine.tray,
                          boardWidth: boardSize,
                          activeIndex: _draggingIndex,
                          onDragStart: _onDragStart,
                          onDragUpdate: _onDragUpdate,
                          onDragEnd: _onDragEnd,
                        ),
                      ),
                      const Spacer(),
                      const BannerAdSlot(),
                    ],
                  );
                },
              ),
              if (_draggingPiece != null && _dragPosition != null)
                _buildDragOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final movesLeft = _controller.movesLeft;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              _level == null ? 'Endless' : 'Level ${_level!.number}',
              textAlign: TextAlign.center,
              style: AppTheme.title(20),
            ),
          ),
          if (movesLeft >= 0)
            _chip(Icons.grid_view_rounded, '$movesLeft')
          else
            _chip(Icons.stars_rounded, '${_controller.engine.score}'),
          IconButton(
            icon: const Icon(Icons.lightbulb_outline, color: AppColors.star),
            tooltip: 'Hint',
            onPressed: _onHintPressed,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textMuted),
            tooltip: 'Restart',
            onPressed: () {
              setState(() => _resultShown = false);
              _controller.restart();
            },
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.accent2),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Widget _buildDragOverlay() {
    final piece = _draggingPiece!;
    final pos = _dragPosition!;
    final rect = _boardRect();
    if (rect == null) return const SizedBox.shrink();
    final cellSize = rect.width / kBoardSize;
    final rootBox = _rootStackKey.currentContext?.findRenderObject() as RenderBox?;
    final rootOffset = rootBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final left = pos.dx - rootOffset.dx - piece.cols * cellSize / 2;
    final top = pos.dy - rootOffset.dy - piece.rows * cellSize / 2;
    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: PieceWidget(piece: piece, cellSize: cellSize, opacity: 0.9),
      ),
    );
  }
}
