import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/game_state.dart';
import '../settings/settings_controller.dart';
import 'game_controller.dart';
import 'widgets/action_bar.dart';
import 'widgets/board_widget.dart';
import 'widgets/number_pad.dart';

class GamePage extends ConsumerStatefulWidget {
  const GamePage({super.key});

  @override
  ConsumerState<GamePage> createState() => _GamePageState();
}

class _GamePageState extends ConsumerState<GamePage>
    with WidgetsBindingObserver {
  int? _selected;
  bool _notesMode = false;
  int _displayMs = 0;
  StreamSubscription<int>? _tickSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final controller = ref.read(gameControllerProvider.notifier);
    _tickSub = controller.tickStream?.listen((ms) {
      if (mounted) setState(() => _displayMs = ms);
    });
    final s = ref.read(gameControllerProvider);
    if (s != null) _displayMs = s.elapsedMs;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      ref.read(gameControllerProvider.notifier).snapshotAndPersist();
    }
  }

  @override
  void dispose() {
    _tickSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    ref.read(gameControllerProvider.notifier).snapshotAndPersist();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameControllerProvider);
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);

    if (game == null) {
      return const Scaffold(body: Center(child: Text('没有进行中的游戏')));
    }

    // React to win/loss with a dialog.
    ref.listen<GameState?>(gameControllerProvider, (prev, next) {
      if (next == null) return;
      if (next.completed && (prev == null || !prev.completed)) {
        _showResultDialog(true, next.elapsedMs);
      } else if (next.failed && (prev == null || !prev.failed)) {
        _showResultDialog(false, next.elapsedMs);
      }
    });

    final paused = controller.isPaused && game.isActive;

    return Scaffold(
      appBar: AppBar(
        title: Text('${game.config.displayName} · ${_fmt(_displayMs)}'),
        actions: [
          IconButton(
            tooltip: paused ? '继续' : '暂停',
            icon: Icon(paused ? Icons.play_arrow : Icons.pause),
            onPressed: () {
              controller.togglePause();
              setState(() {});
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('错误 ${game.mistakes}/${game.config.mistakeLimit}'),
                  Text('提示 ${game.hintsUsed}/${game.config.hintLimit}'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  BoardWidget(
                    state: game,
                    selected: _selected,
                    onSelect: (i) => setState(() => _selected = i),
                    highlightSameNumber: settings.highlightSameNumber,
                    autoCheck: settings.autoCheck && game.config.autoCheck,
                  ),
                  if (paused)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.6),
                        alignment: Alignment.center,
                        child: const Text('已暂停',
                            style: TextStyle(
                                color: Colors.white, fontSize: 28)),
                      ),
                    ),
                ],
              ),
            ),
            const Spacer(),
            ActionBar(
              notesMode: _notesMode,
              onToggleNotes: () => setState(() => _notesMode = !_notesMode),
              onUndo: () => controller.undo(),
              onErase: () {
                if (_selected != null) {
                  controller.setValue(_selected!, 0,
                      inNotesMode: false);
                }
              },
              onHint: () {
                if (_selected != null) controller.useHint(_selected!);
              },
              hintsLeft: game.config.hintLimit - game.hintsUsed,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: NumberPad(
                board: game.current,
                notesMode: _notesMode,
                onTap: (n) {
                  if (_selected != null) {
                    controller.setValue(_selected!, n,
                        inNotesMode: _notesMode);
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showResultDialog(bool won, int ms) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(won ? '🎉 恭喜过关' : '😞 游戏失败'),
        content: Text(won ? '用时 ${_fmt(ms)}' : '你已用尽所有容错次数。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('返回首页'),
          ),
        ],
      ),
    );
  }

  static String _fmt(int ms) {
    final s = ms ~/ 1000;
    final mm = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}
