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

      // yuck! but we want to test actual creation of isolates
      // so allow for upto 250ms for a isolate to be created
      var count = 0;
      while (!tribble.alive && count < 10) {
        await Future.delayed(Duration(milliseconds: 25));
        count++;
      }
      expect(tribble.alive, isTrue);

      tribble.kill();

      expect(tribble.alive, isFalse);
    });
  });
}

void dummy(_) {}
