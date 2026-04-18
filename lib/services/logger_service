import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  Future<File> _getLogFile() async {
    final dir = await getExternalStorageDirectory();
    final logFile = File('${dir!.path}/chess_app_log.txt');
    return logFile;
  }

  Future<void> log(String message) async {
    try {
      final file = await _getLogFile();
      final timestamp = DateTime.now().toIso8601String();
      await file.writeAsString('[$timestamp] $message\n', mode: FileMode.append);
    } catch (e) {
      // Silently fail if logging fails
    }
  }

  Future<String> readLog() async {
    try {
      final file = await _getLogFile();
      return await file.readAsString();
    } catch (e) {
      return 'No logs yet.';
    }
  }

  Future<void> clearLog() async {
    try {
      final file = await _getLogFile();
      await file.delete();
    } catch (_) {}
  }
}
