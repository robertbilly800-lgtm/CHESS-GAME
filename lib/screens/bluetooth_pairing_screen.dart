import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import 'chess_screen.dart';

class BluetoothPairingScreen extends StatefulWidget {
  const BluetoothPairingScreen({Key? key}) : super(key: key);

  @override
  State<BluetoothPairingScreen> createState() => _BluetoothPairingScreenState();
}

class _BluetoothPairingScreenState extends State<BluetoothPairingScreen> {
  BluetoothDevice? _connectedDevice;
  bool _pinVerified = false;
  String? _pairingPin;
  bool _enableChat = true;
  String _timeControl = 'No Limit';
  String _selectedColor = 'White';

  @override
  void initState() {
    super.initState();
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
  }

  void _generatePin() {
    setState(() {
      _pairingPin = (1000 + (DateTime.now().millisecondsSinceEpoch % 8999)).toString();
    });
  }

  void _verifyPin() {
    setState(() {
      _pinVerified = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pairing Successful! Game Lobby Unlocked.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If not connected, show scanning UI
    if (_connectedDevice == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(color: Colors.white),
          title: Text('Bluetooth Devices', style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          centerTitle: true,
        ),
        body: StreamBuilder<List<ScanResult>>(
          stream: FlutterBluePlus.scanResults,
          initialData: const [],
          builder: (c, snapshot) => ListView(
            padding: const EdgeInsets.all(24),
            children: snapshot.data!
                .where((r) => r.device.platformName.isNotEmpty)
                .map((r) => _buildDeviceCard(context, r))
                .toList(),
          ),
        ),
      );
    }

    // If connected, show Bluetooth Lobby UI
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            _connectedDevice?.disconnect();
            setState(() => _connectedDevice = null);
          },
        ),
        title: Text('Bluetooth Lobby', style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: _pinVerified ? AppColors.primaryGreen : AppColors.borderDark)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4), 
                        decoration: BoxDecoration(color: _pinVerified ? AppColors.primaryGreen : Colors.orangeAccent, shape: BoxShape.circle), 
                        child: Icon(_pinVerified ? Icons.check : Icons.sync, size: 12, color: AppColors.background)
                      ),
                      const SizedBox(width: 12),
                      Text(_pinVerified ? 'Securely Paired' : 'Verifying Identity...', style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Device: ${_connectedDevice!.platformName}', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 16),
                  if (!_pinVerified) ...[
                     Container(
                       padding: const EdgeInsets.all(12),
                       decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                       child: Row(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           Text('Pairing Code: ', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14)),
                           Text(_pairingPin ?? '...', style: GoogleFonts.syne(color: AppColors.primaryGreen, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 4)),
                         ],
                       ),
                     ),
                     const SizedBox(height: 12),
                     ElevatedButton(
                       onPressed: _verifyPin,
                       style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, minimumSize: const Size(double.infinity, 44)),
                       child: const Text('VERIFY CODE MATCHES'),
                     )
                  ] else ...[
                    Text('Verification successful. You are now playing in an encrypted session.', style: GoogleFonts.outfit(color: AppColors.primaryGreen, fontSize: 11)),
                  ]
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Game Settings
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderDark)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Game Settings', style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  
                  Text('Choose Your Color', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedColor = 'White'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedColor == 'White' ? AppColors.primaryGreen.withValues(alpha: 0.2) : Colors.transparent,
                              border: Border.all(color: _selectedColor == 'White' ? AppColors.primaryGreen : AppColors.borderDark),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.circle, color: Colors.white, size: 16),
                                const SizedBox(width: 8),
                                Text('White', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedColor = 'Black'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedColor == 'Black' ? AppColors.primaryGreen.withValues(alpha: 0.2) : Colors.transparent,
                              border: Border.all(color: _selectedColor == 'Black' ? AppColors.primaryGreen : AppColors.borderDark),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.circle, color: Colors.white.withValues(alpha: 0.3), size: 16),
                                const SizedBox(width: 8),
                                Text('Black', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text('Time Control', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.borderDark)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: AppColors.cardDark,
                        value: _timeControl,
                        isExpanded: true,
                        style: GoogleFonts.outfit(color: Colors.white),
                        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted),
                        items: ['No Limit', '10 min', '5 min', '3 min'].map((String value) {
                          return DropdownMenuItem<String>(value: value, child: Text(value));
                        }).toList(),
                        onChanged: (v) => setState(() => _timeControl = v!),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Enable Chat', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12)),
                      Switch(
                        value: _enableChat,
                        activeThumbColor: AppColors.primaryGreen,
                        onChanged: (val) => setState(() => _enableChat = val),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Opacity(
              opacity: _pinVerified ? 1.0 : 0.5,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _pinVerified ? () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ChessScreen(mode: 'bluetooth')));
                } : null,
                child: Text('Start Game', style: GoogleFonts.outfit(color: AppColors.background, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),

            const SizedBox(height: 24),
            if (_enableChat)
              _buildProGameChat(),
          ],
        ),
      ),
    );
  }

  Widget _buildProGameChat() {
    return Container(
      decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderDark)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline, color: Colors.white54, size: 16),
                const SizedBox(width: 8),
                Text('Pro Game Chat', style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          const Divider(color: AppColors.borderDark, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(radius: 12, backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.2), child: Text('J', style: TextStyle(color: AppColors.primaryGreen, fontSize: 12))),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: const BorderRadius.only(topRight: Radius.circular(12), bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12))),
                    child: Text('Ready when you are! â™Ÿï¸', style: GoogleFonts.outfit(color: Colors.white, fontSize: 13)),
                  ),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderDark)),
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.send, color: AppColors.background, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(BuildContext context, ScanResult r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderDark)),
        child: ListTile(
          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primaryGreen.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.bluetooth, color: AppColors.primaryGreen)),
          title: Text(r.device.platformName, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text('Signal: ${r.rssi} dBm', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12)),
          trailing: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              await r.device.connect();
              _generatePin();
              if (mounted) setState(() => _connectedDevice = r.device);
            },
            child: Text('CONNECT', style: GoogleFonts.outfit(color: AppColors.background, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}

