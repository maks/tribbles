/// Each Tribble represents a single Isolate.
class Tribble {
  static final List<Tribble> _tribbles = [];

  bool alive = true;

  /// Total number of currently running tribbles
  static int get count => _tribbles.length;

  /// Create a new tribble
  Tribble() {
    _tribbles.add(this);
  }

  void kill() {
    alive = false;
    _tribbles.remove(this);
  }

  static void killAll() {
    for (final t in _tribbles) {
      t.alive = false;
    }
    _tribbles.clear();
  }
}
