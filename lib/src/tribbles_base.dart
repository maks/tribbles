import 'dart:async';
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
  static final List<Tribble> _tribbles = [];

  static const _portKey = 'port';
  static const _paramsKey = 'params';

  /// Total number of currently running tribbles
  static int get count => _tribbles.length;

  Isolate? _isolate;
  final ReceivePort _responses = ReceivePort();
  SendPort? _requests;
  bool _ready = false;

  Future<bool> get alive async {
    while (!_ready) {
      await Future.delayed(Duration(milliseconds: 100));
    }
    return _isolate != null;
  }

  final _messageStream = StreamController();

  Stream get messages => _messageStream.stream;

  /// Create a new tribble
  Tribble(TribbleCallback worker, {Map parameters = const {}}) {
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
        _messageStream.add(message);
      }
    });

    _tribbles.add(this);
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
    _tribbles.remove(this);
  }

  static void killAll() {
    final old = List.from(_tribbles);
    _tribbles.clear();
    for (final t in old) {
      t._isolate?.kill();
    }
  }

  static ReceivePort connect(Map m) {
    final requestPort = ReceivePort();
    m[_portKey].send(requestPort.sendPort);
    return requestPort;
  }

  static void reply(Map m, String reply) {
    m[_portKey].send(reply);
  }
}
