import 'package:fake_async/fake_async.dart';
import 'package:tribbles/src/tribbles_base.dart';
import 'package:tribbles/tribbles.dart';
import 'package:test/test.dart';

void main() {
  group('creating tribbles', () {
    setUp(() async {
      Tribble.stopAll();
    });

    test('creating tribble increases tribble count', () {
      Tribble((_, __) {});
      expect(Tribble.tribbleCount, equals(1));
    });

    test('killing a tribble decreases tribble count', () {
      final tribble = Tribble((_, __) {});
      expect(Tribble.tribbleCount, equals(1));

      tribble.stop();

      expect(Tribble.tribbleCount, equals(0));
    });

    test('killing a tribble marks it as no longer alive', () async {
      final tribble = Tribble((connect, __) => connect());
      await tribble.waitForReady();
      expect(tribble.alive, isTrue);

      tribble.stop();

      final alive = tribble.alive;
      expect(alive, isFalse);
    });

    test('send a tribble a message', () async {
      final tribble = Tribble(echo);

      await tribble.waitForReady();
      expect(tribble.alive, isTrue);

      var reply = '';
      tribble.messages.listen((mesg) {
        reply = mesg.toString();
      });
      tribble.sendMessage('test1');

      // sadly can't use FakeAsync with & inside Isolates so
      // just need this hacky way of waiting on Isolate to send
      // to its output SendPort stream
      var count = 0; // 250ms timeout
      while (reply == '' && count < 50) {
        await Future<void>.delayed(Duration(milliseconds: 5));
        count++;
      }
      expect(reply, equals('test1'));
    });

    test('no tribbles before first one is created', () async {
      expect(Tribble.byId(""), equals(null));
    });

    test('get a tribble by id', () async {
      final tribble = Tribble((connect, __) => connect());

      expect(Tribble.byId(tribble.id), equals(tribble));
    });

    test('get a tribble by id', () async {
      final tribble = Tribble((connect, __) => connect());

      expect(Tribble.byId(tribble.id), equals(tribble));
    });

    test('notified ID of Tribble when a Tribble exits after its worker function completes normally', () async {
      String exitedId = "";
      late final Tribble tribble;

      tribble = Tribble(
        (connect, __) async {
          final reqPort = connect();
          // wait to give time before closing down the tribbles Isolate
          await Future<void>.delayed(Duration(milliseconds: 10));
          // once the worker completes we need to explicitly close the incoming requests ReceivePort to
          // shutdown this Tribble
          reqPort.close();
        },
        onChildExit: (cid) {
          exitedId = cid;
        },
      );

      // wait until tribble is initialised
      await tribble.waitForReady(timeOut: 20);
      expect(tribble.alive, isTrue);

      //yuck, but need some way to give tribble time to stop and notify of being stopped
      await Future<void>.delayed(Duration(milliseconds: 20));

      expect(tribble.alive, isFalse);

      expect(exitedId, tribble.id);
    });
  });

  test('sending replies should be of the correct type', () async {
    final tribble = Tribble((connect, reply) {
      connect().listen((message) {
        reply(42);
      });
    });

    bool replyOk = false;

    tribble.messages.listen((mesg) {
      if (mesg == 42) {
        replyOk = true;
      }
    });
    await tribble.waitForReady();
    tribble.sendMessage("");

    // yuck, but need delay to return control to runloop for reply to
    // be delivered on messages stream
    await Future<void>.delayed(Duration(milliseconds: 1));

    expect(replyOk, isTrue);
  });
}

void echo(ConnectFn connect, ReplyFn reply) {
  connect().listen((message) {
    reply(message.toString());
  });
}

/// Runs a callback using FakeAsync.run while continually pumping the
/// microtask queue. This avoids a deadlock when tests `await` a Future
/// which queues a microtask that will not be processed unless the queue
/// is flushed.
Future<T> runFakeAsync<T>(Future<T> Function(FakeAsync time) f) async {
  return FakeAsync().run((FakeAsync time) async {
    bool pump = true;
    final Future<T> future = f(time).whenComplete(() => pump = false);
    while (pump) {
      time.flushMicrotasks();
    }
    return future;
  });
}
