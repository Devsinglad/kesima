import 'package:flutter/material.dart';
import '../constants/game_constants.dart';
import '../theme/app_colors.dart';

/// Simplified board preview used on the home screen.
/// Mirrors the 11-node layout: top row (Blue) + circle area + bottom row (Red).
class MiniBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final lp = Paint()
      ..color = AppColors.goldLight.withValues(alpha: 0.70)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    // Top home row: node 0 → node 2
    canvas.drawLine(
      Offset(kNodePos[0].dx * size.width, kNodePos[0].dy * size.height),
      Offset(kNodePos[2].dx * size.width, kNodePos[2].dy * size.height),
      lp,
    );

    // Bottom home row: node 8 → node 10
    canvas.drawLine(
      Offset(kNodePos[8].dx * size.width, kNodePos[8].dy * size.height),
      Offset(kNodePos[10].dx * size.width, kNodePos[10].dy * size.height),
      lp,
    );

    // Vertical: node 1 → node 9
    canvas.drawLine(
      Offset(kNodePos[1].dx * size.width, kNodePos[1].dy * size.height),
      Offset(kNodePos[9].dx * size.width, kNodePos[9].dy * size.height),
      lp,
    );

    // Horizontal through circle: node 4 → node 6
    canvas.drawLine(
      Offset(kNodePos[4].dx * size.width, kNodePos[4].dy * size.height),
      Offset(kNodePos[6].dx * size.width, kNodePos[6].dy * size.height),
      lp,
    );

    // Circle (centered at node 5)
    canvas.drawCircle(
      Offset(kNodePos[5].dx * size.width, kNodePos[5].dy * size.height),
      size.width * kCircleR,
      lp..style = PaintingStyle.stroke,
    );

    // Blue pieces: top row nodes 0, 1, 2
    _drawPieces(canvas, size, [0, 1, 2], AppColors.blue, AppColors.blueDark);

    // Red pieces: bottom row nodes 8, 9, 10
    _drawPieces(canvas, size, [8, 9, 10], AppColors.red, AppColors.redDark);

    // Empty node dots: 3, 4, 5, 6, 7
    _drawEmptyDots(canvas, size, [3, 4, 5, 6, 7]);
  }

  void _drawPieces(
      Canvas canvas, Size size, List<int> nodes, Color fill, Color border) {
    for (final n in nodes) {
      final pos = Offset(kNodePos[n].dx * size.width, kNodePos[n].dy * size.height);
      canvas.drawCircle(pos, size.width * 0.065, Paint()..color = fill);
      canvas.drawCircle(
        pos,
        size.width * 0.065,
        Paint()
          ..color = border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  void _drawEmptyDots(Canvas canvas, Size size, List<int> nodes) {
    for (final n in nodes) {
      canvas.drawCircle(
        Offset(kNodePos[n].dx * size.width, kNodePos[n].dy * size.height),
        size.width * 0.028,
        Paint()..color = AppColors.goldPale.withValues(alpha: 0.70),
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
