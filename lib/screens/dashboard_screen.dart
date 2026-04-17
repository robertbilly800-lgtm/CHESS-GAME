import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_colors.dart';
import '../services/user_service.dart';
import '../services/sound_service.dart';
import '../data/lessons_data.dart';
import 'chess_screen.dart';
import 'bluetooth_pairing_screen.dart';
import 'matchmaking_screen.dart';
import 'lesson_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tab = 0;
  final UserService _user = UserService();
  final SoundService _sound = SoundService();
  final TextEditingController _phoneCtrl = TextEditingController();
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _user.init().then((_) {
      _phoneCtrl.text = _user.phoneNumber;
      _sound.setMuted(!_user.soundsEnabled);
      if (mounted) setState(() {});
    });
    _user.addListener(() { if (mounted) setState(() {}); });
  }

  void _tap() => _sound.playButtonTap();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: IndexedStack(index: _tab, children: [
        _buildPlay(),
        _buildLearn(),
        _buildSettings(),
        _buildProfile(),
      ])),
      bottomNavigationBar: _buildNav(),
    );
  }

  // ══════════════════════════════════════════════════════
  // PLAY TAB
  // ══════════════════════════════════════════════════════
  Widget _buildPlay() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('Play Chess'),
        const SizedBox(height: 20),

        // AI
        _playCard(
          title: 'Play vs AI',
          subtitle: 'Challenge the Stockfish engine',
          icon: Icons.psychology_outlined,
          badge: 'Single Player',
          badgeColor: AppColors.primaryGreen,
          onTap: () { _tap(); _go(const ChessScreen(mode: 'ai')); },
          child: _infoBox(Icons.bolt, 'Stockfish Engine', '20 difficulty levels — from complete beginner to Grandmaster strength.'),
        ),
        const SizedBox(height: 14),

        // Pass & Play
        _playCard(
          title: 'Pass & Play',
          subtitle: 'Two players on one device',
          icon: Icons.people_outline,
          badge: 'Local',
          badgeColor: AppColors.tutorialBlue,
          onTap: () { _tap(); _go(const ChessScreen(mode: 'local')); },
          child: _infoBox(Icons.devices, 'Same Device', 'Hand the phone back and forth. Perfect for playing with a friend nearby.'),
        ),
        const SizedBox(height: 14),

        // Online
        _playCard(
          title: 'Online Chess',
          subtitle: 'Play against global opponents',
          icon: Icons.public,
          badge: 'Online',
          badgeColor: AppColors.catStrategy,
          onTap: () { _tap(); _go(const MatchmakingScreen()); },
          child: _infoBox(Icons.language, 'Global Matchmaking', 'Find opponents near your rating worldwide. Real-time games with in-game chat.'),
        ),

        const SizedBox(height: 24),
        Text('OFFLINE MULTIPLAYER', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11, letterSpacing: 1.2)),
        const SizedBox(height: 14),

        // SMS Play - fully functional
        _playCard(
          title: 'SMS Play',
          subtitle: 'Play via text message',
          icon: Icons.chat_bubble_outline,
          badge: 'SMS',
          badgeColor: AppColors.catOpenings,
          onTap: null,
          child: _buildSmsSection(),
        ),
        const SizedBox(height: 14),

        // Bluetooth
        _playCard(
          title: 'Bluetooth Play',
          subtitle: 'Play with nearby devices',
          icon: Icons.bluetooth,
          badge: 'Nearby',
          badgeColor: AppColors.catTutorials,
          onTap: () { _tap(); _go(const BluetoothPairingScreen()); },
          child: _infoBox(Icons.bluetooth_searching, 'Local Wireless', 'Connect to a nearby device over Bluetooth. No internet needed. Range ~10m.'),
        ),
      ]),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildSmsSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _infoBox(Icons.sync_alt, 'How it works', 'Each move sends one SMS to your opponent. Moves sync automatically when received.'),
      const SizedBox(height: 14),

      // Phone number input
      Text("Opponent's Number", style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.borderDark)),
            child: TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                icon: const Icon(Icons.phone, color: AppColors.textMuted, size: 18),
                hintText: '+255 700 000 000',
                hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Pick from contacts
        GestureDetector(
          onTap: _pickContact,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.borderDark)),
            child: const Icon(Icons.contacts, color: AppColors.primaryGreen, size: 20),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            final phone = _phoneCtrl.text.trim();
            if (phone.isEmpty) { _snack('Enter a phone number'); return; }
            _tap();
            _user.addSmsContact(phone);
            _go(ChessScreen(mode: 'sms', opponentPhone: phone, username: _user.displayName));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.send, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text('Play', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ]),
          ),
        ),
      ]),

      // Recent SMS contacts
      if (_user.smsContacts.isNotEmpty) ...[
        const SizedBox(height: 14),
        Text('Recent Opponents', style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ..._user.smsContacts.take(3).map((phone) => _smsContact(phone)),
      ],
    ]);
  }

  Widget _smsContact(String phone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.borderDark)),
      child: Row(children: [
        const Icon(Icons.person_outline, color: AppColors.textMuted, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(phone, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))),
        GestureDetector(
          onTap: () { _tap(); _phoneCtrl.text = phone; _go(ChessScreen(mode: 'sms', opponentPhone: phone, username: _user.displayName)); },
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: AppColors.primaryGreen.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Text('Play', style: GoogleFonts.outfit(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 12))),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () { _user.removeSmsContact(phone); setState(() {}); },
          child: const Icon(Icons.close, color: AppColors.textMuted, size: 16),
        ),
      ]),
    );
  }

  Future<void> _pickContact() async {
    _tap();
    final status = await Permission.contacts.request();
    if (!status.isGranted) { _snack('Contacts permission needed'); return; }
    try {
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      if (!mounted) return;
      final picked = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: AppColors.cardDark,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => Column(children: [
          Container(margin: const EdgeInsets.only(top: 10), width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.all(18), child: Text('Choose Contact', style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
          Expanded(child: ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (_, i) {
              final c = contacts[i];
              final phone = c.phones.isNotEmpty ? c.phones.first.number : '';
              if (phone.isEmpty) return const SizedBox.shrink();
              return ListTile(
                leading: CircleAvatar(backgroundColor: AppColors.borderDark, child: Text(c.displayName.isNotEmpty ? c.displayName[0] : '?', style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.bold))),
                title: Text(c.displayName, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: Text(phone, style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12)),
                onTap: () => Navigator.pop(context, phone),
              );
            },
          )),
        ]),
      );
      if (picked != null && mounted) setState(() => _phoneCtrl.text = picked);
    } catch (e) {
      _snack('Could not load contacts: $e');
    }
  }

  // ══════════════════════════════════════════════════════
  // LEARN TAB
  // ══════════════════════════════════════════════════════
  Widget _buildLearn() {
    final cats = ['All', 'Tutorial', 'Openings', 'Tactics', 'Endgames'];
    final filtered = _selectedCategory == 'All' ? chessLessons : chessLessons.where((l) => l.category == _selectedCategory).toList();

    return ListView(padding: const EdgeInsets.all(20), children: [
      _sectionTitle('Learn Chess'),
      const SizedBox(height: 16),

      // Daily puzzle card
      _buildDailyPuzzleCard(),
      const SizedBox(height: 20),

      // Category filter
      SizedBox(
        height: 38,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: cats.length,
          itemBuilder: (_, i) {
            final active = _selectedCategory == cats[i];
            return GestureDetector(
              onTap: () { _tap(); setState(() => _selectedCategory = cats[i]); },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? AppColors.primaryGreen : AppColors.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: active ? AppColors.primaryGreen : AppColors.borderDark),
                ),
                child: Text(cats[i], style: GoogleFonts.outfit(color: active ? Colors.white : AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 20),

      // Stats row
      Row(children: [
        _statChip('${tutorialLessons.length}', 'Tutorials', AppColors.tutorialBlue),
        const SizedBox(width: 10),
        _statChip('${openingLessons.length}', 'Openings', AppColors.openingGreen),
        const SizedBox(width: 10),
        _statChip('${tacticsLessons.length}', 'Tactics', AppColors.puzzleGold),
        const SizedBox(width: 10),
        _statChip('${endgameLessons.length}', 'Endgames', AppColors.endgameRed),
      ]),
      const SizedBox(height: 20),

      // Lessons list
      Text('${filtered.length} LESSONS', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11, letterSpacing: 1.2)),
      const SizedBox(height: 12),
      ...filtered.map((lesson) => _lessonCard(lesson)),
    ]);
  }

  Widget _buildDailyPuzzleCard() {
    final puzzle = dailyPuzzles.first;
    return GestureDetector(
      onTap: () { _tap(); _go(PuzzleScreen(puzzle: puzzle)); },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1A2A1A), Color(0xFF0A1A0A)]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.primaryGreen.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)), child: Text('DAILY PUZZLE', style: GoogleFonts.outfit(color: AppColors.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1))),
            const SizedBox(height: 10),
            Text(puzzle.title, style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            Text('Theme: ${puzzle.theme} · ${puzzle.difficulty}', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 14),
            Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(8)), child: Text('Solve Puzzle →', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
          ])),
          const SizedBox(width: 16),
          const Icon(Icons.extension, color: AppColors.primaryGreen, size: 60),
        ]),
      ),
    );
  }

  Widget _lessonCard(ChessLesson lesson) {
    final color = _catColor(lesson.category);
    return GestureDetector(
      onTap: () { _tap(); _go(LessonScreen(lesson: lesson)); },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderDark)),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(_catIcon(lesson.category), color: color, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(lesson.title, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 2),
            Text('${lesson.category} · ${lesson.difficulty}', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11)),
          ])),
          const Icon(Icons.arrow_forward_ios, color: AppColors.textMuted, size: 13),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // SETTINGS TAB
  // ══════════════════════════════════════════════════════
  Widget _buildSettings() {
    return ListView(padding: const EdgeInsets.all(20), children: [
      _sectionTitle('Settings'),
      const SizedBox(height: 20),

      _settingsGroup('🎨 Appearance', [
        _toggle('Dark Mode', _user.darkMode, Icons.dark_mode_outlined, (v) => _user.toggleDarkMode(v)),
        _divider(),
        _settingRow('Color Theme', _buildColorPicker()),
      ]),
      const SizedBox(height: 20),

      _settingsGroup('🔊 Sounds & Feel', [
        _toggle('Game Sounds', _user.soundsEnabled, Icons.volume_up_outlined, (v) { _user.toggleSounds(v); _sound.setMuted(!v); }),
        _divider(),
        _toggle('Move Vibration', _user.vibrationEnabled, Icons.vibration_outlined, (v) => _user.toggleVibration(v)),
      ]),
      const SizedBox(height: 20),

      _settingsGroup('♟ Gameplay', [
        _toggle('Confirm Moves', _user.confirmMoves, Icons.check_circle_outline, (v) => _user.toggleConfirmMoves(v)),
        _divider(),
        _tapRow('Board Theme', _user.boardTheme, Icons.palette_outlined, () => _pickBoardTheme()),
        _divider(),
        _tapRow('Piece Style', _user.pieceStyle, Icons.extension_outlined, () => _pickPieceStyle()),
      ]),
      const SizedBox(height: 20),

      _settingsGroup('ℹ️ About', [
        _infoRow('Version', '1.0.4'),
        _divider(),
        _infoRow('Engine', 'Stockfish 16'),
        _divider(),
        _infoRow('Developer', 'Chess Grandmaster Team'),
      ]),
    ]);
  }

  Widget _buildColorPicker() {
    final colors = [AppColors.primaryGreen, Colors.blue, Colors.purple, Colors.deepOrange, Colors.pink, Colors.teal];
    return Row(mainAxisSize: MainAxisSize.min, children: colors.map((c) => GestureDetector(
      onTap: () { _tap(); setState(() {}); },
      child: Container(margin: const EdgeInsets.only(left: 6), width: 26, height: 26, decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: c == AppColors.primaryGreen ? Border.all(color: Colors.white, width: 2) : null)),
    )).toList());
  }

  void _pickBoardTheme() {
    _tap();
    final themes = ['Classic Green', 'Wood', 'Ice', 'Midnight', 'Royal', 'Sand', 'Ocean', 'Walnut'];
    showModalBottomSheet(
      context: context, backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        Container(margin: const EdgeInsets.only(top: 10), width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
        Padding(padding: const EdgeInsets.all(18), child: Text('Board Theme', style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
        ...themes.map((t) => ListTile(
          leading: Icon(Icons.palette, color: _user.boardTheme == t ? AppColors.primaryGreen : AppColors.textMuted),
          title: Text(t, style: GoogleFonts.outfit(color: Colors.white)),
          trailing: _user.boardTheme == t ? const Icon(Icons.check, color: AppColors.primaryGreen) : null,
          onTap: () { _user.setBoardTheme(t); Navigator.pop(context); },
        )),
        const SizedBox(height: 16),
      ]),
    );
  }

  void _pickPieceStyle() {
    _tap();
    final styles = ['Neo', 'Classic', 'Minimal', 'Wooden'];
    showModalBottomSheet(
      context: context, backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        Container(margin: const EdgeInsets.only(top: 10), width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
        Padding(padding: const EdgeInsets.all(18), child: Text('Piece Style', style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
        ...styles.map((s) => ListTile(
          leading: Icon(Icons.extension, color: _user.pieceStyle == s ? AppColors.primaryGreen : AppColors.textMuted),
          title: Text(s, style: GoogleFonts.outfit(color: Colors.white)),
          trailing: _user.pieceStyle == s ? const Icon(Icons.check, color: AppColors.primaryGreen) : null,
          onTap: () { _user.setPieceStyle(s); Navigator.pop(context); },
        )),
        const SizedBox(height: 16),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════
  // PROFILE TAB
  // ══════════════════════════════════════════════════════
  Widget _buildProfile() {
    final total = _user.wins + _user.losses + _user.draws;
    final winRate = total == 0 ? 0.0 : _user.wins / total;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // Avatar
        CircleAvatar(radius: 44, backgroundColor: AppColors.cardDark, child: Icon(Icons.person, size: 48, color: AppColors.primaryGreen)),
        const SizedBox(height: 14),
        Text(_user.displayName, style: GoogleFonts.syne(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        Text('Chess Grandmaster Player', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13)),
        const SizedBox(height: 24),

        // Stats
        Row(children: [
          _bigStat(_user.elo.toString(), 'ELO Rating'),
          const SizedBox(width: 12),
          _bigStat('#--', 'Global Rank'),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _smallStat(_user.wins.toString(), 'Wins', AppColors.primaryGreen),
          const SizedBox(width: 8),
          _smallStat(_user.losses.toString(), 'Losses', AppColors.resignRed),
          const SizedBox(width: 8),
          _smallStat(_user.draws.toString(), 'Draws', AppColors.textMuted),
        ]),
        const SizedBox(height: 16),

        // Win rate bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderDark)),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Win Rate', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12)),
              Text('${(winRate * 100).toStringAsFixed(0)}%', style: GoogleFonts.syne(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: winRate, minHeight: 8, backgroundColor: Colors.white10, color: AppColors.primaryGreen)),
          ]),
        ),
        const SizedBox(height: 20),

        // Account details
        _settingsGroup('Account Details', [
          _editRow('Username', _user.displayName, (v) => _user.updateProfile(name: v)),
          _divider(),
          _editRow('Phone Number', _user.phoneNumber.isEmpty ? 'Not set' : _user.phoneNumber, (v) { _user.updateProfile(phoneNumber: v); _phoneCtrl.text = v; }),
          _divider(),
          _editRow('Favored Opening', _user.favoredOpening, (v) => _user.updateProfile(favoredOpening: v)),
          _divider(),
          _infoRow('Member Since', 'April 2026'),
        ]),

        const SizedBox(height: 24),

        // Sign out
        GestureDetector(
          onTap: () { _tap(); _snack('Signed out'); },
          child: Container(
            width: double.infinity, padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.resignRed.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.resignRed.withValues(alpha: 0.3))),
            child: Text('Sign Out', style: GoogleFonts.outfit(color: AppColors.resignRed, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════

  Widget _buildNav() {
    return Container(
      decoration: const BoxDecoration(color: AppColors.background, border: Border(top: BorderSide(color: AppColors.borderDark, width: 1))),
      child: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) { _tap(); setState(() => _tab = i); },
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 10),
        unselectedLabelStyle: GoogleFonts.outfit(fontSize: 10),
        items: [
          _navItem(Icons.grid_view_outlined, 'Play', 0),
          _navItem(Icons.school_outlined, 'Learn', 1),
          _navItem(Icons.settings_outlined, 'Settings', 2),
          _navItem(Icons.person_outline, 'Profile', 3),
        ],
      ),
    );
  }

  BottomNavigationBarItem _navItem(IconData icon, String label, int idx) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: _tab == idx ? AppColors.primaryGreen.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon),
      ),
      label: label,
    );
  }

  Widget _sectionTitle(String t) => Text(t, style: GoogleFonts.syne(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white));

  Widget _playCard({required String title, required String subtitle, required IconData icon, required String badge, required Color badgeColor, required Widget child, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.borderDark)),
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppColors.primaryGreen, size: 22)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text(subtitle, style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12)),
            ])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)), child: Text(badge, style: GoogleFonts.outfit(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 11))),
          ]),
          const SizedBox(height: 16),
          child,
        ]),
      ),
    );
  }

  Widget _infoBox(IconData icon, String title, String body) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.background.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: AppColors.primaryGreen, size: 14),
          const SizedBox(width: 6),
          Text(title, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ]),
        const SizedBox(height: 6),
        Text(body, style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12, height: 1.4)),
      ]),
    );
  }

  Widget _settingsGroup(String title, List<Widget> children) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11, letterSpacing: 1)),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderDark)),
        child: Column(children: children),
      ),
    ]);
  }

  Widget _toggle(String label, bool val, IconData icon, Function(bool) onChanged) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textMuted, size: 20),
      title: Text(label, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14)),
      trailing: Switch(value: val, onChanged: (v) { _tap(); onChanged(v); }, activeColor: AppColors.primaryGreen, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
    );
  }

  Widget _tapRow(String label, String value, IconData icon, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.textMuted, size: 20),
      title: Text(label, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(width: 6),
        const Icon(Icons.arrow_forward_ios, color: AppColors.textMuted, size: 12),
      ]),
    );
  }

  Widget _settingRow(String label, Widget trailing) {
    return ListTile(
      title: Text(label, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14)),
      trailing: trailing,
    );
  }

  Widget _infoRow(String label, String value) {
    return ListTile(
      title: Text(label, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14)),
      trailing: Text(value, style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13)),
    );
  }

  Widget _editRow(String label, String value, Function(String) onSave) {
    return ListTile(
      title: Text(label, style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11)),
      subtitle: Text(value, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: IconButton(
        icon: const Icon(Icons.edit, color: AppColors.textMuted, size: 16),
        onPressed: () {
          _tap();
          final ctrl = TextEditingController(text: value == 'Not set' ? '' : value);
          showDialog(context: context, builder: (_) => AlertDialog(
            backgroundColor: AppColors.cardDark,
            title: Text('Edit $label', style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.bold)),
            content: TextField(
              controller: ctrl,
              style: GoogleFonts.outfit(color: Colors.white),
              keyboardType: label == 'Phone Number' ? TextInputType.phone : TextInputType.text,
              decoration: InputDecoration(
                hintText: 'Enter $label',
                hintStyle: GoogleFonts.outfit(color: Colors.white38),
                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.borderDark)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryGreen)),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white54))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: () { onSave(ctrl.text.trim()); Navigator.pop(context); setState(() {}); },
                child: Text('Save', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ));
        },
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, color: AppColors.borderDark, indent: 16, endIndent: 16);

  Widget _bigStat(String val, String label) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderDark)),
      child: Column(children: [
        Text(val, style: GoogleFonts.syne(color: AppColors.primaryGreen, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11)),
      ]),
    ));
  }

  Widget _smallStat(String val, String label, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderDark)),
      child: Column(children: [
        Text(val, style: GoogleFonts.syne(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.outfit(color: color, fontSize: 11)),
      ]),
    ));
  }

  Widget _statChip(String val, String label, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Column(children: [
        Text(val, style: GoogleFonts.syne(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.outfit(color: color.withValues(alpha: 0.8), fontSize: 10), textAlign: TextAlign.center),
      ]),
    ));
  }

  Color _catColor(String cat) {
    switch (cat) {
      case 'Tutorial': return AppColors.tutorialBlue;
      case 'Openings': return AppColors.openingGreen;
      case 'Tactics': return AppColors.puzzleGold;
      case 'Endgames': return AppColors.endgameRed;
      default: return AppColors.primaryGreen;
    }
  }

  IconData _catIcon(String cat) {
    switch (cat) {
      case 'Tutorial': return Icons.school_outlined;
      case 'Openings': return Icons.grid_view_outlined;
      case 'Tactics': return Icons.bolt;
      case 'Endgames': return Icons.flag_outlined;
      default: return Icons.book_outlined;
    }
  }

  void _go(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: GoogleFonts.outfit()), backgroundColor: AppColors.cardDark, duration: const Duration(seconds: 2)));
}
