const int kBoardSize = 10;
const int kEmptyCell = -1;

/// A connected run of this many same-coloured cells clears.
const int kClearThreshold = 3;

class Cell {
  int colorIndex; // -1 = empty
  bool isNew; // just placed (for the pop-in animation)
  bool isClearing; // being cleared (for the fade-out animation)

  Cell({this.colorIndex = kEmptyCell, this.isNew = false, this.isClearing = false});

  bool get isEmpty => colorIndex == kEmptyCell;

  Cell copy() => Cell(colorIndex: colorIndex, isNew: isNew, isClearing: isClearing);
}

class Board {
  final List<List<Cell>> cells;

  Board()
      : cells = List.generate(
          kBoardSize,
          (_) => List.generate(kBoardSize, (_) => Cell()),
        );

  Board.from(Board other)
      : cells = List.generate(
          kBoardSize,
          (r) => List.generate(kBoardSize, (c) => other.cells[r][c].copy()),
        );

  /// Build from a 10x10 colour-index grid (-1 = empty). Used by level presets.
  Board.fromGrid(List<List<int>> grid)
      : cells = List.generate(
          kBoardSize,
          (r) => List.generate(kBoardSize, (c) => Cell(colorIndex: grid[r][c])),
        );

  Cell get(int row, int col) => cells[row][col];

  bool isValidPosition(int row, int col) =>
      row >= 0 && row < kBoardSize && col >= 0 && col < kBoardSize;

  bool isCellEmpty(int row, int col) =>
      isValidPosition(row, col) && cells[row][col].isEmpty;

  void setCell(int row, int col, int colorIndex, {bool isNew = false}) {
    if (isValidPosition(row, col)) {
      cells[row][col].colorIndex = colorIndex;
      cells[row][col].isNew = isNew;
      cells[row][col].isClearing = false;
    }
  }

  void clearCell(int row, int col) {
    if (isValidPosition(row, col)) {
      cells[row][col].colorIndex = kEmptyCell;
      cells[row][col].isNew = false;
      cells[row][col].isClearing = false;
    }
  }

  void clearAll() {
    for (int r = 0; r < kBoardSize; r++) {
      for (int c = 0; c < kBoardSize; c++) {
        clearCell(r, c);
      }
    }
  }

  int get filledCount {
    int n = 0;
    for (final row in cells) {
      for (final cell in row) {
        if (!cell.isEmpty) n++;
      }
    }
    return n;
  }

  List<List<int>> toGrid() => List.generate(
        kBoardSize,
        (r) => List.generate(kBoardSize, (c) => cells[r][c].colorIndex),
      );

  /// All cells orthogonally connected to (startRow, startCol) sharing its colour.
  Set<int> findConnectedGroup(int startRow, int startCol) {
    final targetColor = cells[startRow][startCol].colorIndex;
    if (targetColor == kEmptyCell) return {};

    final visited = <int>{};
    final queue = <int>[startRow * kBoardSize + startCol];

    while (queue.isNotEmpty) {
      final id = queue.removeLast();
      if (visited.contains(id)) continue;
      final r = id ~/ kBoardSize;
      final c = id % kBoardSize;
      if (!isValidPosition(r, c)) continue;
      if (cells[r][c].colorIndex != targetColor) continue;

      visited.add(id);
      queue.add((r - 1) * kBoardSize + c);
      queue.add((r + 1) * kBoardSize + c);
      queue.add(r * kBoardSize + (c - 1));
      queue.add(r * kBoardSize + (c + 1));
    }
    return visited;
  }

  /// Groups of [kClearThreshold]+ same-coloured adjacent cells to be cleared.
  List<Set<int>> findClearableGroups() {
    final checked = <int>{};
    final groups = <Set<int>>[];

    for (int r = 0; r < kBoardSize; r++) {
      for (int c = 0; c < kBoardSize; c++) {
        final id = r * kBoardSize + c;
        if (!checked.contains(id) && !cells[r][c].isEmpty) {
          final group = findConnectedGroup(r, c);
          checked.addAll(group);
          if (group.length >= kClearThreshold) groups.add(group);
        }
      }
    }
    return groups;
  }

  void markClearing(Set<int> positions) {
    for (final id in positions) {
      cells[id ~/ kBoardSize][id % kBoardSize].isClearing = true;
    }
  }

  int clearGroups(List<Set<int>> groups) {
    int cleared = 0;
    for (final group in groups) {
      for (final id in group) {
        clearCell(id ~/ kBoardSize, id % kBoardSize);
        cleared++;
      }
    }
    return cleared;
  }

  void resetNewFlags() {
    for (final row in cells) {
      for (final cell in row) {
        cell.isNew = false;
      }
    }
  }
}
