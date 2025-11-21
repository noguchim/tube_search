import 'package:logger/logger.dart';

final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0, // コールスタック非表示
    colors: true,
  ),
);
