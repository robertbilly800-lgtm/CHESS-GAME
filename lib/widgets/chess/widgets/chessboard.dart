library;

import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess;
import '../models/piece.dart';
import 'chess_vectors_definitions.dart';
import '../../../theme/chess_pieces.dart';
import '../models/piece_type.dart';
import '../models/board_arrow.dart';
import '../models/board_color.dart';
import '../models/short_move.dart';

final piecesDefinition = {
  "wp": whitePawnDefinition, "wn": whiteKnightDefinition,
  "wb": whiteBishopDefinition, "wr": whiteRookDefinition,
  "wq": whiteQueenDefinition, "wk": whiteKingDefinition,
  "bp": blackPawnDefinition, "bn": blackKnightDefinition,
  "bb": blackBishopDefinition, "br": blackRookDefinition,
  "bq": blackQueenDefinition, "bk": blackKingDefinition,
};

const baseImageSize = 45.0;

class ChessBoardColors {
  Color lightSquaresColor = const Color.fromRGBO(240, 217, 181, 1);
  Color darkSquaresColor  = const Color.fromRGBO(181, 136, 99, 1);
  Color coordinatesZoneColor = Colors.transparent;
  Color lastMoveArrowColor   = Colors.greenAccent;
  Color circularProgressBarColor = Colors.teal;
  Color coordinatesColor  = Colors.white54;
  Color startSquareColor  = Colors.red;
  Color endSquareColor    = Colors.green;
  Color? dndIndicatorColor;
  Color possibleMovesColor = const Color(0x80808080);
  ChessBoardColors();
}

enum PlayerType { human, computer }

class SimpleChessBoard extends StatelessWidget {
  final String fen;
  final bool blackSideAtBottom;
  final PlayerType whitePlayerType;
  final PlayerType blackPlayerType;
  final void Function({required ShortMove move}) onMove;
  final Future<PieceType?> Function() onPromote;
  final void Function({required ShortMove moveDone, required PieceType pieceType}) onPromotionCommited;
  final void Function({required String cellCoordinate}) onTap;
  final bool showPossibleMoves;
  final ChessBoardColors? chessBoardColors;
  final Map<String, Color> cellHighlights;
  final bool showCoordinatesZone;
  final BoardArrow? arrow;
  final bool? highlightLastMoveSquares;
  final bool isInteractive;
  final Color? nonInteractiveOverlayColor;
  final TextStyle? nonInteractiveTextStyle;
  final String? nonInteractiveMessage;
  final void Function({required ShortMove move, required String newFen})? onMoveComplete;
  final Widget Function(String, bool)? normalMoveIndicatorBuilder;
  final Widget Function(String, bool)? captureMoveIndicatorBuilder;

  const SimpleChessBoard({
    super.key,
    required this.fen,
    required this.onMove,
    required this.onPromote,
    required this.onPromotionCommited,
    required this.onTap,
    this.blackSideAtBottom = false,
    this.whitePlayerType = PlayerType.human,
    this.blackPlayerType = PlayerType.human,
    this.showPossibleMoves = true,
    this.chessBoardColors,
    this.cellHighlights = const {},
    this.showCoordinatesZone = false,
    this.arrow,
    this.highlightLastMoveSquares,
    this.isInteractive = true,
    this.nonInteractiveOverlayColor,
    this.nonInteractiveTextStyle,
    this.nonInteractiveMessage,
    this.onMoveComplete,
    this.normalMoveIndicatorBuilder,
    this.captureMoveIndicatorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final size = constraints.maxWidth;
      return _Chessboard(
        fen: fen,
        size: size,
        blackSideAtBottom: blackSideAtBottom,
        whitePlayerType: whitePlayerType,
        blackPlayerType: blackPlayerType,
        onMove: onMove,
        onPromote: onPromote,
        onPromotionCommited: onPromotionCommited,
        onTap: onTap,
        showPossibleMoves: showPossibleMoves,
        boardColors: chessBoardColors ?? ChessBoardColors(),
        cellHighlights: cellHighlights,
        showCoordinatesZone: showCoordinatesZone,
        highlightLastMoveSquares: highlightLastMoveSquares ?? true,
        isInteractive: isInteractive,
        arrow: arrow,
        nonInteractiveOverlayColor: nonInteractiveOverlayColor,
        nonInteractiveTextStyle: nonInteractiveTextStyle,
        nonInteractiveMessage: nonInteractiveMessage,
        normalMoveIndicatorBuilder: normalMoveIndicatorBuilder,
        captureMoveIndicatorBuilder: captureMoveIndicatorBuilder,
      );
    });
  }
}

