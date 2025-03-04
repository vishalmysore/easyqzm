
import 'package:flutter/foundation.dart';

final bool isDebug = !kReleaseMode && const bool.fromEnvironment('debug', defaultValue: false);

void d(String s) {
  if (isDebug) {
    final stackTrace = StackTrace.current;
    final traceString = stackTrace.toString().split("\n")[1]; // Get caller info
    print("[DEBUG] $traceString: $s");
  }
}

void err(String e) {
  final stackTrace = StackTrace.current;
  final traceString = stackTrace.toString().split("\n")[1];
  print("[ERROR] $traceString: $e");
}