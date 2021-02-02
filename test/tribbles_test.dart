import 'package:tribbles/tribbles.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {
    Tribble.killAll();
  });

  group('creating tribbles', () {
    test('creating tribble increases tribble count', () {
      // ignore: unused_local_variable
      final tribble = Tribble();

      expect(Tribble.count, equals(1));
    });

    test('killing a tribble decreases tribble count', () {
      final tribble = Tribble();
      expect(Tribble.count, equals(1));

      tribble.kill();

      expect(Tribble.count, equals(0));
    });

    test('killing a tribble marks it as an not alive', () {
      final tribble = Tribble();
      expect(tribble.alive, isTrue);

      tribble.kill();

      expect(tribble.alive, isFalse);
    });
  });
}