class _Chessboard extends StatefulWidget {
  final String fen;
  final double size;
  final bool blackSideAtBottom;
  final PlayerType whitePlayerType;
  final PlayerType blackPlayerType;
  final void Function({required ShortMove move}) onMove;
  final Future<PieceType?> Function() onPromote;
  final void Function({required ShortMove moveDone, required PieceType pieceType}) onPromotionCommited;
  final void Function({required String cellCoordinate}) onTap;
  final bool showPossibleMoves;
  final ChessBoardColors boardColors;
  final Map<String, Color> cellHighlights;
  final bool showCoordinatesZone;
  final bool highlightLastMoveSquares;
  final bool isInteractive;
  final BoardArrow? arrow;
  final Color? nonInteractiveOverlayColor;
  final TextStyle? nonInteractiveTextStyle;
  final String? nonInteractiveMessage;
  final Widget Function(String, bool)? normalMoveIndicatorBuilder;
  final Widget Function(String, bool)? captureMoveIndicatorBuilder;

  const _Chessboard({
    required this.fen, required this.size, required this.blackSideAtBottom,
    required this.whitePlayerType, required this.blackPlayerType,
    required this.onMove, required this.onPromote, required this.onPromotionCommited,
    required this.onTap, required this.showPossibleMoves, required this.boardColors,
    required this.cellHighlights, required this.showCoordinatesZone,
    required this.highlightLastMoveSquares, required this.isInteractive,
    this.arrow, this.nonInteractiveOverlayColor, this.nonInteractiveTextStyle,
    this.nonInteractiveMessage, this.normalMoveIndicatorBuilder, this.captureMoveIndicatorBuilder,
  });

  @override
  State<_Chessboard> createState() => _ChessboardState();
}

class _ChessboardState extends State<_Chessboard> {
  _DndDetails? _dnd;
  (int, int)? _tapStart;
  Map<String, Piece?> _squares = {};
  List<String> _possibleMoves = [];

  @override
  void initState() { super.initState(); _squares = _getSquares(widget.fen); }

  @override
  void didUpdateWidget(_Chessboard old) {
    super.didUpdateWidget(old);
    if (old.fen != widget.fen) {
      setState(() { _squares = _getSquares(widget.fen); _possibleMoves = []; _tapStart = null; });
    }
  }

  bool _isHumanTurn() {
    final white = widget.fen.split(' ')[1] == 'w';
    return white ? widget.whitePlayerType == PlayerType.human : widget.blackPlayerType == PlayerType.human;
  }

  (int, int) _cellFromOffset(Offset o) {
    final cs = widget.size / 8;
    final col = (o.dx / cs).floor().clamp(0, 7);
    final row = (o.dy / cs).floor().clamp(0, 7);
    final file = widget.blackSideAtBottom ? 7 - col : col;
    final rank = widget.blackSideAtBottom ? row : 7 - row;
    return (file, rank);
  }

  String _sq(int file, int rank) => '${String.fromCharCode(97 + file)}${rank + 1}';

  void _handleTap(TapUpDetails d) {
    if (!_isHumanTurn() || !widget.isInteractive) return;
    final (file, rank) = _cellFromOffset(d.localPosition);
    final square = _sq(file, rank);
    widget.onTap(cellCoordinate: square);

    if (_tapStart == null) {
      final piece = _squares[square];
      if (piece == null) return;
      final white = widget.fen.split(' ')[1] == 'w';
      if (white != piece.name.startsWith('w')) return;
      setState(() {
        _tapStart = (file, rank);
        if (widget.showPossibleMoves) _calcMoves(square);
      });
    } else {
      final from = _sq(_tapStart!.$1, _tapStart!.$2);
      setState(() { _tapStart = null; _possibleMoves = []; });
      if (from == square) return;
      _doMove(from, square);
    }
  }

