import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';
import 'chess_screen.dart';

class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({Key? key}) : super(key: key);

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> {
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _simulateMatchfound();
  }

  void _startTimer() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _seconds++);
    }
  }

  void _simulateMatchfound() async {
    await Future.delayed(const Duration(seconds: 5));
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ChessScreen(mode: 'online')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text('Finding Opponent', style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            
            // Search Animation Circle
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryGreen, width: 2),
                boxShadow: [
                  BoxShadow(color: AppColors.primaryGreen.withValues(alpha: 0.1), blurRadius: 40, spreadRadius: 10),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shield, color: Colors.white, size: 40), // Placeholder for king icon
                    const SizedBox(width: 8),
                    Text('vs', style: GoogleFonts.syne(color: AppColors.textMuted, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    const Icon(Icons.shield, color: AppColors.textMuted, size: 40),
                  ],
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2.seconds),
            
            const SizedBox(height: 48),
            Text('Searching for an opponent...', style: GoogleFonts.syne(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Time Control: 10 min | Rated', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 14)),
            
            const SizedBox(height: 32),
            Text('ELAPSED TIME', style: GoogleFonts.syne(color: AppColors.textMuted, fontSize: 10, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text(
              '00:${_seconds.toString().padLeft(2, '0')}',
              style: GoogleFonts.outfit(color: AppColors.primaryGreen, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(height: 48),
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: AppColors.resignRed, size: 16),
              label: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.resignRed, fontWeight: FontWeight.bold)),
            ),
            
            const Spacer(),
            
            // Tip Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline, color: AppColors.primaryGreen, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TIP', style: GoogleFonts.syne(color: AppColors.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Text(
                          'Control the center of the board early in the game. Knights and bishops are most effective when they influence central squares.',
                          style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
