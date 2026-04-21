import 'dart:async';
import 'package:flutter/material.dart';
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
  final UserService _user = UserService();

  bool _isHardwareValid = true;
  String _errorMsg = '';
  bool _aiThinking = false;
  int _aiLevel = 10;
  String _statusMsg = "White's turn";
  String _btStatus = '';
  bool _resultRecorded = false;

  // Game state variables

  // Captures tracking
  List<String> _whiteCaptured = [];
  List<String> _blackCaptured = [];

  @override
  void initState() {
    super.initState();
    _activeTheme = _user.boardTheme;
    _initServices();
  }

  @override
  void dispose() {
    _ai?.dispose();
    super.dispose();
  }

  // ── Services ───────────────────────────────────────────────────────────────

  Future<void> _initServices() async {
    _sound = SoundService();

    try {
      switch (widget.mode) {
        case 'ai':
          _ai = AiService();
          await _ai!.init();
          if (_ai!.isHardwareSupported) {
            _ai!.setDifficulty(_aiLevel);
          } else {
            setState(() { _isHardwareValid = false; _errorMsg = "AI Error: Hardware not supported."; });
          }
          break;

        case 'local':
          break;

        case 'sms':
          _sms = SmsService();
          if (await _sms!.isSupported()) {
            final granted = await _requestSmsPermissions();
            if (granted) {
              _sms!.listenForMoves(onMoveReceived: _applyOpponentMove);
            }
          }
          break;

        case 'bluetooth':
          _bt = ChessBluetoothService();
          if (await _bt!.isSupported()) {
            _bt!.status.listen((msg) { if (mounted) setState(() => _btStatus = msg); });
            _bt!.moveReceived.listen(_applyOpponentMove);
          }
          break;
      }
    } catch (e) {
      setState(() { _isHardwareValid = false; _errorMsg = 'Service initialization error.'; });
    }
  }

  Future<bool> _requestSmsPermissions() async {
    final s = await Permission.sms.request();
    final p = await Permission.phone.request();
    return s.isGranted && p.isGranted;
  }

  // ── Move Logic ─────────────────────────────────────────────────────────────

  void _onBoardMove(String uci) {
    if (uci.length < 4 || _game.game_over) return;
    final from = uci.substring(0, 2);
    final to = uci.substring(2, 4);

    try {
      final move = _game.move({'from': from, 'to': to, 'promotion': 'q'});
      if (move != null) {
        _trackCapture(move);
        _onMoveExecuted(uci);
      }
    } catch (e) {
      debugPrint('[Chess] Invalid move: $e');
    }
  }

  void _trackCapture(dynamic move) {
    final captured = move['captured'];
    if (captured != null) {
      final color = move['color'];
      if (color == 'w') { _whiteCaptured.add(captured as String); } else { _blackCaptured.add(captured as String); }
      _sound?.playCapture();
    } else {
      _sound?.playMove();
    }
    if (_game.in_check) _sound?.playCheck();
  }

  void _onMoveExecuted(String lastUci) {
    _updateStatus();
    if (_user.vibrationEnabled) Vibration.vibrate(duration: 30);
    if (mounted) setState(() => _moveHistory.add(lastUci));

    if (widget.mode == 'ai' && !_isWhiteTurn(_game)) { _triggerAiMove(_game.fen); }
    if (widget.mode == 'sms' && widget.opponentPhone != null) { _sms?.sendMove(phoneNumber: widget.opponentPhone!, uciMove: lastUci); }
    if (widget.mode == 'bluetooth') { _bt?.sendMove(lastUci); }
    setState(() {});
  }

  void _applyOpponentMove(String uciMove) {
    if (!mounted || uciMove.length < 4 || _game.game_over) return;
    try {
      final from = uciMove.substring(0, 2);
      final to = uciMove.substring(2, 4);
      final move = _game.move({'from': from, 'to': to, 'promotion': 'q'});
      if (move != null) {
        _trackCapture(move);
        _updateStatus();
        setState(() => _moveHistory.add(uciMove));
      }
    } catch (e) {
      debugPrint('[Chess] applyOpponentMove error: $e');
    }
  }

  Future<void> _triggerAiMove(String fen) async {
    if (_ai == null || _aiThinking) return;
    setState(() => _aiThinking = true);
    await Future.delayed(const Duration(milliseconds: 600));
    final best = await _ai!.getBestMove(fen);
    if (best != null && best.length >= 4) {
      final from = best.substring(0, 2);
      final to = best.substring(2, 4);
      final move = _game.move({'from': from, 'to': to, 'promotion': 'q'});
      if (move != null) {
        _trackCapture(move);
        _updateStatus();
        setState(() => _moveHistory.add(best));
      }
    }
    setState(() => _aiThinking = false);
  }

  void _updateStatus() {
    if (!mounted) return;
    setState(() {
      if (_game.in_checkmate) {
        final winner = _isWhiteTurn(_game) ? 'Black' : 'White';
        _handleGameOver(winner == 'White' ? 'win' : 'loss', '♛ Checkmate! $winner wins.');
      } else if (_game.in_draw) {
        _handleGameOver('draw', '½ Draw! Game Over.');
      } else {
        _statusMsg = _isWhiteTurn(_game) ? "⬜ White's turn" : "⬛ Black's turn";
      }
    });
  }

  void _handleGameOver(String result, String message) {
    _statusMsg = message;
    if (!_resultRecorded) {
      _user.recordGameResult(result);
      _resultRecorded = true;
      _sound?.playGameOver();
    }
    setState(() {});
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_isHardwareValid) { return _buildErrorScreen(); }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildPlayerCard(
                name: widget.mode == 'ai' ? 'Stockfish Engine' : 'Opponent',
                elo: '1450',
                captured: _blackCaptured,
                isActive: !_isWhiteTurn(_game),
                isClient: false,
              ),
              const SizedBox(height: 20),
              _buildBoard(),
              const SizedBox(height: 20),
              _buildPlayerCard(
                name: _user.displayName,
                elo: _user.elo.toString(),
                captured: _whiteCaptured,
                isActive: _isWhiteTurn(_game),
                isClient: true,
              ),
              const SizedBox(height: 24),
              _buildMoveHistory(),
              const SizedBox(height: 16),
              _buildBoardThemeSelector(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18), onPressed: () => Navigator.pop(context)),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: _game.game_over ? Colors.red : AppColors.primaryGreen)),
              const SizedBox(width: 10),
              Text(_statusMsg, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
        const SizedBox(width: 10),
        _buildActionBtn(Icons.undo, () {
          setState(() {
            _game.undo_move();
            if (_moveHistory.isNotEmpty) _moveHistory.removeLast();
            _updateStatus();
          });
        }),
      ],
    );
  }

  Widget _buildActionBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: Colors.white70, size: 20)),
  );

  Widget _buildPlayerCard({required String name, required String elo, required List<String> captured, required bool isActive, required bool isClient}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? AppColors.primaryGreen.withValues(alpha: 0.5) : AppColors.borderDark, width: isActive ? 1.5 : 1),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 22, backgroundColor: AppColors.background, child: Icon(isClient ? Icons.person : Icons.psychology, color: AppColors.primaryGreen, size: 24)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            Row(children: [
              Text('ELO $elo', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12)),
              if (captured.isNotEmpty) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: captured.map((p) => _getCapturedPieceIcon(p, !isClient)).toList(),
                  ),
                ),
              ],
            ]),
          ])),
        ],
      ),
    );
  }

  Widget _getCapturedPieceIcon(String p, bool isWhitePiece) {
    String symbol = '';
    switch (p.toLowerCase()) {
      case 'p': symbol = isWhitePiece ? '♙' : '♟'; break;
      case 'n': symbol = isWhitePiece ? '♘' : '♞'; break;
      case 'b': symbol = isWhitePiece ? '♗' : '♝'; break;
      case 'r': symbol = isWhitePiece ? '♖' : '♜'; break;
      case 'q': symbol = isWhitePiece ? '♕' : '♛'; break;
    }
    return Text(symbol, style: TextStyle(fontSize: 16, color: isWhitePiece ? Colors.white : Colors.white70));
  }

  Widget _buildBoard() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 2)]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SimpleChessBoard(
            fen: _game.fen,
            onMove: ({required ShortMove move}) => _onBoardMove(move.from + move.to),
            whitePlayerType: PlayerType.human,
            blackPlayerType: widget.mode == 'ai' ? PlayerType.computer : PlayerType.human,
            showPossibleMoves: true,
            chessBoardColors: _getBoardColors(),
            onPromote: () async => PieceType.queen,
            onPromotionCommited: ({required ShortMove moveDone, required PieceType pieceType}) {},
            onTap: ({required String cellCoordinate}) {},
          ),
        ),
      ),
    );
  }

  ChessBoardColors _getBoardColors() {
    final colors = ChessBoardColors();
    switch (_activeTheme) {
      case 'Wood':
        colors.lightSquaresColor = const Color(0xFFEEDAB8);
        colors.darkSquaresColor = const Color(0xFFB58763);
        break;
      case 'Midnight':
        colors.lightSquaresColor = const Color(0xFF4A4A5A);
        colors.darkSquaresColor = const Color(0xFF1E1E2E);
        break;
      default:
        colors.lightSquaresColor = const Color(0xFFC8D5B1);
        colors.darkSquaresColor = const Color(0xFF7A9859);
    }
    return colors;
  }

  Widget _buildMoveHistory() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderDark)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Move History', style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            Text('${_moveHistory.length} moves', style: GoogleFonts.outfit(color: AppColors.primaryGreen, fontSize: 12, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          Text(_moveHistory.isEmpty ? 'Waiting for first move...' : _moveHistory.join('  '), style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildBoardThemeSelector() {
    final themes = ['Classic Green', 'Wood', 'Midnight'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('BOARD THEME', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Row(children: themes.map((t) => Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _activeTheme = t); _user.setBoardTheme(t); },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _activeTheme == t ? AppColors.primaryGreen : AppColors.cardDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _activeTheme == t ? AppColors.primaryGreen : AppColors.borderDark),
              ),
              child: Center(child: Text(t.split(' ').first, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
            ),
          ),
        )).toList()),
      ],
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(backgroundColor: AppColors.background, body: Center(child: Text(_errorMsg, style: const TextStyle(color: Colors.white))));
  }
}
