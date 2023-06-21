import 'dart:io';

import 'package:tribbles/tribbles.dart';

void hi(Map<dynamic, dynamic> m) {
  print('hi from Tribble worker');
  Tribble.connect(m).listen((message) {
    print('[Tribble received] $message');

    Tribble.reply(m, 'I got your message!');
  });
}

void main() async {
  final tribble = Tribble(hi);

  tribble.messages.listen((event) {
    print('[mesg from Tribble] $event');
  });

  print('created your first tribble $tribble');

  // wait for tribble to be ready
  await tribble.alive;

  tribble.sendMessage('do something tribble');
  await Future<void>.delayed(Duration(milliseconds: 50));
  print('good bye tribble');
  tribble.kill();
  exit(0);
}
