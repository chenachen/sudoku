import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/core/sudoku/board.dart';
import 'package:sudoku/core/sudoku/generator.dart';
import 'package:sudoku/core/sudoku/solver.dart';
import 'package:sudoku/core/sudoku/validator.dart';

void main() {
  group('SudokuValidator', () {
    test('detects no conflicts on empty board', () {
      final b = List<int>.filled(81, 0);
      expect(SudokuValidator.conflicts(b), isEmpty);
    });

    test('detects row conflict', () {
      final b = List<int>.filled(81, 0);
      b[0] = 5;
      b[1] = 5;
      expect(SudokuValidator.conflicts(b), containsAll(<int>[0, 1]));
    });

    test('detects column conflict', () {
      final b = List<int>.filled(81, 0);
      b[0] = 7;
      b[9] = 7;
      expect(SudokuValidator.conflicts(b), containsAll(<int>[0, 9]));
    });

    test('detects 3x3 box conflict', () {
      final b = List<int>.filled(81, 0);
      b[0] = 3;
      b[10] = 3; // same 3x3 box
      expect(SudokuValidator.conflicts(b), containsAll(<int>[0, 10]));
    });
  });

  group('SudokuBoard', () {
    test('peers contain row, column and box mates', () {
      final peers = SudokuBoard.peersOf(0).toSet();
      // Row mates 1..8
      for (var i = 1; i < 9; i++) {
        expect(peers.contains(i), isTrue);
      }
      // Column mates 9, 18, ..., 72
      for (var i = 9; i < 81; i += 9) {
        expect(peers.contains(i), isTrue);
      }
      // Box mates 10, 11, 19, 20
      for (final i in [10, 11, 19, 20]) {
        expect(peers.contains(i), isTrue);
      }
      // 20 peers in total
      expect(peers.length, 20);
    });
  });

  group('SudokuSolver', () {
    test('counts a single solution for a known unique-solution puzzle', () {
      // A well-known minimal-clue puzzle (17 clues, unique solution).
      const raw =
          '000000010400000000020000000000050407008000300001090000300400200050100000000806000';
      final b = raw.split('').map(int.parse).toList();
      expect(SudokuSolver.countSolutions(b, stopAfter: 2), 1);
      expect(SudokuSolver.hasUniqueSolution(b), isTrue);
    });

    test('detects multiple solutions on under-constrained puzzle', () {
      final b = List<int>.filled(81, 0);
      // Empty board has many solutions.
      expect(SudokuSolver.countSolutions(b, stopAfter: 2), 2);
      expect(SudokuSolver.hasUniqueSolution(b), isFalse);
    });
  });

  group('SudokuGenerator', () {
    test('generates a solution that is valid and unique-solution puzzle',
        () {
      final gen = SudokuGenerator(random: Random(42));
      final r = gen.generate(blanks: 40);

      // Solution has no conflicts and no zeros.
      expect(r.solution.contains(0), isFalse);
      expect(SudokuValidator.conflicts(r.solution), isEmpty);

      // Puzzle has the requested number of blanks (or fewer if generator
      // could not safely remove that many while preserving uniqueness).
      final blankCount = r.puzzle.where((v) => v == 0).length;
      expect(blankCount, lessThanOrEqualTo(40));
      expect(blankCount, greaterThan(0));

      // Puzzle solution must be unique and equal to r.solution.
      expect(SudokuSolver.hasUniqueSolution(r.puzzle), isTrue);
      final solved = List<int>.filled(81, 0);
      SudokuSolver.hasSolution(r.puzzle, outSolved: solved);
      expect(solved, equals(r.solution));
    });
  });
}
