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

See the [sample code](example/tribbles_example.dart) for a more completed example of using Tribble.

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/maks/tribbles/issues/new
