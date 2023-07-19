import 'dart:io';
import 'dart:math' as math;
import 'package:filesize/filesize.dart';
import '../lib/tribbles.dart';

const _debug = false;

void main(List<String> args) async {
  if (args.length != 1) {
    print("usage: please supply as a single argument the number of Tribbles to spawn");
    exit(1);
  } 

  print('Multi Tribble test [${args[0]}]');
  printMemUsage('Initial');
  print("=========================================");

  final int tribbleCount = int.parse(args[0]);
  int responseCount = 0;
  int sendCount = 0;

  final startTime = DateTime.now();
  for (var i = 0; i < tribbleCount; i++) {
    final tribble = await createTribble();

    await tribble.waitForReady();

    tribble.messages.listen((event) {
      responseCount++;
      debugWrite('>');
    });
    tribble.sendMessage('.');
    sendCount++;
  }
  print('finished spawning tribbles in: ${elapsedMs(startTime)}ms');

  while (responseCount < sendCount) {
    await Future<void>.delayed(Duration(milliseconds: 1));
  }

  print("=========================================");
  print('finished collecting tribble results in: ${elapsedMs(startTime)}ms');
  printMemUsage('Final');
  exit(0);
}

Future<Tribble> createTribble() async {
  final tribble = Tribble(calculate);
  return tribble;
}

void calculate(ConnectFn connect, ReplyFn reply) {
  connect().listen((message) async {
    debugWrite('+');
    const res = 42 * 2023;
    reply(res);
  });
}

final rnd = math.Random();

int elapsedMs(DateTime start) => DateTime.now().millisecondsSinceEpoch - start.millisecondsSinceEpoch;

void debugWrite(String s) => _debug ? stdout.write(s) : null; 

void printMemUsage([String? prefix]) {
  final currentRss = ProcessInfo.currentRss;
  final maxRss = ProcessInfo.maxRss;
  print('$prefix RSS current:${filesize(currentRss)} max:${filesize(maxRss)}');
}
