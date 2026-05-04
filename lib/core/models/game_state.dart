import 'difficulty.dart';

/// Per-cell user notes (1..9). Empty when no notes set.
typedef Notes = Set<int>;

/// Immutable snapshot of an in-progress or finished Sudoku game.
class GameState {
  GameState({
    required this.config,
    required this.puzzle,
    required this.solution,
    required this.current,
    required this.notes,
    required this.elapsedMs,
    required this.hintsUsed,
    required this.mistakes,
    required this.completed,
    required this.failed,
    required this.startedAt,
  });

  /// Difficulty/DIY parameters this game was started with.
  final DifficultyConfig config;

  /// The original puzzle (0 marks blanks).
  final List<int> puzzle;

  /// The unique solution.
  final List<int> solution;

  /// Player's current board (a mix of givens, correctly placed values and
  /// in-progress guesses).
  final List<int> current;

  /// Per-cell pencil-marks. `notes[i]` lists candidate digits for cell i.
  final List<Notes> notes;

  /// Accumulated playing time in milliseconds (excludes paused periods).
  final int elapsedMs;

  /// Hints the player has consumed so far.
  final int hintsUsed;

  /// Mistakes the player has made so far.
  final int mistakes;

  /// True when the player has fully solved the puzzle.
  final bool completed;

  /// True when [mistakes] exceeds [DifficultyConfig.mistakeLimit].
  final bool failed;

  /// Timestamp the game was first started.
  final DateTime startedAt;

  /// Whether the cell at [index] was a given (cannot be edited).
  bool isGiven(int index) => puzzle[index] != 0;

  /// True if the game is still in progress (not yet completed nor failed).
  bool get isActive => !completed && !failed;

  GameState copyWith({
    DifficultyConfig? config,
    List<int>? puzzle,
    List<int>? solution,
    List<int>? current,
    List<Notes>? notes,
    int? elapsedMs,
    int? hintsUsed,
    int? mistakes,
    bool? completed,
    bool? failed,
    DateTime? startedAt,
  }) {
    return GameState(
      config: config ?? this.config,
      puzzle: puzzle ?? this.puzzle,
      solution: solution ?? this.solution,
      current: current ?? this.current,
      notes: notes ?? this.notes,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      mistakes: mistakes ?? this.mistakes,
      completed: completed ?? this.completed,
      failed: failed ?? this.failed,
      startedAt: startedAt ?? this.startedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'config': config.toJson(),
        'puzzle': puzzle,
        'solution': solution,
        'current': current,
        'notes': notes.map((n) => n.toList()).toList(),
        'elapsedMs': elapsedMs,
        'hintsUsed': hintsUsed,
        'mistakes': mistakes,
        'completed': completed,
        'failed': failed,
        'startedAt': startedAt.toIso8601String(),
      };

  factory GameState.fromJson(Map json) => GameState(
        config: DifficultyConfig.fromJson(json['config'] as Map),
        puzzle: List<int>.from(json['puzzle'] as List),
        solution: List<int>.from(json['solution'] as List),
        current: List<int>.from(json['current'] as List),
        notes: (json['notes'] as List)
            .map<Notes>((n) => Set<int>.from(n as List))
            .toList(),
        elapsedMs: json['elapsedMs'] as int,
        hintsUsed: json['hintsUsed'] as int,
        mistakes: json['mistakes'] as int,
        completed: json['completed'] as bool,
        failed: json['failed'] as bool,
        startedAt: DateTime.parse(json['startedAt'] as String),
      );
}
