/// Create a new tribble
class Tribble {
  static final List<Tribble> _tribbles = [];

  static int get count => _tribbles.length;

  Tribble() {
    _tribbles.add(this);
  }
}
