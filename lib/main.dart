import 'package:flutter/material.dart';
import 'package:crashlog/crashlog.dart';
import 'screens/menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Crashlog.init(
    enabled: true,
    enableScreenshots: true,
    autoOpenOnError: false,
    maxConsoleLogs: 1000,
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
      home: const MenuScreen(),
    );
  }
}
