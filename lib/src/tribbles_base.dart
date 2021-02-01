/// Each Tribble represents a single Isolate.
class Tribble {
  static final List<Tribble> _tribbles = [];

  /// Total number of currently running tribbles
  static int get count => _tribbles.length;

  /// Create a new tribble
  Tribble() {
    _tribbles.add(this);
  }

  void kill() {
    _tribbles.remove(this);
  }

  static void killAll() {
    _tribbles.clear();
  }
}