  void _handlePanStart(DragStartDetails d) {
    if (!_isHumanTurn() || !widget.isInteractive || _tapStart != null) return;
    final (file, rank) = _cellFromOffset(d.localPosition);
    final square = _sq(file, rank);
    final piece = _squares[square];
    if (piece == null) return;
    final white = widget.fen.split(' ')[1] == 'w';
    if (white != piece.name.startsWith('w')) return;
    setState(() {
      _dnd = _DndDetails(startCell: (file, rank), position: (d.localPosition.dx, d.localPosition.dy), movedPiece: piece);
      if (widget.showPossibleMoves) _calcMoves(square);
    });
  }

  void _handlePanUpdate(DragUpdateDetails d) {
    if (_dnd == null) return;
    setState(() => _dnd!.position = (d.localPosition.dx, d.localPosition.dy));
  }

  void _handlePanEnd(DragEndDetails d) {
    if (_dnd == null) return;
    final cs = widget.size / 8;
    final col = (_dnd!.position.$1 / cs).floor().clamp(0, 7);
    final row = (_dnd!.position.$2 / cs).floor().clamp(0, 7);
    final toFile = widget.blackSideAtBottom ? 7 - col : col;
    final toRank = widget.blackSideAtBottom ? row : 7 - row;
    final from = _sq(_dnd!.startCell.$1, _dnd!.startCell.$2);
    final to   = _sq(toFile, toRank);
    setState(() { _dnd = null; _possibleMoves = []; });
    if (from != to) _doMove(from, to);
  }

  void _handlePanCancel() => setState(() { _dnd = null; _possibleMoves = []; });

  // Real implementation of square parsing for consistency
  Map<String, Piece?> _getSquaresFromFen(String fen) {
    final logic = chess.Chess.fromFEN(fen);
    final Map<String, Piece?> squares = {};
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final sq = '${String.fromCharCode(97 + c)}${r + 1}';
        final p = logic.get(sq);
        if (p != null) {
          final boardColor = (p.color == chess.Color.WHITE) ? BoardColor.white : BoardColor.black;
          final pieceType = PieceType.fromString(p.type.name);
          squares[sq] = Piece(boardColor, pieceType);
        } else {
          squares[sq] = null;
        }
      }
    }
    return squares;
  }

  void _calcMoves(String square) {
    final logic = chess.Chess.fromFEN(widget.fen);
    _possibleMoves = logic.moves({'square': square, 'verbose': true})
        .map((m) => (m as Map)['to'] as String).toList();
  }

  void _doMove(String from, String to) {
    final move = ShortMove(from: from, to: to);
    final piece = _squares[from];
    if (piece != null && (piece.name == 'wp' || piece.name == 'bp')) {
      if ((piece.name == 'wp' && to[1] == '8') || (piece.name == 'bp' && to[1] == '1')) {
        widget.onPromote().then((pt) {
          if (pt != null) { widget.onPromotionCommited(moveDone: move, pieceType: pt); widget.onMove(move: move); }
        });
        return;
      }
    }
    widget.onMove(move: move);
  }

  List<Widget> _buildPieces() {
    final cs = widget.size / 8;
    final widgets = <Widget>[];

    final entries = _squares.entries.where((e) => e.value != null).toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (final e in entries) {
      final sq = e.key;
      final piece = e.value!;
      final file = sq.codeUnitAt(0) - 97;
      final rank = int.parse(sq[1]) - 1;

      final isBeingDragged = _dnd != null && _dnd!.startCell.$1 == file && _dnd!.startCell.$2 == rank;

      final col = widget.blackSideAtBottom ? 7 - file : file;
      final row = widget.blackSideAtBottom ? rank : 7 - rank;

      widgets.add(AnimatedPositioned(
        key: ValueKey('piece_sq_${piece.name}_$sq'),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        left: col * cs,
        top:  row * cs,
        width: cs,
        height: cs,
        child: Opacity(
          opacity: isBeingDragged ? 0.0 : 1.0, 
          child: _pieceWidget(piece.name, cs)
        ),
      ));
    }
    return widgets;
  }

  Widget _buildDragged() {
    if (_dnd == null) return const SizedBox.shrink();
    final cs = widget.size / 8;
    return Positioned(
      left: _dnd!.position.$1 - cs / 2,
      top:  _dnd!.position.$2 - cs / 2,
      width: cs, height: cs,
      child: Opacity(opacity: 0.85, child: _pieceWidget(_dnd!.movedPiece.name, cs)),
    );
  }

  Widget _pieceWidget(String name, double size) {
    final type = name.substring(1);
    final key  = name.startsWith('w') ? type.toUpperCase() : type;
    return ChessPieceFactory.createPieceWidget(key, size, Colors.white);
  }

  List<Widget> _buildMoveHints() {
    final cs = widget.size / 8;
    return _possibleMoves.map((sq) {
      final file = sq.codeUnitAt(0) - 97;
      final rank = int.parse(sq[1]) - 1;
      final col  = widget.blackSideAtBottom ? 7 - file : file;
      final row  = widget.blackSideAtBottom ? rank : 7 - rank;
      final cap  = _squares[sq] != null;
      return Positioned(
        left: col * cs, top: row * cs, width: cs, height: cs,
        child: Center(child: Container(
          width:  cap ? cs * 0.88 : cs * 0.3,
          height: cap ? cs * 0.88 : cs * 0.3,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:  cap ? Colors.transparent : widget.boardColors.possibleMovesColor,
            border: cap ? Border.all(color: widget.boardColors.possibleMovesColor, width: 3) : null,
          ),
        )),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final board = GestureDetector(
      onTapUp: _handleTap,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      onPanCancel: _handlePanCancel,
      child: Stack(children: [
        CustomPaint(
          painter: _BoardPainter(
            colors: widget.boardColors,
            blackSideAtBottom: widget.blackSideAtBottom,
            tapStart: _tapStart,
            cellHighlights: widget.cellHighlights,
            showCoords: widget.showCoordinatesZone,
            arrow: widget.arrow,
          ),
          size: Size.square(widget.size),
        ),
        ..._buildPieces(),
        if (_dnd != null) _buildDragged(),
        if (widget.showPossibleMoves) ..._buildMoveHints(),
      ]),
    );

    if (!widget.isInteractive) {
      return Stack(children: [
        Opacity(opacity: 0.6, child: board),
        Positioned.fill(child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: widget.nonInteractiveOverlayColor ?? Colors.orange, width: 3),
            borderRadius: BorderRadius.circular(4),
          ),
          child: widget.nonInteractiveMessage != null
              ? Center(child: Text(widget.nonInteractiveMessage!, style: widget.nonInteractiveTextStyle))
              : null,
        )),
      ]);
    }
    return board;
  }
  
  Map<String, Piece?> _getSquares(String fen) => _getSquaresFromFen(fen);
}

