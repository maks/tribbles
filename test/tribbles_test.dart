import 'package:tribbles/src/tribbles_base.dart';
import 'package:tribbles/tribbles.dart';
import 'package:test/test.dart';

void main() {
  setUp(() async {
    Tribble.killAll();
  });

  group('creating tribbles', () {
    test('creating tribble increases tribble count', () {
      // ignore: unused_local_variable
      final tribble = Tribble(dummy);
      expect(Tribble.count, equals(1));
    });

    test('killing a tribble decreases tribble count', () {
      final tribble = Tribble(dummy);
      expect(Tribble.count, equals(1));

      tribble.kill();

      expect(Tribble.count, equals(0));
    });

    test('killing a tribble marks it as no longer alive', () async {
      final tribble = Tribble(dummy);
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
      expect(Tribble.byId(0), equals(null));
    });

    test('get a tribble by id', () async {
      final tribble = Tribble(dummy);

      expect(Tribble.byId(tribble.id), equals(tribble));
    });
  });
}

void dummy(_) {}

void echo(Map<dynamic, dynamic> m) {
  Tribble.connect(m).listen((message) {
    Tribble.reply(m, message.toString());
  });
}
