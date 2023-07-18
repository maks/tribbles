A Dart library for working with large numbers of Isolates.

## Usage

A simple usage example:

```dart
import 'package:tribbles/tribbles.dart';

void hi(String mesg) {
  print('tribble says: $mesg');
}

main() {
  final tribble = Tribble(hi);
}
```

See the [sample code](example/basic_example.dart) for a more completed example of using Tribble.


A more complex example showing how to use large numbers of Tribbles [is also available](example/multi_example.dart).
Note if you wish, you can compare performance (memory, clock time and cpu usage) of the multi Tribble example by compiling AOT to a executable using: `dart compile exe example/multi_example.dart`.  

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/maks/tribbles/issues/new
