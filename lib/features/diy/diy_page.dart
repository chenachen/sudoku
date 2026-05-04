import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/difficulty.dart';
import '../game/game_controller.dart';
import '../game/game_page.dart';
import '../theme/theme_controller.dart';

class DiyPage extends ConsumerStatefulWidget {
  const DiyPage({super.key});

  @override
  ConsumerState<DiyPage> createState() => _DiyPageState();
}

class _DiyPageState extends ConsumerState<DiyPage> {
  double _blanks = 50;
  double _hints = 2;
  double _mistakes = 2;
  bool _autoCheck = true;
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  DifficultyConfig _build({String? name}) => DifficultyConfig(
        difficulty: Difficulty.diy,
        blanks: _blanks.round(),
        hintLimit: _hints.round(),
        mistakeLimit: _mistakes.round(),
        autoCheck: _autoCheck,
        name: name,
      );

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageProvider);
    final presets = storage.diyPresets();

    return Scaffold(
      appBar: AppBar(title: const Text('DIY 模式')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _slider('挖空数', _blanks, 17, 64,
              (v) => setState(() => _blanks = v)),
          _slider('提示次数', _hints, 0, 9,
              (v) => setState(() => _hints = v)),
          _slider('容错次数', _mistakes, 0, 9,
              (v) => setState(() => _mistakes = v)),
          SwitchListTile(
            title: const Text('启用自动检查'),
            value: _autoCheck,
            onChanged: (v) => setState(() => _autoCheck = v),
          ),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: '预设名称（可选）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('保存预设'),
                  onPressed: () async {
                    final name = _nameCtrl.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('请输入预设名称')));
                      return;
                    }
                    await storage.addDiyPreset(_build(name: name));
                    _nameCtrl.clear();
                    if (mounted) setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('开始'),
                  onPressed: () => _start(_build(name: '自定义')),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          Text('已保存预设',
              style: Theme.of(context).textTheme.titleMedium),
          if (presets.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('暂无预设'),
            )
          else
            ...List.generate(presets.length, (i) {
              final p = presets[i];
              return ListTile(
                title: Text(p.displayName),
                subtitle: Text(
                    '挖空 ${p.blanks} · 提示 ${p.hintLimit} · 容错 ${p.mistakeLimit}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await storage.deleteDiyPresetAt(i);
                    if (mounted) setState(() {});
                  },
                ),
                onTap: () => _start(p),
              );
            }),
        ],
      ),
    );
  }

  Widget _slider(String label, double v, double min, double max,
      ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${v.round()}'),
        Slider(
          value: v,
          min: min,
          max: max,
          divisions: (max - min).round(),
          label: '${v.round()}',
          onChanged: onChanged,
        ),
      ],
    );
  }

  Future<void> _start(DifficultyConfig config) async {
    final controller = ref.read(gameControllerProvider.notifier);
    await controller.startNewGame(config);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GamePage()));
  }
}
