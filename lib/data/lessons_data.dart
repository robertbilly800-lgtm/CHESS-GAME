class ChessLesson {
  final String id;
  final String title;
  final String category;
  final String description;
  final List<String> objectives;
  final String difficulty;
  final List<String> keyMoves;
  final String? startFen; // board position for interactive lessons
  final String? explanation;

  const ChessLesson({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.objectives,
    required this.difficulty,
    this.keyMoves = const [],
    this.startFen,
    this.explanation,
  });
}

class ChessPuzzle {
  final String id;
  final String title;
  final String fen;
  final String solution; // UCI move e.g. "e1g1"
  final String hint;
  final String difficulty;
  final String theme; // Fork, Pin, Skewer, Checkmate, etc.

  const ChessPuzzle({
    required this.id,
    required this.title,
    required this.fen,
    required this.solution,
    required this.hint,
    required this.difficulty,
    required this.theme,
  });
}

// ════════════════════════════════════════════════════════
// TUTORIALS
// ════════════════════════════════════════════════════════
final List<ChessLesson> tutorialLessons = [
  ChessLesson(
    id: 'tut_1',
    title: 'How the Pieces Move',
    category: 'Tutorial',
    difficulty: 'Beginner',
    description: 'Learn how every chess piece moves and captures. The foundation of all chess knowledge.',
    explanation: '''
♟ PAWN — Moves one square forward. On its first move it can move two squares. Captures diagonally. Can promote to any piece when reaching the last rank.

♞ KNIGHT — Moves in an "L" shape: 2 squares in one direction and 1 square perpendicular. The only piece that can jump over others.

♝ BISHOP — Slides diagonally any number of squares. Always stays on the same color.

♜ ROOK — Slides horizontally or vertically any number of squares. Used in castling.

♛ QUEEN — The most powerful piece. Slides in any direction (horizontal, vertical, diagonal) any number of squares.

♚ KING — Moves one square in any direction. Must never be left in check. Can castle with a rook.
''',
    objectives: [
      'Understand how pawns move and capture',
      'Learn the unique L-shaped knight move',
      'Distinguish how bishops and rooks move',
      'Know the queen is the most powerful piece',
      'Understand why the king must be protected',
    ],
    keyMoves: ['e2e4', 'g1f3', 'f1c4'],
  ),
  ChessLesson(
    id: 'tut_2',
    title: 'Check, Checkmate & Stalemate',
    category: 'Tutorial',
    difficulty: 'Beginner',
    description: 'The three most important outcomes in chess: putting the king in danger, ending the game, and drawing.',
    explanation: '''
CHECK — Your king is under attack. You MUST respond by: (1) moving your king, (2) blocking the attack, or (3) capturing the attacker.

CHECKMATE — Your king is in check and there is no legal move to escape. The game ends — the checking player wins.

STALEMATE — It is your turn but you have NO legal moves, yet your king is NOT in check. This is a DRAW. It often happens when a losing player has only their king left.

TIPS:
• Always scan if your move leaves your king in check — it's illegal!
• Look for stalemate tricks when you are losing — it can save a draw.
• Checkmate requires coordination — rarely a single piece can do it alone.
''',
    objectives: [
      'Identify when a king is in check',
      'Know the three ways to escape check',
      'Understand why checkmate ends the game',
      'Recognize stalemate as a drawing resource',
    ],
    keyMoves: ['e1g1'],
  ),
  ChessLesson(
    id: 'tut_3',
    title: 'The Power of Castling',
    category: 'Tutorial',
    difficulty: 'Beginner',
    description: 'Castling is the only move where two pieces move at once. It keeps your king safe and activates your rook.',
    explanation: '''
HOW TO CASTLE:
• King moves 2 squares toward the rook
• The rook jumps to the other side of the king
• Kingside castling (O-O): King goes g1, rook goes f1
• Queenside castling (O-O-O): King goes c1, rook goes d1

CONDITIONS — You CANNOT castle if:
1. The king or that rook has already moved
2. Your king is currently in check
3. Any square the king passes through is under attack
4. There are pieces between king and rook

WHY CASTLE?
• Your king is safer behind a wall of pawns
• Your rook becomes active in the center
• Castle early (before move 10) as a general rule
''',
    objectives: [
      'Know how kingside and queenside castling works',
      'Identify when castling is illegal',
      'Understand why castling improves your position',
      'Practice castling in the first 10 moves',
    ],
    keyMoves: ['e1g1', 'e1c1'],
  ),
  ChessLesson(
    id: 'tut_4',
    title: 'Special Moves: En Passant & Promotion',
    category: 'Tutorial',
    difficulty: 'Beginner',
    description: 'Two unique rules that surprise beginners. Master them to avoid being caught off guard.',
    explanation: '''
EN PASSANT (French: "in passing"):
• Happens when a pawn moves 2 squares from its start and lands beside an enemy pawn
• The enemy pawn can capture it AS IF it had only moved 1 square
• This capture must be made IMMEDIATELY on the very next move or the right is lost

PROMOTION:
• When your pawn reaches the last rank (rank 8 for White, rank 1 for Black) it must promote
• You can choose: Queen, Rook, Bishop, or Knight
• Almost always promote to a Queen (the strongest piece)
• Promoting to a Knight (underpromotion) can sometimes be better to deliver an immediate checkmate

STRATEGY TIP:
• Passed pawns — pawns with no enemy pawns blocking or attacking their path — are very powerful. Push them toward promotion!
''',
    objectives: [
      'Understand en passant and when it applies',
      'Know that en passant must be played immediately',
      'Learn pawn promotion rules',
      'Understand why queen promotion is usually best',
    ],
    keyMoves: ['e5d6'],
  ),
];

