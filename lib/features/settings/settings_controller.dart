import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/theme_controller.dart';

/// Player-facing toggles persisted in the settings map.
class AppSettings {
  const AppSettings({
    this.highlightSameNumber = true,
    this.autoCheck = true,
  });

  final bool highlightSameNumber;
  final bool autoCheck;

  AppSettings copyWith({bool? highlightSameNumber, bool? autoCheck}) =>
      AppSettings(
        highlightSameNumber: highlightSameNumber ?? this.highlightSameNumber,
        autoCheck: autoCheck ?? this.autoCheck,
      );
}

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final raw = ref.read(storageProvider).loadSettings();
    return AppSettings(
      highlightSameNumber: (raw['highlightSameNumber'] as bool?) ?? true,
      autoCheck: (raw['autoCheck'] as bool?) ?? true,
    );
  }

  Future<void> setHighlightSameNumber(bool v) async {
    state = state.copyWith(highlightSameNumber: v);
    await _persist();
  }

  Future<void> setAutoCheck(bool v) async {
    state = state.copyWith(autoCheck: v);
    await _persist();
  }

  Future<void> _persist() async {
    final storage = ref.read(storageProvider);
    final raw = Map<String, dynamic>.from(storage.loadSettings());
    raw['highlightSameNumber'] = state.highlightSameNumber;
    raw['autoCheck'] = state.autoCheck;
    await storage.saveSettings(raw);
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
