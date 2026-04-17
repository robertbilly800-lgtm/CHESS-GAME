import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';
import 'chess_screen.dart';

class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({Key? key}) : super(key: key);

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> {
  int _seconds = 0;
  String _username = 'Player';
  int _elo = 1200;
  bool _searching = false;
  String _timeControl = '10 min';
  bool _rated = true;

  final List<String> _timeControls = ['1 min', '3 min', '5 min', '10 min', '15 min', '30 min'];
  final List<Map<String, dynamic>> _tips = [
    {'icon': Icons.center_focus_strong, 'tip': 'Control the center — e4, d4, e5, d5 are key squares.'},
    {'icon': Icons.visibility, 'tip': 'Always check your opponent\'s last move before responding.'},
    {'icon': Icons.castle, 'tip': 'Castle early to protect your king from attacks.'},
    {'icon': Icons.swap_horiz, 'tip': 'Don\'t move the same piece twice in the opening.'},
    {'icon': Icons.flag, 'tip': 'In the endgame, activate your king — it\'s a fighting piece.'},
  ];
  int _tipIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _rotateTips();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? 'Player';
      _elo = prefs.getInt('elo') ?? 1200;
    });
  }

  void _rotateTips() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) setState(() => _tipIndex = (_tipIndex + 1) % _tips.length);
    }
  }

  void _startSearch() {
    setState(() {
      _searching = true;
      _seconds = 0;
    });
    _runTimer();

    // Navigate to chess screen in online mode
    // The OnlineService inside ChessScreen will handle actual Firebase matchmaking
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChessScreen(
              mode: 'online',
              username: _username,
              userElo: _elo,
            ),
          ),
        );
      }
    });
  }

  void _runTimer() async {
    while (mounted && _searching) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _searching) setState(() => _seconds++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.white),
        title: Text('Online Chess', style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Player card
            _buildMyCard(),
            const SizedBox(height: 24),

            // Time control selector
            if (!_searching) ...[
              _buildTimeControlSection(),
              const SizedBox(height: 20),
              _buildRatedToggle(),
              const SizedBox(height: 32),
              _buildFindButton(),
            ] else ...[
              _buildSearchingAnimation(),
              const SizedBox(height: 32),
              TextButton.icon(
                onPressed: () => setState(() => _searching = false),
                icon: const Icon(Icons.close, color: AppColors.resignRed, size: 16),
                label: Text('Cancel Search', style: GoogleFonts.outfit(color: AppColors.resignRed, fontWeight: FontWeight.bold)),
              ),
            ],

            const SizedBox(height: 32),

            // Tip card
            _buildTipCard(),

            const SizedBox(height: 24),

            // How it works
            _buildHowItWorks(),
          ],
        ),
      ),
    );
  }

  Widget _buildMyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
            child: const Icon(Icons.person, color: AppColors.primaryGreen, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_username, style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.primaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text('ELO $_elo', style: GoogleFonts.outfit(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    Text('Ready to play', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.wifi, color: AppColors.primaryGreen, size: 20),
        ],
      ),
    );
  }

  Widget _buildTimeControlSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TIME CONTROL', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _timeControls.map((tc) {
            final isSelected = _timeControl == tc;
            return GestureDetector(
              onTap: () => setState(() => _timeControl = tc),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryGreen : AppColors.cardDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSelected ? AppColors.primaryGreen : AppColors.borderDark),
                ),
                child: Text(tc, style: GoogleFonts.outfit(color: isSelected ? Colors.white : AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRatedToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderDark)),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_outlined, color: AppColors.primaryGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rated Game', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('Affects your ELO rating', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Switch(value: _rated, onChanged: (v) => setState(() => _rated = v), activeColor: AppColors.primaryGreen),
        ],
      ),
    );
  }

  Widget _buildFindButton() {
    return GestureDetector(
      onTap: _startSearch,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF00B873), Color(0xFF00D4A0)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.primaryGreen.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.public, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text('Find Opponent', style: GoogleFonts.syne(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildSearchingAnimation() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.15), width: 2),
              ),
            ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), duration: 1.5.seconds, curve: Curves.easeInOut),
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3), width: 2),
              ),
            ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(1, 1), end: const Offset(1.12, 1.12), duration: 1.2.seconds, curve: Curves.easeInOut),
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                border: Border.all(color: AppColors.primaryGreen, width: 2),
              ),
              child: const Icon(Icons.search, color: AppColors.primaryGreen, size: 36),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Searching globally...', style: GoogleFonts.syne(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('$_timeControl · ${_rated ? 'Rated' : 'Casual'}', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13)),
        const SizedBox(height: 16),
        Text(
          'Elapsed: ${_seconds}s',
          style: GoogleFonts.outfit(color: AppColors.primaryGreen, fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTipCard() {
    final tip = _tips[_tipIndex];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Container(
        key: ValueKey(_tipIndex),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.primaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(tip['icon'] as IconData, color: AppColors.primaryGreen, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CHESS TIP', style: GoogleFonts.outfit(color: AppColors.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(tip['tip'] as String, style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('HOW ONLINE PLAY WORKS', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildStep('1', 'Tap Find Opponent — we search for a player near your ELO.'),
        _buildStep('2', 'Once matched, your game board opens instantly.'),
        _buildStep('3', 'Moves sync in real-time over our global servers.'),
        _buildStep('4', 'Win, draw, or resign — your ELO updates automatically.'),
      ],
    );
  }

  Widget _buildStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(color: AppColors.primaryGreen.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
            child: Center(child: Text(num, style: GoogleFonts.syne(color: AppColors.primaryGreen, fontSize: 12, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13, height: 1.4))),
        ],
      ),
    );
  }
}
