import 'dart:async';
import 'dart:collection';
import 'dart:isolate';

/// Callback function that a tribble will invoke in a new Isolate.
/// The Map that will be passed in should be treated as Opaque!
///
/// The Callback function is expected to call the Tribble.connect(map) static function
/// with the map that was passed in if it wishes to receive future incoming messages.
/// Likewise it can use the passed in map with the Tribble.reply() static function to
/// send messages to any listeners of the tribbles 'messages' stream.
typedef TribbleCallback = void Function(Map<String, dynamic>);

/// Each Tribble represents a single Isolate.
class Tribble {
  static final Map<int, Tribble> _tribbles = HashMap();

  static const _portKey = 'port';
  static const _paramsKey = 'params';

  static var _idCounter = 0;

  /// Total number of currently running tribbles
  static int get count => _tribbles.length;

  /// Retrieve Tribble with Id if it exists
  static Tribble? byId(int id) => _tribbles[id];

  Isolate? _isolate;
  final ReceivePort _responses = ReceivePort();
  SendPort? _requests;
  bool _ready = false;
  final int id = _idCounter++;

  Future<bool> get alive async {
    while (!_ready) {
      await Future<void>.delayed(Duration(milliseconds: 100));
    }
    return _isolate != null;
  }

  final _messageStream = StreamController<String>();

  Stream<String> get messages => _messageStream.stream;

  /// Create a new tribble
  Tribble(TribbleCallback worker, {Map<dynamic, dynamic> parameters = const {}}) {
    Isolate.spawn(
      worker,
      {
        _portKey: _responses.sendPort,
        _paramsKey: parameters,
      },
    ).then((i) {
      _isolate = i;
      _ready = true;
    });

    _responses.listen((message) {
      if (message is SendPort) {
        _requests = message;
      } else {
        _messageStream.add(message.toString());
      }
    });

    _tribbles.putIfAbsent(id, () => this);
  }

  bool sendMessage(String message) {
    final requests = _requests;
    if (requests != null) {
      requests.send(message);
      return true;
    } else {
      // cannot send message to isolate
      return false;
    }
  }

  void kill() {
    _isolate?.kill();
    _isolate = null;
    _tribbles.remove(id);
  }

  static void killAll() {
    final old = _tribbles.values.toList();
    _tribbles.clear();
    for (final t in old) {
      t._isolate?.kill();
    }
  }

  static ReceivePort connect(Map<dynamic, dynamic> m) {
    final requestPort = ReceivePort();
    m[_portKey].send(requestPort.sendPort);
    return requestPort;
  }

  static void reply(Map<dynamic, dynamic> m, String reply) {
    m[_portKey].send(reply);
  }
}
