import 'package:tribbles/src/tribbles_base.dart';
import 'package:tribbles/tribbles.dart';
import 'package:test/test.dart';

void main() {
  group('creating tribbles', () {
    setUp(() async {
      Tribble.killAll();
    });

    test('creating tribble increases tribble count', () {
      Tribble((_, __) {});
      expect(Tribble.count, equals(1));
    });

    test('killing a tribble decreases tribble count', () {
      final tribble = Tribble((_, __) {});
      expect(Tribble.count, equals(1));

      tribble.kill();

      expect(Tribble.count, equals(0));
    });

    test('killing a tribble marks it as no longer alive', () async {
      final tribble = Tribble((_, __) {});
      final ready = await tribble.alive;
      expect(ready, isTrue);

      tribble.kill();

      final alive = await tribble.alive;
      expect(alive, isFalse);
    });

    test('send a tribble a message', () async {
      final tribble = Tribble(echo);

      final ready = await tribble.alive;
      expect(ready, isTrue);

      var reply = '';
      tribble.messages.listen((mesg) {
        reply = mesg.toString();
      });
      final r = tribble.sendMessage('test1');
      expect(r, isTrue);

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
      final tribble = Tribble((_, __) {});

      expect(Tribble.byId(tribble.id), equals(tribble));
    });

    test('get a tribble by id', () async {
      final tribble = Tribble((_, __) {});

      expect(Tribble.byId(tribble.id), equals(tribble));
    });

    test('notified ID of Tribble when a Tribble exits', () async {
      String exitedId = "";
      final tribble = Tribble(
        (_, __) {},
        onChildExit: (cid) {
          exitedId = cid;
        },
      );

      // wait until tribble is initialised
      final ready = await tribble.alive;
      expect(ready, isTrue);

      expect(exitedId, tribble.id);
    });
  });
}

void echo(ConnectFn connect, ReplyFn reply) {
  connect().listen((message) {
    reply(message.toString());
  });
}
