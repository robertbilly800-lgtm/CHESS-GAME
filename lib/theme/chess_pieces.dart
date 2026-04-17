import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChessPieceFactory {
  // Mapping of piece codes to asset paths
  static String _getAssetPath(String key) {
    switch (key) {
      case 'K': return 'assets/chess_pieces/wk.png';
      case 'Q': return 'assets/chess_pieces/wq.png';
      case 'R': return 'assets/chess_pieces/wr.png';
      case 'B': return 'assets/chess_pieces/wb.png';
      case 'N': return 'assets/chess_pieces/wn.png';
      case 'P': return 'assets/chess_pieces/wp.png';
      case 'k': return 'assets/chess_pieces/bk.png';
      case 'q': return 'assets/chess_pieces/bq.png';
      case 'r': return 'assets/chess_pieces/br.png';
      case 'b': return 'assets/chess_pieces/bb.png';
      case 'n': return 'assets/chess_pieces/bn.png';
      case 'p': return 'assets/chess_pieces/bp.png';
      default: return '';
    }
  }

  static Widget createPieceWidget(String key, double size, Color color) {
    final path = _getAssetPath(key);
    if (path.isEmpty) return const SizedBox.shrink();
    
    return Image.asset(
      path,
      width: size,
      height: size,
      fit: BoxFit.contain,
      // No color filter needed for PNGs as they are pre-colored
    );
  }
}
