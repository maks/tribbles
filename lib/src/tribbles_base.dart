import 'dart:isolate';

/// Each Tribble represents a single Isolate.
class Tribble {
  static final List<Tribble> _tribbles = [];

  bool get alive => _isolate != null;

  Isolate? _isolate;
  final ReceivePort _responses = ReceivePort();

  /// Total number of currently running tribbles
  static int get count => _tribbles.length;

  /// Create a new tribble
  Tribble() {
    Isolate.spawn(_isolateHandler, _responses.sendPort)
        .then((i) => _isolate = i);
    _tribbles.add(this);
  }

  void kill() {
    _isolate?.kill();
    _isolate = null;
    _tribbles.remove(this);
  }

  static void killAll() {
    final old = List.from(_tribbles);
    _tribbles.clear();
    for (final t in old) {
      t._isolate?.kill();
    }
  }
}

void _isolateHandler(SendPort responsePort) {
  //TODO: use responsePort to send requestPort
}
