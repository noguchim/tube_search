import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final logger = Logger(
  level: kReleaseMode ? Level.off : Level.debug,
  printer: SimplePrinter(),
  output: DevLogOutput(), // ← ここ！
);

class DevLogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (final line in event.lines) {
      dev.log(line); // ← print を使わない
    }
  }
}
