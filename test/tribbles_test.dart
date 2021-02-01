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
      // ignore: unused_local_variable
      final tribble = Tribble();
      expect(Tribble.count, equals(1));

      tribble.kill();

      expect(Tribble.count, equals(0));
    });
  });
}
