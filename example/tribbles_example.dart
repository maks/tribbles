import 'package:tribbles/tribbles.dart';

void hi(_) {
  print('hi from tribble');
}

void main() {
  final tribble = Tribble(hi);
  print('created your first tribble ${tribble}');
}
