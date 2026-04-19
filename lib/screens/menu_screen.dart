import 'package:flutter/material.dart';
import 'package:crashlog/crashlog.dart';
import 'chess_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chess Grandmaster'),
        actions: const [ErrorRecorderIconButton()],
        backgroundColor: Colors.black87,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _startGame(context, 'local'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
                child: const Text('Play Local (2 players)', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _startGame(context, 'ai'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
                child: const Text('Play vs AI', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _startGame(context, 'sms'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
                child: const Text('Play via SMS', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _startGame(context, 'bluetooth'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
                child: const Text('Play via Bluetooth', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startGame(BuildContext context, String mode) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChessScreen(mode: mode)),
    );
  }
}
