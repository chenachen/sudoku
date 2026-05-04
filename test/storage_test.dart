import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sudoku/core/models/difficulty.dart';
import 'package:sudoku/core/models/game_state.dart';
import 'package:sudoku/core/models/stats.dart';
import 'package:sudoku/core/storage/storage_service.dart';

import 'dart:io';

Future<StorageService> _open() async {
  final tmp = await Directory.systemTemp.createTemp('sudoku-test-');
  Hive.init(tmp.path);
  final app = await Hive.openBox('app_${tmp.path.hashCode}');
  final records = await Hive.openBox('records_${tmp.path.hashCode}');
  final presets = await Hive.openBox('presets_${tmp.path.hashCode}');
  return StorageService.forTesting(app: app, records: records, presets: presets);
}

GameState _dummyGame(DifficultyConfig cfg) => GameState(
      config: cfg,
      puzzle: List<int>.filled(81, 0),
      solution: List<int>.generate(81, (i) => (i % 9) + 1),
      current: List<int>.filled(81, 0),
      notes: List.generate(81, (_) => <int>{}),
      elapsedMs: 1234,
      hintsUsed: 0,
      mistakes: 0,
      completed: false,
      failed: false,
      startedAt: DateTime(2024, 1, 1),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('saveCurrentGame persists round-trip', () async {
    final svc = await _open();
    final game = _dummyGame(DifficultyConfig.easy);
    await svc.saveCurrentGame(game);
    final loaded = svc.loadCurrentGame()!;
    expect(loaded.config.difficulty, Difficulty.easy);
    expect(loaded.elapsedMs, 1234);
    expect(loaded.solution.length, 81);
  });

  test('clearCurrentGame removes save', () async {
    final svc = await _open();
    await svc.saveCurrentGame(_dummyGame(DifficultyConfig.easy));
    expect(svc.loadCurrentGame(), isNotNull);
    await svc.clearCurrentGame();
    expect(svc.loadCurrentGame(), isNull);
  });

  test('records aggregation: best and average', () async {
    final svc = await _open();
    await svc.addRecord(GameRecord(
        difficulty: Difficulty.easy,
        elapsedMs: 60000,
        completedAt: DateTime.now(),
        won: true));
    await svc.addRecord(GameRecord(
        difficulty: Difficulty.easy,
        elapsedMs: 120000,
        completedAt: DateTime.now(),
        won: true));
    await svc.addRecord(GameRecord(
        difficulty: Difficulty.easy,
        elapsedMs: 30000,
        completedAt: DateTime.now(),
        won: false)); // ignored for best/avg

    final stats = svc.aggregatedStats();
    final easy = stats.firstWhere((s) => s.difficulty == Difficulty.easy);
    expect(easy.totalPlays, 3);
    expect(easy.totalWins, 2);
    expect(easy.bestMs, 60000);
    expect(easy.averageMs, 90000);
  });

  test('DIY presets can be saved and deleted', () async {
    final svc = await _open();
    expect(svc.diyPresets(), isEmpty);
    await svc.addDiyPreset(const DifficultyConfig(
      difficulty: Difficulty.diy,
      blanks: 60,
      hintLimit: 0,
      mistakeLimit: 0,
      autoCheck: false,
      name: 'extreme',
    ));
    expect(svc.diyPresets(), hasLength(1));
    await svc.deleteDiyPresetAt(0);
    expect(svc.diyPresets(), isEmpty);
  });
}
