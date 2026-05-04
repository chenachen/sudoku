import 'package:hive_flutter/hive_flutter.dart';

import '../models/difficulty.dart';
import '../models/game_state.dart';
import '../models/stats.dart';

/// Persists application data using Hive.
///
/// We intentionally store JSON-friendly maps so that we don't depend on
/// generated Hive type adapters (no `build_runner`).
///
/// Boxes:
///   * `app` — single-key storage for `current_game` and `settings`.
///   * `records` — list-like of [GameRecord]s.
///   * `diy_presets` — list-like of [DifficultyConfig]s tagged as DIY.
class StorageService {
  StorageService._(this._app, this._records, this._presets);

  static const _appBoxName = 'sudoku_app';
  static const _recordsBoxName = 'sudoku_records';
  static const _presetsBoxName = 'sudoku_diy_presets';

  static const _kCurrentGame = 'current_game';
  static const _kSettings = 'settings';

  final Box _app;
  final Box _records;
  final Box _presets;

  static Future<StorageService> open() async {
    await Hive.initFlutter();
    final app = await Hive.openBox(_appBoxName);
    final records = await Hive.openBox(_recordsBoxName);
    final presets = await Hive.openBox(_presetsBoxName);
    return StorageService._(app, records, presets);
  }

  /// In-memory variant useful for tests. Pass already-opened boxes.
  static StorageService forTesting({
    required Box app,
    required Box records,
    required Box presets,
  }) =>
      StorageService._(app, records, presets);

  // -------- current game --------

  Future<void> saveCurrentGame(GameState? state) async {
    if (state == null) {
      await _app.delete(_kCurrentGame);
    } else {
      await _app.put(_kCurrentGame, state.toJson());
    }
  }

  GameState? loadCurrentGame() {
    final raw = _app.get(_kCurrentGame);
    if (raw == null) return null;
    try {
      return GameState.fromJson(Map<String, dynamic>.from(raw as Map));
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCurrentGame() => _app.delete(_kCurrentGame);

  // -------- records --------

  Future<void> addRecord(GameRecord record) async {
    await _records.add(record.toJson());
  }

  List<GameRecord> allRecords() {
    return _records.values
        .map((e) => GameRecord.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> clearRecords() => _records.clear();

  /// Aggregates statistics for every built-in difficulty plus DIY.
  List<DifficultyStats> aggregatedStats() {
    final all = allRecords();
    return Difficulty.values
        .map((d) => DifficultyStats.fromRecords(d, all))
        .toList();
  }

  // -------- settings --------

  Map<String, dynamic> loadSettings() {
    final raw = _app.get(_kSettings);
    if (raw == null) return <String, dynamic>{};
    return Map<String, dynamic>.from(raw as Map);
  }

  Future<void> saveSettings(Map<String, dynamic> settings) =>
      _app.put(_kSettings, settings);

  // -------- DIY presets --------

  List<DifficultyConfig> diyPresets() => _presets.values
      .map((e) => DifficultyConfig.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();

  Future<void> addDiyPreset(DifficultyConfig preset) async {
    await _presets.add(preset.toJson());
  }

  Future<void> deleteDiyPresetAt(int index) async {
    final key = _presets.keyAt(index);
    await _presets.delete(key);
  }
}
