import 'dart:async';
import 'package:flutter/material.dart';
import 'package:crashlog/crashlog.dart';          // ADDED for logging
import '../widgets/chess/simple_chess_board.dart';
import 'package:chess/chess.dart' as ch;
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';

import '../theme/app_colors.dart';
import '../services/ai_service.dart';
import '../services/sms_service.dart';
import '../services/bluetooth_service.dart';
import '../services/sound_service.dart';
import '../services/online_service.dart';
import '../services/user_service.dart';

bool _isWhiteTurn(ch.Chess game) => game.turn == ch.Color.WHITE;

class ChessScreen extends StatefulWidget {
  final String mode;
  final String? opponentPhone;
  final String? username;
  final int? userElo;

  const ChessScreen({
    super.key,
    this.mode = 'local',
    this.opponentPhone,
    this.username,
    this.userElo,
  });

  @override
  State<ChessScreen> createState() => _ChessScreenState();
}

class _ChessScreenState extends State<ChessScreen> with TickerProviderStateMixin {
  ch.Chess _game = ch.Chess();
  List<String> _moveHistory = [];
  String _activeTheme = 'Classic Green';

  AiService? _ai;
  SmsService? _sms;
  ChessBluetoothService? _bt;
  SoundService? _sound;
  OnlineService? _online;
  final UserService _user = UserService();

  bool _isHardwareValid = true;
  String _errorMsg = '';
  bool _aiThinking = false;
  int _aiLevel = 5;
  String _statusMsg = "White's turn";
  String _btStatus = '';
  String _onlineStatus = '';
  bool _gameOver = false;

  // Timers
  int _whiteTime = 600;
  int _blackTime = 600;
  Timer? _clockTimer;

  // Captures
  List<String> _whiteCaptured = [];
  List<String> _blackCaptured = [];

  // Online
  String _opponentName = 'Opponent';
  int _opponentElo = 1200;
  bool _isMyTurn = true;
  String? _myColor;

  // Chat
  final TextEditingController _chatCtrl = TextEditingController();
  List<Map<String, dynamic>> _chatMessages = [];
  StreamSubscription? _chatSub;

  // Piece move animation
  late AnimationController _moveAnimCtrl;
  late Animation<double> _moveAnim;

  @override
  void initState() {
    super.initState();
    _moveAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _moveAnim = CurvedAnimation(parent: _moveAnimCtrl, curve: Curves.easeOutCubic);
    _activeTheme = _user.boardTheme;
    _initServices();
  }

