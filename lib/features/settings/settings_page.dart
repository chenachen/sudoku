import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/theme_controller.dart';
import 'settings_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    final themeCtrl = ref.read(themeControllerProvider.notifier);
    final settings = ref.watch(settingsControllerProvider);
    final settingsCtrl = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          const ListTile(
            title: Text('主题'),
            subtitle: Text('选择浅色 / 深色 / 跟随系统'),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('跟随系统'),
            value: ThemeMode.system,
            groupValue: theme,
            onChanged: (v) => themeCtrl.setMode(v!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('浅色'),
            value: ThemeMode.light,
            groupValue: theme,
            onChanged: (v) => themeCtrl.setMode(v!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('深色（暗夜模式）'),
            value: ThemeMode.dark,
            groupValue: theme,
            onChanged: (v) => themeCtrl.setMode(v!),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('高亮相同数字'),
            subtitle: const Text('选中含数字的格子时联动高亮'),
            value: settings.highlightSameNumber,
            onChanged: settingsCtrl.setHighlightSameNumber,
          ),
          SwitchListTile(
            title: const Text('自动检查错误'),
            subtitle: const Text('实时高亮冲突格并计入错误次数'),
            value: settings.autoCheck,
            onChanged: settingsCtrl.setAutoCheck,
          ),
          const Divider(),
          const ListTile(
            title: Text('关于'),
            subtitle: Text('Sudoku · Flutter · v1.0.0'),
          ),
        ],
      ),
    );
  }
}
