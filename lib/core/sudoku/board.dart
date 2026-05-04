/// Pure-Dart Sudoku board representation with no Flutter dependencies.
///
/// A board is a flat list of 81 integers where 0 means empty and 1..9 are
/// digits. Helpers exist for row/col/box indexing.
class SudokuBoard {
  /// Length of one side of the standard board.
  static const int size = 9;

  /// Total number of cells (81).
  static const int cellCount = size * size;

  /// Returns the row index (0..8) of cell [index].
  static int rowOf(int index) => index ~/ size;

  /// Returns the column index (0..8) of cell [index].
  static int colOf(int index) => index % size;

  /// Returns the 3x3 box index (0..8) of cell [index].
  static int boxOf(int index) =>
      (rowOf(index) ~/ 3) * 3 + (colOf(index) ~/ 3);

  /// Returns the flat cell index for [row], [col].
  static int indexOf(int row, int col) => row * size + col;

  /// Cell indexes that share a row, column or box with [index] (excluding it).
  static List<int> peersOf(int index) {
    final r = rowOf(index);
    final c = colOf(index);
    final b = boxOf(index);
    final peers = <int>{};
    for (var i = 0; i < cellCount; i++) {
      if (i == index) continue;
      if (rowOf(i) == r || colOf(i) == c || boxOf(i) == b) {
        peers.add(i);
      }
    }
    return peers.toList(growable: false);
  }
}
