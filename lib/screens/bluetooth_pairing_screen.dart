import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_colors.dart';
import '../services/bluetooth_service.dart';
import '../services/sound_service.dart';
import 'chess_screen.dart';

class BluetoothPairingScreen extends StatefulWidget {
  const BluetoothPairingScreen({Key? key}) : super(key: key);
  @override
  State<BluetoothPairingScreen> createState() => _BluetoothPairingScreenState();
}

class _BluetoothPairingScreenState extends State<BluetoothPairingScreen> {
  final ChessBluetoothService _bt = ChessBluetoothService();
  final SoundService _sound = SoundService();

  // Screen states: scanning → connecting → pinVerify → lobby
  String _stage = 'scanning';
  BluetoothDevice? _device;
  String? _myPin;        // PIN this device generated
  String? _remotePin;    // PIN received from other device
  bool   _pinMatch = false;
  bool   _scanning = false;
  String _statusMsg = 'Tap Scan to find nearby players';
  List<ScanResult> _results = [];
  StreamSubscription? _statusSub;
  StreamSubscription? _scanSub;
  StreamSubscription? _pinSub;

  // Lobby settings
  String _myColor    = 'White';
  String _timeControl = '10 min';
  bool   _chatEnabled = true;

  @override
  void initState() {
    super.initState();
    _statusSub = _bt.status.listen((m) {
      if (mounted) setState(() => _statusMsg = m);
    });
    _scanSub = _bt.scanResults.listen((r) {
      if (mounted) setState(() => _results = r.where((s) => s.device.platformName.isNotEmpty).toList());
    });
    _pinSub = _bt.pinReceived.listen((pin) {
      if (mounted) {
        setState(() {
          _remotePin = pin;
          _checkPins();
        });
      }
    });
  }

  void _checkPins() {
    if (_myPin != null && _remotePin != null && _myPin == _remotePin) {
      setState(() { _pinMatch = true; _stage = 'lobby'; });
      _sound.playButtonTap();
      _snack('✓ Codes match! Game lobby unlocked.');
    }
  }

