class ChessLesson {
  final String id;
  final String title;
  final String category;
  final String description;
  final List<String> objectives;
  final String difficulty;
  final List<String> keyMoves;

  ChessLesson({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.objectives,
    required this.difficulty,
    this.keyMoves = const [],
  });
}

final List<ChessLesson> chessLessons = [
  // ══════════════════════════════════════════════════════════════════════════
  // ── OPENINGS ──────────────────────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════
  ChessLesson(
    id: 'opening_1',
    title: 'The Italian Game',
    category: 'Openings',
    difficulty: 'Beginner',
    description: 'One of the oldest openings in chess. Develops pieces quickly and controls the center with pawns and knights.',
    keyMoves: ['1. e4 e5', '2. Nf3 Nc6', '3. Bc4'],
    objectives: [
      'Develop your bishop to an active diagonal.',
      'Castle early for king safety.',
      'Control the center with pawns and knights.',
    ],
  ),
  ChessLesson(
    id: 'opening_2',
    title: 'The Ruy Lopez',
    category: 'Openings',
    difficulty: 'Intermediate',
    description: 'Named after a 16th-century Spanish bishop. Focuses on long-term pressure against Black\'s e5 pawn.',
    keyMoves: ['1. e4 e5', '2. Nf3 Nc6', '3. Bb5'],
    objectives: [
      'Understand the setup 1. e4 e5 2. Nf3 Nc6 3. Bb5.',
      'Learn the Morphy Defense (3… a6).',
      'Control the center and apply pressure on the king-side.',
    ],
  ),
  ChessLesson(
    id: 'opening_3',
    title: 'Sicilian Defense',
    category: 'Openings',
    difficulty: 'Advanced',
    description: 'The most aggressive response to 1. e4. Creates asymmetrical positions with high winning chances for Black.',
    keyMoves: ['1. e4 c5'],
    objectives: [
      'Master the 1. e4 c5 counter-attack.',
      'Identify Open Sicilian vs Closed Sicilian lines.',
      'Understand the pawn structures that arise in the center.',
    ],
  ),
  ChessLesson(
    id: 'opening_4',
    title: "Queen's Gambit",
    category: 'Openings',
    difficulty: 'Intermediate',
    description: 'A classical opening for White that fights for the center with the d-pawn. Made famous by the Netflix series.',
    keyMoves: ['1. d4 d5', '2. c4'],
    objectives: [
      'Understand Accepted vs Declined variations.',
      'Learn why c4 is a "gambit" and how to recover the pawn.',
      'Control the center with c4 + d4 pawn duo.',
    ],
  ),
  ChessLesson(
    id: 'opening_5',
    title: 'The London System',
    category: 'Openings',
    difficulty: 'Beginner',
    description: 'A solid, easy-to-learn system for White. The same setup works against almost any Black response.',
    keyMoves: ['1. d4', '2. Bf4', '3. e3', '4. Nf3'],
    objectives: [
      'Learn the "autopilot" piece setup.',
      'Develop the dark-squared bishop before e3.',
      'Create a solid pawn structure with e3 + d4.',
    ],
  ),

  // ══════════════════════════════════════════════════════════════════════════
  // ── TACTICS ───────────────────────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════
  ChessLesson(
    id: 'tactic_1',
    title: 'The Power of the Fork',
    category: 'Tactics',
    difficulty: 'Beginner',
    description: 'A tactical double-attack where one piece attacks two or more enemy pieces simultaneously.',
    objectives: [
      'Knight forks: the most lethal weapon in chess.',
      'Pawn forks that win material in the middle-game.',
      'Recognizing and defending against potential forks.',
    ],
  ),
  ChessLesson(
    id: 'tactic_2',
    title: 'Pins and Skewers',
    category: 'Tactics',
    difficulty: 'Beginner',
    description: 'Using long-range pieces (Bishops, Rooks, Queen) to restrict opponent movement and win material.',
    objectives: [
      'Absolute vs Relative pins — when can you move?',
      'Setting up a skewer on the King and Queen.',
      'Breaking a pin effectively without losing material.',
    ],
  ),
  ChessLesson(
    id: 'tactic_3',
    title: 'Discovered Attacks',
    category: 'Tactics',
    difficulty: 'Intermediate',
    description: 'Moving one piece reveals an attack from another. The most powerful version is the "discovered check".',
    objectives: [
      'Understand the "battery" concept (two pieces on one line).',
      'Discovered check: the most dangerous attack in chess.',
      'Double check: when the King has no choice but to move.',
    ],
  ),
  ChessLesson(
    id: 'tactic_4',
    title: 'Sacrifices and Combinations',
    category: 'Tactics',
    difficulty: 'Advanced',
    description: 'Sometimes giving up material leads to a winning position or checkmate. Learn when to sacrifice.',
    objectives: [
      'Greek Gift sacrifice (Bxh7+) — a classic bishop sacrifice.',
      'Exchange sacrifices for positional advantage.',
      'Calculating forced sequences after a sacrifice.',
    ],
  ),
  ChessLesson(
    id: 'tactic_5',
    title: 'Back Rank Mate',
    category: 'Tactics',
    difficulty: 'Beginner',
    description: 'The most common checkmate pattern in chess. Learn to exploit a weak back rank and how to prevent it.',
    objectives: [
      'Recognize when your opponent\'s back rank is weak.',
      'Create a "luft" (breathing space) for your own King.',
      'Set up back rank combinations with rook sacrifices.',
    ],
  ),

  // ══════════════════════════════════════════════════════════════════════════
  // ── ENDGAMES ──────────────────────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════
  ChessLesson(
    id: 'endgame_1',
    title: 'King and Pawn Endings',
    category: 'Endgames',
    difficulty: 'Intermediate',
    description: 'The fundamental endgame. Learn when a pawn can be promoted and how to use your King as an attacker.',
    objectives: [
      'The Rule of the Square — can the King catch the pawn?',
      'Understanding Opposition (key squares).',
      'Pawn breakthrough techniques.',
    ],
  ),
  ChessLesson(
    id: 'endgame_2',
    title: 'Rook Endgames',
    category: 'Endgames',
    difficulty: 'Advanced',
    description: 'The most common endgame type. Learning these patterns will save (and win) you countless games.',
    objectives: [
      "Lucena Position: the winning technique.",
      "Philidor Position: the drawing technique.",
      'Rook activity: keeping your rook behind passed pawns.',
    ],
  ),
  ChessLesson(
    id: 'endgame_3',
    title: 'Checkmate Patterns',
    category: 'Endgames',
    difficulty: 'Beginner',
    description: 'Basic checkmate techniques that every player must know to convert a winning position.',
    objectives: [
      'King + Queen vs King mate.',
      'King + Rook vs King mate (the "box" method).',
      'Two bishops mate pattern.',
    ],
  ),

  // ══════════════════════════════════════════════════════════════════════════
  // ── STRATEGY ──────────────────────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════
  ChessLesson(
    id: 'strategy_1',
    title: 'Center Control',
    category: 'Strategy',
    difficulty: 'Beginner',
    description: 'Why the four central squares (d4, d5, e4, e5) are the most important part of the board.',
    objectives: [
      'Developing pieces towards the center.',
      'Occupying vs Influencing the center.',
      'Dealing with flank attacks by striking back in the center.',
    ],
  ),
  ChessLesson(
    id: 'strategy_2',
    title: 'Pawn Structure',
    category: 'Strategy',
    difficulty: 'Intermediate',
    description: 'Pawns are the soul of chess. Their structure determines the plans for both sides.',
    objectives: [
      'Isolated pawns: weakness or attacking tool?',
      'Doubled pawns and when they are acceptable.',
      'Passed pawns: how to create and push them to promotion.',
    ],
  ),
  ChessLesson(
    id: 'strategy_3',
    title: 'Piece Activity',
    category: 'Strategy',
    difficulty: 'Intermediate',
    description: 'A well-placed knight can be worth more than a rook. Learn to maximize your piece placement.',
    objectives: [
      'Good vs Bad bishops (blocked by own pawns).',
      'Knight outposts on the 5th rank.',
      'Rook lifts: moving rooks to the 3rd rank for attack.',
    ],
  ),
  ChessLesson(
    id: 'strategy_4',
    title: 'When to Exchange Pieces',
    category: 'Strategy',
    difficulty: 'Advanced',
    description: 'Knowing when to trade and when to keep pieces on the board is a hallmark of strong players.',
    objectives: [
      'Trade pieces when ahead in material.',
      'Keep pieces when you have the initiative.',
      'Exchanging your bad pieces for opponent\'s good pieces.',
    ],
  ),
];
