import 'dart:math';

import 'board.dart';
import 'solver.dart';

/// Generates Sudoku puzzles with a guaranteed unique solution.
///
/// Strategy:
///   1. Build a fully solved 9x9 board by random backtracking.
///   2. Iteratively remove cells; after each removal, ensure the puzzle still
///      has a unique solution by counting solutions (early-exiting after 2).
///   3. Stop when the requested number of [blanks] have been removed or no more
///      cells can be safely removed without breaking uniqueness.
class SudokuGenerator {
  SudokuGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Generates a `(puzzle, solution)` pair with the requested number of
  /// blank cells. The puzzle list is a copy of the solution with [blanks]
  /// indices set to 0 while preserving a unique solution.
  ({List<int> puzzle, List<int> solution}) generate({required int blanks}) {
    assert(blanks >= 0 && blanks <= 64,
        'blanks must be in [0, 64] for a sane puzzle');
    final solution = List<int>.filled(SudokuBoard.cellCount, 0);
    _fill(solution);
    final puzzle = List<int>.of(solution);

    final indices = List<int>.generate(SudokuBoard.cellCount, (i) => i)
      ..shuffle(_random);

    var removed = 0;
    for (final i in indices) {
      if (removed >= blanks) break;
      final backup = puzzle[i];
      if (backup == 0) continue;
      puzzle[i] = 0;
      // Ensure puzzle still has a unique solution.
      if (!SudokuSolver.hasUniqueSolution(puzzle)) {
        puzzle[i] = backup; // revert
      } else {
        removed++;
      }
    }
    return (puzzle: puzzle, solution: solution);
  }

  /// Randomly fills an empty board using shuffled candidate order.
  bool _fill(List<int> board) {
    final empty = _findEmpty(board);
    if (empty == -1) return true;
    final digits = [1, 2, 3, 4, 5, 6, 7, 8, 9]..shuffle(_random);
    for (final v in digits) {
      if (_isSafe(board, empty, v)) {
        board[empty] = v;
        if (_fill(board)) return true;
        board[empty] = 0;
      }
    }
    return false;
  }

  static int _findEmpty(List<int> b) {
    for (var i = 0; i < SudokuBoard.cellCount; i++) {
      if (b[i] == 0) return i;
    }
    return -1;
  }

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
}
