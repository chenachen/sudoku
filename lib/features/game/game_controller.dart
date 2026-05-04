import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/difficulty.dart';
import '../../core/models/game_state.dart';
import '../../core/models/stats.dart';
import '../../core/sudoku/board.dart';
import '../../core/sudoku/generator.dart';
import '../../core/sudoku/validator.dart';
import '../../core/timer/game_timer.dart';
import '../theme/theme_controller.dart';

/// Holds one move in the undo stack.
class _Move {
  _Move({
    required this.index,
    required this.previousValue,
    required this.previousNotes,
    required this.previousMistakes,
    required this.previousHints,
  });

  final int index;
  final int previousValue;
  final Set<int> previousNotes;
  final int previousMistakes;
  final int previousHints;
}

class GameController extends Notifier<GameState?> {
  GameTimer? _timer;
  final List<_Move> _undoStack = [];

  /// Convenience getter so widgets can subscribe to the timer's tick stream.
  Stream<int>? get tickStream => _timer?.stream;

  @override
  GameState? build() {
    ref.onDispose(() {
      _timer?.dispose();
    });
    return null;
  }

  /// Generates a brand-new game with [config] and starts the timer.
  Future<void> startNewGame(DifficultyConfig config) async {
    final gen = SudokuGenerator();
    final result = gen.generate(blanks: config.blanks);
    final game = GameState(
      config: config,
      puzzle: result.puzzle,
      solution: result.solution,
      current: List<int>.of(result.puzzle),
      notes: List.generate(SudokuBoard.cellCount, (_) => <int>{}),
      elapsedMs: 0,
      hintsUsed: 0,
      mistakes: 0,
      completed: false,
      failed: false,
      startedAt: DateTime.now(),
    );
    _resetTimer(0);
    _undoStack.clear();
    state = game;
    _timer!.start();
    await _persist();
  }

  /// Restores a previously saved game and resumes the timer.
  Future<void> resumeGame(GameState game) async {
    _resetTimer(game.elapsedMs);
    _undoStack.clear();
    state = game;
    if (game.isActive) _timer!.start();
  }

  /// Toggles between paused/running.
  void togglePause() {
    final t = _timer;
    if (t == null) return;
    if (t.isRunning) {
      t.pause();
    } else if (state?.isActive ?? false) {
      t.start();
    }
    _flushTimerToState();
  }

  bool get isPaused => !(_timer?.isRunning ?? false);

  /// Commits a digit into [index]. Wrong commits increase the mistake count
  /// when auto-check is enabled.
  Future<void> setValue(int index, int value, {required bool inNotesMode}) async {
    final s = state;
    if (s == null || !s.isActive) return;
    if (s.isGiven(index)) return;
    if (value < 0 || value > 9) return;

    _flushTimerToState();
    final current = List<int>.of(state!.current);
    final notes = state!.notes.map((n) => Set<int>.of(n)).toList();
    final move = _Move(
      index: index,
      previousValue: current[index],
      previousNotes: Set<int>.of(notes[index]),
      previousMistakes: state!.mistakes,
      previousHints: state!.hintsUsed,
    );

    var mistakes = state!.mistakes;

    if (value == 0) {
      // erase
      current[index] = 0;
      notes[index] = <int>{};
    } else if (inNotesMode) {
      current[index] = 0;
      if (notes[index].contains(value)) {
        notes[index].remove(value);
      } else {
        notes[index].add(value);
      }
    } else {
      current[index] = value;
      notes[index] = <int>{};
      // Clear that candidate from peers' notes
      for (final p in SudokuBoard.peersOf(index)) {
        notes[p].remove(value);
      }
      if (state!.config.autoCheck && value != state!.solution[index]) {
        mistakes++;
      }
    }

    _undoStack.add(move);

    final updated = state!.copyWith(
      current: current,
      notes: notes,
      mistakes: mistakes,
    );

    final completed =
        SudokuValidator.isSolved(updated.current, updated.solution);
    final failed = !completed && mistakes > updated.config.mistakeLimit;

    state = updated.copyWith(completed: completed, failed: failed);
    if (completed || failed) {
      _timer?.pause();
      await _onFinished();
    }
    await _persist();
  }

  /// Reveals the correct value for [index] using a hint, if available.
  Future<void> useHint(int index) async {
    final s = state;
    if (s == null || !s.isActive) return;
    if (s.isGiven(index)) return;
    if (s.hintsUsed >= s.config.hintLimit) return;
    _flushTimerToState();
    final current = List<int>.of(state!.current);
    final notes = state!.notes.map((n) => Set<int>.of(n)).toList();
    _undoStack.add(_Move(
      index: index,
      previousValue: current[index],
      previousNotes: Set<int>.of(notes[index]),
      previousMistakes: state!.mistakes,
      previousHints: state!.hintsUsed,
    ));
    current[index] = state!.solution[index];
    notes[index] = <int>{};
    for (final p in SudokuBoard.peersOf(index)) {
      notes[p].remove(state!.solution[index]);
    }
    final updated = state!.copyWith(
      current: current,
      notes: notes,
      hintsUsed: state!.hintsUsed + 1,
    );
    final completed =
        SudokuValidator.isSolved(updated.current, updated.solution);
    state = updated.copyWith(completed: completed);
    if (completed) {
      _timer?.pause();
      await _onFinished();
    }
    await _persist();
  }

  /// Undoes the most recent edit.
  Future<void> undo() async {
    final s = state;
    if (s == null || _undoStack.isEmpty || !s.isActive) return;
    _flushTimerToState();
    final move = _undoStack.removeLast();
    final current = List<int>.of(state!.current);
    final notes = state!.notes.map((n) => Set<int>.of(n)).toList();
    current[move.index] = move.previousValue;
    notes[move.index] = move.previousNotes;
    state = state!.copyWith(
      current: current,
      notes: notes,
      mistakes: move.previousMistakes,
      hintsUsed: move.previousHints,
    );
    await _persist();
  }

  /// Drops the active game (e.g. user starts new mid-game).
  Future<void> abandon() async {
    _timer?.pause();
    state = null;
    _undoStack.clear();
    await ref.read(storageProvider).clearCurrentGame();
  }

  /// Records the result and clears persistent save (if won/lost).
  Future<void> _onFinished() async {
    final s = state;
    if (s == null) return;
    final storage = ref.read(storageProvider);
    await storage.addRecord(GameRecord(
      difficulty: s.config.difficulty,
      elapsedMs: s.elapsedMs,
      completedAt: DateTime.now(),
      won: s.completed,
    ));
    await storage.clearCurrentGame();
  }

  void _flushTimerToState() {
    final t = _timer;
    final s = state;
    if (t == null || s == null) return;
    state = s.copyWith(elapsedMs: t.elapsedMs);
  }

  Future<void> _persist() async {
    final s = state;
    if (s == null) return;
    if (s.isActive) {
      await ref.read(storageProvider).saveCurrentGame(s);
    }
  }

  void _resetTimer(int initialMs) {
    _timer?.dispose();
    _timer = GameTimer(initialMs: initialMs);
  }

  /// Should be called by the UI when leaving the game page.
  Future<void> snapshotAndPersist() async {
    _flushTimerToState();
    _timer?.pause();
    await _persist();
  }
}

final gameControllerProvider =
    NotifierProvider<GameController, GameState?>(GameController.new);
