import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  Future<File> _getLogFile() async {
    final dir = await getExternalStorageDirectory();
    return File('${dir!.path}/chess_app_log.txt');
  }

  Future<void> log(String message) async {
    try {
      final file = await _getLogFile();
      final timestamp = DateTime.now().toIso8601String();
      await file.writeAsString('[$timestamp] $message\n', mode: FileMode.append);
    } catch (e) {
      // Ignore logging errors
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
}
