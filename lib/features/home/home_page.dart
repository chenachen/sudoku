import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/difficulty.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../diy/diy_page.dart';
import '../game/game_controller.dart';
import '../game/game_page.dart';
import '../settings/settings_page.dart';
import '../stats/stats_page.dart';
import '../theme/theme_controller.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  Future<void> _go(BuildContext context, Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageProvider);
    final saved = storage.loadCurrentGame();
    final hasSave = saved != null && saved.isActive;

    return Scaffold(
      appBar: AppBar(title: const Text('数独 Sudoku')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Icon(Icons.grid_4x4, size: 96),
            const SizedBox(height: 24),
            if (hasSave)
              FilledButton.icon(
                onPressed: () async {
                  await ref
                      .read(gameControllerProvider.notifier)
                      .resumeGame(saved);
                  if (context.mounted) {
                    await _go(context, const GamePage());
                  }
                },
                icon: const Icon(Icons.play_arrow),
                label: Text('继续游戏 (${saved.config.displayName})'),
              ),
            if (hasSave) const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () => _newGame(context, hasSave),
              icon: const Icon(Icons.add),
              label: const Text('新游戏'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _go(context, const DiyPage()),
              icon: const Icon(Icons.tune),
              label: const Text('DIY 模式'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _go(context, const StatsPage()),
              icon: const Icon(Icons.bar_chart),
              label: const Text('统计'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _go(context, const SettingsPage()),
              icon: const Icon(Icons.settings),
              label: const Text('设置'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _newGame(BuildContext context, bool hasSave) async {
    if (hasSave) {
      final ok = await showConfirmDialog(context,
          title: '开始新游戏', message: '当前进度将被覆盖，是否继续？');
      if (!ok) return;
    }
    if (!context.mounted) return;
    final difficulty = await showModalBottomSheet<DifficultyConfig>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: DifficultyConfig.builtIns
              .map((c) => ListTile(
                    title: Text(c.displayName),
                    subtitle: Text(
                        '挖空 ${c.blanks} · 提示 ${c.hintLimit} · 容错 ${c.mistakeLimit}'),
                    onTap: () => Navigator.of(ctx).pop(c),
                  ))
              .toList(),
        ),
      ),
    );
    if (difficulty == null || !context.mounted) return;
    final controller = ref.read(gameControllerProvider.notifier);
    await controller.startNewGame(difficulty);
    if (!context.mounted) return;
    await _go(context, const GamePage());
  }
}
