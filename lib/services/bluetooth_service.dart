import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// GATT UUIDs for chess protocol
const _svcUuid  = '12345678-1234-1234-1234-123456789abc';
const _moveUuid = '12345678-1234-1234-1234-123456789abd';
const _pinUuid  = '12345678-1234-1234-1234-123456789abe'; // PIN characteristic

class ChessBluetoothService {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _moveChar;
  BluetoothCharacteristic? _pinChar;

  final _scanCtrl   = StreamController<List<ScanResult>>.broadcast();
  final _moveCtrl   = StreamController<String>.broadcast();
  final _statusCtrl = StreamController<String>.broadcast();
  final _pinCtrl    = StreamController<String>.broadcast();

  Stream<List<ScanResult>> get scanResults => _scanCtrl.stream;
  Stream<String> get moveReceived => _moveCtrl.stream;
  Stream<String> get status       => _statusCtrl.stream;
  Stream<String> get pinReceived  => _pinCtrl.stream;
  bool get isConnected => _device != null;

  // The 4-digit PIN generated for this session
  String? _localPin;
  String? get localPin => _localPin;

  ChessBluetoothService() {
    FlutterBluePlus.scanResults.listen((r) {
      if (!_scanCtrl.isClosed) _scanCtrl.add(r);
    });
  }

  // ── Generate a 4-digit PIN ────────────────────────────────────────────────
  String generatePin() {
    _localPin = (1000 + Random().nextInt(9000)).toString();
    return _localPin!;
  }

  // ── Scanning ──────────────────────────────────────────────────────────────
  Future<bool> isSupported() async => FlutterBluePlus.isSupported;

  Future<void> startScan() async {
    try {
      if (!await isSupported()) { _emit('Bluetooth not supported.'); return; }
      final state = await FlutterBluePlus.adapterState.first;
      if (state != BluetoothAdapterState.on) { _emit('Bluetooth is OFF — please enable it.'); return; }
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
      _emit('Scanning for nearby players…');
    } catch (e) {
      _emit('Scan error: $e');
      debugPrint('[BT] startScan: $e');
    }
  }

  Future<void> stopScan() async {
    try { await FlutterBluePlus.stopScan(); } catch (_) {}
  }

  // ── Connect + discover chess service ─────────────────────────────────────
  Future<bool> connectToDevice(BluetoothDevice device) async {
    int attempts = 0;
    const maxAttempts = 3;

    while (attempts < maxAttempts) {
      try {
        attempts++;
        _emit('Connecting to ${device.platformName} (Attempt $attempts)…');
        await device.connect(timeout: const Duration(seconds: 12));
        _device = device;

        device.connectionState.listen((s) {
          if (s == BluetoothConnectionState.disconnected) {
            _device = null; _moveChar = null; _pinChar = null;
            _emit('Disconnected.');
          }
        });

        final services = await device.discoverServices();
        for (final svc in services) {
          if (svc.uuid.toString().toLowerCase() != _svcUuid) continue;
          for (final c in svc.characteristics) {
            final uuid = c.uuid.toString().toLowerCase();
            if (uuid == _moveUuid) {
              _moveChar = c;
              await c.setNotifyValue(true);
              c.onValueReceived.listen((v) {
                final msg = utf8.decode(v).trim();
                debugPrint('[BT] move received: $msg');
                _moveCtrl.add(msg);
              });
            }
            if (uuid == _pinUuid) {
              _pinChar = c;
              await c.setNotifyValue(true);
              c.onValueReceived.listen((v) {
                final pin = utf8.decode(v).trim();
                debugPrint('[BT] PIN received: $pin');
                _pinCtrl.add(pin);
              });
            }
          }
        }
        _emit('Connected to ${device.platformName}!');
        return true;
      } catch (e) {
        debugPrint('[BT] connect error (Attempt $attempts): $e');
        if (attempts >= maxAttempts) {
          _emit('Connection failed after $maxAttempts attempts: $e');
          return false;
        }
        await Future.delayed(const Duration(seconds: 2)); // Wait before retry
      }
    }
    return false;
  }

  // ── Send PIN to other device ──────────────────────────────────────────────
  Future<void> sendPin(String pin) async {
    if (_pinChar == null) return;
    try {
      await _pinChar!.write(utf8.encode(pin), withoutResponse: false);
      debugPrint('[BT] PIN sent: $pin');
    } catch (e) {
      debugPrint('[BT] sendPin error: $e');
    }
  }

  // ── Send chess move ───────────────────────────────────────────────────────
  Future<void> sendMove(String uci) async {
    if (_moveChar == null) { _emit('Not connected.'); return; }
    try {
      await _moveChar!.write(utf8.encode(uci), withoutResponse: false);
      debugPrint('[BT] move sent: $uci');
    } catch (e) {
      _emit('Send error: $e');
      debugPrint('[BT] sendMove error: $e');
    }
  }

  void _emit(String msg) {
    if (!_statusCtrl.isClosed) _statusCtrl.add(msg);
  }

  void dispose() {
    _scanCtrl.close();
    _moveCtrl.close();
    _statusCtrl.close();
    _pinCtrl.close();
    _device?.disconnect();
    _device = null;
  }
}
