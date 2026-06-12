import 'package:flutter/material.dart';
import '../models/player.dart';
import '../theme/app_colors.dart';

class PlayerCard extends StatelessWidget {
  final Player player;
  final bool   isActive;
  final bool   isWinner;

  const PlayerCard({
    required this.player,
    required this.isActive,
    required this.isWinner,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isBlue = player.isBlue;
    final accent = isBlue ? AppColors.blue : AppColors.red;
    final nameColor = isBlue
        ? const Color(0xFF90C0FF)
        : const Color(0xFFFF9090);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isWinner
            ? accent.withValues(alpha: 0.22)
            : isActive
                ? accent.withValues(alpha: 0.14)
                : Colors.black.withValues(alpha: 0.12),
        border: Border.all(
          color: (isActive || isWinner) ? accent : accent.withValues(alpha: 0.30),
          width: isActive ? 2.0 : 1.0,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: isActive
            ? [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 10)]
            : null,
      ),
      child: Row(
        mainAxisAlignment:
            isBlue ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: isBlue
            ? [_disc(accent), const SizedBox(width: 8), _label(nameColor, isBlue)]
            : [_label(nameColor, isBlue), const SizedBox(width: 8), _disc(accent)],
      ),
    );
  }

  Widget _disc(Color c) => Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c),
      );

  Widget _label(Color c, bool isBlue) => Column(
        crossAxisAlignment:
            isBlue ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            player.label,
            style: TextStyle(
              color: c,
              fontSize: 14,
              fontWeight:
                  (isActive || isWinner) ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            isBlue ? 'Top row' : 'Bottom row',
            style: TextStyle(color: c.withValues(alpha: 0.55), fontSize: 9),
          ),
        ],
      );
}
