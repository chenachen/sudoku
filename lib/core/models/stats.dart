import 'difficulty.dart';

/// A single completed game record kept in the local statistics database.
class GameRecord {
  const GameRecord({
    required this.difficulty,
    required this.elapsedMs,
    required this.completedAt,
    required this.won,
  });

  final Difficulty difficulty;
  final int elapsedMs;
  final DateTime completedAt;
  final bool won;

  Map<String, dynamic> toJson() => {
        'difficulty': difficulty.name,
        'elapsedMs': elapsedMs,
        'completedAt': completedAt.toIso8601String(),
        'won': won,
      };

  factory GameRecord.fromJson(Map json) => GameRecord(
        difficulty: Difficulty.values
            .firstWhere((d) => d.name == json['difficulty'] as String),
        elapsedMs: json['elapsedMs'] as int,
        completedAt: DateTime.parse(json['completedAt'] as String),
        won: json['won'] as bool,
      );
}

/// Aggregated statistics for a single difficulty category.
class DifficultyStats {
  const DifficultyStats({
    required this.difficulty,
    required this.totalPlays,
    required this.totalWins,
    required this.bestMs,
    required this.averageMs,
  });

  final Difficulty difficulty;
  final int totalPlays;
  final int totalWins;

  /// Best (fastest) winning time in ms, or null if no wins recorded.
  final int? bestMs;

  /// Average winning time in ms, or null if no wins recorded.
  final int? averageMs;

  static DifficultyStats fromRecords(
      Difficulty d, Iterable<GameRecord> records) {
    final relevant = records.where((r) => r.difficulty == d).toList();
    final wins = relevant.where((r) => r.won).toList();
    int? best;
    int? avg;
    if (wins.isNotEmpty) {
      best = wins.map((r) => r.elapsedMs).reduce((a, b) => a < b ? a : b);
      avg = wins.map((r) => r.elapsedMs).fold<int>(0, (a, b) => a + b) ~/
          wins.length;
    }
    return DifficultyStats(
      difficulty: d,
      totalPlays: relevant.length,
      totalWins: wins.length,
      bestMs: best,
      averageMs: avg,
    );
  }
}
