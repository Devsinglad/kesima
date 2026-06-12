import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// ── Mode chip ──────────────────────────────────────────────────────────────
// Selects VS-Computer or 2-Player mode.

class ModeChip extends StatelessWidget {
  final String       label;
  final IconData     icon;
  final bool         selected;
  final VoidCallback onTap;
  const ModeChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.gold : AppColors.goldPale;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? AppColors.gold
                  : AppColors.goldPale.withValues(alpha: 0.30),
              width: selected ? 2 : 1,
            ),
            color: selected
                ? AppColors.gold.withValues(alpha: 0.12)
                : Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Color chip ─────────────────────────────────────────────────────────────
// Selects which colour the human plays (Blue / Red) in VS-Computer mode.

class ColorChip extends StatelessWidget {
  final Color        color;
  final String       label;
  final String       sub;
  final bool         selected;
  final VoidCallback onTap;
  const ColorChip({
    super.key,
    required this.color,
    required this.label,
    required this.sub,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? color : color.withValues(alpha: 0.25),
              width: selected ? 2 : 1,
            ),
            color: selected ? color.withValues(alpha: 0.14) : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 14, height: 14,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? color : color.withValues(alpha: 0.55),
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    sub,
                    style: TextStyle(
                      color: color.withValues(alpha: selected ? 0.65 : 0.35),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Zone chip ──────────────────────────────────────────────────────────────
// Shows a coloured player zone label (Blue / Red) in the VS row.

class ZoneChip extends StatelessWidget {
  final Color  color;
  final String label;
  final String sub;
  const ZoneChip({
    super.key,
    required this.color,
    required this.label,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.60)),
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.12),
      ),
      child: Column(
        children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.90),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          Text(
            sub,
            style: TextStyle(
              color: color.withValues(alpha: 0.50),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
