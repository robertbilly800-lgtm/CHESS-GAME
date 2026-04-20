import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class UserService extends ChangeNotifier {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;

  // Profile Data
  String _displayName = "Chess Master";
  int _elo = 1200;
  int _wins = 0;
  int _losses = 0;
  int _draws = 0;
  String _favoredOpening = "Ruy Lopez";
  String _phoneNumber = "";
  List<String> _smsContacts = [];
  String _boardTheme = "Classic Green";
  String _pieceStyle = "Neo";

  // Settings Data
  bool _darkMode = true;
  bool _soundsEnabled = true;
  bool _vibrationEnabled = true;
  bool _confirmMoves = true;

  // Getters
  bool get initialized => _initialized;
  String get displayName => _displayName;
  int get elo => _elo;
  int get wins => _wins;
  int get losses => _losses;
  int get draws => _draws;
  String get favoredOpening => _favoredOpening;
  String get phoneNumber => _phoneNumber;
  List<String> get smsContacts => _smsContacts;
  String get boardTheme => _boardTheme;
  String get pieceStyle => _pieceStyle;
  bool get darkMode => _darkMode;
  bool get soundsEnabled => _soundsEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get confirmMoves => _confirmMoves;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    
    _displayName = _prefs.getString('displayName') ?? "Chess Master";
    _elo = _prefs.getInt('elo') ?? 1200;
    _wins = _prefs.getInt('wins') ?? 0;
    _losses = _prefs.getInt('losses') ?? 0;
    _draws = _prefs.getInt('draws') ?? 0;
    _favoredOpening = _prefs.getString('favoredOpening') ?? "Ruy Lopez";
    _phoneNumber = _prefs.getString('phoneNumber') ?? "";
    _smsContacts = _prefs.getStringList('smsContacts') ?? [];
    _boardTheme = _prefs.getString('boardTheme') ?? "Classic Green";
    _pieceStyle = _prefs.getString('pieceStyle') ?? "Neo";
    
    _darkMode = _prefs.getBool('darkMode') ?? true;
    _soundsEnabled = _prefs.getBool('soundsEnabled') ?? true;
    _vibrationEnabled = _prefs.getBool('vibrationEnabled') ?? true;
    _confirmMoves = _prefs.getBool('confirmMoves') ?? true;

    _initialized = true;
    notifyListeners();
  }

  // Setters
  Future<void> updateProfile({String? name, int? elo, String? favoredOpening, String? phoneNumber}) async {
    if (name != null) {
      _displayName = name;
      await _prefs.setString('displayName', name);
    }
    if (elo != null) {
      _elo = elo;
      await _prefs.setInt('elo', elo);
    }
    if (favoredOpening != null) {
      _favoredOpening = favoredOpening;
      await _prefs.setString('favoredOpening', favoredOpening);
    }
    if (phoneNumber != null) {
      _phoneNumber = phoneNumber;
      await _prefs.setString('phoneNumber', phoneNumber);
    }
    notifyListeners();
  }

  Future<void> addSmsContact(String phone) async {
    if (!_smsContacts.contains(phone)) {
      _smsContacts.insert(0, phone);
      if (_smsContacts.length > 5) _smsContacts.removeLast();
      await _prefs.setStringList('smsContacts', _smsContacts);
      notifyListeners();
    }
  }

  Future<void> removeSmsContact(String phone) async {
    if (_smsContacts.contains(phone)) {
      _smsContacts.remove(phone);
      await _prefs.setStringList('smsContacts', _smsContacts);
      notifyListeners();
    }
  }

  Future<void> recordGameResult(String result) async {
    if (result == 'win') {
      _wins++;
      _elo += 15;
      await _prefs.setInt('wins', _wins);
    } else if (result == 'loss') {
      _losses++;
      _elo = (_elo - 10).clamp(100, 3000);
      await _prefs.setInt('losses', _losses);
    } else {
      _draws++;
      _elo += 2;
      await _prefs.setInt('draws', _draws);
    }
    await _prefs.setInt('elo', _elo);
    notifyListeners();
  }

  // Settings Setters
  Future<void> toggleDarkMode(bool value) async { _darkMode = value; await _prefs.setBool('darkMode', value); notifyListeners(); }
  Future<void> toggleSounds(bool value) async { _soundsEnabled = value; await _prefs.setBool('soundsEnabled', value); notifyListeners(); }
  Future<void> toggleVibration(bool value) async { _vibrationEnabled = value; await _prefs.setBool('vibrationEnabled', value); notifyListeners(); }
  Future<void> toggleConfirmMoves(bool value) async { _confirmMoves = value; await _prefs.setBool('confirmMoves', value); notifyListeners(); }
  Future<void> setBoardTheme(String theme) async { _boardTheme = theme; await _prefs.setString('boardTheme', theme); notifyListeners(); }
  Future<void> setPieceStyle(String style) async { _pieceStyle = style; await _prefs.setString('pieceStyle', style); notifyListeners(); }
}
