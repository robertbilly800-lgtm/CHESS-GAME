import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as ch;
import 'package:vibration/vibration.dart';

import '../widgets/chess/simple_chess_board.dart';
import '../theme/app_colors.dart';
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
  final ch.Chess _game = ch.Chess();
  final List<String> _moveHistory = [];

  final SoundService _sound = SoundService();
  final UserService _user = UserService();

  String _status = "White's turn";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBoard()),
            _buildStatus(),
            _buildHistory(),
          ],
        ),
      ),
    );
  }

  // ───────────────── HEADER ─────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.undo, color: Colors.white),
          onPressed: _undoMove,
        ),
      ],
    );
  }

  // ───────────────── BOARD ─────────────────

  Widget _buildBoard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SimpleChessBoard(
        fen: _game.fen,
        whitePlayerType: PlayerType.human,
        blackPlayerType: PlayerType.human,

        onMove: ({required ShortMove move}) {
          _handleMove(move.from + move.to);
        },

        onPromote: () async => PieceType.queen,

        onPromotionCommited: ({required ShortMove moveDone, required PieceType pieceType}) {},

        showPossibleMoves: true,

        // ✅ FIX: added required onTap parameter
        onTap: ({required String cellCoordinate}) {
          // Optional: handle board tap if needed
        },
      ),
    );
  }

  // ───────────────── MOVE LOGIC ─────────────────

  void _handleMove(String uci) {
    if (_game.game_over) return;

    final from = uci.substring(0, 2);
    final to = uci.substring(2, 4);

    final result = _game.move({
      'from': from,
      'to': to,
      'promotion': 'q',
    });

    if (result == null) return;

    _sound.playMove();

    if (_game.in_check) {
      _sound.playCheck();
    }

    if (_user.vibrationEnabled) {
      Vibration.vibrate(duration: 30);
    }

    setState(() {
      _moveHistory.add(uci);
      _updateStatus();
    });
  }

  void _undoMove() {
    _game.undo_move();
    if (_moveHistory.isNotEmpty) {
      _moveHistory.removeLast();
    }
    setState(() {
      _updateStatus();
    });
  }

  void _updateStatus() {
    if (_game.in_checkmate) {
      final winner = _isWhiteTurn(_game) ? "Black" : "White";
      _status = "Checkmate! $winner wins";
    } else if (_game.in_draw) {
      _status = "Draw";
    } else {
      _status = _isWhiteTurn(_game) ? "White's turn" : "Black's turn";
    }
  }

  // ───────────────── UI ─────────────────

  Widget _buildStatus() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        _status,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  Widget _buildHistory() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Text(
        _moveHistory.isEmpty
            ? "No moves yet"
            : _moveHistory.join(" "),
        style: const TextStyle(color: Colors.white70),
      ),
    );
  }
}
