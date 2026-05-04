import 'package:flutter/material.dart';

import '../../../core/sudoku/board.dart';

/// 1..9 number pad. Buttons for fully-placed digits (count == 9) are dimmed.
class NumberPad extends StatelessWidget {
  const NumberPad({
    super.key,
    required this.board,
    required this.onTap,
    required this.notesMode,
  });

  final List<int> board;
  final ValueChanged<int> onTap;
  final bool notesMode;

  @override
  Widget build(BuildContext context) {
    final counts = List<int>.filled(10, 0);
    for (var i = 0; i < SudokuBoard.cellCount; i++) {
      counts[board[i]]++;
    }
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(9, (i) {
        final n = i + 1;
        final completed = counts[n] >= 9;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: notesMode
                    ? theme.colorScheme.secondaryContainer
                    : theme.colorScheme.surfaceContainerHigh,
                foregroundColor: completed
                    ? theme.disabledColor
                    : theme.colorScheme.onSurface,
              ),
              onPressed: completed ? null : () => onTap(n),
              child: Text(
                '$n',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        );
      }),
    );
  }
}
