import 'board.dart';

/// Validation utilities used by both the engine tests and the UI.
class SudokuValidator {
  /// Returns true if the value at [index] in [board] does not duplicate any
  /// other non-zero value in its row, column or box. An empty cell (0) is
  /// always considered non-conflicting.
  static bool isCellValid(List<int> board, int index) {
    final v = board[index];
    if (v == 0) return true;
    final r = SudokuBoard.rowOf(index);
    final c = SudokuBoard.colOf(index);
    final b = SudokuBoard.boxOf(index);
    for (var i = 0; i < SudokuBoard.cellCount; i++) {
      if (i == index) continue;
      if (board[i] != v) continue;
      if (SudokuBoard.rowOf(i) == r ||
          SudokuBoard.colOf(i) == c ||
          SudokuBoard.boxOf(i) == b) {
        return false;
      }
    }
    return true;
  }

  /// Returns the set of indices that are currently in conflict.
  static Set<int> conflicts(List<int> board) {
    final result = <int>{};
    for (var i = 0; i < SudokuBoard.cellCount; i++) {
      if (board[i] != 0 && !isCellValid(board, i)) {
        result.add(i);
      }
    }
    return result;
  }

  /// Returns true when [board] is fully filled and matches [solution].
  static bool isSolved(List<int> board, List<int> solution) {
    for (var i = 0; i < SudokuBoard.cellCount; i++) {
      if (board[i] == 0 || board[i] != solution[i]) return false;
    }
    return true;
  }
}
