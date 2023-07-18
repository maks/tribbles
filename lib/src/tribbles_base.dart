import 'dart:async';
import 'dart:isolate';

typedef ConnectFn = ReceivePort Function();
typedef ReplyFn = void Function(dynamic);

/// Callback function that a tribble will invoke in a new Isolate.
/// The Map that will be passed in should be treated as Opaque!
///
/// The Callback function is expected to call the Tribble.connect(map) static function
/// with the map that was passed in if it wishes to receive future incoming messages.
/// Likewise it can use the passed in map with the Tribble.reply() static function to
/// send messages to any listeners of the tribbles 'messages' stream.
typedef TribbleCallback = void Function(ConnectFn, ReplyFn);

typedef OnChildExitedCallback = void Function(String);

const _portKey = 'port';
const _paramsKey = 'params';
const _workerKey = 'worker';

late final Map<dynamic, dynamic> _tribbleMap;

void _workerWrapper(Map<dynamic, dynamic> m) {
  _tribbleMap = m;
  _worker = m[_workerKey] as TribbleCallback;
  return _worker(_connect, _reply);
}

ReceivePort _connect() {
  final requestPort = ReceivePort();
  _tribbleMap[_portKey].send(requestPort.sendPort);
  return requestPort;
}

void _reply(dynamic reply) {
  _tribbleMap[_portKey].send(reply);
}

late final TribbleCallback _worker;

int _idCounter = 0;

int get _nextTribbleId => ++_idCounter;

String? get _isolateName => Isolate.current.debugName;

/// Each Tribble represents a single Isolate.
class Tribble {
  Isolate? _isolate;
  final ReceivePort _responses = ReceivePort();
  SendPort? _requests;
  // for now cache ID in the Tribble obj as well as setting it on the Tribbles underlying Isolate
  late final String id;

  bool get alive {
    return _isolate != null && _requests != null;
  }

  final _messageStream = StreamController<dynamic>();

  Stream<dynamic> get messages => _messageStream.stream;

  static final Map<String, Tribble> _children = {};

  static int get tribbleCount => _children.length;

  static Tribble? byId(String id) => _children[id];

  /// Create a new tribble
  Tribble(TribbleCallback worker, {Map<dynamic, dynamic> parameters = const {}, OnChildExitedCallback? onChildExit}) {
    id = "$_isolateName/$_nextTribbleId";

    final onExitPort = ReceivePort();

    onExitPort.forEach((_) {
      _children.remove(id);
      if (onChildExit != null) {
        onChildExit(id);
      }
    });

    Isolate.spawn(
      _workerWrapper,
      {
        _portKey: _responses.sendPort,
        _paramsKey: parameters,
        _workerKey: worker,
      },
      debugName: id,
      onExit: onExitPort.sendPort,
    ).then((i) {
      _isolate = i;
    });

    _responses.listen((message) {
      if (message is SendPort) {
        _requests = message;
      } else {
        _messageStream.add(message.toString());
      }
    });
    _children[id] = this;
  }

  /// Wait for the Tribble to be ready.
  /// Will time out after 10 seconds and throw an Exception if the Tribble is not ready within that time.
  ///
  /// returns the number of 100 microsecond waits that were required for the Tribble to be ready.
  Future<int> waitForReady() async {
    // wait for tribble to be ready
    int aliveWaitCount = 0;
    while (!alive) {
      await Future<void>.delayed(Duration(microseconds: 100));
      aliveWaitCount++;
      const timeOutInSecIn100Microsec = 10 * 1000 * 100;
      if (aliveWaitCount > timeOutInSecIn100Microsec) {
        //timeout after 10 sec
        throw Exception("timeout waiting for tribble to be ready");
      }
    }
    return aliveWaitCount;
  }

  /// Send a message to this Tribble that can be received by listening to the messages stream.
  ///
  /// returns false if the message could not be delivered to the tribble
  bool sendMessage(dynamic message) {
    final requests = _requests;
    if (requests != null) {
      requests.send(message);
      return true;
    } else {
      // cannot send message to isolate
      return false;
    }
  }

  /// Kill this Tribble
  void kill() {
    _isolate?.kill();
    _isolate = null;
    _children.remove(id);
  }

  @override
  String toString() {
    return "Tribble [$id]";
  }

  static void killAll() {
    final old = _children.values.toList();
    for (var t in old) {
      t.kill();
    }
  }
}
