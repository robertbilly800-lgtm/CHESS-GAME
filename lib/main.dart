import 'package:flutter/material.dart';
import 'package:crashlog/crashlog.dart';
import 'screens/chess_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize crashlog to capture all errors and print logs
  await Crashlog.init(
    enabled: true,
    enableScreenshots: true,
    autoOpenOnError: false,
    maxLogs: 50,
    maxConsoleLogs: 1000,
    logRetentionDays: 7,
    showDeviceInfo: true,
    logFileName: "error_logs.json",
    consoleLogFileName: "console_logs.json",
    screenshotFolder: "screenshots",
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chess Grandmaster',
      theme: ThemeData.dark(),
      home: const ChessScreen(mode: 'local'), // or whatever default mode you want
    );
  }
}