// ════════════════════════════════════════════════════════
// OPENINGS
// ════════════════════════════════════════════════════════
final List<ChessLesson> openingLessons = [
  ChessLesson(
    id: 'op_1',
    title: 'The Italian Game',
    category: 'Openings',
    difficulty: 'Beginner',
    description: 'One of the oldest openings in chess history. Develops pieces quickly and aims for rapid king safety.',
    keyMoves: ['e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1c4'],
    explanation: '''
MOVES: 1. e4 e5  2. Nf3 Nc6  3. Bc4

WHY IT WORKS:
• 1. e4 — controls the center, opens lines for queen and bishop
• 2. Nf3 — develops a knight AND attacks the e5 pawn
• 3. Bc4 — the "Italian bishop" eyes the f7 square, a weak point near Black's king

MAIN IDEAS:
• Castle kingside early (usually move 4-5)
• Play d3 for solid center control
• Plan f4 or Ng5 for kingside attacks

WATCH OUT FOR:
• The Fried Liver Attack: Ng5, Nxf7 sacrificing a knight for a fierce attack
• Always count your pieces are defended before attacking
''',
    objectives: [
      'Learn the 3-move Italian setup: e4, Nf3, Bc4',
      'Understand why f7 is a weak square for Black',
      'Practice developing pieces before castling',
      'Recognize the Giuoco Piano position',
    ],
  ),
  ChessLesson(
    id: 'op_2',
    title: 'The Ruy Lopez',
    category: 'Openings',
    difficulty: 'Intermediate',
    description: 'The most famous and deeply studied opening. Used by world champions for 500 years. Creates lasting pressure on Black.',
    keyMoves: ['e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1b5'],
    explanation: '''
MOVES: 1. e4 e5  2. Nf3 Nc6  3. Bb5

THE IDEA:
• Bb5 pins — or threatens to remove — the knight defending e5
• White plans to take on c6, then capture the undefended e5 pawn
• Black usually plays 3...a6 (Morphy Defense) to kick the bishop back

MAIN LINES:
• Closed Ruy Lopez: 4. Ba4 Nf6 5. 0-0 Be7 6. Re1 — solid and positional
• Exchange Variation: 4. Bxc6 dxc6 — doubled pawns for Black but open files

STRATEGY:
• White often maneuvers the knight to g3-f5 for kingside pressure
• Black tries to free the position with d5 at the right moment
• This opening leads to long positional battles — think 30+ moves ahead

FAMOUS PLAYERS: Bobby Fischer, Magnus Carlsen, Garry Kasparov all used this as White.
''',
    objectives: [
      'Understand the pin idea behind Bb5',
      'Learn the Morphy Defense (3...a6)',
      'Know the difference between Closed and Exchange variations',
      'Recognize the typical Ruy Lopez pawn structure',
    ],
  ),
  ChessLesson(
    id: 'op_3',
    title: 'The Sicilian Defense',
    category: 'Openings',
    difficulty: 'Advanced',
    description: 'The most popular response to 1. e4. Creates an imbalanced position where Black fights for the initiative from move one.',
    keyMoves: ['e2e4', 'c7c5'],
    explanation: '''
MOVE: 1. e4 c5

WHY SICILIAN?
• Black avoids the symmetrical 1...e5 and fights for the center differently
• 1...c5 controls d4 without giving White a second center pawn
• Black typically gets active counterplay on the queenside

MAIN VARIATIONS:
• Najdorf (5...a6): The sharpest. Used by Fischer, Kasparov. Black plays a6 to prevent Nb5
• Dragon (5...g6): Black fianchettoes the bishop. Wild tactical battles
• Classical (5...Nc6): Solid and flexible
• Scheveningen (5...e6): Careful setup — Black waits to see White's plan

OPEN SICILIAN: After 2. Nf3 and 3. d4, wild tactical play begins
CLOSED SICILIAN: 2. Nc3 g3 — positional, slower game

THIS IS THEORY: Top players have memorized 20-30 moves of Sicilian theory!
''',
    objectives: [
      'Understand why 1...c5 is Black\'s best fighting response',
      'Identify Najdorf, Dragon, and Classical variations',
      'Know the plan of d5 breakthrough for Black',
      'Understand pawn tension in the Open Sicilian',
    ],
  ),
  ChessLesson(
    id: 'op_4',
    title: "The Queen's Gambit",
    category: 'Openings',
    difficulty: 'Intermediate',
    description: 'One of the most respected openings. White offers a pawn to control the center — but it\'s not really a gambit!',
    keyMoves: ['d2d4', 'd7d5', 'c2c4'],
    explanation: '''
MOVES: 1. d4 d5  2. c4

THE "GAMBIT":
• White offers the c4 pawn, but if Black takes (2...dxc4) White plays 3. e4 and gets a huge center
• The pawn can usually be won back easily, so it\'s really not a risky gambit

TWO RESPONSES:
• Queen\'s Gambit Accepted (2...dxc4): Black takes the pawn. Sharp play.
• Queen\'s Gambit Declined (2...e6): Black declines. Solid but slightly passive.

KEY IDEAS FOR WHITE:
• Control the center with pawns on c4 and d4
• Develop Nc3, Nf3, and fianchetto or centralize bishops
• Minority attack: push b4-b5 to create queenside weaknesses

KEY IDEAS FOR BLACK:
• Free the position with ...c5 at the right moment
• The "problem bishop" on c8 — find a way to develop it!
• Counterattack with ...e5 or ...c5 to challenge White\'s center

FAMOUS: Made popular again by the Netflix series "The Queen\'s Gambit".
''',
    objectives: [
      'Know the Queen\'s Gambit starting moves: 1.d4 d5 2.c4',
      'Understand QGA vs QGD',
      'Learn the minority attack concept',
      'Solve the problem of the c8 bishop',
    ],
  ),
];

