import 'package:flutter/material.dart';

import '../../../core/models/game_state.dart';
import '../../../core/sudoku/board.dart';
import '../../../core/sudoku/validator.dart';

/// Renders a 9x9 Sudoku board.
class BoardWidget extends StatelessWidget {
  const BoardWidget({
    super.key,
    required this.state,
    required this.selected,
    required this.onSelect,
    required this.highlightSameNumber,
    required this.autoCheck,
  });

  final GameState state;
  final int? selected;
  final ValueChanged<int> onSelect;
  final bool highlightSameNumber;
  final bool autoCheck;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selectedValue =
        (selected != null && state.current[selected!] != 0)
            ? state.current[selected!]
            : null;
    final conflicts =
        autoCheck ? SudokuValidator.conflicts(state.current) : <int>{};

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final size = constraints.biggest.shortestSide;
          final cell = size / 9;
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outline, width: 2),
              borderRadius: BorderRadius.circular(6),
              color: scheme.surface,
            ),
            child: Stack(
              children: [
                Column(
                  children: List.generate(9, (r) {
                    return Expanded(
                      child: Row(
                        children: List.generate(9, (c) {
                          final i = SudokuBoard.indexOf(r, c);
                          return _Cell(
                            index: i,
                            size: cell,
                            value: state.current[i],
                            given: state.isGiven(i),
                            notes: state.notes[i],
                            isSelected: selected == i,
                            isPeerOfSelected: selected != null &&
                                _isPeer(i, selected!),
                            isSameNumber: highlightSameNumber &&
                                selectedValue != null &&
                                state.current[i] == selectedValue,
                            isConflict: conflicts.contains(i),
                            onTap: () => onSelect(i),
                            scheme: scheme,
                          );
                        }),
                      ),
                    );
                  }),
                ),
                IgnorePointer(child: _GridLines(scheme: scheme)),
              ],
            ),
          );
        },
      ),
    );
  }

  static bool _isPeer(int a, int b) {
    if (a == b) return false;
    return SudokuBoard.rowOf(a) == SudokuBoard.rowOf(b) ||
        SudokuBoard.colOf(a) == SudokuBoard.colOf(b) ||
        SudokuBoard.boxOf(a) == SudokuBoard.boxOf(b);
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.index,
    required this.size,
    required this.value,
    required this.given,
    required this.notes,
    required this.isSelected,
    required this.isPeerOfSelected,
    required this.isSameNumber,
    required this.isConflict,
    required this.onTap,
    required this.scheme,
  });

  final int index;
  final double size;
  final int value;
  final bool given;
  final Set<int> notes;
  final bool isSelected;
  final bool isPeerOfSelected;
  final bool isSameNumber;
  final bool isConflict;
  final VoidCallback onTap;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    Color bg;
    if (isSelected) {
      bg = scheme.primaryContainer;
    } else if (isSameNumber) {
      bg = scheme.secondaryContainer;
    } else if (isPeerOfSelected) {
      bg = scheme.surfaceContainerHighest;
    } else {
      bg = scheme.surface;
    }
    final fg = isConflict
        ? scheme.error
        : (given ? scheme.onSurface : scheme.primary);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: scheme.outlineVariant, width: 0.5),
          ),
          alignment: Alignment.center,
          child: value != 0
              ? Text(
                  '$value',
                  style: TextStyle(
                    color: fg,
                    fontSize: size * 0.55,
                    fontWeight:
                        given ? FontWeight.w600 : FontWeight.w500,
                  ),
                )
              : _NotesGrid(notes: notes, size: size, color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _NotesGrid extends StatelessWidget {
  const _NotesGrid({required this.notes, required this.size, required this.color});

  final Set<int> notes;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(2),
      child: GridView.count(
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(9, (i) {
          final n = i + 1;
          return Center(
            child: Text(
              notes.contains(n) ? '$n' : '',
              style: TextStyle(
                fontSize: size * 0.18,
                color: color,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _GridLines extends StatelessWidget {
  const _GridLines({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(color: scheme.outline),
      size: Size.infinite,
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.color});
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    for (var i = 1; i < 3; i++) {
      final dx = size.width * i / 3;
      final dy = size.height * i / 3;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.color != color;
}
