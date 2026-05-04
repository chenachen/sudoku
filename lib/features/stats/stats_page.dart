import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/difficulty.dart';
import '../../core/models/stats.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../theme/theme_controller.dart';

class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageProvider);
    final stats = storage.aggregatedStats();
    return Scaffold(
      appBar: AppBar(
        title: const Text('统计'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: '清空记录',
            onPressed: () async {
              final ok = await showConfirmDialog(context,
                  title: '清空记录', message: '该操作不可撤销。');
              if (ok) {
                await storage.clearRecords();
                if (mounted) setState(() {});
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: stats.map((s) => _StatCard(stats: s)).toList(),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stats});
  final DifficultyStats stats;

  String _fmt(int? ms) {
    if (ms == null) return '—';
    final s = ms ~/ 1000;
    final mm = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  String _label(Difficulty d) {
    switch (d) {
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

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_label(stats.difficulty),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _Metric(
                        title: '局数', value: '${stats.totalPlays}')),
                Expanded(
                    child: _Metric(
                        title: '胜利', value: '${stats.totalWins}')),
                Expanded(
                    child: _Metric(
                        title: '最快', value: _fmt(stats.bestMs))),
                Expanded(
                    child: _Metric(
                        title: '平均', value: _fmt(stats.averageMs))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.title, required this.value});
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w600)),
        Text(title,
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
