const int kBoardSize = 10;
const int kEmptyCell = -1;

class Cell {
  int colorIndex; // -1 = empty
  bool isNew; // just placed (for animation)
  bool isClearing; // being cleared (for animation)

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

  // Find all connected cells with the same color starting from (row, col)
  Set<String> findConnectedGroup(int startRow, int startCol) {
    final targetColor = cells[startRow][startCol].colorIndex;
    if (targetColor == kEmptyCell) return {};

    final visited = <String>{};
    final queue = <List<int>>[[startRow, startCol]];

    while (queue.isNotEmpty) {
      final pos = queue.removeAt(0);
      final r = pos[0];
      final c = pos[1];
      final key = '$r,$c';

      if (visited.contains(key)) continue;
      if (!isValidPosition(r, c)) continue;
      if (cells[r][c].colorIndex != targetColor) continue;

      visited.add(key);

      queue.add([r - 1, c]);
      queue.add([r + 1, c]);
      queue.add([r, c - 1]);
      queue.add([r, c + 1]);
    }

    return visited;
  }

  // Find all groups of 3+ same-colored adjacent cells that should be cleared
  List<Set<String>> findClearableGroups() {
    final checked = <String>{};
    final groups = <Set<String>>[];

    for (int r = 0; r < kBoardSize; r++) {
      for (int c = 0; c < kBoardSize; c++) {
        final key = '$r,$c';
        if (!checked.contains(key) && !cells[r][c].isEmpty) {
          final group = findConnectedGroup(r, c);
          for (final k in group) {
            checked.add(k);
          }
          if (group.length >= 3) {
            groups.add(group);
          }
        }
      }
    }

    return groups;
  }

  // Mark cells as clearing
  void markClearing(Set<String> positions) {
    for (final key in positions) {
      final parts = key.split(',');
      final r = int.parse(parts[0]);
      final c = int.parse(parts[1]);
      cells[r][c].isClearing = true;
    }
  }

  // Execute the clear
  int clearGroups(List<Set<String>> groups) {
    int cleared = 0;
    for (final group in groups) {
      for (final key in group) {
        final parts = key.split(',');
        final r = int.parse(parts[0]);
        final c = int.parse(parts[1]);
        clearCell(r, c);
        cleared++;
      }
    }
    return cleared;
  }

  void resetNewFlags() {
    for (int r = 0; r < kBoardSize; r++) {
      for (int c = 0; c < kBoardSize; c++) {
        cells[r][c].isNew = false;
      }
    }
  }
}
