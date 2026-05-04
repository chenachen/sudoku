import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/storage_service.dart';

final storageProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('overridden in main()');
});

class ThemeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final settings = ref.read(storageProvider).loadSettings();
    final raw = settings['themeMode'] as String?;
    return _parse(raw) ?? ThemeMode.system;
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final storage = ref.read(storageProvider);
    final settings = Map<String, dynamic>.from(storage.loadSettings());
    settings['themeMode'] = mode.name;
    await storage.saveSettings(settings);
  }

  ThemeMode? _parse(String? raw) {
    if (raw == null) return null;
    return ThemeMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => ThemeMode.system,
    );
  }
}

final themeControllerProvider =
    NotifierProvider<ThemeController, ThemeMode>(ThemeController.new);

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF3F6EE3),
      brightness: Brightness.light,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF3F6EE3),
      brightness: Brightness.dark,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
    );
  }
}
