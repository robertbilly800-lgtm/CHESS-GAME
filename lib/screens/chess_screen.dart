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

class _ChessScreenState extends State<ChessScreen> {
  ch.Chess _game = ch.Chess();
  List<String> _moveHistory = [];

  AiService? _ai;
  SmsService? _sms;
  ChessBluetoothService? _bt;
  SoundService? _sound;
  final UserService _user = UserService();

  bool _isHardwareValid = true;
  String _errorMsg = '';
  bool _aiThinking = false;

  List<String> _whiteCaptured = [];
  List<String> _blackCaptured = [];

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  @override
  void dispose() {
    _ai?.dispose();
    super.dispose();
  }

  Future<void> _initServices() async {
    _sound = SoundService();

    try {
      if (widget.mode == 'ai') {
        _ai = AiService();
        await _ai!.init();
      }

      if (widget.mode == 'sms') {
        _sms = SmsService();
        if (await _sms!.isSupported()) {
          final granted = await _requestSmsPermissions();
          if (granted) {
            _sms!.listenForMoves(
              onMoveReceived: (move) => _onBoardMove(move, isRemote: true),
            );
          }
        }
      }

      if (widget.mode == 'bluetooth') {
        _bt = ChessBluetoothService();
        if (await _bt!.isSupported()) {
          await _bt!.startScan();
          _bt!.moveReceived.listen(
            (move) => _onBoardMove(move, isRemote: true),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isHardwareValid = false;
        _errorMsg = 'Service error';
      });
    }
  }

  Future<bool> _requestSmsPermissions() async {
    final s = await Permission.sms.request();
    final p = await Permission.phone.request();
    return s.isGranted && p.isGranted;
  }

  void _onBoardMove(String uci, {bool isRemote = false}) {
    if (uci.length < 4 || _game.game_over) return;

    final move = _game.move({
      'from': uci.substring(0, 2),
      'to': uci.substring(2, 4),
      'promotion': 'q',
    });

    if (move != null) {
      final captured = move['captured'];
      if (captured != null) {
        if (move['color'] == 'w') {
          _blackCaptured.add(captured);
        } else {
          _whiteCaptured.add(captured);
        }
      }

      if (_user.vibrationEnabled) {
        Vibration.vibrate(duration: 30);
      }

      setState(() {
        _moveHistory.add(uci);
      });

      if (widget.mode == 'ai' && !_isWhiteTurn(_game)) {
        _triggerAiMove();
      }
    }
  }

  Future<void> _triggerAiMove() async {
    if (_ai == null || _aiThinking) return;

    _aiThinking = true;
    final best = await _ai!.getBestMove(_game.fen);
    _aiThinking = false;

    if (best != null) {
      _onBoardMove(best, isRemote: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isHardwareValid) {
      return Scaffold(
        body: Center(child: Text(_errorMsg)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const SizedBox(height: 40),

          Text(
            "Chess Game",
            style: GoogleFonts.syne(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: SimpleChessBoard(
              fen: _game.fen,
              onMove: ({required ShortMove move}) {
                _onBoardMove(move.from + move.to);
              },
              whitePlayerType: PlayerType.human,
              blackPlayerType: widget.mode == 'ai'
                  ? PlayerType.computer
                  : PlayerType.human,
              showPossibleMoves: true,
              chessBoardColors: ChessBoardColors(),

              onPromote: () async {
                return PieceType.queen;
              },

              onPromotionCommited: ({
                required ShortMove moveDone,
                required PieceType pieceType,
              }) {},

              onTap: ({required String cellCoordinate}) {},
            ),
          ),

          const SizedBox(height: 10),

          Text(
            "Moves: ${_moveHistory.join(', ')}",
            style: const TextStyle(color: Colors.white),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
