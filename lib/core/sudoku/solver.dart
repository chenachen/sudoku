import 'board.dart';

/// Backtracking Sudoku solver. Counts up to two solutions so it can be used to
/// verify uniqueness during puzzle generation.
class SudokuSolver {
  /// Returns true when [board] has at least one solution. If [outSolved] is
  /// supplied, it is populated with the first solution found (in-place copy).
  static bool hasSolution(List<int> board, {List<int>? outSolved}) {
    final work = List<int>.of(board);
    final ok = _solve(work, stopAfter: 1);
    if (ok && outSolved != null) {
      for (var i = 0; i < SudokuBoard.cellCount; i++) {
        outSolved[i] = work[i];
      }
    }
    return ok;
  }

  /// Returns true iff [board] has exactly one solution.
  static bool hasUniqueSolution(List<int> board) {
    final work = List<int>.of(board);
    final count = _countSolutions(work, stopAfter: 2);
    return count == 1;
  }

  /// Counts solutions up to [stopAfter]. Returns the count which is at most
  /// [stopAfter].
  static int countSolutions(List<int> board, {int stopAfter = 2}) {
    final work = List<int>.of(board);
    return _countSolutions(work, stopAfter: stopAfter);
  }

  // --- internal ---

  static bool _isSafe(List<int> b, int idx, int v) {
    final r = SudokuBoard.rowOf(idx);
    final c = SudokuBoard.colOf(idx);
    final br = (r ~/ 3) * 3;
    final bc = (c ~/ 3) * 3;
    for (var i = 0; i < 9; i++) {
      if (b[r * 9 + i] == v) return false;
      if (b[i * 9 + c] == v) return false;
      final boxIdx = (br + i ~/ 3) * 9 + (bc + i % 3);
      if (b[boxIdx] == v) return false;
    }
    return true;
  }

  static int _firstEmpty(List<int> b) {
    for (var i = 0; i < SudokuBoard.cellCount; i++) {
      if (b[i] == 0) return i;
    }
    return -1;
  }

  static bool _solve(List<int> b, {required int stopAfter}) {
    final empty = _firstEmpty(b);
    if (empty == -1) return true;
    for (var v = 1; v <= 9; v++) {
      if (_isSafe(b, empty, v)) {
        b[empty] = v;
        if (_solve(b, stopAfter: stopAfter)) return true;
        b[empty] = 0;
      }
    }
    return false;
  }

  static int _countSolutions(List<int> b, {required int stopAfter}) {
    final empty = _firstEmpty(b);
    if (empty == -1) return 1;
    var found = 0;
    for (var v = 1; v <= 9; v++) {
      if (_isSafe(b, empty, v)) {
        b[empty] = v;
        found += _countSolutions(b, stopAfter: stopAfter);
        b[empty] = 0;
        if (found >= stopAfter) return found;
      }
    }
    return found;
  }
}
