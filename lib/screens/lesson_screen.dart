import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../data/lessons_data.dart';
import '../widgets/chess/simple_chess_board.dart';
import 'package:chess/chess.dart' as ch;

class LessonScreen extends StatefulWidget {
  final ChessLesson lesson;
  const LessonScreen({Key? key, required this.lesson}) : super(key: key);

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  int _step = 0;
  late ch.Chess _game;
  bool _showBoard = false;

  @override
  void initState() {
    super.initState();
    _game = widget.lesson.startFen != null
        ? ch.Chess.fromFEN(widget.lesson.startFen!)
        : ch.Chess();
    _showBoard = widget.lesson.startFen != null;
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(lesson.title, style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _categoryColor(lesson.category).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(lesson.category, style: GoogleFonts.outfit(color: _categoryColor(lesson.category), fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Difficulty badge
            Row(
              children: [
                _badge(lesson.difficulty),
                const SizedBox(width: 8),
                _badge('${lesson.objectives.length} objectives'),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Text(lesson.description,
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, height: 1.6)),
            ),
            const SizedBox(height: 20),

            // Key moves
            if (lesson.keyMoves.isNotEmpty) ...[
              Text('KEY MOVES', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: lesson.keyMoves.map((move) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
                  ),
                  child: Text(move, style: GoogleFonts.outfit(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                )).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // Board if available
            if (_showBoard) ...[
              Text('POSITION', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: SimpleChessBoard(
                    fen: _game.fen,
                    onMove: ({required ShortMove move}) {
                      final m = _game.move({'from': move.from, 'to': move.to, 'promotion': 'q'});
                      if (m != null) setState(() {});
                    },
                    whitePlayerType: PlayerType.human,
                    blackPlayerType: PlayerType.human,
                    showPossibleMoves: true,
                    blackSideAtBottom: false,
                    chessBoardColors: ChessBoardColors()
                      ..lightSquaresColor = const Color(0xFFC8D5B1)
                      ..darkSquaresColor = const Color(0xFF7A9859),
                    cellHighlights: const {},
                    showCoordinatesZone: true,
                    onPromote: () async => PieceType.queen,
                    onPromotionCommited: ({required ShortMove moveDone, required PieceType pieceType}) {},
                    onTap: ({required String cellCoordinate}) {},
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _game = widget.lesson.startFen != null
                        ? ch.Chess.fromFEN(widget.lesson.startFen!)
                        : ch.Chess();
                  });
                },
                icon: const Icon(Icons.refresh, size: 16, color: AppColors.textMuted),
                label: Text('Reset position', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12)),
              ),
              const SizedBox(height: 12),
            ],

            // Full explanation
            if (lesson.explanation != null) ...[
              Text('LESSON CONTENT', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Text(
                  lesson.explanation!,
                  style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, height: 1.75),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Objectives checklist
            Text('OBJECTIVES', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            ...lesson.objectives.asMap().entries.map((e) => _buildObjective(e.key, e.value)),

            const SizedBox(height: 32),
            // Complete button
            GestureDetector(
              onTap: () {
                setState(() {
                  if (_step < lesson.objectives.length) _step = lesson.objectives.length;
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  backgroundColor: AppColors.primaryGreen,
                  content: Text('Lesson complete! ✓', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                  duration: const Duration(seconds: 2),
                ));
                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted) Navigator.pop(context);
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF00B873), Color(0xFF00D4A0)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text('Mark as Complete', style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildObjective(int index, String text) {
    final done = index < _step;
    return GestureDetector(
      onTap: () => setState(() => _step = index + 1),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: done ? AppColors.primaryGreen.withValues(alpha: 0.08) : AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: done ? AppColors.primaryGreen.withValues(alpha: 0.4) : AppColors.borderDark),
        ),
        child: Row(
          children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppColors.primaryGreen : AppColors.borderDark,
              ),
              child: Center(
                child: done
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : Text('${index + 1}', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                  style: GoogleFonts.outfit(
                    color: done ? Colors.white : Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                    decoration: done ? TextDecoration.none : null,
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.borderDark)),
    child: Text(label, style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11)),
  );

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'Tutorial': return AppColors.tutorialBlue;
      case 'Openings': return AppColors.openingGreen;
      case 'Tactics': return AppColors.puzzleGold;
      case 'Endgames': return AppColors.endgameRed;
      default: return AppColors.primaryGreen;
    }
  }
}

// ─────────────────────────────────────────────────────────
// Puzzle screen
// ─────────────────────────────────────────────────────────
class PuzzleScreen extends StatefulWidget {
  final ChessPuzzle puzzle;
  const PuzzleScreen({Key? key, required this.puzzle}) : super(key: key);

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  late ch.Chess _game;
  bool _solved = false;
  bool _failed = false;
  bool _showHint = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _game = ch.Chess.fromFEN(widget.puzzle.fen);
  }

  void _onMove(String from, String to) {
    final uci = from + to;
    final move = _game.move({'from': from, 'to': to, 'promotion': 'q'});
    if (move == null) return;

    if (uci == widget.puzzle.solution) {
      setState(() { _solved = true; _message = '🎉 Correct! Well done!'; });
    } else {
      setState(() { _failed = true; _message = '✗ Not quite. Try again!'; });
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _game = ch.Chess.fromFEN(widget.puzzle.fen);
            _failed = false;
            _message = '';
          });
        }
      });
    }
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.puzzle.title, style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                _badge(widget.puzzle.theme, AppColors.puzzleGold),
                const SizedBox(width: 8),
                _badge(widget.puzzle.difficulty, AppColors.primaryGreen),
              ],
            ),
            const SizedBox(height: 14),

            // Status message
            if (_message.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _solved ? AppColors.primaryGreen.withValues(alpha: 0.15) : AppColors.resignRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _solved ? AppColors.primaryGreen : AppColors.resignRed),
                ),
                child: Text(_message, style: GoogleFonts.syne(color: _solved ? AppColors.primaryGreen : AppColors.resignRed, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ).animate().fadeIn(),

            const SizedBox(height: 14),

            // Board
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 1,
                child: SimpleChessBoard(
                  fen: _game.fen,
                  onMove: ({required ShortMove move}) {
                    if (!_solved && !_failed) _onMove(move.from, move.to);
                  },
                  whitePlayerType: PlayerType.human,
                  blackPlayerType: PlayerType.human,
                  showPossibleMoves: !_solved,
                  blackSideAtBottom: false,
                  chessBoardColors: ChessBoardColors()
                    ..lightSquaresColor = const Color(0xFFC8D5B1)
                    ..darkSquaresColor = const Color(0xFF7A9859),
                  cellHighlights: const {},
                  showCoordinatesZone: true,
                  onPromote: () async => PieceType.queen,
                  onPromotionCommited: ({required ShortMove moveDone, required PieceType pieceType}) {},
                  onTap: ({required String cellCoordinate}) {},
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Hint
            if (!_solved) ...[
              if (_showHint)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderDark)),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, color: AppColors.puzzleGold, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(widget.puzzle.hint, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13))),
                    ],
                  ),
                ).animate().fadeIn()
              else
                TextButton.icon(
                  onPressed: () => setState(() => _showHint = true),
                  icon: const Icon(Icons.lightbulb_outline, color: AppColors.puzzleGold, size: 16),
                  label: Text('Show Hint', style: GoogleFonts.outfit(color: AppColors.puzzleGold, fontWeight: FontWeight.bold)),
                ),
            ],

            if (_solved) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF00B873), Color(0xFF00D4A0)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Continue', style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
                ),
              ).animate().fadeIn(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withValues(alpha: 0.3))),
    child: Text(label, style: GoogleFonts.outfit(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
  );
}