// ════════════════════════════════════════════════════════
// TACTICS (PUZZLES THEORY)
// ════════════════════════════════════════════════════════
final List<ChessLesson> tacticsLessons = [
  ChessLesson(
    id: 'tac_1',
    title: 'The Fork',
    category: 'Tactics',
    difficulty: 'Beginner',
    description: 'A fork attacks two or more pieces at once with a single move. The most common tactical weapon in chess.',
    explanation: '''
WHAT IS A FORK?
A fork is when ONE piece attacks TWO or more enemy pieces simultaneously. Your opponent can only save one — you win the other.

KNIGHT FORKS ARE MOST COMMON:
• The knight\'s L-shape lets it jump to surprising squares
• A knight on d5 can fork pieces on c7, e7, b6, f6, b4, f4, c3, e3

EXAMPLE:
White knight on e5, attacks Black queen on d7 AND rook on c6 at the same time. Black must move one, White takes the other.

PAWN FORKS:
• Advance a pawn to attack two pieces diagonally
• Example: pawn to e5 attacks knight on d6 and bishop on f6

KING FORKS:
• In endgames, the king can fork pieces when the position opens up

HOW TO FIND FORKS:
1. Look at all undefended or only-once-defended enemy pieces
2. Find a square your piece can jump to that attacks two at once
3. Check that square is safe (not recaptured)
''',
    objectives: [
      'Recognize a fork opportunity in a position',
      'Find knight forks attacking king and rook',
      'Identify pawn fork opportunities',
      'Calculate that the forking square is safe',
    ],
    keyMoves: ['e5d7'],
  ),
  ChessLesson(
    id: 'tac_2',
    title: 'The Pin',
    category: 'Tactics',
    difficulty: 'Beginner',
    description: 'A pin immobilizes a piece because moving it would expose a more valuable piece behind it to attack.',
    explanation: '''
TWO TYPES OF PINS:

ABSOLUTE PIN — The pinned piece cannot legally move because it would expose the king to check.
• Example: Bishop on b5 pins the Nc6 to the king on e8. Moving Nc6 is illegal!

RELATIVE PIN — Moving the pinned piece is legal but would lose a more valuable piece behind it.
• Example: Bishop on g5 pins Nf6 to the queen on d8. Black CAN move the knight, but loses the queen.

HOW TO EXPLOIT A PIN:
1. Attack the pinned piece with pawns or less valuable pieces
2. The pinned piece cannot retreat or capture back effectively
3. Often forces material gain or positional advantage

BREAKING A PIN:
• Interpose a piece between the attacking piece and the piece behind
• Move the valuable piece that is being threatened behind
• Attack the pinning piece to drive it away
• Castle to move the king out of the pin line

WATCH FOR: Bishops and rooks creating pins along ranks, files and diagonals
''',
    objectives: [
      'Distinguish absolute pin from relative pin',
      'Find pieces that can create pins',
      'Learn how to attack a pinned piece',
      'Know the three ways to break a pin',
    ],
  ),
  ChessLesson(
    id: 'tac_3',
    title: 'The Skewer',
    category: 'Tactics',
    difficulty: 'Intermediate',
    description: 'A skewer is like a reverse pin — it attacks a valuable piece that must move, exposing a less valuable piece behind it.',
    explanation: '''
SKEWER vs PIN:
• PIN: Less valuable piece is in front, more valuable behind. Front piece is "stuck."
• SKEWER: More valuable piece is in front. It moves to safety — revealing the weaker piece behind. You win that weaker piece.

CLASSIC SKEWER:
White rook on a1, Black king on a8, Black rook on a5.
White plays Ra1+ — the king MUST move. Now the Black rook on a5 is hanging. White takes it.

BISHOP SKEWER EXAMPLE:
White bishop on b1, Black queen on f5, Black rook on h7 (all on the same diagonal).
Bg2! skewers the queen. Queen moves, bishop takes the rook.

TIPS:
• Skewers most commonly involve the king being checked along a rank or file
• After check, the king must move — always look what\'s behind the king!
• Skewers with bishops are trickier to see — practice diagonal vision
''',
    objectives: [
      'Understand the difference between skewer and pin',
      'Identify skewer opportunities with rooks and bishops',
      'See what piece stands behind the target',
      'Deliver a king-skewer to win material',
    ],
  ),
  ChessLesson(
    id: 'tac_4',
    title: 'Discovered Attack',
    category: 'Tactics',
    difficulty: 'Intermediate',
    description: 'Moving one piece reveals an attack from another piece behind it — often devastatingly effective.',
    explanation: '''
WHAT IS A DISCOVERED ATTACK?
When you move Piece A, it reveals an attack from Piece B that was hidden behind it. Often Piece A makes its OWN threat at the same time — creating two threats that cannot both be met.

DISCOVERED CHECK:
The most powerful version — the revealed piece gives check. Your opponent MUST deal with check, so they lose the piece your moving piece attacks.

DOUBLE CHECK:
Both the moving piece AND the revealed piece give check simultaneously. The only legal response is to move the king — cannot block or capture both attackers at once.

EXAMPLE:
White has: Rook on e1, Knight on e4, queen on d8 (Black)
Ne4 moves to c5 — DISCOVERED CHECK on Black king from Re1, AND Nc5 attacks Black queen!
Black must deal with check — White wins the queen.

STRATEGY:
• Pieces "in line" with enemy valuable pieces are dangerous
• Always scan if moving a piece reveals an attack from behind
• Discovered attacks are often missed by beginners!
''',
    objectives: [
      'Recognize discovered attack setups',
      'Understand discovered check vs double check',
      'Find pieces that are "lined up" behind your pieces',
      'Create a two-pronged threat with discovered attacks',
    ],
  ),
];

