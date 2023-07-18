import 'dart:io';

import '../lib/tribbles.dart';

void hi(ConnectFn connect, ReplyFn reply) {
  print('hi from Tribble worker');
  connect().listen((message) {
    print('[Tribble received] $message');

    reply('I got your message: $message');
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
