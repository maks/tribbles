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
  bool _ready = false;
  // for now cache ID in the Tribble obj as well as setting it on the Tribbles underlying Isolate
  late final String id;

  Future<bool> get alive async {
    while (!_ready) {
      await Future<void>.delayed(Duration(milliseconds: 100));
    }
    return _isolate != null;
  }

  final _messageStream = StreamController<dynamic>();

  Stream<dynamic> get messages => _messageStream.stream;

  static final Map<String, Tribble> _children = {};

  static int get count => _children.length;

  static Tribble? byId(String id) => _children[id]; 

  /// Create a new tribble
  Tribble(TribbleCallback worker, {Map<dynamic, dynamic> parameters = const {}}) {
    id = "$_isolateName/$_nextTribbleId";
    Isolate.spawn(
      _workerWrapper,
      {
        _portKey: _responses.sendPort,
        _paramsKey: parameters,
        _workerKey: worker,
      },
      debugName: id,
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
    _children[id] = this;
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
