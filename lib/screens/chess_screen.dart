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
int _aiLevel = 10;
String _statusMsg = "White's turn";
String _btStatus = '';

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

```
try {
  if (widget.mode == 'ai') {
    _ai = AiService();
    await _ai!.init();
    if (_ai!.isHardwareSupported) {
      _ai!.setDifficulty(_aiLevel);
    }
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
      await _bt!.start();
      _bt!.status.listen((msg) {
        if (mounted) setState(() => _btStatus = msg);
      });
      _bt!.moveReceived.listen((move) {
        _onBoardMove(move, isRemote: true);
      });
    }
  }
} catch (e) {
  setState(() {
    _isHardwareValid = false;
    _errorMsg = 'Service error';
  });
}
```

}

Future<bool> _requestSmsPermissions() async {
final s = await Permission.sms.request();
final p = await Permission.phone.request();
return s.isGranted && p.isGranted;
}

void _onBoardMove(String uci, {bool isRemote = false}) {
if (!mounted || uci.length < 4 || _game.game_over) return;

```
final from = uci.substring(0, 2);
final to = uci.substring(2, 4);

try {
  final move = _game.move({
    'from': from,
    'to': to,
    'promotion': 'q'
  });

  if (move != null) {
    _trackCapture(move);

    if (_user.vibrationEnabled) {
      Vibration.vibrate(duration: 30);
    }

    setState(() {
      _moveHistory.add(uci);
    });

    _handleAfterMove(uci, isRemote: isRemote);
  }
} catch (e) {
  debugPrint("Invalid move: $e");
}
```

}

void _trackCapture(dynamic move) {
final captured = move['captured'];

```
if (captured != null) {
  final color = move['color'];
  if (color == 'w') {
    _blackCaptured.add(captured);
  } else {
    _whiteCaptured.add(captured);
  }
}
```

}

void _handleAfterMove(String lastMove, {bool isRemote = false}) {
_updateStatus();

```
if (_game.game_over) return;

if (widget.mode == 'ai') {
  Future.delayed(const Duration(milliseconds: 300), () {
    _triggerAiMove();
  });
}

if (!isRemote) {
  if (widget.mode == 'sms' && widget.opponentPhone != null) {
    _sms?.sendMove(
      phoneNumber: widget.opponentPhone!,
      uciMove: lastMove,
    );
  }

  if (widget.mode == 'bluetooth') {
    _bt?.sendMove(lastMove);
  }
}
```

}

Future<void> _triggerAiMove() async {
if (_ai == null || _aiThinking || _game.game_over) return;

```
_aiThinking = true;

final move = await _ai!.getBestMove(_game.fen);

_aiThinking = false;

if (move != null && move.length >= 4 && mounted) {
  _onBoardMove(move, isRemote: true);
}
```

}

void _updateStatus() {
if (!mounted) return;

```
setState(() {
  if (_game.in_checkmate) {
    final winner = _isWhiteTurn(_game) ? 'Black' : 'White';
    _statusMsg = "$winner wins";
  } else if (_game.in_draw) {
    _statusMsg = "Draw";
  } else {
    _statusMsg =
        _isWhiteTurn(_game) ? "White's turn" : "Black's turn";
  }
});
```

}

@override
Widget build(BuildContext context) {
if (!_isHardwareValid) {
return Scaffold(
body: Center(child: Text(_errorMsg)),
);
}

```
return Scaffold(
  backgroundColor: AppColors.background,
  body: SafeArea(
    child: Column(
      children: [
        const SizedBox(height: 20),

        Text(
          _statusMsg,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 18,
          ),
        ),

        const SizedBox(height: 20),

        Expanded(
          child: SimpleChessBoard(
            fen: _game.fen,

            onMove: ({required ShortMove move}) {
              final uci = move.from + move.to;
              _onBoardMove(uci);
            },

            whitePlayerType: PlayerType.human,
            blackPlayerType: PlayerType.human,

            showPossibleMoves: true,

            onTap: ({required String cellCoordinate}) {
              debugPrint("Tapped: $cellCoordinate");
            },
          ),
        ),
      ],
    ),
  ),
);
```

}
}
