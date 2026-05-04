/// Difficulty level of a puzzle. The DIY level uses user-supplied parameters.
enum Difficulty { easy, medium, hard, expert, diy }

/// Configurable parameters for a difficulty preset.
///
/// Instances are immutable. Built-in presets are exposed as static getters.
class DifficultyConfig {
  const DifficultyConfig({
    required this.difficulty,
    required this.blanks,
    required this.hintLimit,
    required this.mistakeLimit,
    this.autoCheck = true,
    this.name,
  });

  final Difficulty difficulty;

  /// Number of blank cells in the generated puzzle.
  final int blanks;

  /// Maximum hints the player may use during a single game.
  final int hintLimit;

  /// Maximum mistakes (wrong commits) tolerated before the game is lost.
  final int mistakeLimit;

  /// When true, conflicts and wrong commits are highlighted automatically.
  final bool autoCheck;

  /// Optional display name for DIY presets.
  final String? name;

  static const easy = DifficultyConfig(
    difficulty: Difficulty.easy,
    blanks: 36,
    hintLimit: 5,
    mistakeLimit: 5,
  );
  static const medium = DifficultyConfig(
    difficulty: Difficulty.medium,
    blanks: 46,
    hintLimit: 3,
    mistakeLimit: 4,
  );
  static const hard = DifficultyConfig(
    difficulty: Difficulty.hard,
    blanks: 52,
    hintLimit: 2,
    mistakeLimit: 3,
  );
  static const expert = DifficultyConfig(
    difficulty: Difficulty.expert,
    blanks: 58,
    hintLimit: 1,
    mistakeLimit: 1,
  );

  static const builtIns = <DifficultyConfig>[easy, medium, hard, expert];

  static DifficultyConfig forBuiltIn(Difficulty d) {
    switch (d) {
      case Difficulty.easy:
        return easy;
      case Difficulty.medium:
        return medium;
      case Difficulty.hard:
        return hard;
      case Difficulty.expert:
        return expert;
      case Difficulty.diy:
        throw ArgumentError('DIY has no built-in config');
    }
  }

  Map<String, dynamic> toJson() => {
        'difficulty': difficulty.name,
        'blanks': blanks,
        'hintLimit': hintLimit,
        'mistakeLimit': mistakeLimit,
        'autoCheck': autoCheck,
        if (name != null) 'name': name,
      };

  factory DifficultyConfig.fromJson(Map json) => DifficultyConfig(
        difficulty: Difficulty.values
            .firstWhere((d) => d.name == json['difficulty'] as String),
        blanks: json['blanks'] as int,
        hintLimit: json['hintLimit'] as int,
        mistakeLimit: json['mistakeLimit'] as int,
        autoCheck: (json['autoCheck'] as bool?) ?? true,
        name: json['name'] as String?,
      );

  String get displayName {
    if (name != null) return name!;
    switch (difficulty) {
      case Difficulty.easy:
        return '简单';
      case Difficulty.medium:
        return '中级';
      case Difficulty.hard:
        return '高级';
      case Difficulty.expert:
        return '专家';
      case Difficulty.diy:
        return 'DIY';
    }
  }
}