  Future<void> _startScan() async {
    // Request permissions first
    final sc = await Permission.bluetoothScan.request();
    final co = await Permission.bluetoothConnect.request();
    if (!sc.isGranted || !co.isGranted) {
      _snack('Bluetooth permissions required');
      return;
    }
    setState(() { _scanning = true; _results = []; _stage = 'scanning'; });
    await _bt.startScan();
    // Stop scanning after 15s
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted) setState(() => _scanning = false);
    });
  }

  Future<void> _connectTo(BluetoothDevice device) async {
    setState(() { _stage = 'connecting'; _statusMsg = 'Connecting…'; });
    _sound.playButtonTap();
    final ok = await _bt.connectToDevice(device);
    if (!ok) {
      setState(() { _stage = 'scanning'; });
      return;
    }
    // Generate PIN and send to other device
    final pin = _bt.generatePin();
    setState(() { _device = device; _myPin = pin; _stage = 'pinVerify'; });
    await _bt.sendPin(pin);
  }

  void _startGame() {
    if (!_pinMatch) { _snack('Verify PIN first'); return; }
    _sound.playButtonTap();
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => ChessScreen(mode: 'bluetooth'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () { _bt.dispose(); Navigator.pop(context); },
        ),
        title: Text('Bluetooth Play', style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_stage) {
      case 'connecting': return _buildConnecting();
      case 'pinVerify':  return _buildPinVerify();
      case 'lobby':      return _buildLobby();
      default:           return _buildScanning();
    }
  }

  // ── SCANNING ──────────────────────────────────────────────────
  Widget _buildScanning() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        _statusCard(),
        const SizedBox(height: 20),

        // Scan button
        GestureDetector(
          onTap: _scanning ? null : _startScan,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _scanning ? AppColors.cardDark : AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _scanning ? AppColors.borderDark : AppColors.primaryGreen),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (_scanning) ...[
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGreen)),
                const SizedBox(width: 10),
                Text('Scanning…', style: GoogleFonts.outfit(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 14)),
              ] else ...[
                const Icon(Icons.bluetooth_searching, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Scan for Players', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ]),
          ),
        ),

        const SizedBox(height: 20),

        if (_results.isEmpty && !_scanning)
          Center(child: Column(children: [
            const Icon(Icons.bluetooth_disabled, color: AppColors.textMuted, size: 48),
            const SizedBox(height: 12),
            Text('No devices found.\nMake sure both devices have Bluetooth ON and the app open.', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13, height: 1.5), textAlign: TextAlign.center),
          ]))
        else
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (_, i) => _deviceCard(_results[i]),
            ),
          ),

        // How it works
        const SizedBox(height: 12),
        _infoBox('How Bluetooth Play Works', 'Both players open this screen and tap Scan. Tap the other player\'s device name to connect. A 4-digit code is generated — both phones must show the same code to start.'),
      ]),
    );
  }

  Widget _deviceCard(ScanResult r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderDark)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.phone_android, color: AppColors.primaryGreen, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r.device.platformName, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          Text('Signal: ${r.rssi} dBm', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11)),
        ])),
        GestureDetector(
          onTap: () => _connectTo(r.device),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(8)),
            child: Text('Connect', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
      ]),
    );
  }

  // ── CONNECTING ────────────────────────────────────────────────
  Widget _buildConnecting() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const SizedBox(width: 60, height: 60, child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primaryGreen)),
      const SizedBox(height: 24),
      Text('Connecting…', style: GoogleFonts.syne(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text(_statusMsg, style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13)),
    ]));
  }

  // ── PIN VERIFY ────────────────────────────────────────────────
  Widget _buildPinVerify() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        _statusCard(),
        const SizedBox(height: 32),

        // PIN display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Column(children: [
            const Icon(Icons.lock_outline, color: AppColors.primaryGreen, size: 32),
            const SizedBox(height: 16),
            Text('Your Pairing Code', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 12),
            // The 4-digit PIN - large and prominent
            Text(
              _myPin ?? '----',
              style: GoogleFonts.syne(
                color: AppColors.primaryGreen,
                fontSize: 56,
                fontWeight: FontWeight.bold,
                letterSpacing: 14,
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2.seconds, color: Colors.white24),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
              child: Text(
                'Show this code to your opponent.\nBoth devices must show the SAME code.\nThis confirms you are playing with the right person.',
                style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12, height: 1.6),
                textAlign: TextAlign.center,
              ),
            ),
          ]),
        ),

        const SizedBox(height: 24),

        // Waiting for other device
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderDark)),
          child: Row(children: [
            _remotePin == null
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGreen))
                : Icon(_remotePin == _myPin ? Icons.check_circle : Icons.cancel, color: _remotePin == _myPin ? AppColors.primaryGreen : AppColors.resignRed, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(
              _remotePin == null
                  ? 'Waiting for opponent\'s code…'
                  : _remotePin == _myPin
                      ? 'Codes match! You\'re connected securely.'
                      : 'Code mismatch (got: $_remotePin). Wrong device?',
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
            )),
          ]),
        ),

        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () { _bt.dispose(); setState(() { _stage = 'scanning'; _device = null; _myPin = null; _remotePin = null; _pinMatch = false; }); },
          icon: const Icon(Icons.close, color: AppColors.textMuted, size: 16),
          label: Text('Cancel & re-scan', style: GoogleFonts.outfit(color: AppColors.textMuted)),
        ),
      ]),
    );
  }

  // ── LOBBY ─────────────────────────────────────────────────────
  Widget _buildLobby() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // Connected badge
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.primaryGreen.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.4))),
          child: Row(children: [
            const Icon(Icons.bluetooth_connected, color: AppColors.primaryGreen, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Connected & Verified', style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              Text('Playing with ${_device?.platformName ?? "opponent"}  ·  Code: $_myPin', style: GoogleFonts.outfit(color: AppColors.primaryGreen, fontSize: 11)),
            ])),
            const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 22),
          ]),
        ).animate().fadeIn(duration: 300.ms),

        const SizedBox(height: 20),

        // Game settings
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderDark)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Game Settings', style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 16),

            // Color selection
            Text('Play as', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 8),
            Row(children: ['White', 'Black'].map((c) => Expanded(
              child: GestureDetector(
                onTap: () { setState(() => _myColor = c); _sound.playButtonTap(); },
                child: Container(
                  margin: EdgeInsets.only(right: c == 'White' ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _myColor == c ? AppColors.primaryGreen.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _myColor == c ? AppColors.primaryGreen : AppColors.borderDark),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.circle, color: c == 'White' ? Colors.white : Colors.black, size: 14, shadows: c == 'Black' ? [const Shadow(color: Colors.white30, blurRadius: 2)] : null),
                    const SizedBox(width: 6),
                    Text(c, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ]),
                ),
              ),
            )).toList()),

            const SizedBox(height: 16),

            // Time control
            Text('Time Control', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: ['No Limit', '5 min', '10 min', '15 min'].map((t) => GestureDetector(
                onTap: () { setState(() => _timeControl = t); _sound.playButtonTap(); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _timeControl == t ? AppColors.primaryGreen : AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _timeControl == t ? AppColors.primaryGreen : AppColors.borderDark),
                  ),
                  child: Text(t, style: GoogleFonts.outfit(color: _timeControl == t ? Colors.white : AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              )).toList(),
            ),

            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Enable Chat', style: GoogleFonts.outfit(color: Colors.white, fontSize: 14)),
              Switch(value: _chatEnabled, onChanged: (v) => setState(() => _chatEnabled = v), activeColor: AppColors.primaryGreen),
            ]),
          ]),
        ),

        const SizedBox(height: 20),

        // Start game button
        GestureDetector(
          onTap: _startGame,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00B873), Color(0xFF00D4A0)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppColors.primaryGreen.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.play_arrow, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text('Start Game', style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
            ]),
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
      ]),
    );
  }

  // ── Shared widgets ─────────────────────────────────────────────
  Widget _statusCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.borderDark)),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: _stage == 'scanning' ? AppColors.textMuted : AppColors.primaryGreen)),
        const SizedBox(width: 10),
        Expanded(child: Text(_statusMsg, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12))),
      ]),
    );
  }

  Widget _infoBox(String title, String body) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderDark)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 6),
        Text(body, style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12, height: 1.5)),
      ]),
    );
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: GoogleFonts.outfit()),
    backgroundColor: AppColors.cardDark,
    duration: const Duration(seconds: 3),
  ));

  @override
  void dispose() {
    _statusSub?.cancel();
    _scanSub?.cancel();
    _pinSub?.cancel();
    _bt.dispose();
    super.dispose();
  }
}
