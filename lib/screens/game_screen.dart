import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../ads/banner_ad_widget.dart';
import '../game/game_controller.dart';
import '../models/piece.dart';
import '../widgets/board_widget.dart';
import '../widgets/piece_widget.dart';
import '../widgets/tray_widget.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late final GameController _controller;
  final GlobalKey _boardKey = GlobalKey();
  final GlobalKey _rootStackKey = GlobalKey();

  // Drag state
  Offset? _dragPosition; // global position of drag pointer
  Piece? _draggingPiece;
  int? _hoverRow;
  int? _hoverCol;
  bool _hoverValid = false;

  // Score animation
  late AnimationController _scoreAnim;
  int _displayScore = 0;

  @override
  void initState() {
    super.initState();
    _controller = GameController();
    _controller.addListener(_onGameChanged);
    _scoreAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onGameChanged);
    _controller.dispose();
    _scoreAnim.dispose();
    super.dispose();
  }

  void _onGameChanged() {
    setState(() {
      _displayScore = _controller.score;
    });
    if (_controller.state == GameState.gameOver) {
      _showGameOver();
    }
  }

  Rect? _getBoardRect() {
    final renderBox =
        _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;
    final offset = renderBox.localToGlobal(Offset.zero);
    return offset & renderBox.size;
  }

  void _updateHover(Offset globalPos) {
    final boardRect = _getBoardRect();
    if (boardRect == null || _draggingPiece == null) return;

    // Only show hover when the finger is actually over the board
    if (!boardRect.contains(globalPos)) {
      setState(() {
        _hoverRow = null;
        _hoverCol = null;
        _hoverValid = false;
      });
      return;
    }

    final cellSize = boardRect.width / 10;
    final piece = _draggingPiece!;
    final pieceWidth = piece.shape.cols * cellSize;
    final pieceHeight = piece.shape.rows * cellSize;
    final adjustedX = globalPos.dx - pieceWidth / 2;
    final adjustedY = globalPos.dy - pieceHeight / 2;

    final localX = adjustedX - boardRect.left;
    final localY = adjustedY - boardRect.top;

    int col = (localX / cellSize).floor();
    int row = (localY / cellSize).floor();

    col = col.clamp(0, 10 - piece.shape.cols);
    row = row.clamp(0, 10 - piece.shape.rows);

    final valid = _controller.canPlacePiece(piece, row, col);

    setState(() {
      _hoverRow = row;
      _hoverCol = col;
      _hoverValid = valid;
    });
  }

  void _onDragStart(int trayIndex, Offset startPosition) {
    HapticFeedback.lightImpact();
    setState(() {
      _draggingPiece = _controller.tray[trayIndex];
      _dragPosition = startPosition;
    });
    _updateHover(startPosition);
  }

  void _onDragUpdate(int trayIndex, DragUpdateDetails details) {
    setState(() {
      _dragPosition = details.globalPosition;
    });
    _updateHover(details.globalPosition);
  }

  void _onDragEnd(int trayIndex, DragEndDetails details) {
    if (_hoverRow != null && _hoverCol != null && _hoverValid) {
      HapticFeedback.mediumImpact();
      _controller.placePiece(trayIndex, _hoverRow!, _hoverCol!);
    }

    setState(() {
      _draggingPiece = null;
      _dragPosition = null;
      _hoverRow = null;
      _hoverCol = null;
      _hoverValid = false;
    });
  }

  void _showGameOver() {
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _GameOverDialog(
          score: _controller.score,
          highScore: _controller.highScore,
          onRestart: () {
            Navigator.of(ctx).pop();
            _controller.restart();
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Stack(
          key: _rootStackKey,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isLandscape = constraints.maxWidth > constraints.maxHeight;
                if (isLandscape) {
                  return _buildLandscape(constraints);
                }
                return _buildPortrait(constraints);
              },
            ),
            if (_draggingPiece != null && _dragPosition != null)
              _buildDraggingPieceOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildPortrait(BoxConstraints constraints) {
    final boardSize = constraints.maxWidth - 24;

    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _buildBoard(boardSize),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _buildTray(boardSize),
        ),
        const Spacer(),
        const BannerAdWidget(),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildLandscape(BoxConstraints constraints) {
    final boardSize = constraints.maxHeight - 40;

    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildScoreCard(),
              const SizedBox(height: 16),
              _buildTray(boardSize * 0.6),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: _buildBoard(boardSize),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text(
            '1010',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const Text(
            ' Color Match',
            style: TextStyle(
              color: Color(0xFF3498DB),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          _buildScoreCard(),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1A2A3A),
                  title: const Text('Restart?', style: TextStyle(color: Colors.white)),
                  content: const Text(
                    'Your current progress will be lost.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _controller.restart();
                      },
                      child: const Text('Restart', style: TextStyle(color: Color(0xFFE74C3C))),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.refresh, color: Colors.white70),
            tooltip: 'Restart',
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ScoreBox(
          label: 'SCORE',
          value: _displayScore,
          color: const Color(0xFF3498DB),
        ),
        const SizedBox(width: 8),
        _ScoreBox(
          label: 'BEST',
          value: _controller.highScore,
          color: const Color(0xFFF39C12),
        ),
      ],
    );
  }

  Widget _buildBoard(double boardSize) {
    final piece = _draggingPiece;
    Piece? hoverPiece;
    int? hoverRow;
    int? hoverCol;
    bool hoverValid = false;

    if (piece != null && _dragPosition != null) {
      final boardRect = _getBoardRect();
      if (boardRect != null && boardRect.contains(_dragPosition!)) {
        hoverPiece = piece;
        hoverRow = _hoverRow;
        hoverCol = _hoverCol;
        hoverValid = _hoverValid;
      }
    }

    return SizedBox(
      key: _boardKey,
      width: boardSize,
      height: boardSize,
      child: BoardWidget(
        board: _controller.board,
        hoverPiece: hoverPiece,
        hoverRow: hoverRow,
        hoverCol: hoverCol,
        hoverValid: hoverValid,
      ),
    );
  }

  Widget _buildDraggingPieceOverlay() {
    final piece = _draggingPiece!;
    final pos = _dragPosition!;
    final boardRect = _getBoardRect();
    if (boardRect == null) return const SizedBox();

    final cellSize = boardRect.width / 10;
    final pieceWidth = piece.shape.cols * cellSize;
    final pieceHeight = piece.shape.rows * cellSize;

    // Convert global position to coordinates within _rootStackKey
    final rootBox = _rootStackKey.currentContext?.findRenderObject() as RenderBox?;
    final rootOffset = rootBox?.localToGlobal(Offset.zero) ?? Offset.zero;

    final localX = pos.dx - rootOffset.dx - pieceWidth / 2;
    final localY = pos.dy - rootOffset.dy - pieceHeight / 2;

    return Positioned(
      left: localX,
      top: localY,
      child: IgnorePointer(
        child: PieceWidget(
          piece: piece,
          cellSize: cellSize,
          opacity: 0.9,
        ),
      ),
    );
  }

  Widget _buildTray(double boardWidth) {
    return TrayWidget(
      tray: _controller.tray,
      boardWidth: boardWidth,
      onDragStart: _onDragStart,
      onDragUpdate: _onDragUpdate,
      onDragEnd: _onDragEnd,
    );
  }
}

class _ScoreBox extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _ScoreBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A3A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _GameOverDialog extends StatelessWidget {
  final int score;
  final int highScore;
  final VoidCallback onRestart;

  const _GameOverDialog({
    required this.score,
    required this.highScore,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final isHighScore = score >= highScore;
    return Dialog(
      backgroundColor: const Color(0xFF1A2A3A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isHighScore ? '🏆 New High Score!' : 'Game Over',
              style: TextStyle(
                color: isHighScore
                    ? const Color(0xFFF39C12)
                    : Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '$score',
              style: const TextStyle(
                color: Color(0xFF3498DB),
                fontSize: 56,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Best: $highScore',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRestart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3498DB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Play Again',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
