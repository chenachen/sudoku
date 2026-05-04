import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/core/timer/game_timer.dart';

void main() {
  test('starts and accumulates time', () async {
    final t = GameTimer();
    expect(t.elapsedMs, 0);
    t.start();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final mid = t.elapsedMs;
    expect(mid, greaterThan(0));
    await t.dispose();
  });

  test('pause stops time accumulation', () async {
    final t = GameTimer();
    t.start();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    t.pause();
    final paused = t.elapsedMs;
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(t.elapsedMs, paused,
        reason: 'Timer must not advance while paused');
    await t.dispose();
  });

  test('resume continues accumulating from paused total', () async {
    final t = GameTimer();
    t.start();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    t.pause();
    final paused = t.elapsedMs;
    t.start();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(t.elapsedMs, greaterThan(paused));
    await t.dispose();
  });

  test('honours initialMs', () async {
    final t = GameTimer(initialMs: 5000);
    expect(t.elapsedMs, 5000);
    t.start();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(t.elapsedMs, greaterThan(5000));
    await t.dispose();
  });
}
