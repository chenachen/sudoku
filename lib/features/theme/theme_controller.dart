import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/storage_service.dart';

final storageProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('overridden in main()');
});

// ---------------------------------------------------------------------------
// Color schemes
// ---------------------------------------------------------------------------

class AppColorScheme {
  const AppColorScheme(
      {required this.key, required this.label, required this.seed});
  final String key;
  final String label;
  final Color seed;
}

const builtInColorSchemes = <AppColorScheme>[
  AppColorScheme(key: 'ocean', label: '海洋蓝', seed: Color(0xFF3F6EE3)),
  AppColorScheme(key: 'teal', label: '松石绿', seed: Color(0xFF00897B)),
  AppColorScheme(key: 'forest', label: '森林绿', seed: Color(0xFF388E3C)),
  AppColorScheme(key: 'violet', label: '薰衣草紫', seed: Color(0xFF7B1FA2)),
  AppColorScheme(key: 'rose', label: '玫瑰红', seed: Color(0xFFC62828)),
  AppColorScheme(key: 'sunset', label: '落日橙', seed: Color(0xFFE64A19)),
  AppColorScheme(key: 'indigo', label: '靛蓝', seed: Color(0xFF283593)),
  AppColorScheme(key: 'sakura', label: '樱花粉', seed: Color(0xFFAD1457)),
];

// ---------------------------------------------------------------------------
// Theme settings state
// ---------------------------------------------------------------------------

class ThemeSettings {
  const ThemeSettings({
    this.mode = ThemeMode.system,
    this.colorSchemeKey = 'ocean',
  });

  final ThemeMode mode;
  final String colorSchemeKey;

  AppColorScheme get colorScheme => builtInColorSchemes.firstWhere(
        (s) => s.key == colorSchemeKey,
        orElse: () => builtInColorSchemes.first,
      );

  ThemeSettings copyWith({ThemeMode? mode, String? colorSchemeKey}) =>
      ThemeSettings(
        mode: mode ?? this.mode,
        colorSchemeKey: colorSchemeKey ?? this.colorSchemeKey,
      );
}

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

class ThemeController extends Notifier<ThemeSettings> {
  @override
  ThemeSettings build() {
    final raw = ref.read(storageProvider).loadSettings();
    final rawMode = raw['themeMode'] as String?;
    final rawScheme = raw['colorSchemeKey'] as String?;
    return ThemeSettings(
      mode: _parseMode(rawMode) ?? ThemeMode.system,
      colorSchemeKey: rawScheme ?? 'ocean',
    );
  }

  Future<void> setMode(ThemeMode mode) async {
    state = state.copyWith(mode: mode);
    await _persist();
  }

  Future<void> setColorScheme(String key) async {
    state = state.copyWith(colorSchemeKey: key);
    await _persist();
  }

  Future<void> _persist() async {
    final storage = ref.read(storageProvider);
    final raw = Map<String, dynamic>.from(storage.loadSettings());
    raw['themeMode'] = state.mode.name;
    raw['colorSchemeKey'] = state.colorSchemeKey;
    await storage.saveSettings(raw);
  }

  ThemeMode? _parseMode(String? raw) {
    if (raw == null) return null;
    return ThemeMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => ThemeMode.system,
    );
  }
}

final themeControllerProvider =
    NotifierProvider<ThemeController, ThemeSettings>(ThemeController.new);

// ---------------------------------------------------------------------------
// AppTheme builder
// ---------------------------------------------------------------------------

class AppTheme {
  static ThemeData light([Color seed = const Color(0xFF3F6EE3)]) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
    );
  }

  static ThemeData dark([Color seed = const Color(0xFF3F6EE3)]) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
    );
  }
}
