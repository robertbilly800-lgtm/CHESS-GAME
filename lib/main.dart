import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const ChessApp());
}

class ChessApp extends StatelessWidget {
  const ChessApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChessMate Pro',
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF00B873),
        scaffoldBackgroundColor: const Color(0xFF0F1014),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F1014),
          elevation: 0,
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      ),
      home: const DashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
