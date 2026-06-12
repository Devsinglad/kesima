import 'package:flutter/material.dart';
import '../constants/game_constants.dart';
import '../models/player.dart';
import '../theme/app_colors.dart';

class BoardPainter extends CustomPainter {
  final List<Player?> board;
  final Player        current;
  final int?          selected;
  final List<int>     validMoves;
  final Player?       winner;
  final List<int>?    winLine;  // invaded nodes of winning player
  final double        pulse;    // 0.82–1.18, driven by AnimationController
  final int?          hintFrom; // suggested move source (hint button)
  final int?          hintTo;   // suggested move destination

  const BoardPainter({
    required this.board,
    required this.current,
    required this.selected,
    required this.validMoves,
    required this.winner,
    required this.winLine,
    required this.pulse,
    this.hintFrom,
    this.hintTo,
  });

  // Node i → pixel Offset on canvas
  Offset _p(int i, Size s) =>
      Offset(kNodePos[i].dx * s.width, kNodePos[i].dy * s.height);

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawZoneShading(canvas, size);
    _drawWinGlow(canvas, size);
    _drawBoardLines(canvas, size);
    _drawCircle(canvas, size);
    _drawHintArrow(canvas, size);
    _drawHighlights(canvas, size);
    _drawEmptyNodes(canvas, size);
    _drawPieces(canvas, size);
  }

  // ── Board background (parchment) ─────────────────
  void _drawBackground(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(16),
    );
    // shadow
    canvas.drawRRect(
      rr.shift(const Offset(4, 6)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    // parchment fill
    canvas.drawRRect(rr, Paint()..color = AppColors.parchment);
    // outer border
    canvas.drawRRect(
      rr,
      Paint()
        ..color = AppColors.midBrown
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8,
    );
    // inner decorative rule
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, 8, size.width - 16, size.height - 16),
        const Radius.circular(12),
      ),
      Paint()
        ..color = AppColors.lightBrown.withValues(alpha: 0.40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  // ── Home zone shading (top strip = blue, bottom strip = red) ────
  void _drawZoneShading(Canvas canvas, Size size) {
    final topBottom = size.height * 0.13;
    final bottomTop = size.height * 0.87;
    const rr = Radius.circular(14);

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0, 0, size.width, topBottom),
        topLeft: rr, topRight: rr,
      ),
      Paint()..color = AppColors.blue.withValues(alpha: 0.08),
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0, bottomTop, size.width, size.height - bottomTop),
        bottomLeft: rr, bottomRight: rr,
      ),
      Paint()..color = AppColors.red.withValues(alpha: 0.08),
    );
  }

  // ── Win glow: soft radial halos on invaded nodes ─────────────────
  void _drawWinGlow(Canvas canvas, Size size) {
    if (winLine == null || winLine!.isEmpty) return;
    for (final n in winLine!) {
      canvas.drawCircle(
        _p(n, size),
        size.width * 0.15 * pulse,
        Paint()..color = AppColors.goldLight.withValues(alpha: 0.28 * pulse),
      );
    }
  }

  // ── Board lines ───────────────────────────────────
  void _drawBoardLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.darkBrown
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // Top home row: node 0 ── node 2 (through node 1)
    canvas.drawLine(_p(0, size), _p(2, size), paint);
    // Vertical: node 1 ── node 9 (through 3, 5, 7)
    canvas.drawLine(_p(1, size), _p(9, size), paint);
    // Horizontal through circle: node 4 ── node 6 (through node 5)
    canvas.drawLine(_p(4, size), _p(6, size), paint);
    // Bottom home row: node 8 ── node 10 (through node 9)
    canvas.drawLine(_p(8, size), _p(10, size), paint);
  }

  // ── Circle ────────────────────────────────────────
  void _drawCircle(Canvas canvas, Size size) {
    final ctr = _p(5, size); // center hub
    final r   = size.width * kCircleR;
    // filled background so circle interior looks distinct
    canvas.drawCircle(ctr, r, Paint()..color = AppColors.parchment2);
    // stroke
    canvas.drawCircle(
      ctr, r,
      Paint()
        ..color = AppColors.darkBrown
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );
  }

  // ── Hint arrow ────────────────────────────────────
  void _drawHintArrow(Canvas canvas, Size size) {
    if (hintFrom == null || hintTo == null) return;
    final from = _p(hintFrom!, size);
    final to   = _p(hintTo!,   size);
    final pr   = size.width * kPieceR;

    // Glowing line
    canvas.drawLine(
      from, to,
      Paint()
        ..color       = AppColors.goldLight.withValues(alpha: 0.55 * pulse)
        ..strokeWidth = 4.0
        ..strokeCap   = StrokeCap.round,
    );

    // Pulsing ring around the destination
    canvas.drawCircle(
      to,
      pr * 1.55 * pulse,
      Paint()
        ..color = AppColors.goldLight.withValues(alpha: 0.30 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Highlight ring around the source
    canvas.drawCircle(
      from,
      pr * 1.30,
      Paint()
        ..color = AppColors.goldLight.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
  }

  // ── Selection ring + valid-move dots ─────────────
  void _drawHighlights(Canvas canvas, Size size) {
    final pr = size.width * kPieceR;

    // Amber valid-move dots
    for (final n in validMoves) {
      final pos = _p(n, size);
      final r   = pr * 0.90 * pulse;
      canvas.drawCircle(pos, r * 1.55,
          Paint()..color = AppColors.validMoveAmber.withValues(alpha: 0.22));
      canvas.drawCircle(pos, r * 1.05,
          Paint()..color = AppColors.validMoveAmber.withValues(alpha: 0.70));
      canvas.drawCircle(pos, r * 0.52,
          Paint()..color = AppColors.validMoveLight);
    }

    // Green selection rings (3 rings, fading out)
    if (selected != null) {
      final pos = _p(selected!, size);
      for (int i = 0; i < 3; i++) {
        canvas.drawCircle(
          pos,
          pr * (1.22 + i * 0.22),
          Paint()
            ..color = AppColors.selectionGreen.withValues(alpha: 0.42 - i * 0.11)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2 - i * 0.5,
        );
      }
    }
  }

  // ── Empty node markers ────────────────────────────
  void _drawEmptyNodes(Canvas canvas, Size size) {
    for (int i = 0; i < kNodePos.length; i++) {
      if (board[i] != null) { continue; }
      if (validMoves.contains(i)) { continue; } // amber dot handles these
      canvas.drawCircle(
        _p(i, size),
        size.width * 0.026,
        Paint()..color = AppColors.midBrown,
      );
    }
  }

  // ── Pieces ────────────────────────────────────────
  void _drawPieces(Canvas canvas, Size size) {
    final r = size.width * kPieceR;

    for (int i = 0; i < kNodePos.length; i++) {
      if (board[i] == null) { continue; }

      final pos      = _p(i, size);
      final isBlue   = board[i]!.isBlue;
      final isSel    = i == selected;
      final isWinPc  = winLine?.contains(i) ?? false;
      final pr       = r * (isSel ? 1.16 : 1.0)
                         * (isWinPc ? (0.92 + 0.08 * pulse) : 1.0);

      final (base, light, dark) = AppColors.pieceColors(isBlue);

      _drawSinglePiece(canvas, pos, pr, base, light, dark, isWinPc);
    }
  }

  void _drawSinglePiece(
    Canvas canvas, Offset pos, double r,
    Color base, Color light, Color dark,
    bool isWinPiece,
  ) {
    // Drop shadow
    canvas.drawCircle(
      pos + Offset(r * 0.22, r * 0.28),
      r,
      Paint()..color = Colors.black.withValues(alpha: 0.38),
    );
    // Base
    canvas.drawCircle(pos, r, Paint()..color = base);
    // Dark border
    canvas.drawCircle(pos, r,
        Paint()
          ..color = dark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2);
    // Inner highlight ring
    canvas.drawCircle(pos, r * 0.68,
        Paint()
          ..color = light.withValues(alpha: 0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
    // Diffuse highlight
    canvas.drawCircle(
      pos + Offset(-r * 0.27, r * 0.27),
      r * 0.36,
      Paint()..color = light.withValues(alpha: 0.55),
    );
    // Specular point
    canvas.drawCircle(
      pos + Offset(-r * 0.16, r * 0.16),
      r * 0.13,
      Paint()..color = Colors.white.withValues(alpha: 0.38),
    );
    // Win pulse ring
    if (isWinPiece) {
      canvas.drawCircle(
        pos,
        r * (1.0 + 0.18 * pulse),
        Paint()
          ..color = AppColors.goldLight.withValues(alpha: 0.62)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  @override
  bool shouldRepaint(BoardPainter old) =>
      old.pulse      != pulse      ||
      old.selected   != selected   ||
      old.winner     != winner     ||
      old.validMoves != validMoves ||
      old.winLine    != winLine    ||
      old.hintFrom   != hintFrom   ||
      old.hintTo     != hintTo;
}
