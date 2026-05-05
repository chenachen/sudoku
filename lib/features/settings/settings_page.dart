import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/theme_controller.dart';
import 'settings_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.watch(themeControllerProvider);
    final themeCtrl = ref.read(themeControllerProvider.notifier);
    final settings = ref.watch(settingsControllerProvider);
    final settingsCtrl = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          // ── 亮暗模式 ────────────────────────────────────────────────────
          const ListTile(
            title: Text('亮暗模式'),
            subtitle: Text('选择浅色 / 深色 / 跟随系统'),
          ),
          RadioGroup<ThemeMode>(
            groupValue: themeSettings.mode,
            onChanged: (v) {
              if (v != null) themeCtrl.setMode(v);
            },
            child: const Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: Text('跟随系统'),
                  value: ThemeMode.system,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('浅色'),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('深色（暗夜模式）'),
                  value: ThemeMode.dark,
                ),
              ],
            ),
          ),
          const Divider(),
          // ── 主题配色 ────────────────────────────────────────────────────
          const ListTile(
            title: Text('主题配色'),
            subtitle: Text('选择你喜欢的颜色'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: builtInColorSchemes.map((scheme) {
                final selected = themeSettings.colorSchemeKey == scheme.key;
                return GestureDetector(
                  onTap: () => themeCtrl.setColorScheme(scheme.key),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: scheme.seed,
                          shape: BoxShape.circle,
                          border: selected
                              ? Border.all(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  width: 3,
                                )
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: scheme.seed.withValues(alpha: 0.45),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: selected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 22,
                              )
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        scheme.label,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(),
          // ── 游戏行为 ────────────────────────────────────────────────────
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
          SwitchListTile(
            title: const Text('置灰已用完的数字'),
            subtitle: const Text('数字键盘中已填满 9 个的数字将被禁用'),
            value: settings.dimCompletedNumbers,
            onChanged: settingsCtrl.setDimCompletedNumbers,
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
