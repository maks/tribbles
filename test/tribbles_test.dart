import 'package:tribbles/tribbles.dart';
import 'package:test/test.dart';

void main() {
  group('creating tribbles', () {
    test('creating tribble increases tribble count', () {
      // ignore: unused_local_variable
      final tribble = Tribble();

      expect(Tribble.count, equals(1));
    });
  });
}
