import 'dart:developer' as developer;

enum LogLevel { verbose, debug, info, warning, error, wtf }

class ConsoleAppLogger {
  static final ConsoleAppLogger _instance = ConsoleAppLogger._internal();

  factory ConsoleAppLogger() {
    return _instance;
  }

  ConsoleAppLogger._internal();

  void _log(LogLevel level, String message,
      [dynamic error, StackTrace? stackTrace]) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage =
        '$timestamp [${level.toString().split('.').last.toUpperCase()}] $message';

    developer.log(
      logMessage,
      name: 'ConsoleAppLogger',
      error: error,
      stackTrace: stackTrace,
    );
  }

  void v(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.verbose, message, error, stackTrace);
  }

  void d(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.debug, message, error, stackTrace);
  }

  void i(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.info, message, error, stackTrace);
  }

  void w(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, error, stackTrace);
  }

  void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  void wtf(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.wtf, message, error, stackTrace);
  }
}