  void _startClock() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _gameOver) { _clockTimer?.cancel(); return; }
      setState(() {
        if (_isWhiteTurn(_game)) {
          if (_whiteTime > 0) _whiteTime--; else { _clockTimer?.cancel(); _endGame("Black wins on time!"); }
        } else {
          if (_blackTime > 0) _blackTime--; else { _clockTimer?.cancel(); _endGame("White wins on time!"); }
        }
      });
    });
  }

  String _fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  Future<void> _initServices() async {
    _sound = SoundService();
    _sound!.setMuted(!_user.soundsEnabled);

    debugPrint('[Chess] _initServices for mode: ${widget.mode}');
    try {
      switch (widget.mode) {
        case 'ai':
          debugPrint('[Chess] Creating AiService...');
          _ai = AiService();
          debugPrint('[Chess] Calling _ai!.init()...');
          await _ai!.init();
          debugPrint('[Chess] _ai!.init() completed. isHardwareSupported=${_ai!.isHardwareSupported}');
          if (_ai!.isHardwareSupported) {
            _ai!.setDifficulty(_aiLevel);
            _startClock();
            debugPrint('[Chess] AI mode ready.');
          } else {
            debugPrint('[Chess] AI not supported: ${_ai!.errorMsg}');
            setState(() { _isHardwareValid = false; _errorMsg = _ai!.errorMsg.isNotEmpty ? _ai!.errorMsg : 'AI not supported on this device.'; });
          }
          break;

        case 'local':
          _startClock();
          break;

        case 'sms':
          _sms = SmsService();
          if (await _sms!.isSupported()) {
            final ok = await _requestSmsPerms();
            if (ok) {
              try {
                _sms!.listenForMoves(onMoveReceived: _applyOpponentMove);
                _startClock();
              } catch (e) {
                _snack('Failed to listen for SMS: $e');
                setState(() { _isHardwareValid = false; _errorMsg = 'SMS listen error: $e'; });
              }
            } else _snack('SMS permissions denied.');
          } else {
            setState(() { _isHardwareValid = false; _errorMsg = 'SMS not available. Check SIM card.'; });
          }
          break;

        case 'bluetooth':
          _bt = ChessBluetoothService();
          if (await _bt!.isSupported()) {
            final ok = await _requestBtPerms();
            if (ok) {
              _bt!.status.listen((m) { if (mounted) setState(() => _btStatus = m); });
              _bt!.moveReceived.listen(_applyOpponentMove);
              await _bt!.startScan();
              _startClock();
            } else _snack('Bluetooth permissions denied.');
          } else {
            setState(() { _isHardwareValid = false; _errorMsg = 'Bluetooth not supported.'; });
          }
          break;

        case 'online':
          _online = OnlineService();
          _online!.statusStream.listen((m) { if (mounted) setState(() => _onlineStatus = m); });
          final roomId = await _online!.findMatch(username: widget.username ?? 'Player', elo: widget.userElo ?? 1200);
          if (roomId != null) {
            _myColor = _online!.myColor;
            _isMyTurn = _myColor == 'white';
            _online!.moveReceived.listen(_applyOpponentMove);
            _startClock();
          }
          break;
      }
    } catch (e) {
      debugPrint('[Chess] init error: $e');
      setState(() { _isHardwareValid = false; _errorMsg = 'Failed to init: $e'; });
    }
  }

  Future<bool> _requestSmsPerms() async {
    final s = await Permission.sms.request();
    final p = await Permission.phone.request();
    if (!s.isGranted || !p.isGranted) {
      if (await Permission.sms.isPermanentlyDenied || await Permission.phone.isPermanentlyDenied) {
        openAppSettings();
      }
    }
    return s.isGranted && p.isGranted;
  }

  Future<bool> _requestBtPerms() async {
    final sc = await Permission.bluetoothScan.request();
    final co = await Permission.bluetoothConnect.request();
    return sc.isGranted && co.isGranted;
  }

  void _onBoardMove(String from, String to) {
    if (_gameOver || _aiThinking) return;

    if (widget.mode == 'online') {
      final isWhite = _isWhiteTurn(_game);
      if ((_myColor == 'white' && !isWhite) || (_myColor == 'black' && isWhite)) {
        _snack("Not your turn"); return;
      }
    }

    final move = _game.move({'from': from, 'to': to, 'promotion': 'q'});
    if (move == null) return;

    _moveAnimCtrl.forward(from: 0);
    _onMoveExecuted(from + to, move);
  }

  void _onMoveExecuted(String uci, dynamic move) {
    if (move['captured'] != null) {
      _sound?.playCapture();
      (_isWhiteTurn(_game) ? _blackCaptured : _whiteCaptured).add(move['captured'] as String);
    } else {
      _sound?.playMove();
    }
    if (_game.in_check) _sound?.playCheck();

    if (_user.vibrationEnabled) Vibration.vibrate(duration: 25);

    _updateStatus();
    if (mounted) setState(() => _moveHistory.add(uci));

    if (_game.game_over) {
      _clockTimer?.cancel();
      _sound?.playGameOver();
      _gameOver = true;
      _showGameOverDialog();
      return;
    }

    if (widget.mode == 'ai' && !_isWhiteTurn(_game)) {
      debugPrint('[Chess] Human move done, now triggering AI move');
      _triggerAiMove();
    }
    if (widget.mode == 'sms') {
      final phone = widget.opponentPhone;
      if (phone != null && phone.trim().isNotEmpty) {
        _sms?.sendMove(phoneNumber: phone, sanMove: uci, onResult: (ok) {
          if (!ok && mounted) _snack('SMS send failed.');
        });
      } else {
        _snack('Invalid phone number. Cannot send move.');
      }
    }
    if (widget.mode == 'bluetooth') _bt?.sendMove(uci);
    if (widget.mode == 'online') {
      _online?.sendMove(uci, _game.fen);
      setState(() => _isMyTurn = false);
    }
    setState(() {});
  }

  void _applyOpponentMove(String uci) {
    if (!mounted || uci.length < 4 || _gameOver) return;
    final dynamic m = _game.move({'from': uci.substring(0, 2), 'to': uci.substring(2, 4), 'promotion': 'q'});
    if (m != null) {
      _moveAnimCtrl.forward(from: 0);
      if (m['captured'] != null) _sound?.playCapture(); else _sound?.playMove();
      if (_game.in_check) _sound?.playCheck();
      _updateStatus();
      if (widget.mode == 'online') setState(() => _isMyTurn = true);
      if (_game.game_over) { _clockTimer?.cancel(); _sound?.playGameOver(); _gameOver = true; _showGameOverDialog(); }
      setState(() => _moveHistory.add(uci));
    }
  }

  Future<void> _triggerAiMove() async {
    debugPrint('[Chess] _triggerAiMove called. ai=${_ai != null}, aiThinking=$_aiThinking, gameOver=$_gameOver');
    if (_ai == null || _aiThinking || _gameOver) return;
    setState(() => _aiThinking = true);

    await Future.delayed(const Duration(milliseconds: 300));

    final fen = _game.fen;
    debugPrint('[Chess] Asking AI for best move. fen=$fen');
    final best = await _ai!.getBestMove(fen, movetime: 600);
    debugPrint('[Chess] AI returned best move: $best');
    if (!mounted) return;

    if (best != null && best.length >= 4) {
      final dynamic m = _game.move({'from': best.substring(0, 2), 'to': best.substring(2, 4), 'promotion': 'q'});
      if (m != null) {
        debugPrint('[Chess] AI move applied: $best');
        _moveAnimCtrl.forward(from: 0);
        if (m['captured'] != null) _sound?.playCapture(); else _sound?.playMove();
        if (_game.in_check) _sound?.playCheck();
        _updateStatus();
        if (_game.game_over) { _clockTimer?.cancel(); _sound?.playGameOver(); _gameOver = true; _showGameOverDialog(); }
        setState(() => _moveHistory.add(best));
      } else {
        debugPrint('[Chess] AI move $best was illegal!');
      }
    } else {
      debugPrint('[Chess] AI returned null or invalid move');
    }
    setState(() => _aiThinking = false);
  }

  void _updateStatus() {
    if (!mounted) return;
    setState(() {
      if (_game.in_checkmate) _statusMsg = '${_isWhiteTurn(_game) ? "Black" : "White"} wins — CHECKMATE!';
      else if (_game.in_draw) _statusMsg = 'Draw!';
      else if (_game.in_check) _statusMsg = '⚠ CHECK!';
      else _statusMsg = _isWhiteTurn(_game) ? "White's turn" : "Black's turn";
    });
  }

  void _endGame(String msg) {
    if (!mounted) return;
    _sound?.playGameOver();
    setState(() { _gameOver = true; _statusMsg = msg; });
    _showGameOverDialog();
  }

  void _showGameOverDialog() {
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Game Over', style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22), textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events, color: AppColors.primaryGreen, size: 48),
              const SizedBox(height: 12),
              Text(_statusMsg, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 15), textAlign: TextAlign.center),
            ],
          ),
          actions: [
            TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: Text('Menu', style: GoogleFonts.outfit(color: AppColors.textMuted))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _game = ch.Chess(); _moveHistory.clear(); _whiteCaptured.clear(); _blackCaptured.clear();
                  _whiteTime = 600; _blackTime = 600; _gameOver = false; _aiThinking = false;
                  _updateStatus(); _startClock();
                });
              },
              child: Text('Play Again', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    });
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit()),
      backgroundColor: AppColors.cardDark,
      duration: const Duration(seconds: 2),
    ));
  }

  // ── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_isHardwareValid) return _buildErrorScreen();

    return Scaffold(
      appBar: AppBar(
        title: Text('Chess ${widget.mode.toUpperCase()}'),
        actions: const [
          ErrorRecorderIconButton(),   // ADDED crashlog button
        ],
        backgroundColor: AppColors.cardDark,
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 10),
                _buildPlayerCard(
                  name: _opponentLabel(),
                  elo: _opponentEloStr(),
                  time: _isWhiteTurn(_game) ? _blackTime : _whiteTime,
                  captured: _myColor == 'black' ? _whiteCaptured : _blackCaptured,
                  isActive: widget.mode == 'online' ? !_isMyTurn : !_isWhiteTurn(_game),
                  isClient: false,
                ),
                const SizedBox(height: 8),
                _buildBoard(),
                const SizedBox(height: 8),
                _buildPlayerCard(
                  name: widget.username ?? 'You',
                  elo: (widget.userElo ?? 1200).toString(),
                  time: _myColor == 'black' ? _blackTime : _whiteTime,
                  captured: _myColor == 'black' ? _blackCaptured : _whiteCaptured,
                  isActive: widget.mode == 'online' ? _isMyTurn : _isWhiteTurn(_game),
                  isClient: true,
                ),
                const SizedBox(height: 12),
                _buildMoveHistory(),
                const SizedBox(height: 12),
                _buildBoardThemeRow(),
                const SizedBox(height: 12),
                _buildActions(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final status = widget.mode == 'online' && _onlineStatus.isNotEmpty ? _onlineStatus
        : _btStatus.isNotEmpty ? _btStatus : _statusMsg;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: _gameOver ? Colors.red : AppColors.primaryGreen)),
              const SizedBox(width: 8),
              Expanded(child: Text(status, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis)),
              if (_aiThinking) const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGreen)),
            ]),
          ),
        ),
        if (widget.mode == 'ai') ...[const SizedBox(width: 8), _buildAiMenu()],
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            if (_moveHistory.isNotEmpty) {
              setState(() { _game.undo_move(); if (_moveHistory.isNotEmpty) _moveHistory.removeLast(); _updateStatus(); });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.undo, color: Colors.white54, size: 18),
          ),
        ),
      ],
    );
  }

  String _opponentLabel() {
    switch (widget.mode) {
      case 'ai': return 'AI: ${_aiRankName(_aiLevel)}';
      case 'online': return _opponentName;
      case 'bluetooth': return 'BT Opponent';
      case 'sms': return widget.opponentPhone ?? 'SMS Player';
      default: return 'Player 2';
    }
  }

  String _opponentEloStr() {
    if (widget.mode == 'ai') return (800 + _aiLevel * 100).toString();
    if (widget.mode == 'online') return _opponentElo.toString();
    return '1450';
  }

  Widget _buildErrorScreen() => Scaffold(
    backgroundColor: AppColors.background,
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 64),
          const SizedBox(height: 20),
          Text('Error', style: GoogleFonts.syne(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(_errorMsg, textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.white60, fontSize: 14)),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(context),
            child: Text('Go Back', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ]),
      ),
    ),
  );

  Widget _buildPlayerCard({required String name, required String elo, required int time, required List<String> captured, required bool isActive, required bool isClient}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: isActive ? AppColors.primaryGreen.withValues(alpha: 0.6) : AppColors.borderDark, width: isActive ? 1.5 : 1),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.borderDark,
          child: Icon(isClient ? Icons.person : Icons.person_outline, color: isClient ? AppColors.primaryGreen : Colors.white60, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          Text('ELO $elo${captured.isNotEmpty ? " · +${captured.length}♟" : ""}', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11)),
        ])),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: time < 60 ? AppColors.resignRed.withValues(alpha: 0.2) : Colors.black87,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isActive ? AppColors.primaryGreen.withValues(alpha: 0.4) : Colors.transparent),
          ),
          child: Text(_fmt(time), style: GoogleFonts.outfit(color: time < 60 ? AppColors.resignRed : (isClient ? AppColors.primaryGreen : Colors.white), fontWeight: FontWeight.bold, fontSize: 18)),
        ),
      ]),
    );
  }

  Widget _buildBoard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.primaryGreen.withValues(alpha: 0.06), blurRadius: 24, spreadRadius: 2)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 1,
          child: SimpleChessBoard(
            fen: _game.fen,
            onMove: ({required ShortMove move}) => _onBoardMove(move.from, move.to),
            whitePlayerType: PlayerType.human,
            blackPlayerType: widget.mode == 'ai' ? PlayerType.computer : PlayerType.human,
            showPossibleMoves: true,
            blackSideAtBottom: _myColor == 'black',
            chessBoardColors: _boardColors(),
            cellHighlights: const {},
            showCoordinatesZone: true,
            onPromote: () async => PieceType.queen,
            onPromotionCommited: ({required ShortMove moveDone, required PieceType pieceType}) {},
            onTap: ({required String cellCoordinate}) {},
          ),
        ),
      ),
    );
  }

  Widget _buildMoveHistory() {
    if (_moveHistory.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderDark)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Move History', style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          Text('${(_moveHistory.length / 2).ceil()} moves', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11)),
        ]),
        const SizedBox(height: 10),
        SizedBox(
          height: 34,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: (_moveHistory.length / 2).ceil(),
            itemBuilder: (_, i) {
              final w = _moveHistory[i * 2];
              final b = (i * 2 + 1 < _moveHistory.length) ? _moveHistory[i * 2 + 1] : '...';
              final last = i == (_moveHistory.length / 2).ceil() - 1;
              return Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: last ? AppColors.primaryGreen.withValues(alpha: 0.12) : AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: last ? AppColors.primaryGreen.withValues(alpha: 0.3) : Colors.transparent),
                ),
                child: Text('${i + 1}. $w  $b', style: GoogleFonts.outfit(color: last ? AppColors.primaryGreen : Colors.white60, fontSize: 11)),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _buildBoardThemeRow() {
    final themes = [
      {'n': 'Classic Green', 'c1': const Color(0xFFC8D5B1), 'c2': const Color(0xFF7A9859)},
      {'n': 'Wood', 'c1': const Color(0xFFEEDAB8), 'c2': const Color(0xFFB58763)},
      {'n': 'Ice', 'c1': const Color(0xFFE8F4FD), 'c2': const Color(0xFF8EC5D6)},
      {'n': 'Midnight', 'c1': const Color(0xFF4A4A5A), 'c2': const Color(0xFF1E1E2E)},
      {'n': 'Royal', 'c1': const Color(0xFFF5ECF8), 'c2': const Color(0xFF8B4AA8)},
      {'n': 'Sand', 'c1': const Color(0xFFF8ECD1), 'c2': const Color(0xFFD6B271)},
    ];
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: themes.length,
        itemBuilder: (_, i) {
          final t = themes[i];
          final active = _activeTheme == t['n'];
          return GestureDetector(
            onTap: () { setState(() => _activeTheme = t['n'] as String); _sound?.playButtonTap(); },
            child: Container(
              width: 52,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: active ? AppColors.primaryGreen : AppColors.borderDark, width: active ? 2 : 1),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: SizedBox(width: 34, height: 18, child: Row(children: [
                    Expanded(child: Container(color: t['c1'] as Color)),
                    Expanded(child: Container(color: t['c2'] as Color)),
                  ])),
                ),
                const SizedBox(height: 3),
                Text((t['n'] as String).split(' ').first, style: GoogleFonts.outfit(color: active ? AppColors.primaryGreen : AppColors.textMuted, fontSize: 8)),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActions() {
    return Row(children: [
      Expanded(child: _actionBtn('Resign', Icons.flag_outlined, AppColors.resignRed, false, () => _confirmDialog('Resign Game?', 'You will lose. Continue?', 'RESIGN', AppColors.resignRed, () { _online?.resign(); _sound?.playButtonTap(); Navigator.pop(context); }))),
      const SizedBox(width: 8),
      Expanded(child: _actionBtn('Draw', Icons.handshake_outlined, Colors.white60, false, () => _confirmDialog('Offer Draw?', 'Send draw offer to opponent?', 'OFFER', AppColors.primaryGreen, () { _online?.offerDraw(); _snack('Draw offer sent.'); }))),
      const SizedBox(width: 8),
      Expanded(child: _actionBtn('Chat', Icons.chat_bubble_outline, AppColors.primaryGreen, true, _openChat)),
    ]);
  }

  Widget _actionBtn(String label, IconData icon, Color color, bool filled, VoidCallback onTap) {
    return GestureDetector(
      onTap: () { _sound?.playButtonTap(); onTap(); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: filled ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(11),
          border: filled ? null : Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: filled ? Colors.white : color, size: 15),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.outfit(color: filled ? Colors.white : color, fontWeight: FontWeight.bold, fontSize: 12)),
        ]),
      ),
    );
  }

  void _confirmDialog(String title, String body, String confirm, Color color, VoidCallback onConfirm) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppColors.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.bold)),
      content: Text(body, style: GoogleFonts.outfit(color: AppColors.textMuted)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white54))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          onPressed: () { Navigator.pop(context); onConfirm(); },
          child: Text(confirm, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    ));
  }

  void _openChat() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(children: [
          Container(margin: const EdgeInsets.only(top: 10), width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.all(18), child: Row(children: [
            const Icon(Icons.chat_bubble_outline, color: AppColors.primaryGreen),
            const SizedBox(width: 10),
            Text('Chat', style: GoogleFonts.syne(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ])),
          Expanded(child: _chatMessages.isEmpty
              ? Center(child: Text('No messages yet', style: GoogleFonts.outfit(color: Colors.white38)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  itemCount: _chatMessages.length,
                  itemBuilder: (_, i) {
                    final m = _chatMessages[i];
                    final me = m['playerId'] == _online?.myPlayerId;
                    return Align(
                      alignment: me ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: me ? AppColors.primaryGreen.withValues(alpha: 0.2) : AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(m['message'] ?? '', style: GoogleFonts.outfit(color: Colors.white, fontSize: 13)),
                      ),
                    );
                  })),
          Padding(padding: const EdgeInsets.all(18), child: Row(children: [
            Expanded(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
              child: TextField(controller: _chatCtrl, style: GoogleFonts.outfit(color: Colors.white), decoration: InputDecoration(hintText: 'Type a message...', hintStyle: GoogleFonts.outfit(color: AppColors.textMuted), border: InputBorder.none)),
            )),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                if (_chatCtrl.text.trim().isNotEmpty) {
                  _online?.sendChat(_chatCtrl.text.trim(), widget.username ?? 'Player');
                  _chatCtrl.clear();
                }
              },
              child: Container(padding: const EdgeInsets.all(11), decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle), child: const Icon(Icons.send, color: Colors.white, size: 16)),
            ),
          ])),
        ]),
      ),
    );
  }

  Widget _buildAiMenu() => PopupMenuButton<int>(
    icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.tune, color: Colors.white54, size: 16)),
    color: AppColors.cardDark,
    onSelected: (lvl) {
      setState(() { _aiLevel = lvl; _ai?.setDifficulty(lvl); });
      _snack('AI: ${_aiRankName(lvl)}');
      _sound?.playButtonTap();
    },
    itemBuilder: (_) => List.generate(20, (i) => i + 1).map((l) => PopupMenuItem(value: l, child: Text('${_aiRankName(l)} (Lv $l)', style: GoogleFonts.outfit(color: Colors.white, fontSize: 12)))).toList(),
  );

  String _aiRankName(int l) {
    const r = ['Newbie', 'Beginner', 'Casual', 'Novice', 'Apprentice', 'Competitor', 'Club Player', 'Class C', 'Class B', 'Class A', 'Expert', 'Cand. Master', 'Nat. Master', 'FIDE Master', 'Intl Master', 'Grandmaster', 'Super GM', 'World Class', 'Engine Pro', 'AlphaZero'];
    return r[(l - 1).clamp(0, 19)];
  }

  ChessBoardColors _boardColors() {
    final c = ChessBoardColors();
    switch (_activeTheme) {
      case 'Wood':     return c..lightSquaresColor = const Color(0xFFEEDAB8)..darkSquaresColor = const Color(0xFFB58763);
      case 'Ice':      return c..lightSquaresColor = const Color(0xFFE8F4FD)..darkSquaresColor = const Color(0xFF8EC5D6);
      case 'Midnight': return c..lightSquaresColor = const Color(0xFF4A4A5A)..darkSquaresColor = const Color(0xFF1E1E2E);
      case 'Royal':    return c..lightSquaresColor = const Color(0xFFF5ECF8)..darkSquaresColor = const Color(0xFF8B4AA8);
      case 'Sand':     return c..lightSquaresColor = const Color(0xFFF8ECD1)..darkSquaresColor = const Color(0xFFD6B271);
      default:         return c..lightSquaresColor = const Color(0xFFC8D5B1)..darkSquaresColor = const Color(0xFF7A9859);
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _chatSub?.cancel();
    _chatCtrl.dispose();
    _moveAnimCtrl.dispose();
    _ai?.dispose();
    _bt?.dispose();
    _sound?.dispose();
    _online?.dispose();
    super.dispose();
  }
}
