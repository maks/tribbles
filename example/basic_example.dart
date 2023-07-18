import 'dart:io';

import '../lib/tribbles.dart';

void hi(ConnectFn connect, ReplyFn reply) {
  print('hi from Tribble worker');
  final reqPort = connect();
  reqPort.listen((message) {
    print('[Tribble received] $message');
    reply('I got your message: $message');

    // closing the port will complete this Tribble (and stop its Isolate)
    reqPort.close();
  });
}

void main() async {
  final tribble = Tribble(hi);

  tribble.messages.listen((event) {
    print('[mesg from Tribble] $event');
  });

  print('created your first tribble $tribble');

  // wait for tribble to be ready
  await tribble.waitForReady();

  tribble.sendMessage('do something tribble');
}