// ════════════════════════════════════════════════════════
// ENDGAMES
// ════════════════════════════════════════════════════════
final List<ChessLesson> endgameLessons = [
  ChessLesson(
    id: 'end_1',
    title: 'King and Pawn Endgames',
    category: 'Endgames',
    difficulty: 'Beginner',
    startFen: '8/8/8/4k3/4P3/4K3/8/8 w - - 0 1',
    description: 'The most fundamental endgame. Understanding the key square principle and opposition wins games.',
    explanation: '''
THE OPPOSITION:
• Two kings facing each other with one square between them
• The player who does NOT have to move holds the "opposition"
• Whoever must move first loses ground — forced to give way

KEY SQUARES:
• For a pawn on e4, the key squares are d6, e6, f6
• If White\'s king reaches ANY of these squares with the pawn still on the board, the pawn will promote
• Black must prevent the White king from reaching those squares

THE RULE:
• With the pawn on e4 and kings on e2 vs e5 — it\'s White to move, opposition lost
• White CANNOT queen the pawn with best play from Black
• With kings on e3 vs e5 — White to move, White HOLDS opposition — pawn promotes!

ROOK PAWN EXCEPTION:
• Rook pawns (a and h files) often draw even when the stronger side seems to be winning
• The king gets trapped in the corner and stalemate saves Black

PASSED PAWNS:
• A pawn with no enemy pawns in front or adjacent is passed — very strong in endgames
• "A passed pawn must be pushed!" — classic chess saying
''',
    objectives: [
      'Understand king opposition',
      'Identify key squares for a pawn',
      'Know the rook pawn drawing technique',
      'Practice the Lucena and Philidor positions',
    ],
  ),
  ChessLesson(
    id: 'end_2',
    title: 'Rook Endgames',
    category: 'Endgames',
    difficulty: 'Intermediate',
    description: 'Rook endgames are the most common endgame type. Two key positions every player must memorize.',
    explanation: '''
ROOK ENDGAMES OCCUR IN ~50% OF ALL GAMES. Know these two positions:

PHILIDOR POSITION (DRAW):
• Weaker side has: King on e8, Rook on a6, Pawn on e6 for stronger side
• Black plays Ra6 — stays on the 6th rank, blocking pawn advance
• When White king advances to e6 — Black plays Rf6+ check, then Ra6 checking from behind
• KEY: Keep your rook on the 6th rank until the enemy king advances!

LUCENA POSITION (WIN):
• Stronger side has: King on f7, Pawn on f6, Rook on h1 vs King on f8, Rook on a8
• White uses the "bridge building" technique:
  Step 1: Play Rd1 (or Re1, Rf1) cutting off the enemy king
  Step 2: Advance the king
  Step 3: Build a "bridge" for the king with the rook

GENERAL ROOK RULES:
• "Rooks belong behind passed pawns" — attack them from behind!
• Cut off the enemy king along ranks or files
• Keep your rook active — a passive rook loses
• Rook + pawn vs rook: draws with correct defense ~90% of the time
''',
    objectives: [
      'Memorize the Philidor drawing technique',
      'Learn the Lucena winning method (bridge building)',
      'Apply "rook behind the passed pawn" rule',
      'Practice cutting off the king with a rook',
    ],
  ),
  ChessLesson(
    id: 'end_3',
    title: 'Queen vs Pawn Endgame',
    category: 'Endgames',
    difficulty: 'Advanced',
    description: 'The queen usually wins against a pawn, but rook and bishop pawns on the 7th rank create tricky exceptions.',
    explanation: '''
NORMALLY: Queen beats a pawn easily. Use the queen to stop the pawn while bringing your king over.

TECHNIQUE — Queen vs Pawn on 7th:
Step 1: Check the king with the queen repeatedly, forcing it in front of its own pawn
Step 2: Each time the king blocks the pawn, your king takes a step closer
Step 3: Eventually your king helps deliver checkmate or capture the pawn

THE EXCEPTION — Rook or Bishop Pawn:
If the pawn is on a7, c7, f7 (bishop pawn) or a7/h7 (rook pawn), it\'s often a DRAW:
• The defending king hides in the corner
• The queen cannot check without creating stalemate
• The attacking side must be very precise to win

EXAMPLE (Draw): White queen vs Black pawn on a2, Black king on a1
• If Black king is already on a1 (or b1) with pawn on a2 — it\'s stalemate if White isn\'t careful!
• Queen must first force the king AWAY from the corner, then capture the pawn

IMPORTANT: If YOUR king is far away, sometimes a pawn on 7th draws even without the stalemate trick. Always calculate!
''',
    objectives: [
      'Apply the queen checking technique to gain time',
      'Recognize the stalemate danger with rook/bishop pawns',
      'Practice queen vs a-pawn on the 7th',
      'Understand when queen vs pawn is a guaranteed win',
    ],
  ),
];

