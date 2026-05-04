import 'dart:async';

/// Pause/resume capable timer with millisecond precision.
///
/// The timer wraps a [Stopwatch] and adds a 1Hz heartbeat that listeners can
/// subscribe to via [stream]. The timer can be initialized with a previously
/// accumulated [initialMs] when restoring a saved game.
class GameTimer {
  GameTimer({int initialMs = 0})
      : _accumulatedMs = initialMs,
        _watch = Stopwatch();

  final Stopwatch _watch;
  int _accumulatedMs;
  Timer? _ticker;
  final _controller = StreamController<int>.broadcast();

  /// Total elapsed time in milliseconds (paused intervals not included).
  int get elapsedMs => _accumulatedMs + _watch.elapsedMilliseconds;

  /// 1Hz stream of [elapsedMs]. Useful for UI binding.
  Stream<int> get stream => _controller.stream;

  bool get isRunning => _watch.isRunning;

  void start() {
    if (_watch.isRunning) return;
    _watch.start();
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      _controller.add(elapsedMs);
    });
    _controller.add(elapsedMs);
  }

  void pause() {
    if (!_watch.isRunning) return;
    _watch.stop();
    _accumulatedMs += _watch.elapsedMilliseconds;
    _watch.reset();
    _controller.add(elapsedMs);
  }

  /// Pauses if running and returns the new total in ms.
  int snapshot() {
    if (_watch.isRunning) {
      _accumulatedMs += _watch.elapsedMilliseconds;
      _watch.reset();
      _watch.start();
    }
    return elapsedMs;
  }

  Future<void> dispose() async {
    _ticker?.cancel();
    _ticker = null;
    _watch.stop();
    await _controller.close();
  }
}
