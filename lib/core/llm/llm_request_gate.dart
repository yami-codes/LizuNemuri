import 'dart:async';
import 'dart:collection';

/// Global concurrency gate for LLM requests (player + background queue).
class LlmRequestGate {
  LlmRequestGate({this.maxConcurrent = 2})
      : assert(maxConcurrent > 0);

  final int maxConcurrent;
  int _active = 0;
  final Queue<Completer<void>> _waiters = Queue<Completer<void>>();

  int get activeCount => _active;
  int get waitingCount => _waiters.length;

  Future<T> run<T>(Future<T> Function() action) async {
    await _acquire();
    try {
      return await action();
    } finally {
      _release();
    }
  }

  Future<void> _acquire() async {
    if (_active < maxConcurrent) {
      _active++;
      return;
    }
    final waiter = Completer<void>();
    _waiters.add(waiter);
    await waiter.future;
  }

  void _release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeFirst().complete();
      return;
    }
    if (_active > 0) _active--;
  }
}
