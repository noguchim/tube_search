import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final logger = Logger(
  level: kReleaseMode ? Level.off : Level.debug,
  printer: TimestampPrinter(
    SimplePrinter(), // ← 既存プリンタを包む
  ),
  output: DevLogOutput(),
);

class DevLogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (final line in event.lines) {
      dev.log(line);
    }
  }
}

class TimestampPrinter extends LogPrinter {
  final LogPrinter _inner;

  TimestampPrinter(this._inner);

  @override
  List<String> log(LogEvent event) {
    final now = DateTime.now();
    final ts = "${now.year}-${_2(now.month)}-${_2(now.day)} "
        "${_2(now.hour)}:${_2(now.minute)}:${_2(now.second)}.${now.millisecond}";

    return _inner.log(event).map((l) => "[$ts] $l").toList();
  }
}

String _2(int n) => n.toString().padLeft(2, '0');