// ════════════════════════════════════════════════════════
// DAILY PUZZLES (interactive)
// ════════════════════════════════════════════════════════
final List<ChessPuzzle> dailyPuzzles = [
  ChessPuzzle(
    id: 'puz_1',
    title: 'Knight Fork',
    fen: 'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4',
    solution: 'f3g5',
    hint: 'Look for a knight move that attacks the queen and a key square simultaneously.',
    difficulty: 'Beginner',
    theme: 'Fork',
  ),
  ChessPuzzle(
    id: 'puz_2',
    title: 'Back Rank Mate',
    fen: '6k1/5ppp/8/8/8/8/5PPP/R5K1 w - - 0 1',
    solution: 'a1a8',
    hint: 'The enemy king is trapped on the back rank. One rook move ends it.',
    difficulty: 'Beginner',
    theme: 'Checkmate',
  ),
  ChessPuzzle(
    id: 'puz_3',
    title: 'Pin to Win',
    fen: 'rnbqkb1r/ppp2ppp/4pn2/3p4/2PP4/5NP1/PP2PPBP/RNBQK2R b KQkq - 0 5',
    solution: 'f8b4',
    hint: 'Pin the knight to the king, creating pressure on the center.',
    difficulty: 'Intermediate',
    theme: 'Pin',
  ),
  ChessPuzzle(
    id: 'puz_4',
    title: 'Queen Sacrifice',
    fen: '4k3/8/8/8/8/4Q3/8/4K3 w - - 0 1',
    solution: 'e3e8',
    hint: 'Sometimes sacrificing your queen leads to immediate checkmate.',
    difficulty: 'Beginner',
    theme: 'Checkmate',
  ),
  ChessPuzzle(
    id: 'puz_5',
    title: 'Discovered Check',
    fen: 'r3k2r/ppp2ppp/2n1bn2/2bpp3/2B1P3/2NP1N2/PPP2PPP/R1BQR1K1 w kq - 0 1',
    solution: 'c4f7',
    hint: 'Move the bishop — what piece does it reveal behind it?',
    difficulty: 'Intermediate',
    theme: 'Discovered Attack',
  ),
];

// All lessons combined for the learn tab
final List<ChessLesson> chessLessons = [
  ...tutorialLessons,
  ...openingLessons,
  ...tacticsLessons,
  ...endgameLessons,
];
