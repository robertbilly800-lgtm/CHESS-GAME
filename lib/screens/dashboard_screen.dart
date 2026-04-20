import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import 'chess_screen.dart';
import 'bluetooth_pairing_screen.dart';
import 'matchmaking_screen.dart';
import '../services/user_service.dart';
import '../services/sound_service.dart';
import '../data/lessons_data.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final UserService _user = UserService();
  final SoundService _sound = SoundService();
  final TextEditingController _smsPhoneController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _user.init().then((_) {
      if (!mounted) return;
      setState(() {
        if (_user.phoneNumber.isNotEmpty) {
          _smsPhoneController.text = _user.phoneNumber;
        }
      });
    });
    _user.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _smsPhoneController.dispose();
    super.dispose();
  }

  void _playTap() => _sound.playButtonTap();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildPlayTab(),
            _buildProfileTab(),
            _buildLearnTab(),
            _buildSettingsTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // 1. PLAY TAB (Now with Explicit Offline Section)
  Widget _buildPlayTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Play Chess', style: GoogleFonts.syne(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1)),
              const Icon(Icons.help_outline, color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 24),
          
          // AI CARD
          _buildPlayCard(
            title: 'AI Mode',
            subtitle: 'Challenge our Grandmaster engine',
            icon: Icons.psychology_outlined,
            badge: 'Single Play',
            badgeColor: AppColors.primaryGreen,
            onTap: () { _playTap(); _go(const ChessScreen(mode: 'ai')); },
            content: _buildInfoSection(Icons.bolt, 'Engine Difficulty', 'Test your skills against a powerful Stockfish-based engine. Adjust the level and practice your tactics.'),
          ),
          const SizedBox(height: 16),

          // LOCAL CARD
          _buildPlayCard(
            title: 'Pass & Play',
            subtitle: 'Play together on the same device',
            icon: Icons.people_outline,
            badge: 'Local',
            badgeColor: AppColors.tutorialBlue,
            onTap: () { _playTap(); _go(const ChessScreen(mode: 'local')); },
            content: _buildInfoSection(Icons.devices, 'Same Device Play', 'A classic way to play chess with a friend sitting next to you. Perfect for trips or quick matches.'),
          ),
          const SizedBox(height: 16),

          // ONLINE CARD
          _buildPlayCard(
            title: 'Online Multiplayer Mode',
            subtitle: 'Play with global opponents',
            icon: Icons.public,
            badge: 'Online',
            badgeColor: AppColors.catStrategy,
            onTap: () { _playTap(); _go(const MatchmakingScreen()); },
            content: _buildInfoSection(Icons.language, 'Global Matchmaking', 'Connect with thousands of players worldwide. Improve your ELO and climb the global leaderboard.'),
          ),
          
          const SizedBox(height: 32),
          // EXPLICIT OFFLINE MULTIPLAYER SECTION
          Text('OFFLINE MULTIPLAYER', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 16),

          // SMS CARD
          _buildPlayCard(
            title: 'SMS Play',
            subtitle: 'Challenge via text message',
            icon: Icons.chat_bubble_outline,
            badge: 'SMS',
            badgeColor: AppColors.catOpenings,
            onTap: null,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoSection(Icons.sync_alt, 'How SMS Sync Works', 'One move = One SMS. The board acts as a live chat session where pieces move automatically when a message is received. No internet required.'),
                const SizedBox(height: 16),
                Text("Opponnet's Phone Number", style: GoogleFonts.outfit(color: Colors.white, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildPhoneNumberField()),
                    const SizedBox(width: 8),
                    _buildMiniAction('Invite', Icons.send, onTap: () {
                      final phone = _smsPhoneController.text.trim();
                      if (phone.isNotEmpty) {
                        _playTap();
                        _user.addSmsContact(phone);
                        _go(ChessScreen(mode: 'sms', opponentPhone: phone, username: _user.displayName));
                      }
                    }),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // BLUETOOTH CARD
          _buildPlayCard(
            title: 'Bluetooth Play',
            subtitle: 'Play with nearby devices',
            icon: Icons.bluetooth,
            badge: 'Nearby',
            badgeColor: AppColors.catTutorials,
            onTap: () { _playTap(); _go(const BluetoothPairingScreen()); },
            content: _buildInfoSection(Icons.bluetooth_searching, 'Local Wireless', 'Connect to a nearby device over Bluetooth. No internet needed. Range ~10m.'),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // 2. PROFILE TAB (Moved to 2nd position)
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildSectionTitle('My Profile'),
          const SizedBox(height: 24),
          CircleAvatar(radius: 44, backgroundColor: AppColors.cardDark, child: Icon(Icons.person, size: 48, color: AppColors.primaryGreen)),
          const SizedBox(height: 16),
          Text(_user.displayName, style: GoogleFonts.syne(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text('Rank: Candidate Master', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 14)),
          const SizedBox(height: 32),
          Row(
            children: [
              _buildStatBox(_user.elo.toString(), 'ELO RATING'),
              const SizedBox(width: 16),
              _buildStatBox('#1,429', 'GLOBAL RANK'),
            ],
          ),
          const SizedBox(height: 16),
          _buildSignOutButton(),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // 3. LESSONS TAB (Moved to 3rd position)
  Widget _buildLearnTab() {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        _buildSectionTitle('Chess Lessons'),
        const SizedBox(height: 20),
        _buildDailyChallengeCard(),
        const SizedBox(height: 32),
        Text('AVAILABLE LESSONS', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12, letterSpacing: 1.2)),
        const SizedBox(height: 16),
        ...chessLessons.map((lesson) => _buildLessonRow(lesson)),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  // 4. SETTINGS TAB (Moved to 4th position)
  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        _buildSectionTitle('Settings'),
        const SizedBox(height: 20),
        _buildSettingsGroup('Appearance', [
          _buildToggle('Dark Mode', _user.darkMode, Icons.dark_mode_outlined, (v) => _user.toggleDarkMode(v)),
          _buildDivider(),
          _buildSettingRow('Emerald Theme', const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 20)),
        ]),
        const SizedBox(height: 20),
        _buildSettingsGroup('Sounds & Feel', [
          _buildToggle('Game Sounds', _user.soundsEnabled, Icons.volume_up_outlined, (v) { _user.toggleSounds(v); _sound.setMuted(!v); }),
          _buildDivider(),
          _buildToggle('Vibration', _user.vibrationEnabled, Icons.vibration_outlined, (v) => _user.toggleVibration(v)),
        ]),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }


  // HELPER WIDGETS
  Widget _buildSectionTitle(String t) => Text(t, style: GoogleFonts.syne(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white));

  Widget _buildPlayCard({required String title, required String subtitle, required IconData icon, required String badge, required Color badgeColor, required Widget content, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.borderDark)),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppColors.primaryGreen, size: 24)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(subtitle, style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13)),
                    ],
                  ),
                ),
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)), child: Text(badge, style: GoogleFonts.outfit(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 11))),
              ],
            ),
            const SizedBox(height: 24),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(IconData icon, String title, String body) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.background.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryGreen, size: 16),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(body, style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPhoneNumberField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderDark)),
      child: TextField(
        controller: _smsPhoneController,
        keyboardType: TextInputType.phone,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          icon: Icon(Icons.phone, color: AppColors.textMuted, size: 18),
          hintText: '+255 000 000 000',
          hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 14),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildMiniAction(String label, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyChallengeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF16213E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily Challenge', style: GoogleFonts.syne(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Solve today\'s puzzle to earn XP', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 20),
          _buildMiniAction('Start Puzzle', Icons.bolt),
        ],
      ),
    );
  }

  Widget _buildLessonRow(ChessLesson lesson) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderDark)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primaryGreen.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.school, color: AppColors.primaryGreen, size: 20)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lesson.title, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('${lesson.category} · ${lesson.difficulty}', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: AppColors.textMuted, size: 14),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderDark)),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildToggle(String label, bool val, IconData icon, Function(bool) onChanged) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textMuted, size: 22),
      title: Text(label, style: GoogleFonts.outfit(color: Colors.white, fontSize: 15)),
      trailing: Switch(value: val, onChanged: (v) { _playTap(); onChanged(v); }, activeTrackColor: AppColors.primaryGreen.withValues(alpha: 0.5), activeColor: AppColors.primaryGreen),
    );
  }

  Widget _buildSettingRow(String label, Widget trailing) => ListTile(title: Text(label, style: GoogleFonts.outfit(color: Colors.white, fontSize: 15)), trailing: trailing);
  Widget _buildDivider() => const Divider(height: 1, color: AppColors.borderDark, indent: 16, endIndent: 16);

  Widget _buildStatBox(String val, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderDark)),
        child: Column(
          children: [
            Text(val, style: GoogleFonts.syne(color: AppColors.primaryGreen, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.resignRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.resignRed.withValues(alpha: 0.3))),
      child: Center(child: Text('Sign Out', style: GoogleFonts.outfit(color: AppColors.resignRed, fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(color: AppColors.background, border: Border(top: BorderSide(color: AppColors.borderDark, width: 1))),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) { _playTap(); setState(() => _currentIndex = i); },
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.outfit(fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), label: 'Play'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.school_outlined), label: 'Lessons'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }

  void _go(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}