class _DndDetails {
  (int, int) startCell;
  (double, double) position;
  Piece movedPiece;
  _DndDetails({required this.startCell, required this.position, required this.movedPiece});
}

class _BoardPainter extends CustomPainter {
  final ChessBoardColors colors;
  final bool blackSideAtBottom;
  final (int, int)? tapStart;
  final Map<String, Color> cellHighlights;
  final bool showCoords;
  final BoardArrow? arrow;

  const _BoardPainter({
    required this.colors, required this.blackSideAtBottom,
    required this.tapStart, required this.cellHighlights,
    required this.showCoords, required this.arrow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cs = size.width / 8;
    final paint = Paint();

    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final file = blackSideAtBottom ? 7 - c : c;
        final rank = blackSideAtBottom ? r : 7 - r;
        final sq = '${String.fromCharCode(97 + file)}${rank + 1}';

        Color color = (r + c) % 2 == 0 ? colors.lightSquaresColor : colors.darkSquaresColor;
        if (tapStart != null && tapStart!.$1 == file && tapStart!.$2 == rank) {
          color = colors.startSquareColor.withAlpha(180);
        }
        if (cellHighlights.containsKey(sq)) color = cellHighlights[sq]!;

        paint.color = color;
        canvas.drawRect(Rect.fromLTWH(c * cs, r * cs, cs, cs), paint);

        if (showCoords) {
          if (c == 0) _drawText(canvas, '${rank + 1}', Offset(c * cs + 3, r * cs + 2), cs * 0.17);
          if (r == 7) _drawText(canvas, String.fromCharCode(97 + file), Offset((c + 1) * cs - cs * 0.2, (r + 1) * cs - cs * 0.22), cs * 0.17);
        }
      }
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: colors.coordinatesColor, fontSize: fontSize, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_BoardPainter old) => true;
}
